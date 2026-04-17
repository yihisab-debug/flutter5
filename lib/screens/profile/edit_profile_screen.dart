import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _avatarCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = context.read<UserProvider>().profile;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _ageCtrl = TextEditingController(
        text: (p?.age != null && p!.age > 0) ? '${p.age}' : '');
    _addressCtrl = TextEditingController(text: p?.address ?? '');
    _avatarCtrl = TextEditingController(text: p?.avatar ?? '');
  }

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
    setState(() => _saving = true);
    try {
      await context.read<UserProvider>().updateProfile(
            name: _nameCtrl.text.trim(),
            age: int.tryParse(_ageCtrl.text.trim()) ?? 0,
            address: _addressCtrl.text.trim(),
            avatar: _avatarCtrl.text.trim(),
          );
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
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактирование профиля'),
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
                  animation: _avatarCtrl,
                  builder: (_, __) {
                    final url = _avatarCtrl.text.trim();
                    return CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage:
                          url.isNotEmpty ? NetworkImage(url) : null,
                      onBackgroundImageError:
                          url.isNotEmpty ? (_, __) {} : null,
                      child: url.isEmpty
                          ? const Icon(Icons.person,
                              size: 50, color: Colors.blue)
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
                    border: OutlineInputBorder()),
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
                    border: OutlineInputBorder()),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final n = int.tryParse(v.trim());
                  if (n == null || n < 0 || n > 120) {
                    return 'Некорректный возраст';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressCtrl,
                decoration: const InputDecoration(
                    labelText: 'Адрес',
                    prefixIcon: Icon(Icons.home),
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _avatarCtrl,
                decoration: const InputDecoration(
                    labelText: 'Аватар (URL)',
                    prefixIcon: Icon(Icons.image),
                    border: OutlineInputBorder(),
                    hintText: 'https://...'),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.blue),
                child: _saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Сохранить',
                        style:
                            TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}