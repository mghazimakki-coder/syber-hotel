import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../utils/apartment_image_assets.dart';
import '../utils/hotel_image_assets.dart';

class StayImage extends StatelessWidget {
  const StayImage({
    super.key,
    required this.imageUrl,
    required this.fallbackIcon,
    this.aspectRatio = 16 / 9,
    this.hotelName,
    this.apartmentHotelName,
    this.apartmentName,
  });

  final String imageUrl;
  final IconData fallbackIcon;
  final double aspectRatio;
  final String? hotelName;
  final String? apartmentHotelName;
  final String? apartmentName;

  @override
  Widget build(BuildContext context) {
    final hotelAsset = hotelName == null
        ? null
        : HotelImageAssets.assetForName(hotelName!);
    final apartmentAsset = apartmentHotelName == null || apartmentName == null
        ? null
        : ApartmentImageMapper.assetFor(
            hotelName: apartmentHotelName!,
            apartmentName: apartmentName!,
          );
    final resolvedApartmentImage =
        apartmentAsset != null &&
            RegExp(
              r'^assets/images/apartments/apartment_(0[1-9]|1[0-9])\.jpg$',
            ).hasMatch(apartmentAsset)
        ? apartmentAsset
        : null;

    Widget buildApartmentImage() {
      if (resolvedApartmentImage == null) {
        return _ApartmentImagePlaceholder(
          apartmentName: apartmentName!,
          hotelName: apartmentHotelName ?? '',
        );
      }
      if (kDebugMode) {
        debugPrint(
          'APARTMENT IMAGE => '
          'hotel=${apartmentHotelName ?? ''}, '
          'apartment=$apartmentName, '
          'asset=$resolvedApartmentImage',
        );
      }
      return Image.asset(resolvedApartmentImage, fit: BoxFit.cover);
    }

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: apartmentName != null
          ? buildApartmentImage()
          : hotelName != null
          ? hotelAsset == null
                ? _StayImagePlaceholder(icon: fallbackIcon)
                : Image.asset(
                    hotelAsset,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _StayImagePlaceholder(icon: fallbackIcon),
                  )
          : imageUrl.trim().isEmpty
          ? _StayImagePlaceholder(icon: fallbackIcon)
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) return child;
                return AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOut,
                  child: child,
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const ColoredBox(
                  color: Color(0xFFE8EDF0),
                  child: Center(
                    child: SizedBox(
                      width: 25,
                      height: 25,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF245A7A),
                      ),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) =>
                  _StayImagePlaceholder(icon: fallbackIcon),
            ),
    );
  }
}

class _ApartmentImagePlaceholder extends StatelessWidget {
  const _ApartmentImagePlaceholder({
    required this.apartmentName,
    required this.hotelName,
  });

  final String apartmentName;
  final String hotelName;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF102F43), Color(0xFF31586A), Color(0xFFB08C46)],
          stops: [0, 0.72, 1],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -48,
            left: -35,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.1),
                  width: 24,
                ),
              ),
            ),
          ),
          Positioned(
            right: 18,
            bottom: 18,
            child: Icon(
              Icons.king_bed_rounded,
              size: 72,
              color: Colors.white.withValues(alpha: 0.17),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.apartment_rounded,
                  size: 36,
                  color: Color(0xFFFFE5A3),
                ),
                const SizedBox(height: 12),
                Text(
                  apartmentName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                if (hotelName.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    hotelName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xD9FFFFFF),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StayImagePlaceholder extends StatelessWidget {
  const _StayImagePlaceholder({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF31536A), Color(0xFF172F43), Color(0xFFB08C46)],
          stops: [0, 0.68, 1],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -38,
            left: -24,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 22,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -54,
            right: -34,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              ),
              child: Icon(icon, size: 38, color: const Color(0xFFFFE5A3)),
            ),
          ),
          const Positioned(
            bottom: 12,
            left: 14,
            child: Text(
              'SYBER HOTEL',
              style: TextStyle(
                color: Color(0xB3FFFFFF),
                fontSize: 10,
                letterSpacing: 2.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
