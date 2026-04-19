import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/doctor.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';

class DoctorProfileEditScreen extends StatefulWidget {
  final Doctor doctor;
  const DoctorProfileEditScreen({super.key, required this.doctor});

  @override
  State<DoctorProfileEditScreen> createState() =>
      _DoctorProfileEditScreenState();
}

class _DoctorProfileEditScreenState extends State<DoctorProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();

  late TextEditingController _nameCtrl;
  late TextEditingController _specCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _photoCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.doctor;
    _nameCtrl = TextEditingController(text: d.name);
    _specCtrl = TextEditingController(text: d.specialization);
    _descCtrl = TextEditingController(text: d.description);
    _priceCtrl = TextEditingController(text: '${d.price}');
    _photoCtrl = TextEditingController(text: d.photoUrl);
  }

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

    setState(() => _saving = true);
    try {
      final name = _nameCtrl.text.trim();

      Map<String, dynamic> data = {
        'name': name,
        'specialization': _specCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'price': int.parse(_priceCtrl.text.trim()),
        'photoUrl': _photoCtrl.text.trim(),
      };

      await _api.updateDoctor(widget.doctor.id, data);

      if (mounted) {
        await context.read<UserProvider>().updateProfile(name: name);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Профиль обновлён'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактировать профиль'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: AnimatedBuilder(
                  animation: _photoCtrl,
                  builder: (_, __) {
                    final url = _photoCtrl.text.trim();
                    return CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage: url.isNotEmpty
                          ? NetworkImage(url)
                          : null,
                      onBackgroundImageError: url.isNotEmpty
                          ? (_, __) {}
                          : null,
                      child: url.isEmpty
                          ? const Icon(
                              Icons.medical_services,
                              size: 50,
                              color: Colors.blue,
                            )
                          : null,
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameCtrl,
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
                decoration: const InputDecoration(
                  labelText: 'Специализация',
                  prefixIcon: Icon(Icons.local_hospital),
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
                decoration: const InputDecoration(
                  labelText: 'Описание',
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
                  labelText: 'Фото (URL)',
                  prefixIcon: Icon(Icons.image),
                  hintText: 'https://...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.blue,
                ),
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Сохранить',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
