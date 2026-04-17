class Slot {
  final String id;
  final String doctorId;
  final String date;
  final String startTime;
  final String endTime;
  final bool isBooked;
  final String status;

  Slot({
    required this.id,
    required this.doctorId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isBooked,
    this.status = 'available',
  });

  factory Slot.fromJson(Map<String, dynamic> json) {
    final booked = json['isBooked'] == true;
    return Slot(
      id: json['id'].toString(),
      doctorId: json['doctorId'].toString(),
      date: json['date'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      isBooked: booked,
      status: json['status'] ?? (booked ? 'booked' : 'available'),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'doctorId': doctorId,
    'date': date,
    'startTime': startTime,
    'endTime': endTime,
    'isBooked': isBooked,
    'status': status,
  };

  String get statusLabel {
    switch (status) {
      case 'booked':
        return 'Занято';
      case 'available':
      default:
        return 'Свободно';
    }
  }
}