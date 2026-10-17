import 'package:flutter/material.dart';

import '../models/hotel.dart';
import '../screens/hotel_details_screen.dart';
import 'stay_image.dart';

class HotelCard extends StatefulWidget {
  final Hotel hotel;

  const HotelCard({
    super.key,
    required this.hotel,
  });

  @override
  State<HotelCard> createState() => _HotelCardState();
}

class _HotelCardState extends State<HotelCard> {
  bool isFavorite = false;

  @override
  Widget build(BuildContext context) {
    final hotel = widget.hotel;
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
            // =====================================
            // صورة الفندق
            // =====================================

            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(
                    child: Hero(
                      tag: 'hotel-${hotel.name}',
                      child: StayImage(
                        imageUrl: hotel.imageUrl,
                        fallbackIcon: Icons.hotel,
                        hotelName: hotel.name,
                      ),
                    ),
                  ),

                  // =====================================
                  // زر المفضلة
                  // =====================================

                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () => setState(() {
                          isFavorite = !isFavorite;
                        }),
                        tooltip: isFavorite ? 'إزالة من المفضلة' : 'إضافة للمفضلة',
                        icon: AnimatedScale(
                          scale: isFavorite ? 1.12 : 1,
                          duration: const Duration(milliseconds: 160),
                          curve: Curves.easeOut,
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: const Color(0xFFB53B3B),
                            size: 23,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // =====================================
                  // التقييم على الصورة
                  // =====================================

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
                              hotel.rating > 0
                                  ? hotel.rating.toStringAsFixed(1)
                                  : 'غير مقيّم',
                              textDirection: hotel.rating > 0
                                  ? TextDirection.ltr
                                  : TextDirection.rtl,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (hotel.rating > 0) ...[
                              const SizedBox(width: 7),
                              const Icon(
                                Icons.star,
                                color: Color(0xFFD4A72C),
                                size: 20,
                              ),
                            ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // =====================================
            // معلومات الفندق
            // =====================================

            Padding(
              padding: const EdgeInsets.fromLTRB(
                18,
                16,
                18,
                18,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // =================================
                  // اسم الفندق والتقييم
                  // =================================

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // اسم الفندق
                      Expanded(
                        child: Text(
                          hotel.name,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF171B25),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      const SizedBox(width: 12),

                      Text(
                        hotel.rating > 0
                            ? '${hotel.rating.toStringAsFixed(1)} ★'
                            : 'غير مقيّم',
                        textDirection: hotel.rating > 0
                            ? TextDirection.ltr
                            : TextDirection.rtl,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF171B25),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // =================================
                  // الموقع
                  // =================================

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
                          hotel.location,
                          textDirection: TextDirection.ltr,
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

                  const SizedBox(height: 20),

                  // =================================
                  // السعر وزر التفاصيل
                  // =================================

                  Text(
                    hotel.price > 0
                        ? 'تبدأ أسعار الوحدات من ${hotel.price.toStringAsFixed(0)} جنيه سوداني / ليلة'
                        : 'تحقق من أسعار الوحدات',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF173B56),
                    ),
                  ),
                  const SizedBox(height: 13),
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => HotelDetailsScreen(hotel: hotel),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        foregroundColor: Colors.white,
                        backgroundColor: const Color(0xFF173B56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'التفاصيل',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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