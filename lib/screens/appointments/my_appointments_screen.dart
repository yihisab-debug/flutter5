import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/appointment_provider.dart';
import '../../models/appointment.dart';

class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    Future.microtask(() {
      context.read<AppointmentProvider>().loadForPatient(uid);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    await context.read<AppointmentProvider>().loadForPatient(uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои записи'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: 'Обновить',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Ожидают'),
            Tab(text: 'Подтверждены'),
            Tab(text: 'Завершены'),
            Tab(text: 'Отменены'),
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
              _buildList(provider.pending, canCancel: true),
              _buildList(provider.confirmed, canCancel: true),
              _buildList(provider.completed, canCancel: false),
              _buildList(provider.cancelled, canCancel: false),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(List<Appointment> list, {required bool canCancel}) {
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(child: Text('Нет записей')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: list.length,
        itemBuilder: (ctx, i) {
          final a = list[i];
          return AppointmentCard(
            appointment: a,
            canCancel: canCancel,
            onCancel: () => _cancel(ctx, a),
          );
        },
      ),
    );
  }

  Future<void> _cancel(BuildContext ctx, Appointment a) async {
    final confirm = await showDialog<bool>(
      context: ctx,
      builder: (dCtx) {
        return AlertDialog(
          title: const Text('Отмена записи'),
          content: const Text(
            'Вы уверены, что хотите отменить запись? Сумма не возвращается.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx, false),
              child: const Text('Нет'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dCtx, true),
              child: const Text(
                'Да',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true && ctx.mounted) {
      await ctx.read<AppointmentProvider>().cancelByPatient(a.id);
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Запись отменена')),
        );
      }
    }
  }
}

class AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final bool canCancel;
  final VoidCallback onCancel;

  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.canCancel,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final a = appointment;

    Color statusColor = Colors.red;
    IconData statusIcon = Icons.cancel;
    String statusLabel = 'Отменено';

    if (a.status == 'pending') {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
      statusLabel = 'Ожидает';
    } else if (a.status == 'confirmed') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusLabel = 'Подтверждено';
    } else if (a.status == 'completed') {
      statusColor = Colors.blue;
      statusIcon = Icons.done_all;
      statusLabel = 'Завершено';
    }

    String doctorDisplay = a.doctorName;
    if (doctorDisplay.isEmpty) {
      doctorDisplay = 'Врач ID: ${a.doctorId}';
    }

    String dateDisplay = a.date;
    if (dateDisplay.isEmpty && a.createdAt.isNotEmpty) {
      dateDisplay = a.createdAt.split('T').first;
    }
    if (dateDisplay.isEmpty) dateDisplay = 'Не указана';

    String timeDisplay = 'Не указано';
    if (a.startTime.isNotEmpty) {
      if (a.endTime.isNotEmpty) {
        timeDisplay = '${a.startTime} – ${a.endTime}';
      } else {
        timeDisplay = a.startTime;
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: statusColor,
              child: Icon(statusIcon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doctorDisplay,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  if (a.doctorSpec.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      a.doctorSpec,
                      style: const TextStyle(
                        color: Colors.blue,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  _row(Icons.calendar_today, 'Дата', dateDisplay),
                  _row(Icons.access_time, 'Время', timeDisplay),
                  _row(
                    statusIcon,
                    'Статус',
                    statusLabel,
                    valueColor: statusColor,
                  ),
                  if (a.price > 0)
                    _row(Icons.payments, 'Сумма', '${a.price} ₸'),
                ],
              ),
            ),
            if (canCancel)
              TextButton(
                onPressed: onCancel,
                child: const Text(
                  'Отмена',
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
