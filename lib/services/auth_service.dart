import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Регистрация
  Future<UserCredential> register(
    String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email, password: password);
  }

  // Вход по email
  Future<UserCredential> login(
    String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email, password: password);
  }

  // Вход через Google
  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return await _auth.signInWithCredential(credential);
  }

  // Восстановление пароля
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Выход
  Future<void> logout() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }
}
