class Hotel {
  final String name;
  final String location;
  final double price;
  final String image;
  final double rating;

  const Hotel({
    required this.name,
    required this.location,
    required this.price,
    required this.image,
    this.rating = 0,
  });
}