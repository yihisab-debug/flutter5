import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_profile.dart';
import '../../providers/admin_provider.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  String _filter = 'all';

  List<UserProfile> _filtered(List<UserProfile> all) {
    switch (_filter) {
      case 'patient':
        return [for (final u in all) if (u.isPatient) u];
      case 'doctor':
        return [for (final u in all) if (u.isDoctor) u];
      case 'blocked':
        return [for (final u in all) if (u.isBlocked) u];
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.grey.shade100,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('all', 'Все'),
                _chip('patient', 'Пациенты'),
                _chip('doctor', 'Врачи'),
                _chip('blocked', 'Заблокированные'),
              ],
            ),
          ),
        ),
        Expanded(
          child: Consumer<AdminProvider>(
            builder: (_, prov, __) {
              if (prov.isLoadingUsers) {
                return const Center(child: CircularProgressIndicator());
              }
              final list = _filtered(prov.users);
              if (list.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () =>
                      context.read<AdminProvider>().loadUsers(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      Center(child: Text('Нет пользователей')),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () =>
                    context.read<AdminProvider>().loadUsers(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _UserCard(user: list[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _chip(String value, String label) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
        selectedColor: Colors.deepPurple.shade100,
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserProfile user;
  const _UserCard({required this.user});

  Color _roleColor() {
    if (user.isAdmin) return Colors.deepPurple;
    if (user.isDoctor) return Colors.blue;
    return Colors.teal;
  }

  String _roleLabel() {
    if (user.isAdmin) return 'Админ';
    if (user.isDoctor) return 'Врач';
    return 'Пациент';
  }

  Future<void> _toggleBlock(BuildContext ctx) async {
    final willBlock = !user.isBlocked;
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: Text(willBlock ? 'Заблокировать?' : 'Разблокировать?'),
        content: Text(
          willBlock
              ? 'Пользователь «${user.name.isEmpty ? user.email : user.name}» '
                  'потеряет доступ к приложению.'
              : 'Вернуть пользователю «${user.name.isEmpty ? user.email : user.name}» '
                  'доступ к приложению?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dCtx, true),
            child: Text(
              willBlock ? 'Заблокировать' : 'Разблокировать',
              style: TextStyle(
                color: willBlock ? Colors.red : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !ctx.mounted) return;
    await ctx.read<AdminProvider>().setBlocked(user.id, willBlock);
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(
          content: Text(
            willBlock ? 'Пользователь заблокирован' : 'Пользователь разблокирован',
          ),
          backgroundColor: willBlock ? Colors.red : Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nameDisplay = user.name.isEmpty ? '(без имени)' : user.name;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: _roleColor().withOpacity(0.15),
              backgroundImage: user.avatar.isNotEmpty
                  ? NetworkImage(user.avatar)
                  : null,
              child: user.avatar.isEmpty
                  ? Icon(Icons.person, color: _roleColor())
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          nameDisplay,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _roleColor().withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _roleLabel(),
                          style: TextStyle(
                            color: _roleColor(),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (user.isBlocked) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'BLOCKED',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Баланс: ${user.balance} ₸',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (user.isDoctor && user.doctorId.isNotEmpty)
                    Text(
                      'Doctor ID: ${user.doctorId}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                  const SizedBox(height: 6),
                  if (!user.isAdmin)
                    SizedBox(
                      height: 30,
                      child: OutlinedButton.icon(
                        onPressed: () => _toggleBlock(context),
                        icon: Icon(
                          user.isBlocked
                              ? Icons.lock_open
                              : Icons.block,
                          size: 14,
                        ),
                        label: Text(
                          user.isBlocked
                              ? 'Разблокировать'
                              : 'Заблокировать',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              user.isBlocked ? Colors.green : Colors.red,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
