import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/doctor_provider.dart';
import '../../services/auth_service.dart';
import '../../models/doctor.dart';
import 'doctor_profile_screen.dart';
import '../appointments/my_appointments_screen.dart';

class DoctorListScreen extends StatefulWidget {
  const DoctorListScreen({super.key});
  @override
  State<DoctorListScreen> createState() => _DoctorListScreenState();
}

class _DoctorListScreenState extends State<DoctorListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
      context.read<DoctorProvider>().loadDoctors());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Врачи'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [

          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(
                builder: (_) => const MyAppointmentsScreen())),
            tooltip: 'Мои записи',
          ),

          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().logout(),
            tooltip: 'Выйти',
          ),

        ],
      ),

      body: Consumer<DoctorProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) return _buildShimmer();
          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min, 
                children: [

                const Icon(Icons.error, size: 48, color: Colors.red),

                const SizedBox(height: 8),

                Text(provider.error!),

                ElevatedButton(
                  onPressed: provider.loadDoctors,
                  child: const Text('Повторить')),

              ]),
            );
          }
          
          return Column(
            children: [

            _buildFilters(provider),

            Expanded(
              child: provider.doctors.isEmpty
                ? const Center(child: Text('Врачи не найдены'))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: provider.doctors.length,
                    itemBuilder: (ctx, i) =>
                      _DoctorCard(doctor: provider.doctors[i])),
            ),

          ]);
        },
      ),
    );
  }

  Widget _buildFilters(DoctorProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[100],
      child: Column(
        children: [

        TextField(
          decoration: const InputDecoration(
            hintText: 'Поиск врача...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(vertical: 8)),
          onChanged: provider.setSearch,
        ),

        const SizedBox(height: 8),

        Row(
          children: [

          const Text('Специализация: '),

          const SizedBox(width: 8),

          Expanded(
            child: DropdownButton<String>(
              value: provider.filterSpec,
              isExpanded: true,
              items: provider.specializations
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
              onChanged: (v) => provider.setSpecFilter(v!),
            ),
          ),

        ]),

        Row(
          children: [

          Text('Рейтинг от ${provider.minRating.toStringAsFixed(1)}:'),

          Expanded(
            child: Slider(
              value: provider.minRating,
              min: 0, max: 5, divisions: 10,
              onChanged: provider.setRatingFilter,
            ),
          ),

        ]),
      ]),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: ListView.builder(
        itemCount: 6,
        itemBuilder: (_, __) => Card(
          margin: const EdgeInsets.all(8),

          child: ListTile(
            leading: const CircleAvatar(radius: 28),
            title: Container(height: 14, color: Colors.white),
            subtitle: Container(height: 10, color: Colors.white),
          ),

        ),
      ),
    );
  }
}

class _DoctorCard extends StatelessWidget {
  final Doctor doctor;
  const _DoctorCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(

        leading: CircleAvatar(
          backgroundImage: NetworkImage(doctor.photoUrl),
          radius: 28,
          onBackgroundImageError: (_, __) {},
        ),

        title: Text(doctor.name,
          style: const TextStyle(fontWeight: FontWeight.bold)),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(doctor.specialization,
              style: const TextStyle(color: Colors.blue)),

            Row(
              children: [

              const Icon(Icons.star, size: 14, color: Colors.amber),

              Text(' ${doctor.rating}  •  ${doctor.price} ₸'),

            ]),
          ],
        ),

        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(context,
          MaterialPageRoute(
            builder: (_) => DoctorProfileScreen(doctor: doctor))),
      ),
      
    );
  }
}
