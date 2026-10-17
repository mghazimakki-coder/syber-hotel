import 'package:flutter_test/flutter_test.dart';
import 'package:student_app/utils/hotel_image_assets.dart';

void main() {
  test('maps supported hotel names to their bundled image assets', () {
    expect(
      HotelImageAssets.assetForName('Syber Hotel'),
      'assets/images/hotels/syber_hotel.jpg',
    );
    expect(
      HotelImageAssets.assetForName('Corinthia Hotel Khartoum'),
      'assets/images/hotels/corinthia_hotel.jpg',
    );
    expect(
      HotelImageAssets.assetForName('Acropole Hotel'),
      'assets/images/hotels/acropole_hotel.jpg',
    );
    expect(
      HotelImageAssets.assetForName('Al Salam Hotel Khartoum'),
      'assets/images/hotels/al_salam_hotel.jpg',
    );
    expect(
      HotelImageAssets.assetForName('Grand Holiday Villa Hotel'),
      'assets/images/hotels/grand_holiday_villa.jpg',
    );
    expect(
      HotelImageAssets.assetForName('EWA Khartoum Hotel & Apartments'),
      'assets/images/hotels/ewa_hotel_apartments.jpg',
    );
  });

  test('returns no asset for an unknown hotel name', () {
    expect(HotelImageAssets.assetForName('Unknown Hotel'), isNull);
  });
}
