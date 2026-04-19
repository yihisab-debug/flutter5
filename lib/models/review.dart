class Review {
  final String id;
  final String userId;
  final String doctorId;
  final double rating;
  final String comment;
  final String createdAt;

  Review({
    required this.id,
    required this.userId,
    required this.doctorId,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'].toString(),
      userId: json['userId'] ?? '',
      doctorId: json['doctorId'].toString(),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      comment: json['comment'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'doctorId': doctorId,
      'rating': rating,
      'comment': comment,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}
