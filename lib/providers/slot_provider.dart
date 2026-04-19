import 'package:flutter/material.dart';
import '../models/slot.dart';
import '../services/api_service.dart';

class SlotProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Slot> _slots = [];
  bool isLoading = false;
  String? error;

  List<Slot> get slots => _slots;

  List<String> get availableDates {
    List<String> dates = [];
    for (var s in _slots) {
      if (!s.isBooked && !dates.contains(s.date)) {
        dates.add(s.date);
      }
    }
    dates.sort();
    return dates;
  }

  List<String> get allDates {
    List<String> dates = [];
    for (var s in _slots) {
      if (!dates.contains(s.date)) {
        dates.add(s.date);
      }
    }
    dates.sort();
    return dates;
  }

  List<Slot> freeSlotsForDate(String date) {
    List<Slot> result = [];
    for (var s in _slots) {
      if (s.date == date && !s.isBooked) {
        result.add(s);
      }
    }
    result.sort((a, b) => a.startTime.compareTo(b.startTime));
    return result;
  }

  List<Slot> slotsForDate(String date) {
    List<Slot> result = [];
    for (var s in _slots) {
      if (s.date == date) {
        result.add(s);
      }
    }
    result.sort((a, b) => a.startTime.compareTo(b.startTime));
    return result;
  }

  Future<void> load(String doctorId) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      _slots = await _api.getSlots(doctorId);
    } catch (e) {
      error = 'Не удалось загрузить расписание';
      _slots = [];
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> addSlot({
    required String doctorId,
    required String date,
    required String startTime,
    required String endTime,
  }) async {
    for (var s in _slots) {
      if (s.date == date &&
          s.startTime == startTime &&
          s.doctorId == doctorId) {
        throw Exception('Слот на это время уже существует');
      }
    }

    final newSlot = Slot(
      id: '',
      doctorId: doctorId,
      date: date,
      startTime: startTime,
      endTime: endTime,
      isBooked: false,
      status: 'available',
    );
    final created = await _api.createSlot(newSlot);
    _slots.add(created);
    notifyListeners();
  }

  Future<void> deleteSlot(String id) async {
    await _api.deleteSlot(id);
    _slots.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  Future<void> markBooked(String slotId) async {
    try {
      await _api.updateSlot(slotId, {
        'isBooked': true,
        'status': 'booked',
      });
    } catch (e) {}

    for (int i = 0; i < _slots.length; i++) {
      if (_slots[i].id == slotId) {
        _slots[i] = Slot(
          id: _slots[i].id,
          doctorId: _slots[i].doctorId,
          date: _slots[i].date,
          startTime: _slots[i].startTime,
          endTime: _slots[i].endTime,
          isBooked: true,
          status: 'booked',
        );
        break;
      }
    }
    notifyListeners();
  }

  Future<void> markFree(String slotId) async {
    try {
      await _api.updateSlot(slotId, {
        'isBooked': false,
        'status': 'available',
      });
    } catch (e) {}

    for (int i = 0; i < _slots.length; i++) {
      if (_slots[i].id == slotId) {
        _slots[i] = Slot(
          id: _slots[i].id,
          doctorId: _slots[i].doctorId,
          date: _slots[i].date,
          startTime: _slots[i].startTime,
          endTime: _slots[i].endTime,
          isBooked: false,
          status: 'available',
        );
        break;
      }
    }
    notifyListeners();
  }

  void clear() {
    _slots = [];
    notifyListeners();
  }
}
