class PendingRole {
  static String? _role;

  static void set(String role) {
    _role = role;
  }

  static String? consume() {
    final r = _role;
    _role = null;
    return r;
  }

  static void clear() {
    _role = null;
  }
}
