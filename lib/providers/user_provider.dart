import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';

class UserProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  UserProfile? _profile;
  bool isLoading = false;
  String? error;

  UserProfile? get profile => _profile;

  int get balance {
    if (_profile == null) return 0;
    return _profile!.balance;
  }

  bool get isDoctor {
    if (_profile == null) return false;
    return _profile!.isDoctor;
  }

  bool get isPatient {
    if (_profile == null) return true;
    return _profile!.isPatient;
  }

  Future<void> loadOrCreate({
    required String userId,
    required String email,
    int initialBalance = 1000,
    String pendingRole = 'patient',
  }) async {
    if (isLoading) return;
    if (_profile != null && _profile!.userId == userId) return;

    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final existing = await _api.getUserProfile(userId);
      if (existing != null) {
        _profile = existing;
      } else {
        int startBalance = 0;
        if (pendingRole == 'patient') {
          startBalance = initialBalance;
        }

        final newProfile = UserProfile(
          id: '',
          userId: userId,
          email: email,
          balance: startBalance,
          role: pendingRole,
        );
        final created = await _api.createUserProfile(newProfile);
        _profile = created;
      }
    } catch (e) {
      error = e.toString();
      _profile = null;
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> updateProfile({
    String? name,
    int? age,
    String? address,
    String? avatar,
    String? doctorId,
  }) async {
    if (_profile == null) return;

    Map<String, dynamic> data = {};
    if (name != null) data['name'] = name;
    if (age != null) data['age'] = age;
    if (address != null) data['address'] = address;
    if (avatar != null) data['avatar'] = avatar;
    if (doctorId != null) data['doctorId'] = doctorId;

    final updated = await _api.updateUserProfile(_profile!.id, data);
    _profile = updated;
    notifyListeners();
  }

  Future<void> topUp(int amount) async {
    if (_profile == null) return;
    if (amount <= 0) return;

    int newBalance = _profile!.balance + amount;
    final updated = await _api.updateUserProfile(
      _profile!.id,
      {'balance': newBalance},
    );
    _profile = updated;
    notifyListeners();
  }

  Future<void> charge(int amount) async {
    if (_profile == null) {
      throw Exception('Профиль не загружен');
    }
    if (_profile!.balance < amount) {
      throw Exception('Недостаточно средств');
    }

    int newBalance = _profile!.balance - amount;
    final updated = await _api.updateUserProfile(
      _profile!.id,
      {'balance': newBalance},
    );
    _profile = updated;
    notifyListeners();
  }

  void clear() {
    _profile = null;
    error = null;
    isLoading = false;
    notifyListeners();
  }
}
