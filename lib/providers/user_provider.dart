import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';

class UserProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  UserProfile? _profile;
  bool isLoading = false;
  String? error;

  UserProfile? get profile => _profile;
  int get balance => _profile?.balance ?? 0;

  Future<void> loadOrCreate({
    required String userId,
    required String email,
    int initialBalance = 1000,
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
        final created = await _api.createUserProfile(
          UserProfile(
            id: '',
            userId: userId,
            email: email,
            balance: initialBalance,
          ),
        );
        _profile = created;
      }
    } catch (e, st) {
      debugPrint('UserProvider.loadOrCreate error: $e');
      debugPrint('$st');
      error = e.toString();
      _profile = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? name,
    int? age,
    String? address,
    String? avatar,
  }) async {
    if (_profile == null) return;
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (age != null) data['age'] = age;
    if (address != null) data['address'] = address;
    if (avatar != null) data['avatar'] = avatar;

    final updated = await _api.updateUserProfile(_profile!.id, data);
    _profile = updated;
    notifyListeners();
  }

  Future<void> topUp(int amount) async {
    if (_profile == null || amount <= 0) return;
    final newBalance = _profile!.balance + amount;
    final updated = await _api.updateUserProfile(
      _profile!.id, {'balance': newBalance});
    _profile = updated;
    notifyListeners();
  }

  Future<void> charge(int amount) async {
    if (_profile == null) throw Exception('Профиль не загружен');
    if (_profile!.balance < amount) {
      throw Exception('Недостаточно средств');
    }
    final newBalance = _profile!.balance - amount;
    final updated = await _api.updateUserProfile(
      _profile!.id, {'balance': newBalance});
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