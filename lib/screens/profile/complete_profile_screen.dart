import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _avatarCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _addressCtrl.dispose();
    _avatarCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_saving) return;

    setState(() => _saving = true);
    try {
      await context.read<UserProvider>().updateProfile(
            name: _nameCtrl.text.trim(),
            age: int.parse(_ageCtrl.text.trim()),
            address: _addressCtrl.text.trim(),
            avatar: _avatarCtrl.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Профиль сохранён'),
          backgroundColor: Colors.green,
        ),
      );
      // _AuthGate сам перерисуется на DoctorListScreen,
      // т.к. UserProvider.notifyListeners вызовется после updateProfile.
      // Явный Navigator.push здесь НЕ нужен — иначе будет дубль экрана.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // PopScope заменяет устаревший WillPopScope (Flutter 3.12+)
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Заполните профиль'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                const Icon(Icons.account_circle,
                    size: 72, color: Colors.blue),
                const SizedBox(height: 12),
                const Text(
                  'Расскажите о себе',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Это займёт меньше минуты',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),

                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Имя и фамилия',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Введите имя'
                      : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _ageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Возраст',
                    prefixIcon: Icon(Icons.cake),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Введите возраст';
                    }
                    final n = int.tryParse(v.trim());
                    if (n == null || n < 1 || n > 120) {
                      return 'Некорректный возраст';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _addressCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Место проживания',
                    prefixIcon: Icon(Icons.home),
                    border: OutlineInputBorder(),
                    hintText: 'Город, улица, дом',
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Введите адрес'
                      : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _avatarCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Аватар — URL (необязательно)',
                    prefixIcon: Icon(Icons.image),
                    border: OutlineInputBorder(),
                    hintText: 'https://...',
                  ),
                ),
                const SizedBox(height: 28),

                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.blue,
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Сохранить и продолжить',
                          style: TextStyle(
                              fontSize: 16, color: Colors.white),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}