import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../services/api_service.dart';

class AppointmentProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Appointment> _appointments = [];
  bool isLoading = false;

  List<Appointment> get appointments => _appointments;

  List<Appointment> get pending {
    List<Appointment> result = [];
    for (var a in _appointments) {
      if (a.status == 'pending') result.add(a);
    }
    return result;
  }

  List<Appointment> get confirmed {
    List<Appointment> result = [];
    for (var a in _appointments) {
      if (a.status == 'confirmed') result.add(a);
    }
    return result;
  }

  List<Appointment> get cancelled {
    List<Appointment> result = [];
    for (var a in _appointments) {
      if (a.status == 'cancelled') result.add(a);
    }
    return result;
  }

  List<Appointment> get completed {
    List<Appointment> result = [];
    for (var a in _appointments) {
      if (a.status == 'completed') result.add(a);
    }
    return result;
  }

  List<Appointment> get upcoming {
    List<Appointment> result = [];
    for (var a in _appointments) {
      if (a.status == 'pending' || a.status == 'confirmed') {
        result.add(a);
      }
    }
    return result;
  }

  Appointment? _findById(String id) {
    for (var a in _appointments) {
      if (a.id == id) return a;
    }
    return null;
  }

  Future<void> loadForPatient(String userId) async {
    isLoading = true;
    notifyListeners();
    try {
      _appointments = await _api.getAppointmentsByUser(userId);
    } catch (e) {
      _appointments = [];
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> loadForDoctor(String doctorId) async {
    isLoading = true;
    notifyListeners();
    try {
      _appointments = await _api.getAppointmentsByDoctor(doctorId);
    } catch (e) {
      _appointments = [];
    }
    isLoading = false;
    notifyListeners();
  }

  Future<void> setStatus(String appointmentId, String newStatus) async {
    await _api.updateAppointment(appointmentId, {'status': newStatus});
    for (var a in _appointments) {
      if (a.id == appointmentId) {
        a.status = newStatus;
        break;
      }
    }
    notifyListeners();
  }

  Future<void> cancelByPatient(String appointmentId) async {
    // Отмена пациентом — деньги НЕ возвращаются (ни пациенту, ни с врача).
    await setStatus(appointmentId, 'cancelled');
  }

  Future<void> confirmByDoctor(String appointmentId) async {
    await setStatus(appointmentId, 'confirmed');
  }

  /// Отмена врачом — возврат средств пациенту и списание с баланса врача.
  /// Возвращает true, если возврат прошёл успешно.
  Future<bool> cancelByDoctor(String appointmentId) async {
    final appt = _findById(appointmentId);
    await setStatus(appointmentId, 'cancelled');

    if (appt == null || appt.price <= 0) return true;

    bool ok = true;

    // Списываем деньги у врача (он получил их при записи)
    final debited = await _api.debitDoctorBalance(appt.doctorId, appt.price);
    if (!debited) ok = false;

    // Возвращаем пациенту
    final patientProfile = await _api.getUserProfile(appt.userId);
    if (patientProfile != null) {
      try {
        await _api.updateUserProfile(
          patientProfile.id,
          {'balance': patientProfile.balance + appt.price},
        );
      } catch (_) {
        ok = false;
      }
    } else {
      ok = false;
    }

    return ok;
  }

  Future<void> completeByDoctor(String appointmentId) async {
    await setStatus(appointmentId, 'completed');
  }

  void clear() {
    _appointments = [];
    notifyListeners();
  }
}
