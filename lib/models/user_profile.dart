class UserProfile {
  final String id;
  final String userId;
  String name;
  int age;
  String address;
  final String email;
  String avatar;
  int balance;

  UserProfile({
    required this.id,
    required this.userId,
    this.name = '',
    this.age = 0,
    this.address = '',
    this.email = '',
    this.avatar = '',
    this.balance = 0,
  });

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
    );
  }

  Map<String, dynamic> toJson() => {
    'type': 'user',
    'userId': userId,
    'name': name,
    'age': age,
    'address': address,
    'email': email,
    'avatar': avatar,
    'balance': balance,
  };
}