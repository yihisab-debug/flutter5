import 'package:dio/dio.dart';
import '../models/doctor.dart';
import '../models/slot.dart';
import '../models/appointment.dart';
import '../models/review.dart';
import '../models/user_profile.dart';

class ApiService {
  static const String projectUrl =
      'https://6939834cc8d59937aa082275.mockapi.io/project';
  static const String imageUrl =
      'https://6939834cc8d59937aa082275.mockapi.io/image';

  final Dio _dio = Dio();

  Future<List<Doctor>> getDoctors() async {
    final res = await _dio.get(projectUrl);
    final List raw = res.data as List;
    List<Doctor> result = [];
    for (var j in raw) {
      if (j is Map && j['type'] == 'doctor') {
        result.add(Doctor.fromJson(Map<String, dynamic>.from(j)));
      }
    }
    return result;
  }

  Future<Doctor?> getDoctorById(String id) async {
    if (id.isEmpty) return null;
    try {
      final res = await _dio.get('$projectUrl/$id');
      return Doctor.fromJson(Map<String, dynamic>.from(res.data));
    } catch (e) {
      return null;
    }
  }

  Future<Doctor> createDoctor(Doctor doctor) async {
    final res = await _dio.post(projectUrl, data: doctor.toJson());
    return Doctor.fromJson(Map<String, dynamic>.from(res.data));
  }

  Future<Doctor> updateDoctor(String id, Map<String, dynamic> data) async {
    final res = await _dio.put('$projectUrl/$id', data: data);
    return Doctor.fromJson(Map<String, dynamic>.from(res.data));
  }

  Future<List<Slot>> getSlots(String doctorId) async {
    final res = await _dio.get(projectUrl);
    final List raw = res.data as List;
    List<Slot> result = [];
    for (var j in raw) {
      if (j is Map &&
          j['type'] == 'slot' &&
          j['doctorId']?.toString() == doctorId) {
        result.add(Slot.fromJson(Map<String, dynamic>.from(j)));
      }
    }
    return result;
  }

  Future<Slot> createSlot(Slot slot) async {
    final res = await _dio.post(projectUrl, data: slot.toJson());
    return Slot.fromJson(Map<String, dynamic>.from(res.data));
  }

  Future<void> updateSlot(String id, Map<String, dynamic> data) async {
    await _dio.put('$projectUrl/$id', data: data);
  }

  Future<void> deleteSlot(String id) async {
    await _dio.delete('$projectUrl/$id');
  }

  Future<List<Appointment>> getAppointmentsByUser(String userId) async {
    final res = await _dio.get(imageUrl);
    final List raw = res.data as List;
    List<Appointment> result = [];
    for (var j in raw) {
      if (j is Map &&
          j['slotId'] != null &&
          j['userId']?.toString() == userId) {
        result.add(Appointment.fromJson(Map<String, dynamic>.from(j)));
      }
    }
    return result;
  }

  Future<List<Appointment>> getAppointmentsByDoctor(String doctorId) async {
    final res = await _dio.get(imageUrl);
    final List raw = res.data as List;
    List<Appointment> result = [];
    for (var j in raw) {
      if (j is Map &&
          j['slotId'] != null &&
          j['doctorId']?.toString() == doctorId) {
        result.add(Appointment.fromJson(Map<String, dynamic>.from(j)));
      }
    }
    return result;
  }

  Future<Appointment> createAppointment(Map<String, dynamic> data) async {
    final res = await _dio.post(imageUrl, data: data);
    return Appointment.fromJson(Map<String, dynamic>.from(res.data));
  }

  Future<void> updateAppointment(
      String id, Map<String, dynamic> data) async {
    await _dio.put('$imageUrl/$id', data: data);
  }

  Future<List<Review>> getReviews(String doctorId) async {
    final res = await _dio.get(imageUrl);
    final List raw = res.data as List;
    List<Review> result = [];
    for (var j in raw) {
      if (j is Map &&
          j['doctorId'] != null &&
          j['slotId'] == null &&
          j['doctorId'].toString() == doctorId) {
        result.add(Review.fromJson(Map<String, dynamic>.from(j)));
      }
    }
    return result;
  }

  Future<void> createReview(Map<String, dynamic> data) async {
    await _dio.post(imageUrl, data: data);
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    final res = await _dio.get(projectUrl);
    final List raw = res.data as List;
    for (var j in raw) {
      if (j is Map && j['type'] == 'user' && j['userId'] == userId) {
        return UserProfile.fromJson(Map<String, dynamic>.from(j));
      }
    }
    return null;
  }

  Future<UserProfile?> getUserProfileByDoctorId(String doctorId) async {
    if (doctorId.isEmpty) return null;
    final res = await _dio.get(projectUrl);
    final List raw = res.data as List;
    for (var j in raw) {
      if (j is Map &&
          j['type'] == 'user' &&
          j['role'] == 'doctor' &&
          j['doctorId']?.toString() == doctorId) {
        return UserProfile.fromJson(Map<String, dynamic>.from(j));
      }
    }
    return null;
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

  /// Начисляет сумму на баланс врача (находит UserProfile врача по doctorId).
  /// Возвращает true, если операция успешна. Не кидает исключение —
  /// чтобы не ломать основной flow записи/отмены.
  Future<bool> creditDoctorBalance(String doctorId, int amount) async {
    if (doctorId.isEmpty || amount <= 0) return false;
    try {
      final doctorProfile = await getUserProfileByDoctorId(doctorId);
      if (doctorProfile == null) return false;
      final newBalance = doctorProfile.balance + amount;
      await _dio.put(
        '$projectUrl/${doctorProfile.id}',
        data: {'balance': newBalance},
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Списывает сумму с баланса врача (при отмене врачом — возврат пациенту).
  /// Если на балансе недостаточно — списывает до 0, но не уходит в минус.
  Future<bool> debitDoctorBalance(String doctorId, int amount) async {
    if (doctorId.isEmpty || amount <= 0) return false;
    try {
      final doctorProfile = await getUserProfileByDoctorId(doctorId);
      if (doctorProfile == null) return false;
      int newBalance = doctorProfile.balance - amount;
      if (newBalance < 0) newBalance = 0;
      await _dio.put(
        '$projectUrl/${doctorProfile.id}',
        data: {'balance': newBalance},
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
