class Appointment {
  final String id;
  final String userId;
  final String doctorId;
  final String doctorName;
  final String doctorSpec;
  final String slotId;
  final String date;
  final String startTime;
  final String endTime;
  String status;
  final String createdAt;

  Appointment({
    required this.id,
    required this.userId,
    required this.doctorId,
    this.doctorName = '',
    this.doctorSpec = '',
    required this.slotId,
    this.date = '',
    this.startTime = '',
    this.endTime = '',
    required this.status,
    required this.createdAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id:         json['id'].toString(),
      userId:     json['userId'] ?? '',
      doctorId:   json['doctorId']?.toString() ?? '',
      doctorName: json['doctorName'] ?? '',
      doctorSpec: json['doctorSpec'] ?? '',
      slotId:     json['slotId']?.toString() ?? '',
      date:       json['date'] ?? '',
      startTime:  json['startTime'] ?? '',
      endTime:    json['endTime'] ?? '',
      status:     json['status'] ?? 'confirmed',
      createdAt:  json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id':         id,
    'userId':     userId,
    'doctorId':   doctorId,
    'doctorName': doctorName,
    'doctorSpec': doctorSpec,
    'slotId':     slotId,
    'date':       date,
    'startTime':  startTime,
    'endTime':    endTime,
    'status':     status,
    'createdAt':  createdAt,
  };
}