import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../models/doctor.dart';
import '../../models/slot.dart';
import '../../providers/slot_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';
import '../../services/notification_service.dart';
import '../appointments/my_appointments_screen.dart';

class BookingScreen extends StatefulWidget {
  final Doctor doctor;
  final Slot slot;
  const BookingScreen({
    super.key,
    required this.doctor,
    required this.slot,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _api = ApiService();
  final _notifications = NotificationService();
  bool _loading = false;

  Future<void> _confirm() async {
    if (_loading) return;

    final userProv = context.read<UserProvider>();
    final slotProv = context.read<SlotProvider>();
    final price = widget.doctor.price;

    if (userProv.profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Профиль не загружен, попробуйте позже'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (widget.slot.isBooked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Слот уже занят'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (userProv.balance < price) {
      await _showNotEnoughFundsDialog(userProv.balance, price);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Подтверждение оплаты'),
          content: Text(
            'Со счёта будет списано $price ₸.\n'
            'Текущий баланс: ${userProv.balance} ₸\n'
            'После оплаты: ${userProv.balance - price} ₸\n\n'
            'Запись будет создана со статусом «Ожидает подтверждения» — '
            'врач подтвердит её в ближайшее время.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Оплатить'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    setState(() => _loading = true);

    bool charged = false;
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final patientName = userProv.profile?.name ?? '';

      await userProv.charge(price);
      charged = true;

      await _api.createAppointment({
        'userId': userId,
        'doctorId': widget.doctor.id,
        'doctorName': widget.doctor.name,
        'doctorSpec': widget.doctor.specialization,
        'patientName': patientName,
        'slotId': widget.slot.id,
        'date': widget.slot.date,
        'startTime': widget.slot.startTime,
        'endTime': widget.slot.endTime,
        'price': price,
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      });

      await slotProv.markBooked(widget.slot.id);

      final credited = await _api.creditDoctorBalance(
        widget.doctor.id,
        price,
      );
      if (!credited) {
        debugPrint(
          'WARN: не удалось начислить $price ₸ врачу ${widget.doctor.id}',
        );
      }

      await _notifications.showBookingConfirmation(
        doctorName: widget.doctor.name,
        date: widget.slot.date,
        time: widget.slot.startTime,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Запись создана! Списано $price ₸. Остаток: ${userProv.balance} ₸',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MyAppointmentsScreen()),
          (route) => route.isFirst,
        );
      }
    } catch (e) {
      if (charged) {
        try {
          await userProv.topUp(price);
        } catch (_) {}
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _showNotEnoughFundsDialog(int balance, int price) async {
    final missing = price - balance;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.orange),
              SizedBox(width: 8),
              Text('Недостаточно средств'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Стоимость приёма: $price ₸'),
              const SizedBox(height: 4),
              Text('Ваш баланс: $balance ₸'),
              const SizedBox(height: 4),
              Text(
                'Не хватает: $missing ₸',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Пополните баланс в профиле и попробуйте снова.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Закрыть'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final slot = widget.slot;
    final doctor = widget.doctor;
    final balance = context.watch<UserProvider>().balance;
    final enough = balance >= doctor.price;
    final slotTaken = slot.isBooked;

    Color statusColor = Colors.green;
    if (slotTaken) statusColor = Colors.red;

    Color buttonColor = Colors.grey;
    if (enough && !slotTaken) buttonColor = Colors.blue;

    String buttonText = 'Недостаточно средств';
    if (slotTaken) {
      buttonText = 'Слот занят';
    } else if (enough) {
      buttonText = 'Оплатить ${doctor.price} ₸ и записаться';
    }

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
                    const Text(
                      'Детали записи',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    _infoRow(Icons.person, 'Врач', doctor.name),
                    _infoRow(
                      Icons.medical_services,
                      'Специализация',
                      doctor.specialization,
                    ),
                    _infoRow(Icons.calendar_today, 'Дата', slot.date),
                    _infoRow(
                      Icons.access_time,
                      'Время',
                      '${slot.startTime}–${slot.endTime}',
                    ),
                    _infoRow(
                      Icons.payments,
                      'Стоимость',
                      '${doctor.price} ₸',
                    ),
                    _infoRow(
                      slotTaken ? Icons.event_busy : Icons.event_available,
                      'Статус слота',
                      slot.statusLabel,
                      valueColor: statusColor,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              color: enough ? Colors.blue.shade50 : Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      enough
                          ? Icons.account_balance_wallet
                          : Icons.warning_amber_rounded,
                      color: enough ? Colors.blue : Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ваш баланс: $balance ₸',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            enough
                                ? 'После оплаты останется ${balance - doctor.price} ₸'
                                : 'Недостаточно средств. Не хватает ${doctor.price - balance} ₸',
                            style: TextStyle(
                              color: enough ? Colors.grey : Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: (_loading || !enough || slotTaken)
                  ? null
                  : _confirm,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: buttonColor,
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: valueColor)),
          ),
        ],
      ),
    );
  }
}
