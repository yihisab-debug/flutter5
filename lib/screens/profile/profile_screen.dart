import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const int _topUpAmount = 1000;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Редактировать',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const EditProfileScreen()),
            ),
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (ctx, prov, _) {
          if (prov.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final p = prov.profile;
          if (p == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: Colors.grey),
                  const SizedBox(height: 8),
                  const Text('Профиль не загружен'),
                  if (prov.error != null) ...[
                    const SizedBox(height: 8),
                    Text(prov.error!,
                        style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.blue.shade100,
                      backgroundImage: p.avatar.isNotEmpty
                          ? NetworkImage(p.avatar)
                          : null,
                      child: p.avatar.isEmpty
                          ? const Icon(Icons.person,
                              size: 50, color: Colors.blue)
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      p.name.isNotEmpty ? p.name : 'Имя не указано',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.email,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Баланс',
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${p.balance} ₸',
                        style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _topUp(ctx, _topUpAmount),
                          icon: const Icon(Icons.add),
                          label: const Text(
                            'Пополнить на 1000 ₸',
                            style: TextStyle(fontSize: 15),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Личные данные',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Divider(),
                      _row(Icons.person, 'Имя',
                          p.name.isNotEmpty ? p.name : '—'),
                      _row(Icons.cake, 'Возраст',
                          p.age > 0 ? '${p.age}' : '—'),
                      _row(Icons.home, 'Адрес',
                          p.address.isNotEmpty ? p.address : '—'),
                      _row(Icons.email, 'Email', p.email),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _topUp(BuildContext ctx, int amount) async {
    try {
      await ctx.read<UserProvider>().topUp(amount);
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('Баланс пополнен на $amount ₸'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.blue),
          const SizedBox(width: 8),
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}