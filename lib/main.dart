import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/doctor_provider.dart';
import 'providers/appointment_provider.dart';
import 'providers/user_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/complete_profile_screen.dart';
import 'screens/doctors/doctor_list_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DoctorProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'Online Doctor Booking',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();
  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  User? _user;
  bool _authLoaded = false;
  String? _handledUid;
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();

    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;

      final sameUser = _user?.uid == user?.uid;

      setState(() {
        _user = user;
        _authLoaded = true;
      });

      if (!sameUser) {
        _handleUserChange(user);
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  void _handleUserChange(User? user) {
    if (user == null) {
      _handledUid = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.read<UserProvider>().clear();
      });
      return;
    }
    if (_handledUid == user.uid) return;
    _handledUid = user.uid;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UserProvider>().loadOrCreate(
            userId: user.uid,
            email: user.email ?? '',
            initialBalance: 1000,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_authLoaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_user == null) return const LoginScreen();

    return _ProfileRouter(
      user: _user!,
      onRetry: () {
        context.read<UserProvider>().loadOrCreate(
              userId: _user!.uid,
              email: _user!.email ?? '',
              initialBalance: 1000,
            );
      },
    );
  }
}

class _ProfileRouter extends StatelessWidget {
  final User user;
  final VoidCallback onRetry;
  const _ProfileRouter({required this.user, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<UserProvider>();

    if (prov.profile == null && prov.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (prov.error != null && prov.profile == null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: Colors.red),
                const SizedBox(height: 12),
                Text(
                  'Не удалось загрузить профиль:\n${prov.error}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Повторить'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => FirebaseAuth.instance.signOut(),
                  child: const Text('Выйти'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (prov.profile == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (prov.profile!.name.trim().isEmpty) {
      return const CompleteProfileScreen();
    }

    return const DoctorListScreen();
  }
}