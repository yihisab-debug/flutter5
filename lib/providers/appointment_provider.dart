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
    await setStatus(appointmentId, 'cancelled');
  }

  Future<void> confirmByDoctor(String appointmentId) async {
    await setStatus(appointmentId, 'confirmed');
  }

  Future<void> cancelByDoctor(String appointmentId) async {
    await setStatus(appointmentId, 'cancelled');
  }

  Future<void> completeByDoctor(String appointmentId) async {
    await setStatus(appointmentId, 'completed');
  }

  void clear() {
    _appointments = [];
    notifyListeners();
  }
}
