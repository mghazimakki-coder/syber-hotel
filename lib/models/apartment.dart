import 'bookable_stay.dart';

class Apartment extends BookableStay {
  @override
  final String id;

  @override
  final String hotelId;

  final String hotelName;

  @override
  String? get apartmentId => id;

  @override
  final String name;

  @override
  final String location;

  @override
  final String description;

  @override
  final String imageUrl;

  @override
  final double price;

  @override
  final double rating;

  final int numberOfRooms;
  final int numberOfBeds;
  final int numberOfBathrooms;
  final String apartmentType;

  @override
  final bool available;

  @override
  final List<String> amenities;

  @override
  final DateTime? availabilityCheckIn;

  @override
  final DateTime? availabilityCheckOut;

  @override
  String get typeLabel => 'شقة';

  const Apartment({
    required this.id,
    this.hotelId = '',
    this.hotelName = '',
    required this.name,
    required this.location,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.rating,
    required this.numberOfRooms,
    required this.numberOfBeds,
    required this.numberOfBathrooms,
    required this.apartmentType,
    required this.available,
    required this.amenities,
    this.availabilityCheckIn,
    this.availabilityCheckOut,
  });
}
