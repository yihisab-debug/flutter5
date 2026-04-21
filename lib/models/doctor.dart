class Doctor {
  final String id;
  final String name;
  final String specialization;
  final String photoUrl;
  final String description;
  final double rating;
  final int price;
  final String ownerUid;
  final String moderationStatus;

  Doctor({
    required this.id,
    required this.name,
    required this.specialization,
    required this.photoUrl,
    required this.description,
    required this.rating,
    required this.price,
    this.ownerUid = '',
    this.moderationStatus = 'pending',
  });

  bool get isApproved => moderationStatus == 'approved';
  bool get isPending => moderationStatus == 'pending';
  bool get isRejected => moderationStatus == 'rejected';

  factory Doctor.fromJson(Map<String, dynamic> json) {
    double r = (json['rating'] as num?)?.toDouble() ?? 0.0;
    if (r < 0) r = 0;
    if (r > 5) r = 5;

    String status = (json['moderationStatus'] ?? '').toString();
    if (status != 'pending' &&
        status != 'approved' &&
        status != 'rejected') {
      status = 'approved';
    }

    return Doctor(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      specialization: json['specialization'] ?? '',
      photoUrl: json['photoUrl'] ?? '',
      description: json['description'] ?? '',
      rating: r,
      price: (json['price'] as num?)?.toInt() ?? 0,
      ownerUid: (json['ownerUid'] ?? '').toString(),
      moderationStatus: status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': 'doctor',
      'name': name,
      'specialization': specialization,
      'photoUrl': photoUrl,
      'description': description,
      'rating': rating,
      'price': price,
      'ownerUid': ownerUid,
      'moderationStatus': moderationStatus,
    };
  }
}
