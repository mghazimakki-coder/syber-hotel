import 'package:flutter/material.dart';

import '../models/apartment.dart';
import '../screens/apartment_details_screen.dart';
import 'stay_image.dart';

class ApartmentCard extends StatelessWidget {
  final Apartment apartment;
  final VoidCallback? onReturn;

  const ApartmentCard({super.key, required this.apartment, this.onReturn});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF173B56).withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: Hero(
                      tag: 'apartment-${apartment.id}',
                      child: StayImage(
                        imageUrl: apartment.imageUrl,
                        fallbackIcon: Icons.apartment,
                        apartmentHotelName: apartment.hotelName,
                        apartmentName: apartment.name,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: apartment.available
                            ? const Color(0xFF287A56)
                            : const Color(0xFFB53B3B),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        apartment.available ? 'متاحة' : 'غير متاحة',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            apartment.rating.toStringAsFixed(1),
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 7),
                          const Icon(
                            Icons.star,
                            color: Color(0xFFD4A72C),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    apartment.name,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF171B25),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFF7A8490),
                        size: 21,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          apartment.location,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF7A8490),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 14,
                    runSpacing: 8,
                    children: [
                      if (apartment.numberOfRooms > 0)
                        _Info(
                          icon: Icons.meeting_room_outlined,
                          value: '${apartment.numberOfRooms} غرف',
                        ),
                      if (apartment.numberOfBeds > 0)
                        _Info(
                          icon: Icons.bed_outlined,
                          value: '${apartment.numberOfBeds} أسرّة',
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'السعر لليلة',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '${apartment.price.toStringAsFixed(0)} جنيه سوداني',
                              style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF173B56),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () async {
                            await Navigator.push<void>(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ApartmentDetailsScreen(
                                  apartment: apartment,
                                ),
                              ),
                            );
                            if (context.mounted) onReturn?.call();
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: const Color(0xFF173B56),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'التفاصيل',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  final IconData icon;
  final String value;

  const _Info({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF245A7A)),
        const SizedBox(width: 4),
        Text(value, style: const TextStyle(color: Colors.black54)),
      ],
    );
  }
}
