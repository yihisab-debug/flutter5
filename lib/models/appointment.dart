class Appointment {
  final String id;
  final String name;
  final String specialization;
  final DateTime date;
  final String startTime;
  final String endTime;
  final bool isBooked;

  Appointment({
    required this.id,
    required this.name,
    required this.specialization,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.isBooked,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'],
      name: json['name'],
      specialization: json['specialization'],
      date: DateTime.parse(json['date']), // 🔥 ключевая строка
      startTime: json['startTime'],
      endTime: json['endTime'],
      isBooked: json['isBooked'],
    );
  }
}