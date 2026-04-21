import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/doctor.dart';
import '../../providers/admin_provider.dart';
import 'admin_doctor_edit_screen.dart';

class AdminDoctorsScreen extends StatefulWidget {
  const AdminDoctorsScreen({super.key});

  @override
  State<AdminDoctorsScreen> createState() => _AdminDoctorsScreenState();
}

class _AdminDoctorsScreenState extends State<AdminDoctorsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.deepPurple,
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(
                text:
                    'На модерации (${context.watch<AdminProvider>().pendingDoctors.length})',
              ),
              const Tab(text: 'Одобренные'),
              const Tab(text: 'Отклонённые'),
            ],
          ),
        ),
        Expanded(
          child: Consumer<AdminProvider>(
            builder: (_, prov, __) {
              if (prov.isLoadingDoctors) {
                return const Center(child: CircularProgressIndicator());
              }
              return TabBarView(
                controller: _tabController,
                children: [
                  _buildList(prov.pendingDoctors, isPending: true),
                  _buildList(prov.approvedDoctors),
                  _buildList(prov.rejectedDoctors),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildList(List<Doctor> list, {bool isPending = false}) {
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => context.read<AdminProvider>().loadDoctors(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(child: Text('Пусто')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => context.read<AdminProvider>().loadDoctors(),
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: list.length,
        itemBuilder: (_, i) {
          return _DoctorAdminCard(
            doctor: list[i],
            showModeration: isPending,
          );
        },
      ),
    );
  }
}

class _DoctorAdminCard extends StatelessWidget {
  final Doctor doctor;
  final bool showModeration;

  const _DoctorAdminCard({
    required this.doctor,
    required this.showModeration,
  });

  Color _statusColor() {
    if (doctor.isApproved) return Colors.green;
    if (doctor.isRejected) return Colors.red;
    return Colors.orange;
  }

  String _statusLabel() {
    if (doctor.isApproved) return 'Одобрен';
    if (doctor.isRejected) return 'Отклонён';
    return 'На модерации';
  }

  Future<void> _approve(BuildContext ctx) async {
    await ctx.read<AdminProvider>().approveDoctor(doctor.id);
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Врач одобрен'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _reject(BuildContext ctx) async {
    await ctx.read<AdminProvider>().rejectDoctor(doctor.id);
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Заявка отклонена'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _delete(BuildContext ctx) async {
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: const Text('Удалить врача?'),
        content: Text(
          'Карточка «${doctor.name}» будет удалена. '
          'Это действие нельзя отменить.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dCtx, true),
            child: const Text(
              'Удалить',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (!ctx.mounted) return;
    await ctx.read<AdminProvider>().deleteDoctor(doctor.id);
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Врач удалён')),
      );
    }
  }

  void _edit(BuildContext ctx) {
    Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) => AdminDoctorEditScreen(doctor: doctor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: doctor.photoUrl.isNotEmpty
                      ? NetworkImage(doctor.photoUrl)
                      : null,
                  child: doctor.photoUrl.isEmpty
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor.name.isEmpty ? '(без имени)' : doctor.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        doctor.specialization,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor().withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _statusLabel(),
                              style: TextStyle(
                                color: _statusColor(),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${doctor.price} ₸',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.star,
                            size: 12,
                            color: Colors.amber.shade700,
                          ),
                          Text(
                            ' ${doctor.rating.toStringAsFixed(1)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (doctor.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                doctor.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
            ],
            const Divider(height: 20),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 4,
              children: [
                if (showModeration)
                  ElevatedButton.icon(
                    onPressed: () => _approve(context),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Одобрить'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                if (showModeration)
                  ElevatedButton.icon(
                    onPressed: () => _reject(context),
                    icon: const Icon(Icons.close, size: 18),
                    label: const Text('Отклонить'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: () => _edit(context),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Редакт.'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _delete(context),
                  icon: const Icon(Icons.delete, size: 18),
                  label: const Text('Удалить'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
