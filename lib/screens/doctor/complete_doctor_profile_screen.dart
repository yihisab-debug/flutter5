import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../models/doctor.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';

class CompleteDoctorProfileScreen extends StatefulWidget {
  const CompleteDoctorProfileScreen({super.key});

  @override
  State<CompleteDoctorProfileScreen> createState() =>
      _CompleteDoctorProfileScreenState();
}

class _CompleteDoctorProfileScreenState
    extends State<CompleteDoctorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();

  final _nameCtrl = TextEditingController();
  final _specCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _photoCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _specCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _photoCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_saving) return;

    final userProv = context.read<UserProvider>();
    if (userProv.profile == null) return;

    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final name = _nameCtrl.text.trim();
      final spec = _specCtrl.text.trim();
      final desc = _descCtrl.text.trim();
      final price = int.parse(_priceCtrl.text.trim());
      final photo = _photoCtrl.text.trim();

      final newDoctor = Doctor(
        id: '',
        name: name,
        specialization: spec,
        description: desc,
        photoUrl: photo,
        rating: 0.0,
        price: price,
        ownerUid: uid,
      );
      final createdDoctor = await _api.createDoctor(newDoctor);

      await userProv.updateProfile(
        name: name,
        doctorId: createdDoctor.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Профиль врача создан'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Профиль врача'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Выйти',
              onPressed: () => FirebaseAuth.instance.signOut(),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                const Icon(
                  Icons.medical_services,
                  size: 72,
                  color: Colors.blue,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Расскажите пациентам о себе',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Эти данные увидят пациенты при выборе врача',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Имя и фамилия',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Введите имя';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _specCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Специализация',
                    prefixIcon: Icon(Icons.local_hospital),
                    hintText: 'Например, Кардиолог',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Укажите специализацию';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Описание / опыт',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().length < 10) {
                      return 'Минимум 10 символов';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Цена приёма, ₸',
                    prefixIcon: Icon(Icons.payments),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    final n = int.tryParse((v ?? '').trim());
                    if (n == null || n <= 0) {
                      return 'Введите положительное число';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _photoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Фото — URL (необязательно)',
                    prefixIcon: Icon(Icons.image),
                    hintText: 'https://...',
                    border: OutlineInputBorder(),
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
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Сохранить и продолжить',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
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
