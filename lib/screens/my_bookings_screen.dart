import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/booking_service.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key, this.successMessage});

  final String? successMessage;

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  bool isLoading = true;
  String? error;
  List<Map<String, dynamic>> bookings = [];
  var didShowSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    try {
      final rows = await BookingService.listMyBookings();
      final hotelIds = _ids(rows, 'hotel_id');
      final roomIds = _ids(rows, 'room_id');
      final apartmentIds = _ids(rows, 'apartment_id');
      final related = await Future.wait([
        _relatedRows('hotels', 'id, name, location, image_url', hotelIds),
        _relatedRows('rooms', 'id, room_number, room_type, image_url', roomIds),
        _relatedRows('apartments', 'id, name, image_url', apartmentIds),
      ]);
      final hotelsById = _indexById(related[0]);
      final roomsById = _indexById(related[1]);
      final apartmentsById = _indexById(related[2]);
      if (!mounted) return;
      setState(() {
        bookings = rows.map((booking) {
          return {
            ...booking,
            'hotel': hotelsById[booking['hotel_id']?.toString()],
            'room': roomsById[booking['room_id']?.toString()],
            'apartment': apartmentsById[booking['apartment_id']?.toString()],
          };
        }).toList();
        isLoading = false;
      });
      if (!didShowSuccess && widget.successMessage != null) {
        didShowSuccess = true;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(widget.successMessage!)));
      }
    } catch (loadError) {
      if (!mounted) return;
      setState(() {
        error = loadError is PostgrestException
            ? loadError.message
            : loadError.toString();
        isLoading = false;
      });
    }
  }

  List<String> _ids(List<Map<String, dynamic>> rows, String key) => rows
      .map((row) => row[key]?.toString())
      .whereType<String>()
      .where((id) => id.isNotEmpty)
      .toSet()
      .toList();

  Future<List<Map<String, dynamic>>> _relatedRows(
    String table,
    String columns,
    List<String> ids,
  ) async {
    if (ids.isEmpty) return [];
    try {
      final rows = await Supabase.instance.client
          .from(table)
          .select(columns)
          .inFilter('id', ids);
      return List<Map<String, dynamic>>.from(rows);
    } on PostgrestException catch (error) {
      if (kDebugMode) {
        debugPrint(
          'My bookings relationship query failed: table=$table '
          'message=${error.message} code=${error.code} '
          'details=${error.details} hint=${error.hint}',
        );
      }
      return [];
    }
  }

  Map<String, Map<String, dynamic>> _indexById(
    List<Map<String, dynamic>> rows,
  ) => {
    for (final row in rows)
      if (row['id'] != null) row['id'].toString(): row,
  };

  Widget _bookingTile(Map<String, dynamic> booking) {
    final room = booking['room'] as Map<String, dynamic>?;
    final apartment = booking['apartment'] as Map<String, dynamic>?;
    final hotel = booking['hotel'] as Map<String, dynamic>?;
    final status = booking['status']?.toString() ?? 'pending';
    final statusLabel = switch (status) {
      'confirmed' => 'مؤكد',
      'checked_in' => 'تم تسجيل الوصول',
      'checked_out' => 'تم تسجيل المغادرة',
      'cancelled' => 'ملغي',
      _ => 'قيد الانتظار',
    };
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              room != null
                  ? 'غرفة ${room['room_number'] ?? ''} ${room['room_type'] ?? ''}'
                  : apartment?['name']?.toString() ?? 'حجز إقامة',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
            ),
            if (hotel?['name'] != null) Text(hotel!['name'].toString()),
            if (hotel?['location'] != null) Text(hotel!['location'].toString()),
            const SizedBox(height: 8),
            Text('الوصول: ${booking['check_in'] ?? '—'}'),
            Text('المغادرة: ${booking['check_out'] ?? '—'}'),
            Text('الضيوف: ${booking['guests'] ?? '—'}'),
            Text('الإجمالي: ${booking['total_price'] ?? '—'} جنيه سوداني'),
            Text('الحالة: $statusLabel'),
            if ((booking['notes']?.toString() ?? '').isNotEmpty)
              Text('ملاحظات: ${booking['notes']}'),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('حجوزاتي'),
          actions: [
            IconButton(
              onPressed: _loadBookings,
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('تعذر تحميل الحجوزات: $error'),
                ),
              )
            : bookings.isEmpty
            ? const Center(child: Text('لا توجد حجوزات'))
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: bookings.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, index) => _bookingTile(bookings[index]),
              ),
      ),
    );
  }
}
