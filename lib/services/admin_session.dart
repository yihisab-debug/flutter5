import 'package:flutter/foundation.dart';

class AdminSession extends ChangeNotifier {
  AdminSession._();
  static final AdminSession instance = AdminSession._();

  static const String password = '1234';

  bool _loggedIn = false;
  bool get loggedIn => _loggedIn;

  bool tryLogin(String pass) {
    if (pass == password) {
      _loggedIn = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void logout() {
    _loggedIn = false;
    notifyListeners();
  }
}
