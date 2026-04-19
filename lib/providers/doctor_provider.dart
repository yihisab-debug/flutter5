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
    List<String> specs = [];
    for (var d in _allDoctors) {
      if (!specs.contains(d.specialization)) {
        specs.add(d.specialization);
      }
    }
    specs.sort();
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
      error = 'Не удалось загрузить список врачей';
      _allDoctors = [];
      _filtered = [];
    }

    isLoading = false;
    notifyListeners();
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
    List<Doctor> result = [];
    for (var d in _allDoctors) {
      bool specOk = _filterSpec == 'Все' || d.specialization == _filterSpec;
      bool ratingOk = d.rating >= _minRating;
      bool searchOk = true;
      if (_search.isNotEmpty) {
        final nameMatch = d.name.toLowerCase().contains(_search);
        final specMatch = d.specialization.toLowerCase().contains(_search);
        searchOk = nameMatch || specMatch;
      }

      if (specOk && ratingOk && searchOk) {
        result.add(d);
      }
    }
    _filtered = result;
    notifyListeners();
  }
}
