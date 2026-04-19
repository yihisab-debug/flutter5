import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/slot.dart';
import '../../providers/slot_provider.dart';
import '../../providers/user_provider.dart';

class DoctorScheduleScreen extends StatefulWidget {
  const DoctorScheduleScreen({super.key});

  @override
  State<DoctorScheduleScreen> createState() => _DoctorScheduleScreenState();
}

class _DoctorScheduleScreenState extends State<DoctorScheduleScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    final doctorId = context.read<UserProvider>().profile?.doctorId ?? '';
    if (doctorId.isEmpty) return;
    await context.read<SlotProvider>().load(doctorId);
  }

  Future<void> _addSlotDialog() async {
    final doctorId = context.read<UserProvider>().profile?.doctorId ?? '';
    if (doctorId.isEmpty) return;

    DateTime? date;
    TimeOfDay? start;
    TimeOfDay? end;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSt) {
            String dateText = 'Выбрать дату';
            if (date != null) {
              dateText = _formatDate(date!);
            }

            String startText = '—';
            if (start != null) {
              startText = _formatTime(start!);
            }

            String endText = '—';
            if (end != null) {
              endText = _formatTime(end!);
            }

            return AlertDialog(
              title: const Text('Новый слот'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(dateText),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate:
                            DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 365),
                        ),
                      );
                      if (picked != null) {
                        setSt(() => date = picked);
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.schedule),
                    title: Text('Начало: $startText'),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: ctx,
                        initialTime: const TimeOfDay(hour: 9, minute: 0),
                      );
                      if (picked != null) {
                        setSt(() => start = picked);
                      }
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.schedule_outlined),
                    title: Text('Конец: $endText'),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: ctx,
                        initialTime: const TimeOfDay(hour: 10, minute: 0),
                      );
                      if (picked != null) {
                        setSt(() => end = picked);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Отмена'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (date == null || start == null || end == null) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Заполните все поля'),
                        ),
                      );
                      return;
                    }

                    int startMin = start!.hour * 60 + start!.minute;
                    int endMin = end!.hour * 60 + end!.minute;
                    if (endMin <= startMin) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Время окончания должно быть позже начала',
                          ),
                        ),
                      );
                      return;
                    }

                    final dateStr = _formatDate(date!);
                    final startStr = _formatTime(start!);
                    final endStr = _formatTime(end!);

                    Navigator.pop(ctx);

                    try {
                      await context.read<SlotProvider>().addSlot(
                            doctorId: doctorId,
                            date: dateStr,
                            startTime: startStr,
                            endTime: endStr,
                          );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Слот добавлен'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Ошибка: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Добавить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _addWorkdayDialog() async {
    final doctorId = context.read<UserProvider>().profile?.doctorId ?? '';
    if (doctorId.isEmpty) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Выберите рабочий день',
    );
    if (picked == null || !mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Стандартный день'),
          content: const Text(
            'Добавить 8 часовых слотов с 09:00 до 17:00 на выбранный день?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Добавить'),
            ),
          ],
        );
      },
    );
    if (ok != true) return;

    final dateStr = _formatDate(picked);
    final slotProv = context.read<SlotProvider>();
    int added = 0;

    for (int h = 9; h < 17; h++) {
      String hh = h.toString().padLeft(2, '0');
      String nextHh = (h + 1).toString().padLeft(2, '0');
      String startStr = '$hh:00';
      String endStr = '$nextHh:00';

      try {
        await slotProv.addSlot(
          doctorId: doctorId,
          date: dateStr,
          startTime: startStr,
          endTime: endStr,
        );
        added++;
      } catch (_) {}
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Добавлено слотов: $added'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String _formatDate(DateTime d) {
    String y = d.year.toString();
    String m = d.month.toString().padLeft(2, '0');
    String day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _formatTime(TimeOfDay t) {
    String h = t.hour.toString().padLeft(2, '0');
    String m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final userProv = context.watch<UserProvider>();
    final doctorId = userProv.profile?.doctorId ?? '';

    if (doctorId.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('Сначала заполните профиль врача')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Расписание'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Обновить',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSlotDialog,
        icon: const Icon(Icons.add),
        label: const Text('Добавить слот'),
      ),
      body: Consumer<SlotProvider>(
        builder: (ctx, prov, _) {
          if (prov.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final dates = prov.allDates;
          if (dates.isEmpty) {
            return RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 100),
                  const Center(
                    child: Icon(
                      Icons.event_busy,
                      size: 64,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'Расписание пустое.\nДобавьте первый слот или рабочий день.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: OutlinedButton.icon(
                      onPressed: _addWorkdayDialog,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text(
                        'Добавить рабочий день (9-17)',
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: OutlinedButton.icon(
                    onPressed: _addWorkdayDialog,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Добавить рабочий день (9-17)'),
                  ),
                ),
                for (var d in dates)
                  DateSection(
                    date: d,
                    slots: prov.slotsForDate(d),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class DateSection extends StatelessWidget {
  final String date;
  final List<Slot> slots;
  const DateSection({super.key, required this.date, required this.slots});

  @override
  Widget build(BuildContext context) {
    int free = 0;
    for (var s in slots) {
      if (!s.isBooked) free++;
    }
    int booked = slots.length - free;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 18,
                  color: Colors.blue,
                ),
                const SizedBox(width: 6),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  'Свободно: $free / Занято: $booked',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: slots.map((s) => SlotChip(slot: s)).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class SlotChip extends StatelessWidget {
  final Slot slot;
  const SlotChip({super.key, required this.slot});

  @override
  Widget build(BuildContext context) {
    final booked = slot.isBooked;

    IconData icon = Icons.check_circle_outline;
    Color iconColor = Colors.green;
    Color bg = Colors.green.shade50;

    if (booked) {
      icon = Icons.lock;
      iconColor = Colors.red;
      bg = Colors.red.shade50;
    }

    VoidCallback? onDeleted;
    if (!booked) {
      onDeleted = () => _confirmDelete(context, slot);
    }

    return InputChip(
      avatar: Icon(icon, size: 18, color: iconColor),
      label: Text('${slot.startTime}–${slot.endTime}'),
      backgroundColor: bg,
      deleteIcon: const Icon(Icons.close, size: 18),
      onDeleted: onDeleted,
    );
  }

  Future<void> _confirmDelete(BuildContext context, Slot slot) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Удалить слот?'),
          content: Text(
            'Слот ${slot.date} ${slot.startTime}–${slot.endTime} будет удалён.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text(
                'Удалить',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
    if (ok != true) return;

    try {
      await context.read<SlotProvider>().deleteSlot(slot.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Слот удалён')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
