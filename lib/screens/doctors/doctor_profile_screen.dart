import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../models/doctor.dart';
import '../../models/slot.dart';
import '../../providers/slot_provider.dart';
import '../booking/booking_screen.dart';
import '../reviews/reviews_screen.dart';

class DoctorProfileScreen extends StatefulWidget {
  final Doctor doctor;
  const DoctorProfileScreen({super.key, required this.doctor});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  String? _selectedDate;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<SlotProvider>().load(widget.doctor.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final doctor = widget.doctor;
    double rating = doctor.rating;
    if (rating < 0) rating = 0;
    if (rating > 5) rating = 5;

    final slotProv = context.watch<SlotProvider>();
    final availableDates = slotProv.availableDates;

    if (_selectedDate != null && !availableDates.contains(_selectedDate)) {
      _selectedDate = null;
    }

    List<Slot> slotsForDate = [];
    if (_selectedDate != null) {
      slotsForDate = slotProv.freeSlotsForDate(_selectedDate!);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(doctor.name),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.reviews),
            tooltip: 'Отзывы',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ReviewsScreen(doctor: doctor),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<SlotProvider>().load(doctor.id),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                      imageBuilder: (ctx, img) {
                        return CircleAvatar(
                          backgroundImage: img,
                          radius: 55,
                        );
                      },
                      placeholder: (_, __) => const CircleAvatar(
                        radius: 55,
                        child: CircularProgressIndicator(),
                      ),
                      errorWidget: (_, __, ___) => const CircleAvatar(
                        radius: 55,
                        child: Icon(Icons.person, size: 55),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      doctor.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      doctor.specialization,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    RatingBarIndicator(
                      rating: rating,
                      itemBuilder: (_, __) => const Icon(
                        Icons.star,
                        color: Colors.amber,
                      ),
                      itemSize: 24,
                    ),
                    Text('${rating.toStringAsFixed(1)} / 5.0'),
                    const SizedBox(height: 8),
                    Text(
                      'Цена приёма: ${doctor.price} ₸',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'О враче',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      doctor.description.isEmpty
                          ? 'Описание не указано'
                          : doctor.description,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Доступные даты',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (slotProv.isLoading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (availableDates.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Врач пока не добавил свободные слоты',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: availableDates.length,
                    itemBuilder: (_, i) {
                      final date = availableDates[i];
                      final selected = date == _selectedDate;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(date),
                          selected: selected,
                          onSelected: (_) {
                            setState(() => _selectedDate = date);
                          },
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
                      const Text(
                        'Доступное время',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (slotsForDate.isEmpty)
                        const Text(
                          'Нет свободных слотов',
                          style: TextStyle(color: Colors.grey),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: slotsForDate.map((s) {
                            return SlotButton(slot: s, doctor: doctor);
                          }).toList(),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class SlotButton extends StatelessWidget {
  final Slot slot;
  final Doctor doctor;
  const SlotButton({super.key, required this.slot, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade50,
        foregroundColor: Colors.blue,
      ),
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingScreen(doctor: doctor, slot: slot),
          ),
        );
        if (context.mounted) {
          context.read<SlotProvider>().load(doctor.id);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${slot.startTime}–${slot.endTime}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text(
            'Свободно',
            style: TextStyle(fontSize: 11, color: Colors.green),
          ),
        ],
      ),
    );
  }
}
