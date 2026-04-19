class UserProfile {
  final String id;
  final String userId;
  String name;
  int age;
  String address;
  final String email;
  String avatar;
  int balance;
  String role;
  String doctorId;

  UserProfile({
    required this.id,
    required this.userId,
    this.name = '',
    this.age = 0,
    this.address = '',
    this.email = '',
    this.avatar = '',
    this.balance = 0,
    this.role = 'patient',
    this.doctorId = '',
  });

  bool get isDoctor => role == 'doctor';
  bool get isPatient => role == 'patient';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'].toString(),
      userId: json['userId'] ?? '',
      name: json['name'] ?? '',
      age: (json['age'] as num?)?.toInt() ?? 0,
      address: json['address'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'] ?? '',
      balance: (json['balance'] as num?)?.toInt() ?? 0,
      role: (json['role'] ?? 'patient').toString(),
      doctorId: (json['doctorId'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': 'user',
      'userId': userId,
      'name': name,
      'age': age,
      'address': address,
      'email': email,
      'avatar': avatar,
      'balance': balance,
      'role': role,
      'doctorId': doctorId,
    };
  }
}
