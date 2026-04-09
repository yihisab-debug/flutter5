class Appointment {
  final String id;
  final String userId;
  final String doctorId;
  final String slotId;
  String status; // confirmed, cancelled
  final String createdAt;

  Appointment({
    required this.id,
    required this.userId,
    required this.doctorId,
    required this.slotId,
    required this.status,
    required this.createdAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'].toString(),
      userId: json['userId'] ?? '',
      doctorId: json['doctorId'].toString(),
      slotId: json['slotId'].toString(),
      status: json['status'] ?? 'confirmed',
      createdAt: json['createdAt'] ?? '',
    );
  }
}
