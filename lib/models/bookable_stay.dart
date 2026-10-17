abstract class BookableStay {
  const BookableStay();

  String get id;
  String get hotelId;
  String? get roomId => null;
  String? get apartmentId => null;
  String get name;
  String get location;
  String get description;
  String get imageUrl;

  String get image => imageUrl;
  double get price;
  double get rating;
  bool get available;
  List<String> get amenities;
  String get typeLabel;
  DateTime? get availabilityCheckIn => null;
  DateTime? get availabilityCheckOut => null;
}
