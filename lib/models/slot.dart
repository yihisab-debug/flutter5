class Slot {
  final String id;
  final String doctorId;
  final String date;
  final String startTime;
  final String endTime;
  final bool isBooked;

  Slot({
    required this.id,
    required this.doctorId,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isBooked,
  });

  factory Slot.fromJson(Map<String, dynamic> json) {
    return Slot(
      id: json['id'].toString(),
      doctorId: json['doctorId'].toString(),
      date: json['date'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      isBooked: json['isBooked'] == true,
    );
  }
}
