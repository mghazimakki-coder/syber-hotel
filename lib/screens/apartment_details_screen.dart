import 'package:flutter/material.dart';

import '../models/apartment.dart';
import '../services/booking_service.dart';
import '../widgets/stay_image.dart';
import 'booking_screen.dart';

class ApartmentDetailsScreen extends StatelessWidget {
  final Apartment apartment;

  const ApartmentDetailsScreen({super.key, required this.apartment});

  Future<void> _bookNow(BuildContext context) async {
    final checkIn = apartment.availabilityCheckIn;
    final checkOut = apartment.availabilityCheckOut;
    if (checkIn == null || checkOut == null) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => BookingScreen(stay: apartment)),
      );
      return;
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final available = await BookingService.isStayAvailable(
        stay: apartment,
        checkIn: checkIn,
        checkOut: checkOut,
      );
      if (!context.mounted) return;
      Navigator.pop(context);
      if (!available) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('هذه الوحدة محجوزة بالفعل خلال الفترة المحددة.'),
          ),
        );
        return;
      }
      await Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => BookingScreen(stay: apartment)),
      );
    } catch (error) {
      if (!context.mounted) return;
      Navigator.pop(context);
      final message = error is BookingRequestException
          ? error.message
          : 'تعذر التحقق من التوفر. حاول مرة أخرى';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final availabilityColor = apartment.available
        ? const Color(0xFF287A56)
        : const Color(0xFFB53B3B);
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
            'تفاصيل الشقة',
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
                    tag: 'apartment-${apartment.id}',
                    child: StayImage(
                      imageUrl: apartment.imageUrl,
                      fallbackIcon: Icons.apartment_rounded,
                      aspectRatio: 1.45,
                      apartmentHotelName: apartment.hotelName,
                      apartmentName: apartment.name,
                    ),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              sliver: SliverList.list(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          apartment.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF172A3A),
                            fontSize: 25,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _RatingBadge(rating: apartment.rating),
                    ],
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
                          apartment.location,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF687786),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _PriceCard(price: apartment.price),
                  const SizedBox(height: 24),
                  const _SectionTitle(title: 'عن الشقة'),
                  const SizedBox(height: 9),
                  Text(
                    apartment.description.trim().isEmpty
                        ? 'استمتع بإقامة مريحة في ${apartment.name}.'
                        : apartment.description,
                    style: const TextStyle(
                      color: Color(0xFF617080),
                      fontSize: 15,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const _SectionTitle(title: 'تفاصيل الإقامة'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      if (apartment.numberOfRooms > 0)
                        _Detail(
                          icon: Icons.meeting_room_outlined,
                          label: 'الغرف',
                          value: '${apartment.numberOfRooms}',
                        ),
                      if (apartment.numberOfBeds > 0)
                        _Detail(
                          icon: Icons.bed_outlined,
                          label: 'الأسرّة',
                          value: '${apartment.numberOfBeds}',
                        ),
                      if (apartment.numberOfBathrooms > 0)
                        _Detail(
                          icon: Icons.bathtub_outlined,
                          label: 'الحمامات',
                          value: '${apartment.numberOfBathrooms}',
                        ),
                      _Detail(
                        icon: Icons.home_work_outlined,
                        label: 'نوع الوحدة',
                        value: apartment.apartmentType.trim().isEmpty
                            ? 'شقة'
                            : apartment.apartmentType,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (apartment.amenities.isNotEmpty) ...[
                    const _SectionTitle(title: 'المرافق'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: apartment.amenities
                          .map(
                            (amenity) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE5E9ED),
                                ),
                              ),
                              child: Text(
                                amenity,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF405466),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: availabilityColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          apartment.available
                              ? Icons.check_circle_outline
                              : Icons.event_busy_outlined,
                          color: availabilityColor,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            apartment.available
                                ? 'الشقة متاحة للفترة المحددة'
                                : 'الشقة غير متاحة للفترة المحددة',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: availabilityColor,
                              fontWeight: FontWeight.w700,
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
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
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
            child: SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                onPressed: apartment.available ? () => _bookNow(context) : null,
                icon: const Icon(Icons.calendar_month_outlined),
                label: const Text(
                  'احجز الآن',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF173B56),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFADB7C0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
              ),
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
      width: double.infinity,
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
                  'السعر لليلة',
                  style: TextStyle(color: Color(0xFFD5DEE5), fontSize: 13),
                ),
                const SizedBox(height: 3),
                Text(
                  '${price.toStringAsFixed(0)} جنيه سوداني',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Color(0xFF172A3A),
        fontSize: 19,
        fontWeight: FontWeight.w800,
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

class _Detail extends StatelessWidget {
  const _Detail({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 138, maxWidth: 180),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E9ED)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF9A7627), size: 21),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '$label\n$value',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF405466),
                height: 1.35,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
