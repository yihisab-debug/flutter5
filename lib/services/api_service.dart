import 'package:dio/dio.dart';
import '../models/doctor.dart';
import '../models/slot.dart';
import '../models/appointment.dart';
import '../models/review.dart';
import '../models/user_profile.dart';

class ApiService {
  static const String projectUrl = 'https://6939834cc8d59937aa082275.mockapi.io/project';
  static const String imageUrl = 'https://6939834cc8d59937aa082275.mockapi.io/image';

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ))..interceptors.add(LogInterceptor(
      request: true,
      requestBody: true,
      responseBody: false,
      error: true,
    ));

  Future<List<Doctor>> getDoctors() async {
    final res = await _dio.get(projectUrl);
    final raw = (res.data as List);
    final list = raw.where((j) {
      if (j is! Map) return false;
      final map = Map<String, dynamic>.from(j);

      if (map['type'] == 'doctor') return true;

      if (map['type'] == 'user') return false;
      if (map['userId'] != null &&
          map['userId'].toString().isNotEmpty) {
        return false;
      }

      final hasSpec = (map['specialization'] ?? '').toString().isNotEmpty;
      final hasName = (map['name'] ?? '').toString().isNotEmpty;
      return hasSpec && hasName;
    }).toList();
    return list
        .map((j) => Doctor.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  }

  Future<List<Slot>> getSlots(String doctorId) async {
    final res = await _dio.get(projectUrl,
        queryParameters: {'doctorId': doctorId});
    return (res.data as List).map((j) => Slot.fromJson(j)).toList();
  }

  Future<void> updateSlot(String id, bool isBooked) async {
    await _dio.put('$projectUrl/$id', data: {'isBooked': isBooked});
  }

  Future<List<Appointment>> getAppointments(String userId) async {
    final res = await _dio.get(imageUrl,
        queryParameters: {'userId': userId});
    return (res.data as List).map((j) => Appointment.fromJson(j)).toList();
  }

  Future<Appointment> createAppointment(Map<String, dynamic> data) async {
    final res = await _dio.post(imageUrl, data: data);
    return Appointment.fromJson(res.data);
  }

  Future<void> updateAppointment(String id, Map<String, dynamic> data) async {
    await _dio.put('$imageUrl/$id', data: data);
  }

  Future<List<Review>> getReviews(String doctorId) async {
    final res = await _dio.get(imageUrl,
        queryParameters: {'doctorId': doctorId});
    return (res.data as List).map((j) => Review.fromJson(j)).toList();
  }

  Future<void> createReview(Map<String, dynamic> data) async {
    await _dio.post(imageUrl, data: data);
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    final res = await _dio.get(projectUrl);
    final list = (res.data as List)
        .where((j) =>
            j is Map &&
            j['type'] == 'user' &&
            j['userId'] == userId)
        .toList();
    if (list.isEmpty) return null;
    return UserProfile.fromJson(Map<String, dynamic>.from(list.first));
  }

  Future<UserProfile> createUserProfile(UserProfile profile) async {
    final res = await _dio.post(projectUrl, data: profile.toJson());
    return UserProfile.fromJson(Map<String, dynamic>.from(res.data));
  }

  Future<UserProfile> updateUserProfile(
      String id, Map<String, dynamic> data) async {
    final res = await _dio.put('$projectUrl/$id', data: data);
    return UserProfile.fromJson(Map<String, dynamic>.from(res.data));
  }
}