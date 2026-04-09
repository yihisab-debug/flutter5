class Doctor {
  final String id;
  final String name;
  final String specialization;
  final String photoUrl;
  final String description;
  final double rating;
  final int price;

  Doctor({
    required this.id,
    required this.name,
    required this.specialization,
    required this.photoUrl,
    required this.description,
    required this.rating,
    required this.price,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      specialization: json['specialization'] ?? '',
      photoUrl: json['photoUrl'] ?? '',
      description: json['description'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      price: (json['price'] as num?)?.toInt() ?? 0,
    );
  }
}
