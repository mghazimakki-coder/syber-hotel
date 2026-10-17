class HotelImageAssets {
  const HotelImageAssets._();

  static const Map<String, String> byHotelName = {
    'Syber Hotel': 'assets/images/hotels/syber_hotel.jpg',
    'Corinthia Hotel Khartoum':
        'assets/images/hotels/corinthia_hotel.jpg',
    'Acropole Hotel': 'assets/images/hotels/acropole_hotel.jpg',
    'Al Salam Hotel Khartoum': 'assets/images/hotels/al_salam_hotel.jpg',
    'Grand Holiday Villa Hotel':
        'assets/images/hotels/grand_holiday_villa.jpg',
    'EWA Khartoum Hotel & Apartments':
        'assets/images/hotels/ewa_hotel_apartments.jpg',
  };

  static String? assetForName(String hotelName) => byHotelName[hotelName];
}
