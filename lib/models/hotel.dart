import 'bookable_stay.dart';

class Hotel extends BookableStay {
  @override
  final String id;

  @override
  String get hotelId => id;

  @override
  final String name;

  @override
  final String location;

  @override
  final String description;

  @override
  final double price;

  @override
  final String imageUrl;

  @override
  final double rating;

  @override
  final bool available;

  @override
  final List<String> amenities;

  @override
  String get typeLabel => 'فندق';

  const Hotel({
    this.id = '',
    required this.name,
    required this.location,
    required this.price,
    required this.imageUrl,
    this.rating = 0,
    this.description = '',
    this.available = true,
    this.amenities = const [],
  });

  factory Hotel.fromMap(Map<String, dynamic> map, {double price = 0}) {
    return Hotel(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      location: map['location']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      imageUrl: map['image_url']?.toString() ?? '',
      price: price,
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
    );
  }
}
