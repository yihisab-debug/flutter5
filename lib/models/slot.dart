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
    bool booked = json['isBooked'] == true;
    String status = json['status'] ?? '';
    if (status.isEmpty) {
      if (booked) {
        status = 'booked';
      } else {
        status = 'available';
      }
    }

    return Slot(
      id: json['id'].toString(),
      doctorId: json['doctorId'].toString(),
      date: json['date'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      isBooked: booked,
      status: status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': 'slot',
      'doctorId': doctorId,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'isBooked': isBooked,
      'status': status,
    };
  }

  String get statusLabel {
    if (status == 'booked') {
      return 'Занято';
    }
    return 'Свободно';
  }
}
