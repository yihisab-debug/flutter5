import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/doctor.dart';
import '../../providers/user_provider.dart';
import '../../services/api_service.dart';

class DoctorPendingScreen extends StatefulWidget {
  const DoctorPendingScreen({super.key});

  @override
  State<DoctorPendingScreen> createState() => _DoctorPendingScreenState();
}

class _DoctorPendingScreenState extends State<DoctorPendingScreen> {
  final _api = ApiService();
  Doctor? _doctor;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final userProv = context.read<UserProvider>();
    final doctorId = userProv.profile?.doctorId ?? '';
    if (doctorId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    try {
      final d = await _api.getDoctorById(doctorId);
      if (!mounted) return;
      setState(() {
        _doctor = d;
        _loading = false;
      });
      await userProv.reload();
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rejected = _doctor?.isRejected ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль на модерации'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Проверить статус',
            onPressed: _load,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Выйти',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      rejected ? Icons.cancel : Icons.hourglass_top,
                      size: 96,
                      color: rejected ? Colors.red : Colors.orange,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      rejected
                          ? 'Заявка отклонена'
                          : 'Ожидает проверки администратором',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      rejected
                          ? 'К сожалению, ваш профиль врача не был '
                              'одобрен. Свяжитесь с администрацией '
                              'для уточнения причин.'
                          : 'Ваш профиль создан и отправлен на '
                              'проверку. Как только администратор '
                              'одобрит его, вы сможете принимать '
                              'записи от пациентов.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 32),
                    OutlinedButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Проверить статус'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
