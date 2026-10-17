import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/bookable_stay.dart';
import 'booking_inventory_policy.dart';

class BookingConflictException implements Exception {
  const BookingConflictException();

  @override
  String toString() => 'هذه الوحدة محجوزة بالفعل خلال الفترة المحددة.';
}

class BookingService {
  BookingService._();

  static final SupabaseClient _client = Supabase.instance.client;

  static Future<Map<String, bool>> listInventoryAvailability({
    required String hotelId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    final rows = await _inventoryAvailability(
      hotelId: hotelId,
      checkIn: checkIn,
      checkOut: checkOut,
    );
    return {
      for (final row in rows)
        '${row['inventory_type']}:${row['inventory_id']}':
            row['available'] == true,
    };
  }

  static Future<bool> isStayAvailable({
    required BookableStay stay,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    final itemId = _cleanId(stay.roomId ?? stay.apartmentId);
    if (itemId == null || !checkOut.isAfter(checkIn)) {
      throw const BookingRequestException('بيانات الوحدة أو التواريخ غير صحيحة');
    }
    final inventoryType = stay.roomId == null ? 'apartment' : 'room';
    final rows = await _inventoryAvailability(
      hotelId: stay.hotelId,
      checkIn: checkIn,
      checkOut: checkOut,
      inventoryType: inventoryType,
      inventoryId: itemId,
    );
    if (rows.length != 1) {
      throw const BookingRequestException('تعذر العثور على الوحدة المحددة');
    }
    return rows.single['available'] == true;
  }

  static Future<List<Map<String, dynamic>>> _inventoryAvailability({
    required String hotelId,
    required DateTime checkIn,
    required DateTime checkOut,
    String? inventoryType,
    String? inventoryId,
  }) async {
    if (hotelId.trim().isEmpty || !checkOut.isAfter(checkIn)) {
      throw const BookingRequestException('بيانات الفندق أو التواريخ غير صحيحة');
    }
    final rows = await _client.rpc(
      'get_inventory_availability',
      params: {
        'p_hotel_id': hotelId,
        'p_check_in': _dateValue(checkIn),
        'p_check_out': _dateValue(checkOut),
        'p_inventory_type': inventoryType,
        'p_inventory_id': inventoryId,
      },
    );
    return List<Map<String, dynamic>>.from(rows as List);
  }

  static Future<Map<String, dynamic>> createBooking({
    required BookableStay stay,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
    required double totalPrice,
    String notes = '',
  }) async {
    final user = _client.auth.currentUser;
    final roomId = _cleanId(stay.roomId);
    final apartmentId = _cleanId(stay.apartmentId);
    final hotelId = stay.hotelId;
    if (kDebugMode) {
      debugPrint(
        'Booking create: user_id=${user?.id}, hotel_id=$hotelId, '
        'room_id=$roomId, apartment_id=$apartmentId, '
        'check_in=${_dateValue(checkIn)}, check_out=${_dateValue(checkOut)}, '
        'guests=$guests, total_price=$totalPrice',
      );
    }
    if (user == null) {
      throw const BookingRequestException(
        'انتهت جلسة تسجيل الدخول، يرجى تسجيل الدخول مرة أخرى',
      );
    }
    if (hotelId.isEmpty) {
      throw const BookingRequestException('تعذر تحديد الفندق لهذا الحجز');
    }
    final hasRoom = roomId != null && roomId.isNotEmpty;
    final hasApartment = apartmentId != null && apartmentId.isNotEmpty;
    if (hasRoom == hasApartment) {
      throw const BookingRequestException('يجب تحديد غرفة أو شقة واحدة للحجز');
    }
    if (!checkOut.isAfter(checkIn)) {
      throw const BookingRequestException(
        'تاريخ المغادرة يجب أن يكون بعد الوصول',
      );
    }
    if (guests < 1 || !totalPrice.isFinite || totalPrice <= 0) {
      throw const BookingRequestException('بيانات الحجز غير صحيحة');
    }

    try {
      final availability = await _inventoryAvailability(
        hotelId: hotelId,
        checkIn: checkIn,
        checkOut: checkOut,
        inventoryType: hasRoom ? 'room' : 'apartment',
        inventoryId: hasRoom ? roomId : apartmentId,
      );
      if (availability.length != 1) {
        throw const BookingRequestException('تعذر العثور على الوحدة المحددة');
      }
      if (availability.single['available'] != true) {
        throw const BookingConflictException();
      }

      final values = buildPendingBookingPayload(
        userId: user.id,
        hotelId: hotelId,
        roomId: roomId,
        apartmentId: apartmentId,
        checkIn: _dateValue(checkIn),
        checkOut: _dateValue(checkOut),
        guests: guests,
        totalPrice: totalPrice,
        notes: notes.trim(),
      );
      final inserted = await _client
          .from('bookings')
          .insert(values)
          .select()
          .single();
      final booking = Map<String, dynamic>.from(inserted);
      final bookingId = booking['id'];
      if (bookingId == null || bookingId.toString().isEmpty) {
        throw const BookingRequestException(
          'لم يتم تأكيد حفظ الحجز في قاعدة البيانات',
        );
      }
      if (kDebugMode) {
        debugPrint(
          'Booking insert succeeded: booking_id=$bookingId, '
          'user_id=${user.id}, hotel_id=$hotelId',
        );
      }
      return booking;
    } on BookingConflictException {
      rethrow;
    } on PostgrestException catch (error) {
      if (kDebugMode) {
        debugPrint(
          'Booking Supabase error: message=${error.message}, '
          'status=unavailable (not exposed by PostgrestException), '
          'code=${error.code}, details=${error.details}, hint=${error.hint}',
        );
      }
      if (error.code == '23P01') throw const BookingConflictException();
      throw BookingRequestException(
        bookingDatabaseErrorMessage(code: error.code, message: error.message),
      );
    } catch (error) {
      if (kDebugMode) debugPrint('Booking error: $error');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> listMyBookings() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const BookingRequestException(
        'انتهت جلسة تسجيل الدخول، يرجى تسجيل الدخول مرة أخرى',
      );
    }
    final scope = BookingVisibilityScope.forRole(
      role: 'customer',
      userId: user.id,
    );
    final rows = await _client
        .from('bookings')
        .select('*')
        .eq(scope.column, scope.value)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  static String _dateValue(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static String? _cleanId(String? value) {
    final id = value?.trim();
    return id == null || id.isEmpty ? null : id;
  }
}

class BookingRequestException implements Exception {
  const BookingRequestException(this.message);

  final String message;

  @override
  String toString() => message;
}
