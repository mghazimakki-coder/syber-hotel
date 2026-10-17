class ApartmentImageMapper {
  const ApartmentImageMapper._();

  static const Map<String, Map<String, String>> _assetsByHotelAndApartment = {
    'Syber Hotel': {
      'شقة اقتصادية': 'assets/images/apartments/apartment_01.jpg',
      'شقة عائلية': 'assets/images/apartments/apartment_02.jpg',
      'شقة فاخرة': 'assets/images/apartments/apartment_03.jpg',
      'اليمن': 'assets/images/apartments/apartment_04.jpg',
    },
    'Acropole Hotel': {
      'شقة ستاندرد': 'assets/images/apartments/apartment_05.jpg',
      'شقة عائلية': 'assets/images/apartments/apartment_06.jpg',
      'شقة فاخرة': 'assets/images/apartments/apartment_07.jpg',
    },
    'Corinthia Hotel Khartoum': {
      'شقة ستاندرد': 'assets/images/apartments/apartment_08.jpg',
      'شقة عائلية': 'assets/images/apartments/apartment_09.jpg',
      'شقة فاخرة': 'assets/images/apartments/apartment_10.jpg',
    },
    'Al Salam Hotel Khartoum': {
      'شقة ستاندرد': 'assets/images/apartments/apartment_11.jpg',
      'شقة عائلية': 'assets/images/apartments/apartment_12.jpg',
      'شقة فاخرة': 'assets/images/apartments/apartment_13.jpg',
    },
    'Grand Holiday Villa Hotel': {
      'شقة ستاندرد': 'assets/images/apartments/apartment_14.jpg',
      'شقة عائلية': 'assets/images/apartments/apartment_15.jpg',
      'شقة فاخرة': 'assets/images/apartments/apartment_16.jpg',
    },
    'EWA Khartoum Hotel & Apartments': {
      'شقة ستاندرد': 'assets/images/apartments/apartment_17.jpg',
      'شقة عائلية': 'assets/images/apartments/apartment_18.jpg',
      'شقة فاخرة': 'assets/images/apartments/apartment_19.jpg',
    },
  };

  static String? assetFor({
    required String hotelName,
    required String apartmentName,
  }) {
    return _assetsByHotelAndApartment[hotelName.trim()]?[apartmentName.trim()];
  }
}
