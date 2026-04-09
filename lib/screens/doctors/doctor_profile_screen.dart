import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../models/doctor.dart';
import '../../models/slot.dart';
import '../../services/api_service.dart';
import '../booking/booking_screen.dart';
import '../reviews/reviews_screen.dart';

class DoctorProfileScreen extends StatefulWidget {
  final Doctor doctor;
  const DoctorProfileScreen({super.key, required this.doctor});
  @override
  State<DoctorProfileScreen> createState() =>
    _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final _api = ApiService();
  List<Slot> _slots = [];
  bool _loading = true;
  String? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadSlots();
  }

  Future<void> _loadSlots() async {
    try {
      final slots = await _api.getSlots(widget.doctor.id);
      setState(() { _slots = slots; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  List<String> get _availableDates {
    return _slots
      .where((s) => !s.isBooked)
      .map((s) => s.date)
      .toSet().toList()..sort();
  }

  List<Slot> get _slotsForDate {
    if (_selectedDate == null) return [];
    return _slots.where((s) =>
      s.date == _selectedDate && !s.isBooked).toList();
  }

  @override
  Widget build(BuildContext context) {
    final doctor = widget.doctor;
    return Scaffold(
      appBar: AppBar(
        title: Text(doctor.name),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [

          IconButton(
            icon: const Icon(Icons.reviews),
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(
                builder: (_) => ReviewsScreen(doctor: doctor))),
            tooltip: 'Отзывы',
          ),

        ],
      ),

      body: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Container(
              width: double.infinity,
              color: Colors.blue.shade50,
              padding: const EdgeInsets.all(20),
              child: 
              Column(
                children: [

                CachedNetworkImage(
                  imageUrl: doctor.photoUrl,
                  imageBuilder: (ctx, img) => CircleAvatar(
                    backgroundImage: img, radius: 55),
                  placeholder: (_, __) => const CircleAvatar(
                    radius: 55, child: CircularProgressIndicator()),
                  errorWidget: (_, __, ___) => const CircleAvatar(
                    radius: 55, child: Icon(Icons.person, size: 55)),
                ),

                const SizedBox(height: 12),

                Text(doctor.name, style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold)),

                Text(doctor.specialization,
                  style: const TextStyle(
                    fontSize: 16, color: Colors.blue)),

                const SizedBox(height: 8),

                RatingBarIndicator(
                  rating: doctor.rating,
                  itemBuilder: (_, __) => const Icon(
                    Icons.star, color: Colors.amber),
                  itemSize: 24,
                ),

                Text('${doctor.rating} / 5.0'),

                const SizedBox(height: 8),

                Text('Цена приёма: ${doctor.price} ₸',
                  style: const TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w500)),

              ]),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Text('О враче',
                    style: TextStyle(fontSize: 18,
                      fontWeight: FontWeight.bold)),

                  const SizedBox(height: 8),

                  Text(doctor.description),

                  const SizedBox(height: 20),

                  const Text('Доступные даты',
                    style: TextStyle(fontSize: 18,
                      fontWeight: FontWeight.bold)),

                ],
              ),
            ),

            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_availableDates.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Нет доступных слотов'))
            else
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
                      style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.bold)),

                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: _slotsForDate.map((slot) =>
                        ElevatedButton(
                          onPressed: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) =>
                              BookingScreen(
                                doctor: doctor, slot: slot))),
                          child: Text('${slot.startTime}–${slot.endTime}'),
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
