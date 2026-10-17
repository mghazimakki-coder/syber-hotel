import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/hotel.dart';
import '../models/room.dart';
import '../services/booking_service.dart';
import '../widgets/stay_image.dart';
import 'apartment_list_screen.dart';
import 'booking_screen.dart';

class HotelDetailsScreen extends StatelessWidget {
  final Hotel hotel;

  const HotelDetailsScreen({super.key, required this.hotel});

  Future<void> _selectRoomAndBook(BuildContext context) async {
    try {
      final today = DateTime.now();
      final checkIn = await showDatePicker(
        context: context,
        initialDate: DateTime(today.year, today.month, today.day),
        firstDate: DateTime(today.year, today.month, today.day),
        lastDate: DateTime(today.year + 2),
        helpText: 'اختر تاريخ الوصول',
      );
      if (checkIn == null || !context.mounted) return;
      final checkOut = await showDatePicker(
        context: context,
        initialDate: checkIn.add(const Duration(days: 1)),
        firstDate: checkIn.add(const Duration(days: 1)),
        lastDate: DateTime(today.year + 2),
        helpText: 'اختر تاريخ المغادرة',
      );
      if (checkOut == null || !context.mounted) return;

      final client = Supabase.instance.client;
      Future<dynamic> loadRooms() async => await client
          .from('rooms')
          .select(
            'id, hotel_id, room_number, room_type, description, price, image_url, status',
          )
          .eq('hotel_id', hotel.id);
      final results = await Future.wait<dynamic>([
        loadRooms(),
        BookingService.listInventoryAvailability(
          hotelId: hotel.id,
          checkIn: checkIn,
          checkOut: checkOut,
        ),
      ]);
      final rooms = List<Map<String, dynamic>>.from(results[0] as List);
      final availability = results[1] as Map<String, bool>;
      if (!context.mounted) return;
      if (rooms.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا توجد غرف مسجلة في هذا الفندق')),
        );
        return;
      }
      final selected = await showModalBottomSheet<Room>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        backgroundColor: const Color(0xFFF6F7F9),
        builder: (sheetContext) => SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.78,
            ),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              children: [
                const Text(
                  'اختر الغرفة',
                  style: TextStyle(
                    color: Color(0xFF173B56),
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${hotel.name} · ${_dateLabel(checkIn)} – ${_dateLabel(checkOut)}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFF687786)),
                ),
                const SizedBox(height: 14),
                ...rooms.map((row) {
                  final room = Room(
                    id: row['id'].toString(),
                    hotelId: row['hotel_id'].toString(),
                    roomNumber: row['room_number']?.toString() ?? '',
                    roomType: row['room_type']?.toString() ?? 'غرفة',
                    description: row['description']?.toString() ?? '',
                    price: (row['price'] as num?)?.toDouble() ?? 0,
                    imageUrl: row['image_url']?.toString() ?? hotel.imageUrl,
                    available: availability['room:${row['id']}'] ?? false,
                    location: hotel.location,
                    availabilityCheckIn: checkIn,
                    availabilityCheckOut: checkOut,
                  );
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RoomOptionCard(
                      room: room,
                      onTap: room.available
                          ? () => Navigator.pop(sheetContext, room)
                          : null,
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      );
      if (selected == null || !context.mounted) return;
      await Navigator.push<void>(
        context,
        MaterialPageRoute<void>(builder: (_) => BookingScreen(stay: selected)),
      );
    } on PostgrestException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تحميل الغرف: ${error.message}')),
      );
    } on BookingRequestException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  static String _dateLabel(DateTime value) =>
      '${value.day}/${value.month}/${value.year}';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7F9),
        appBar: AppBar(
          backgroundColor: const Color(0xFFF6F7F9),
          foregroundColor: const Color(0xFF173B56),
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'تفاصيل الفندق',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Hero(
                    tag: 'hotel-${hotel.name}',
                    child: StayImage(
                      imageUrl: hotel.imageUrl,
                      fallbackIcon: Icons.hotel_rounded,
                      aspectRatio: 1.45,
                      hotelName: hotel.name,
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              sliver: SliverList.list(
                children: [
                  Text(
                    hotel.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF172A3A),
                      fontSize: 26,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFF9A7627),
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          hotel.location,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF687786),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _RatingBadge(rating: hotel.rating),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _PriceCard(price: hotel.price),
                  const SizedBox(height: 24),
                  const Text(
                    'عن الفندق',
                    style: TextStyle(
                      color: Color(0xFF172A3A),
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    hotel.description.trim().isEmpty
                        ? 'اكتشف ${hotel.name} في ${hotel.location} واستمتع بإقامة مريحة.'
                        : hotel.description,
                    style: const TextStyle(
                      color: Color(0xFF617080),
                      fontSize: 15,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE7EBEF)),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          color: Color(0xFF9A7627),
                        ),
                        SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            'اختر تواريخ إقامتك لمراجعة الغرف المتاحة وأسعارها.',
                            style: TextStyle(
                              color: Color(0xFF405466),
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF172A3A).withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () => _selectRoomAndBook(context),
                    icon: const Icon(Icons.hotel_outlined),
                    label: const Text(
                      'اختر غرفة للحجز',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF173B56),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                TextButton.icon(
                  onPressed: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ApartmentListScreen(hotelId: hotel.id),
                    ),
                  ),
                  icon: const Icon(Icons.apartment_outlined, size: 20),
                  label: const Text('عرض الشقق في هذا الفندق'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF173B56),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  const _PriceCard({required this.price});

  final double price;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF173B56),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF173B56).withValues(alpha: 0.14),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Color(0x33FFFFFF),
            foregroundColor: Color(0xFFF0CC72),
            child: Icon(Icons.payments_outlined),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'أسعار الإقامة تبدأ من',
                  style: TextStyle(color: Color(0xFFD5DEE5), fontSize: 13),
                ),
                const SizedBox(height: 3),
                Text(
                  price > 0
                      ? '${price.toStringAsFixed(0)} جنيه سوداني / ليلة'
                      : 'تحقق من أسعار الوحدات',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.rating});

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6DF),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, color: Color(0xFFD4A72C), size: 18),
          const SizedBox(width: 4),
          Text(
            rating > 0 ? rating.toStringAsFixed(1) : 'غير مقيّم',
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              color: Color(0xFF604A16),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomOptionCard extends StatelessWidget {
  const _RoomOptionCard({required this.room, required this.onTap});

  final Room room;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = room.available
        ? const Color(0xFF287A56)
        : const Color(0xFFB53B3B);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5E9ED)),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: StayImage(
                    imageUrl: room.imageUrl,
                    fallbackIcon: Icons.bed_rounded,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'غرفة ${room.roomNumber} · ${room.roomType}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF172A3A),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    if (room.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        room.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF687786),
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 7),
                    Text(
                      '${room.price.toStringAsFixed(0)} جنيه سوداني / ليلة',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF173B56),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      room.available ? 'متاحة' : 'غير متاحة',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                room.available ? Icons.chevron_left : Icons.block_outlined,
                color: statusColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
