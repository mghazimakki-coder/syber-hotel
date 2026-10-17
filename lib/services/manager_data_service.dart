import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'booking_inventory_policy.dart';

class ManagerReportData {
  const ManagerReportData({
    required this.bookings,
    required this.rooms,
    required this.apartments,
  });

  final List<Map<String, dynamic>> bookings;
  final List<Map<String, dynamic>> rooms;
  final List<Map<String, dynamic>> apartments;
}

class ManagerDataService {
  ManagerDataService._();

  static final SupabaseClient _client = Supabase.instance.client;

  static Future<String> currentHotelId() async {
    return _currentAssignedHotelId({'manager'});
  }

  static Future<ManagerReportData> loadManagerReportData() async {
    final hotelId = await currentHotelId();
    final results = await Future.wait([
      _listBookingsForHotel(hotelId),
      _listInventoryForHotel('rooms', hotelId),
      _listInventoryForHotel('apartments', hotelId),
    ]);
    return ManagerReportData(
      bookings: results[0],
      rooms: results[1],
      apartments: results[2],
    );
  }

  static Future<String> _currentAssignedHotelId(
    Set<String> allowedRoles,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (kDebugMode) debugPrint('Bookings: current user id=$userId');
    if (userId == null) throw StateError('انتهت جلسة تسجيل الدخول');

    final Map<String, dynamic>? profile;
    try {
      profile = await _client
          .from('profiles')
          .select('hotel_id, role')
          .eq('id', userId)
          .maybeSingle();
    } on PostgrestException catch (error) {
      if (kDebugMode) {
        debugPrint(
          'Bookings: profile query failed user_id=$userId '
          'message=${error.message} code=${error.code} '
          'details=${error.details} hint=${error.hint}',
        );
      }
      throw BookingWorkflowException(
        bookingDatabaseErrorMessage(code: error.code, message: error.message),
      );
    }
    final hotelId = profile?['hotel_id'] as String?;
    final role = profile?['role'] as String?;
    if (kDebugMode) {
      debugPrint('Bookings: role=$role, manager hotel_id=$hotelId');
    }
    if (role == null || !allowedRoles.contains(role)) {
      throw StateError('ليس لديك صلاحية الوصول إلى حجوزات هذا الفندق');
    }
    return BookingVisibilityScope.forRole(
      role: role,
      userId: userId,
      assignedHotelId: hotelId,
    ).value;
  }

