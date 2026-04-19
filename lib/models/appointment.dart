class Appointment {
  final String id;
  final String userId;
  final String doctorId;
  final String doctorName;
  final String doctorSpec;
  final String patientName;
  final String slotId;
  final String date;
  final String startTime;
  final String endTime;
  final int price;
  String status;
  final String createdAt;

  Appointment({
    required this.id,
    required this.userId,
    required this.doctorId,
    this.doctorName = '',
    this.doctorSpec = '',
    this.patientName = '',
    required this.slotId,
    this.date = '',
    this.startTime = '',
    this.endTime = '',
    this.price = 0,
    required this.status,
    required this.createdAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    String status = (json['status'] ?? 'pending').toString();
    if (status != 'pending' &&
        status != 'confirmed' &&
        status != 'cancelled' &&
        status != 'completed') {
      status = 'pending';
    }

    return Appointment(
      id: json['id'].toString(),
      userId: json['userId'] ?? '',
      doctorId: json['doctorId']?.toString() ?? '',
      doctorName: json['doctorName'] ?? '',
      doctorSpec: json['doctorSpec'] ?? '',
      patientName: json['patientName'] ?? '',
      slotId: json['slotId']?.toString() ?? '',
      date: json['date'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      status: status,
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'doctorId': doctorId,
      'doctorName': doctorName,
      'doctorSpec': doctorSpec,
      'patientName': patientName,
      'slotId': slotId,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'price': price,
      'status': status,
      'createdAt': createdAt,
    };
  }
}
