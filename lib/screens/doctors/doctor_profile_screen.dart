import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../models/doctor.dart';
import '../../models/slot.dart';
import '../booking/booking_screen.dart';
import '../reviews/reviews_screen.dart';

class DoctorProfileScreen extends StatefulWidget {
  final Doctor doctor;
  const DoctorProfileScreen({super.key, required this.doctor});
  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  List<Slot> _slots = [];
  String? _selectedDate;

  List<Slot> _generateSlots(String doctorId) {
    final slots = <Slot>[];
    final today = DateTime.now();
    int idCounter = 1;

    for (int day = 1; day <= 7; day++) {
      final date = today.add(Duration(days: day));
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      for (int hour = 9; hour < 17; hour++) {
        final start = '${hour.toString().padLeft(2, '0')}:00';
        final end = '${(hour + 1).toString().padLeft(2, '0')}:00';
        slots.add(Slot(
          id: '${doctorId}_${idCounter++}',
          doctorId: doctorId,
          date: dateStr,
          startTime: start,
          endTime: end,
          isBooked: false,
          status: 'available',
        ));
      }
    }
    return slots;
  }

  @override
  void initState() {
    super.initState();
    _slots = _generateSlots(widget.doctor.id);
  }

  List<String> get _availableDates {
    return _slots
        .where((s) => !s.isBooked)
        .map((s) => s.date)
        .toSet()
        .toList()
      ..sort();
  }

  List<Slot> get _slotsForDate {
    if (_selectedDate == null) return [];
    return _slots
        .where((s) => s.date == _selectedDate && !s.isBooked)
        .toList();
  }

  void _markSlotBooked(String slotId) {
    setState(() {
      final idx = _slots.indexWhere((s) => s.id == slotId);
      if (idx != -1) {
        final old = _slots[idx];
        _slots[idx] = Slot(
          id: old.id,
          doctorId: old.doctorId,
          date: old.date,
          startTime: old.startTime,
          endTime: old.endTime,
          isBooked: true,
          status: 'booked',
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final doctor = widget.doctor;
    final rating = doctor.rating.clamp(0.0, 5.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(doctor.name),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.reviews),
            tooltip: 'Отзывы',
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(
                builder: (_) => ReviewsScreen(doctor: doctor))),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: Colors.blue.shade50,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CachedNetworkImage(
                    imageUrl: doctor.photoUrl,
                    imageBuilder: (ctx, img) => CircleAvatar(
                      backgroundImage: img, radius: 55),
                    placeholder: (_, __) => const CircleAvatar(
                      radius: 55,
                      child: CircularProgressIndicator()),
                    errorWidget: (_, __, ___) => const CircleAvatar(
                      radius: 55,
                      child: Icon(Icons.person, size: 55)),
                  ),
                  const SizedBox(height: 12),
                  Text(doctor.name,
                    style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(doctor.specialization,
                    style: const TextStyle(
                      fontSize: 16, color: Colors.blue)),
                  const SizedBox(height: 8),
                  RatingBarIndicator(
                    rating: rating,
                    itemBuilder: (_, __) =>
                      const Icon(Icons.star, color: Colors.amber),
                    itemSize: 24,
                  ),
                  Text('${rating.toStringAsFixed(1)} / 5.0'),
                  const SizedBox(height: 8),
                  Text('Цена приёма: ${doctor.price} ₸',
                    style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500)),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('О враче',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(doctor.description),
                  const SizedBox(height: 20),
                  const Text('Доступные даты',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _availableDates.length,
                itemBuilder: (_, i) {
                  final date = _availableDates[i];
                  final selected = date == _selectedDate;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(date),
                      selected: selected,
                      onSelected: (_) =>
                        setState(() => _selectedDate = date),
                    ),
                  );
                },
              ),
            ),

            if (_selectedDate != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Доступное время',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _slotsForDate.map((slot) =>
                        _SlotButton(
                          slot: slot,
                          doctor: doctor,
                          onBooked: () => _markSlotBooked(slot.id),
                        )
                      ).toList(),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _SlotButton extends StatelessWidget {
  final Slot slot;
  final Doctor doctor;
  final VoidCallback onBooked;
  const _SlotButton({
    required this.slot,
    required this.doctor,
    required this.onBooked,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade50,
        foregroundColor: Colors.blue,
      ),
      onPressed: () async {
        await Navigator.push(context,
          MaterialPageRoute(
            builder: (_) => BookingScreen(doctor: doctor, slot: slot)));
        onBooked();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${slot.startTime}–${slot.endTime}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
          const Text('Свободно',
            style: TextStyle(fontSize: 11, color: Colors.green)),
        ],
      ),
    );
  }
}