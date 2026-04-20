import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/appointment.dart';
import '../../providers/appointment_provider.dart';
import '../../providers/slot_provider.dart';
import '../../providers/user_provider.dart';

class DoctorAppointmentsScreen extends StatefulWidget {
  const DoctorAppointmentsScreen({super.key});

  @override
  State<DoctorAppointmentsScreen> createState() =>
      _DoctorAppointmentsScreenState();
}

class _DoctorAppointmentsScreenState extends State<DoctorAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    Future.microtask(_load);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final userProv = context.read<UserProvider>();
    final doctorId = userProv.profile?.doctorId ?? '';
    if (doctorId.isEmpty) return;
    await context.read<AppointmentProvider>().loadForDoctor(doctorId);
    // Обновляем баланс врача — мог измениться из-за новых записей/отмен.
    await userProv.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои приёмы'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
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
        builder: (ctx, prov, _) {
          if (prov.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _buildList(prov.pending, showConfirm: true, showCancel: true),
              _buildList(
                prov.confirmed,
                showComplete: true,
                showCancel: true,
              ),
              _buildList(prov.completed),
              _buildList(prov.cancelled),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(
    List<Appointment> list, {
    bool showConfirm = false,
    bool showCancel = false,
    bool showComplete = false,
  }) {
    if (list.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            SizedBox(height: 120),
            Center(child: Text('Здесь пусто')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final a = list[i];
          return DoctorAppointmentCard(
            appointment: a,
            showConfirm: showConfirm,
            showCancel: showCancel,
            showComplete: showComplete,
            onConfirm: () => _confirmAppointment(a),
            onCancel: () => _cancelAppointment(a),
            onComplete: () => _completeAppointment(a),
          );
        },
      ),
    );
  }

  Future<void> _confirmAppointment(Appointment a) async {
    await context.read<AppointmentProvider>().confirmByDoctor(a.id);
    _snack('Запись подтверждена', Colors.green);
  }

  Future<void> _cancelAppointment(Appointment a) async {
    final ok = await _confirmDialog(
      title: 'Отменить запись?',
      body:
          'Пациенту будет возвращено ${a.price} ₸.\n'
          'Сумма будет списана с вашего баланса.\n'
          'Слот снова станет доступен для записи.',
    );
    if (ok != true) return;

    final apptProv = context.read<AppointmentProvider>();
    final slotProv = context.read<SlotProvider>();
    final userProv = context.read<UserProvider>();

    final refundOk = await apptProv.cancelByDoctor(a.id);

    if (a.slotId.isNotEmpty) {
      await slotProv.markFree(a.slotId);
    }

    // Обновляем баланс врача после возврата
    await userProv.reload();

    if (refundOk) {
      _snack('Запись отменена, пациенту возвращено ${a.price} ₸', Colors.red);
    } else {
      _snack(
        'Запись отменена, но возврат прошёл с ошибкой',
        Colors.orange,
      );
    }
  }

  Future<void> _completeAppointment(Appointment a) async {
    final ok = await _confirmDialog(
      title: 'Отметить как завершённую?',
      body: 'Приём будет перемещён в раздел «Завершены».',
    );
    if (ok != true) return;

    await context.read<AppointmentProvider>().completeByDoctor(a.id);
    _snack('Приём завершён', Colors.blue);
  }

  Future<bool?> _confirmDialog({
    required String title,
    required String body,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Нет'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Да'),
            ),
          ],
        );
      },
    );
  }

  void _snack(String text, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: color),
    );
  }
}

class DoctorAppointmentCard extends StatelessWidget {
  final Appointment appointment;
  final bool showConfirm;
  final bool showCancel;
  final bool showComplete;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final VoidCallback onComplete;

  const DoctorAppointmentCard({
    super.key,
    required this.appointment,
    required this.showConfirm,
    required this.showCancel,
    required this.showComplete,
    required this.onConfirm,
    required this.onCancel,
    required this.onComplete,
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

    String patientDisplay = 'Пациент';
    if (a.patientName.isNotEmpty) patientDisplay = a.patientName;

    String dateDisplay = a.date;
    if (dateDisplay.isEmpty) dateDisplay = '—';

    final hasActions = showConfirm || showCancel || showComplete;

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
                  backgroundColor: statusColor,
                  child: Icon(statusIcon, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        patientDisplay,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'ID: ${a.userId}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _row(Icons.calendar_today, 'Дата', dateDisplay),
                      _row(
                        Icons.access_time,
                        'Время',
                        '${a.startTime}–${a.endTime}',
                      ),
                      _row(
                        statusIcon,
                        'Статус',
                        statusLabel,
                        valueColor: statusColor,
                      ),
                      if (a.price > 0)
                        _row(
                          Icons.payments,
                          'Оплачено',
                          '${a.price} ₸',
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (hasActions) ...[
              const Divider(height: 20),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                children: [
                  if (showConfirm)
                    ElevatedButton.icon(
                      onPressed: onConfirm,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Подтвердить'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  if (showComplete)
                    ElevatedButton.icon(
                      onPressed: onComplete,
                      icon: const Icon(Icons.done_all, size: 18),
                      label: const Text('Завершить'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  if (showCancel)
                    OutlinedButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Отменить'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                ],
              ),
            ],
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
