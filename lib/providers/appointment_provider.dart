import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../services/api_service.dart';

class AppointmentProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  List<Appointment> _appointments = [];
  bool isLoading = false;

  List<Appointment> get appointments => _appointments;

  List<Appointment> get upcoming => _appointments
    .where((a) => a.status == 'confirmed').toList();

  List<Appointment> get cancelled => _appointments
    .where((a) => a.status == 'cancelled').toList();

  Future<void> loadAppointments(String userId) async {
    isLoading = true;
    notifyListeners();
    try {
      _appointments = await _api.getAppointments(userId);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> cancelAppointment(
    String appointmentId, String slotId) async {
    await _api.updateAppointment(
      appointmentId, {'status': 'cancelled'});
    await _api.updateSlot(slotId, false);
    final a = _appointments.firstWhere((a) => a.id == appointmentId);
    a.status = 'cancelled';
    notifyListeners();
  }
}