  static Future<List<Map<String, dynamic>>> list(String table) async {
    final hotelId = await currentHotelId();
    final rows = await _client.from(table).select('*').eq('hotel_id', hotelId);
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<List<Map<String, dynamic>>> listBookingsForManager() async {
    final hotelId = await currentHotelId();
    return _listBookingsForHotel(hotelId);
  }

  static Future<List<Map<String, dynamic>>>
  listBookingsForReceptionist() async {
    final hotelId = await _currentAssignedHotelId({'receptionist'});
    return _listBookingsForHotel(hotelId);
  }

  static Future<List<Map<String, dynamic>>> listRoomsForReceptionist() async {
    final hotelId = await _currentAssignedHotelId({'receptionist'});
    final rows = await _client
        .from('rooms')
        .select('id, hotel_id, room_number, room_type, price, status')
        .eq('hotel_id', hotelId)
        .order('room_number');
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<List<Map<String, dynamic>>>
  listApartmentsForReceptionist() async {
    final hotelId = await _currentAssignedHotelId({'receptionist'});
    final rows = await _client
        .from('apartments')
        .select('id, hotel_id, name, price, status, description')
        .eq('hotel_id', hotelId)
        .order('name');
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<Map<String, int>> receptionistDashboardSummary() async {
    final hotelId = await _currentAssignedHotelId({'receptionist'});
    final results = await Future.wait([
      _client
          .from('bookings')
          .select('status, check_in, check_out')
          .eq('hotel_id', hotelId),
      _client.from('rooms').select('status').eq('hotel_id', hotelId),
    ]);
    final bookings = List<Map<String, dynamic>>.from(results[0]);
    final rooms = List<Map<String, dynamic>>.from(results[1]);
    final today = _dateKey(DateTime.now());
    return {
      'total_bookings': bookings.length,
      'pending_bookings': bookings
          .where((booking) => booking['status'] == 'pending')
          .length,
      'confirmed_bookings': bookings
          .where((booking) => booking['status'] == 'confirmed')
          .length,
      'check_ins_today': bookings
          .where(
            (booking) =>
                booking['status'] == 'confirmed' &&
                _dateKey(booking['check_in']) == today,
          )
          .length,
      'check_outs_today': bookings
          .where(
            (booking) =>
                booking['status'] == 'checked_in' &&
                _dateKey(booking['check_out']) == today,
          )
          .length,
      'available_rooms': rooms
          .where((room) => room['status'] == 'available')
          .length,
      'occupied_rooms': rooms
          .where((room) => room['status'] == 'occupied')
          .length,
    };
  }

  static Future<void> updateReceptionistBookingStatus(
    String id,
    String nextStatus,
  ) async {
    await _updateBookingStatus(id, nextStatus, allowedRoles: {'receptionist'});
  }

  static String _dateKey(dynamic value) {
    if (value is DateTime) {
      return '${value.year.toString().padLeft(4, '0')}-'
          '${value.month.toString().padLeft(2, '0')}-'
          '${value.day.toString().padLeft(2, '0')}';
    }
    return value?.toString().split('T').first ?? '';
  }

  static Future<List<Map<String, dynamic>>> _listBookingsForHotel(
    String hotelId,
  ) async {
    final List<dynamic> rows;
    try {
      rows = await _client
          .from('bookings')
          .select('*')
          .eq('hotel_id', hotelId)
          .order('created_at', ascending: false);
    } on PostgrestException catch (error) {
      if (kDebugMode) {
        debugPrint(
          'Bookings query failed: hotel_id=$hotelId, '
          'message=${error.message}, code=${error.code}, '
          'details=${error.details}, hint=${error.hint}',
        );
      }
      rethrow;
    }
    if (kDebugMode) {
      debugPrint('Bookings: hotel_id=$hotelId, returned=${rows.length}');
      if (rows.isEmpty) {
        debugPrint(
          'Bookings: no visible rows for hotel_id=$hotelId; '
          'check the stored booking hotel_id and bookings SELECT RLS policy.',
        );
      }
    }
    final bookings = List<Map<String, dynamic>>.from(rows);
    if (bookings.isEmpty) return bookings;

    final customerIds = bookings
        .map((booking) => booking['user_id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final roomIds = bookings
        .map((booking) => booking['room_id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final apartmentIds = bookings
        .map((booking) => booking['apartment_id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    final hotelIds = bookings
        .map((booking) => booking['hotel_id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    final customerRowsFuture = _loadCustomerRows(customerIds);
    final relatedRows = await Future.wait([
      _loadRelatedRows(
        'rooms',
        'id, room_number, room_type',
        'id',
        roomIds,
        hotelId,
      ),
      _loadRelatedRows('apartments', 'id, name', 'id', apartmentIds, hotelId),
      _loadRelatedRows('hotels', 'id, name, location', 'id', hotelIds, hotelId),
    ]);
    final customerRows = await customerRowsFuture;
    final customersById = _indexById(customerRows);
    final roomsById = _indexById(relatedRows[0]);
    final apartmentsById = _indexById(relatedRows[1]);
    final hotelsById = _indexById(relatedRows[2]);

    return bookings.map((booking) {
      final customer = customersById[booking['user_id']?.toString()];
      final room = roomsById[booking['room_id']?.toString()];
      final apartment = apartmentsById[booking['apartment_id']?.toString()];
      final hotel = hotelsById[booking['hotel_id']?.toString()];
      return {
        ...booking,
        'customer_name': customer?['full_name'],
        'customer_phone': customer?['phone'],
        'customer_email': customer?['email'],
        'hotel_name': hotel?['name'],
        'hotel_location': hotel?['location'],
        'room_number': room?['room_number'],
        'room_type': room?['room_type'],
        'apartment_name': apartment?['name'],
      };
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> _listInventoryForHotel(
    String table,
    String hotelId,
  ) async {
    final rows = await _client
        .from(table)
        .select('id, status')
        .eq('hotel_id', hotelId);
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<void> updateBookingStatus(String id, String status) async {
    await _updateBookingStatus(id, status, allowedRoles: {'manager'});
  }

  static Future<void> _updateBookingStatus(
    String id,
    String nextStatus, {
    required Set<String> allowedRoles,
  }) async {
    if (!bookingStatusTransitions.containsKey(nextStatus)) {
      throw ArgumentError.value(nextStatus, 'status', 'Invalid booking status');
    }

    final hotelId = await _currentAssignedHotelId(allowedRoles);
    final booking = await _client
        .from('bookings')
        .select('status')
        .eq('id', id)
        .eq('hotel_id', hotelId)
        .maybeSingle();
    final currentStatus = booking?['status']?.toString();
    if (currentStatus == null) {
      throw const BookingWorkflowException('تعذر العثور على الحجز');
    }
    if (!canTransitionBookingStatus(currentStatus, nextStatus)) {
      throw const BookingWorkflowException(
        'لا يمكن تنفيذ هذا الإجراء على حالة الحجز الحالية',
      );
    }

    try {
      await _client.rpc(
        'transition_booking_status',
        params: {'p_booking_id': id, 'p_next_status': nextStatus},
      );
    } on PostgrestException catch (error) {
      if (kDebugMode) {
        debugPrint(
          'Booking transition failed: booking_id=$id hotel_id=$hotelId '
          'from=$currentStatus to=$nextStatus code=${error.code} '
          'message=${error.message} details=${error.details} hint=${error.hint}',
        );
      }
      throw BookingWorkflowException(
        bookingDatabaseErrorMessage(code: error.code, message: error.message),
      );
    }
  }

  static Future<List<Map<String, dynamic>>> _loadRelatedRows(
    String table,
    String columns,
    String idColumn,
    List<String> ids,
    String hotelId,
  ) async {
    if (ids.isEmpty) return [];
    try {
      var query = _client.from(table).select(columns).inFilter(idColumn, ids);
      query = table == 'hotels'
          ? query.eq('id', hotelId)
          : query.eq('hotel_id', hotelId);
      final rows = await query;
      return List<Map<String, dynamic>>.from(rows);
    } on PostgrestException catch (error) {
      if (kDebugMode) {
        debugPrint('Bookings: $table lookup error=${error.message}');
      }
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> _loadCustomerRows(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return [];
    try {
      final rows = await _client
          .from('profiles')
          .select('id, full_name, phone, email')
          .inFilter('id', ids);
      return List<Map<String, dynamic>>.from(rows);
    } on PostgrestException catch (error) {
      if (kDebugMode) {
        debugPrint(
          'Bookings: customer name/email lookup error=${error.message}',
        );
      }
      try {
        final rows = await _client
            .from('profiles')
            .select('id, full_name, phone')
            .inFilter('id', ids);
        return List<Map<String, dynamic>>.from(rows);
      } on PostgrestException catch (fallbackError) {
        if (kDebugMode) {
          debugPrint(
            'Bookings: customer name lookup error=${fallbackError.message}',
          );
        }
        try {
          final rows = await _client
              .from('profiles')
              .select('id, full_name')
              .inFilter('id', ids);
          return List<Map<String, dynamic>>.from(rows);
        } on PostgrestException catch (nameError) {
          if (kDebugMode) {
            debugPrint(
              'Bookings: customer name lookup error=${nameError.message}',
            );
          }
          return [];
        }
      }
    }
  }

  static Map<String, Map<String, dynamic>> _indexById(
    List<Map<String, dynamic>> rows,
  ) => {
    for (final row in rows)
      if (row['id'] != null) row['id'].toString(): row,
  };

  static Future<Map<String, dynamic>?> find(String table, String id) async {
    final hotelId = await currentHotelId();
    final row = await _client
        .from(table)
        .select('*')
        .eq('id', id)
        .eq('hotel_id', hotelId)
        .maybeSingle();
    return row;
  }

  static Future<void> insert(String table, Map<String, dynamic> values) async {
    final hotelId = await currentHotelId();
    await _client.from(table).insert({...values, 'hotel_id': hotelId});
  }

  static Future<void> update(
    String table,
    String id,
    Map<String, dynamic> values,
  ) async {
    final hotelId = await currentHotelId();
    await _client
        .from(table)
        .update(values)
        .eq('id', id)
        .eq('hotel_id', hotelId);
  }

  static Future<void> delete(String table, String id) async {
    final hotelId = await currentHotelId();
    await _client.from(table).delete().eq('id', id).eq('hotel_id', hotelId);
  }
}
