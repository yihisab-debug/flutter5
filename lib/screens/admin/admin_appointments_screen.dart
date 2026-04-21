import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/appointment.dart';
import '../../providers/admin_provider.dart';

class AdminAppointmentsScreen extends StatefulWidget {
  const AdminAppointmentsScreen({super.key});

  @override
  State<AdminAppointmentsScreen> createState() =>
      _AdminAppointmentsScreenState();
}

class _AdminAppointmentsScreenState
    extends State<AdminAppointmentsScreen> {
  String _filter = 'all';

  List<Appointment> _apply(List<Appointment> all) {
    if (_filter == 'all') return all;
    return [for (final a in all) if (a.status == _filter) a];
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
                _chip('pending', 'Ожидают'),
                _chip('confirmed', 'Подтверждены'),
                _chip('completed', 'Завершены'),
                _chip('cancelled', 'Отменены'),
              ],
            ),
          ),
        ),
        Expanded(
          child: Consumer<AdminProvider>(
            builder: (_, prov, __) {
              if (prov.isLoadingAppointments) {
                return const Center(child: CircularProgressIndicator());
              }
              final list = _apply(prov.appointments);
              if (list.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () =>
                      context.read<AdminProvider>().loadAppointments(),
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
                onRefresh: () =>
                    context.read<AdminProvider>().loadAppointments(),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _Card(a: list[i]),
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

class _Card extends StatelessWidget {
  final Appointment a;
  const _Card({required this.a});

  @override
  Widget build(BuildContext context) {
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

    String patient = a.patientName.isEmpty ? 'Пациент' : a.patientName;
    String doctor = a.doctorName.isEmpty ? 'Врач' : a.doctorName;

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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '$patient → $doctor',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (a.doctorSpec.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      a.doctorSpec,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 13,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        a.date.isEmpty ? '—' : a.date,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.access_time,
                        size: 13,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        a.startTime.isEmpty
                            ? '—'
                            : '${a.startTime}–${a.endTime}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
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
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (a.price > 0)
                        Text(
                          '${a.price} ₸',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
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
