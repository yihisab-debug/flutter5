import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _auth = AuthService();
  bool _loading = false;
  bool _obscure = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _auth.login(_emailCtrl.text.trim(), _passCtrl.text.trim());
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${e.toString()}'),
          backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _loading = true);
    try {
      final result = await _auth.signInWithGoogle();
      if (result == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Вход через Google отменён')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка Google: ${e.toString()}'),
          backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    if (_emailCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите email')));
      return;
    }
    await _auth.resetPassword(_emailCtrl.text.trim());
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Письмо отправлено!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                const SizedBox(height: 60),

                const Icon(Icons.medical_services,
                  size: 80, color: Colors.blue),

                const SizedBox(height: 16),

                const Text('Online Doctor Booking',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24,
                    fontWeight: FontWeight.bold)),

                const SizedBox(height: 40),

                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder()),
                  validator: (v) => v!.contains('@')
                    ? null : 'Введите корректный email',
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: 'Пароль',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                        ? Icons.visibility
                        : Icons.visibility_off),
                      onPressed: () =>
                        setState(() => _obscure = !_obscure)),
                    border: const OutlineInputBorder()),
                  validator: (v) => v!.length >= 6
                    ? null : 'Минимум 6 символов',
                ),

                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _resetPassword,
                    child: const Text('Забыли пароль?'))),

                const SizedBox(height: 16),

                // Кнопка входа по email
                ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.blue),
                  child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Войти',
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                ),

                const SizedBox(height: 12),

                const Row(children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('или', style: TextStyle(color: Colors.grey)),
                  ),
                  Expanded(child: Divider()),
                ]),

                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: _loading ? null : _loginWithGoogle,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.all(14),
                    side: const BorderSide(color: Colors.grey),
                  ),
                  
                  icon: Image.network(
                    'https://www.google.com/favicon.ico',
                    width: 20, height: 20,
                    errorBuilder: (_, __, ___) =>
                      const Icon(Icons.g_mobiledata, size: 24),
                  ),
                  label: const Text('Войти через Google',
                    style: TextStyle(fontSize: 16, color: Colors.black87)),
                ),

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => Navigator.push(context,
                    MaterialPageRoute(
                      builder: (_) => const RegisterScreen())),
                  child: const Text('Нет аккаунта? Зарегистрируйтесь'),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}