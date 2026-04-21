import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../services/admin_session.dart';
import '../auth/login_screen.dart';
import 'admin_appointments_screen.dart';
import 'admin_doctors_screen.dart';
import 'admin_users_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _index = 0;

  final List<Widget> _tabs = const [
    AdminDoctorsScreen(),
    AdminUsersScreen(),
    AdminAppointmentsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<AdminProvider>().loadAll();
    });
  }

  void _logout() {
    AdminSession.instance.logout();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: const [
              Icon(Icons.admin_panel_settings),
              SizedBox(width: 8),
              Text('Админ-панель'),
            ],
          ),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Обновить всё',
              onPressed: () =>
                  context.read<AdminProvider>().loadAll(),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Выйти',
              onPressed: _logout,
            ),
          ],
        ),
        body: IndexedStack(index: _index, children: _tabs),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.medical_services),
              label: 'Врачи',
            ),
            NavigationDestination(
              icon: Icon(Icons.people),
              label: 'Пользователи',
            ),
            NavigationDestination(
              icon: Icon(Icons.event_note),
              label: 'Записи',
            ),
          ],
        ),
      ),
    );
  }
}
