import 'package:flutter/material.dart';
import '../models/doctor.dart';
import '../services/api_service.dart';

class DoctorProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Doctor> _allDoctors = [];
  List<Doctor> _filtered = [];
  bool isLoading = false;
  String? error;

  String _filterSpec = 'Все';
  double _minRating = 0.0;
  String _search = '';

  List<Doctor> get doctors => _filtered;
  String get filterSpec => _filterSpec;
  double get minRating => _minRating;

  List<String> get specializations {
    final specs = _allDoctors
      .map((d) => d.specialization).toSet().toList();
    return ['Все', ...specs];
  }

  Future<void> loadDoctors() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      _allDoctors = await _api.getDoctors();
      _applyFilters();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setSpecFilter(String spec) {
    _filterSpec = spec;
    _applyFilters();
  }

  void setRatingFilter(double rating) {
    _minRating = rating;
    _applyFilters();
  }

  void setSearch(String query) {
    _search = query.toLowerCase();
    _applyFilters();
  }

  void _applyFilters() {
    _filtered = _allDoctors.where((d) {
      final specOk = _filterSpec == 'Все' ||
        d.specialization == _filterSpec;
      final ratingOk = d.rating >= _minRating;
      final searchOk = _search.isEmpty ||
        d.name.toLowerCase().contains(_search) ||
        d.specialization.toLowerCase().contains(_search);
      return specOk && ratingOk && searchOk;
    }).toList();
    notifyListeners();
  }
}
