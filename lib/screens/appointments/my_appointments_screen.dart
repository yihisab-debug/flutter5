import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/appointment_provider.dart';
import '../../models/appointment.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});
  @override
  State<MyAppointmentsScreen> createState() =>
    _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    Future.microtask(() =>
      context.read<AppointmentProvider>().loadAppointments(uid));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои записи'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Предстоящие'),
            Tab(text: 'Отменённые'),
          ],
        ),
      ),
      body: Consumer<AppointmentProvider>(
        builder: (ctx, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(provider.upcoming, canCancel: true),
              _buildList(provider.cancelled, canCancel: false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<Appointment> list, {required bool canCancel}) {
    if (list.isEmpty) {
      return const Center(child: Text('Нет записей'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final a = list[i];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: canCancel ? Colors.blue : Colors.grey,
              child: Icon(
                canCancel ? Icons.event_available : Icons.event_busy,
                color: Colors.white),
            ),
            title: Text('Врач ID: ${a.doctorId}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Слот: ${a.slotId}\nСтатус: ${a.status}'),
            isThreeLine: true,
            trailing: canCancel ? TextButton(
              onPressed: () => _cancel(ctx, a),
              child: const Text('Отмена',
                style: TextStyle(color: Colors.red)),
            ) : null,
          ),
        );
      },
    );
  }

  Future<void> _cancel(BuildContext ctx, Appointment a) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: const Text('Отмена записи'),
        content: const Text('Вы уверены, что хотите отменить запись?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dCtx, false),
            child: const Text('Нет')),
          TextButton(onPressed: () => Navigator.pop(dCtx, true),
            child: const Text('Да', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true && ctx.mounted) {
      await ctx.read<AppointmentProvider>()
        .cancelAppointment(a.id, a.slotId);
      if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Запись отменена')));
    }
  }
}
