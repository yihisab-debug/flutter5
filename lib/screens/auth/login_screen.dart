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
      await _auth.login(_emailCtrl.text.trim(),
        _passCtrl.text.trim());

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${e.toString()}'),
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

                ElevatedButton(
                  onPressed: _loading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.blue),
                  child: _loading
                    ? const CircularProgressIndicator(
                        color: Colors.white)
                    : const Text('Войти',
                        style: TextStyle(fontSize: 16,
                          color: Colors.white)),
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
