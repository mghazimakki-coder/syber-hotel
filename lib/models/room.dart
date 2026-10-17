import 'bookable_stay.dart';

class Room extends BookableStay {
  const Room({
    required this.id,
    required this.hotelId,
    required this.roomNumber,
    required this.roomType,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.available,
    required this.location,
    this.availabilityCheckIn,
    this.availabilityCheckOut,
  });

  @override
  final String id;

  @override
  final String hotelId;

  @override
  String get roomId => id;

  final String roomNumber;
  final String roomType;

  @override
  final String description;

  @override
  final double price;

  @override
  final String imageUrl;

  @override
  final bool available;

  @override
  final String location;

  @override
  final DateTime? availabilityCheckIn;

  @override
  final DateTime? availabilityCheckOut;

  @override
  double get rating => 0;

  @override
  List<String> get amenities => const [];

  @override
  String get name => 'غرفة $roomNumber';

  @override
  String get typeLabel => roomType;
}
