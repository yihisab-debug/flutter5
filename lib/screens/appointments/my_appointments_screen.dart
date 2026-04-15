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

    Future.microtask(() {
      context.read<AppointmentProvider>().loadAppointments(uid);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

        return _AppointmentCard(
          appointment: a,
          canCancel: canCancel,
          onCancel: () => _cancel(ctx, a),
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
      ),
    );

    if (confirm == true && ctx.mounted) {
      await ctx
          .read<AppointmentProvider>()
          .cancelAppointment(a.id, a.slotId);

      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Запись отменена')),
        );
      }
    }
  }
}

class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final bool canCancel;
  final VoidCallback onCancel;

  const _AppointmentCard({
    required this.appointment,
    required this.canCancel,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final a = appointment;

    final doctorDisplay = a.doctorName.isNotEmpty
        ? a.doctorName
        : 'Врач ID: ${a.doctorId}';

    final hasTime = a.startTime.isNotEmpty;

    // ✅ форматируем дату
    final formattedDate =
        "${a.date.day.toString().padLeft(2, '0')}."
        "${a.date.month.toString().padLeft(2, '0')}."
        "${a.date.year}";

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            CircleAvatar(
              backgroundColor: canCancel ? Colors.blue : Colors.grey,
              child: Icon(
                canCancel ? Icons.event_available : Icons.event_busy,
                color: Colors.white,
              ),
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

                  // ✅ ДАТА
                  _row(Icons.calendar_today, 'Дата', formattedDate),

                  // ✅ ВРЕМЯ
                  if (hasTime)
                    _row(
                      Icons.access_time,
                      'Время',
                      a.endTime.isNotEmpty
                          ? '${a.startTime} – ${a.endTime}'
                          : a.startTime,
                    ),

                  // ✅ СТАТУС
                  _row(
                    canCancel ? Icons.check_circle : Icons.cancel,
                    'Статус',
                    canCancel ? 'Подтверждено' : 'Отменено',
                    valueColor: canCancel ? Colors.green : Colors.red,
                  ),

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