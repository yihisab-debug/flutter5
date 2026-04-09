import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/doctor.dart';
import '../../models/slot.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../appointments/my_appointments_screen.dart';

class BookingScreen extends StatefulWidget {
  final Doctor doctor;
  final Slot slot;
  const BookingScreen({
    super.key, required this.doctor, required this.slot});
  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _api = ApiService();
  final _notifications = NotificationService();
  bool _loading = false;

  Future<void> _confirm() async {
    setState(() => _loading = true);
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      // Создать запись
      await _api.createAppointment({
        'userId': userId,
        'doctorId': widget.doctor.id,
        'slotId': widget.slot.id,
        'status': 'confirmed',
        'createdAt': DateTime.now().toIso8601String(),
      });
      // Занять слот
      await _api.updateSlot(widget.slot.id, true);
      // Уведомление
      await _notifications.showBookingConfirmation(
        doctorName: widget.doctor.name,
        date: widget.slot.date,
        time: widget.slot.startTime,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Запись успешно создана!'),
            backgroundColor: Colors.green));
        Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(
            builder: (_) => const MyAppointmentsScreen()),
          (route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: ${e.toString()}'),
          backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Оформление записи'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Детали записи',
                      style: TextStyle(fontSize: 18,
                        fontWeight: FontWeight.bold)),
                    const Divider(),
                    _infoRow(Icons.person, 'Врач', widget.doctor.name),
                    _infoRow(Icons.medical_services, 'Специализация',
                      widget.doctor.specialization),
                    _infoRow(Icons.calendar_today, 'Дата',
                      widget.slot.date),
                    _infoRow(Icons.access_time, 'Время',
                      '${widget.slot.startTime}–${widget.slot.endTime}'),
                    _infoRow(Icons.payments, 'Стоимость',
                      '${widget.doctor.price} ₸'),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _loading ? null : _confirm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.blue),
              child: _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Подтвердить запись',
                    style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, size: 18, color: Colors.blue),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(
          fontWeight: FontWeight.w600)),
        Expanded(child: Text(value)),
      ]),
    );
  }
}
