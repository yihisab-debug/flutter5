import 'package:flutter/material.dart';
import '../models/doctor.dart';
import '../models/user_profile.dart';
import '../models/appointment.dart';
import '../services/api_service.dart';

class AdminProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Doctor> _doctors = [];
  List<UserProfile> _users = [];
  List<Appointment> _appointments = [];

  bool isLoadingDoctors = false;
  bool isLoadingUsers = false;
  bool isLoadingAppointments = false;

  String? error;

  List<Doctor> get doctors => _doctors;
  List<UserProfile> get users => _users;
  List<Appointment> get appointments => _appointments;

  List<Doctor> get pendingDoctors {
    List<Doctor> r = [];
    for (var d in _doctors) {
      if (d.isPending) r.add(d);
    }
    return r;
  }

  List<Doctor> get approvedDoctors {
    List<Doctor> r = [];
    for (var d in _doctors) {
      if (d.isApproved) r.add(d);
    }
    return r;
  }

  List<Doctor> get rejectedDoctors {
    List<Doctor> r = [];
    for (var d in _doctors) {
      if (d.isRejected) r.add(d);
    }
    return r;
  }

  Future<void> loadDoctors() async {
    isLoadingDoctors = true;
    error = null;
    notifyListeners();
    try {
      _doctors = await _api.getAllDoctors();
    } catch (e) {
      error = 'Не удалось загрузить врачей: $e';
      _doctors = [];
    }
    isLoadingDoctors = false;
    notifyListeners();
  }

  Future<void> approveDoctor(String doctorId) async {
    await _api.updateDoctor(doctorId, {'moderationStatus': 'approved'});
    _patchDoctor(doctorId, moderationStatus: 'approved');
    notifyListeners();
  }

  Future<void> rejectDoctor(String doctorId) async {
    await _api.updateDoctor(doctorId, {'moderationStatus': 'rejected'});
    _patchDoctor(doctorId, moderationStatus: 'rejected');
    notifyListeners();
  }

  Future<void> updateDoctor(
    String doctorId,
    Map<String, dynamic> data,
  ) async {
    final updated = await _api.updateDoctor(doctorId, data);
    for (int i = 0; i < _doctors.length; i++) {
      if (_doctors[i].id == doctorId) {
        _doctors[i] = updated;
        break;
      }
    }
    notifyListeners();
  }

  Future<void> deleteDoctor(String doctorId) async {
    await _api.deleteDoctor(doctorId);
    _doctors.removeWhere((d) => d.id == doctorId);
    for (final u in _users) {
      if (u.doctorId == doctorId) {
        try {
          await _api.updateUserProfile(u.id, {'doctorId': ''});
          u.doctorId = '';
        } catch (_) {}
      }
    }
    notifyListeners();
  }

  void _patchDoctor(String id, {String? moderationStatus}) {
    for (int i = 0; i < _doctors.length; i++) {
      if (_doctors[i].id == id) {
        final old = _doctors[i];
        _doctors[i] = Doctor(
          id: old.id,
          name: old.name,
          specialization: old.specialization,
          photoUrl: old.photoUrl,
          description: old.description,
          rating: old.rating,
          price: old.price,
          ownerUid: old.ownerUid,
          moderationStatus: moderationStatus ?? old.moderationStatus,
        );
        break;
      }
    }
  }

  Future<void> loadUsers() async {
    isLoadingUsers = true;
    error = null;
    notifyListeners();
    try {
      _users = await _api.getAllUserProfiles();
    } catch (e) {
      error = 'Не удалось загрузить пользователей: $e';
      _users = [];
    }
    isLoadingUsers = false;
    notifyListeners();
  }

  Future<void> setBlocked(String profileId, bool blocked) async {
    await _api.updateUserProfile(profileId, {'isBlocked': blocked});
    for (final u in _users) {
      if (u.id == profileId) {
        u.isBlocked = blocked;
        break;
      }
    }
    notifyListeners();
  }

  Future<void> loadAppointments() async {
    isLoadingAppointments = true;
    error = null;
    notifyListeners();
    try {
      _appointments = await _api.getAllAppointments();
    } catch (e) {
      error = 'Не удалось загрузить записи: $e';
      _appointments = [];
    }
    isLoadingAppointments = false;
    notifyListeners();
  }

  Future<void> loadAll() async {
    await Future.wait([
      loadDoctors(),
      loadUsers(),
      loadAppointments(),
    ]);
  }
}
