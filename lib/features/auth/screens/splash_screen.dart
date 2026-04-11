import 'package:flutter/material.dart';

import '../../home/screens/lecturer_dashboard_screen.dart';
import '../../navigation/screens/main_shell.dart';
import '../controllers/auth_controller.dart';
import '../models/user_role.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthController _authController = AuthController();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _authController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    final UserRole? role = await _authController.restoreCurrentUserRole();
    if (!mounted) {
      return;
    }

    if (role == UserRole.lecturer) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const LecturerDashboardScreen()),
      );
      return;
    }

    if (role != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => MainShell(userRole: role)),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/school.jpeg', fit: BoxFit.cover),
          Container(color: const Color(0xB0001433)),
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x33001533), Color(0xAA00122E)],
              ),
            ),
          ),
          Center(
            child: Image.asset(
              'assets/Logo.png',
              width: 180,
              height: 180,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
