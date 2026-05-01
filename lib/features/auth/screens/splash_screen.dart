import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:ictu_community_org/core/widgets/ambient_background.dart';
import 'package:ictu_community_org/features/auth/controllers/auth_controller.dart';
import 'package:ictu_community_org/features/auth/models/user_role.dart';
import 'package:ictu_community_org/features/auth/screens/welcome_screen.dart';
import 'package:ictu_community_org/features/home/screens/lecturer_dashboard_screen.dart';
import 'package:ictu_community_org/features/navigation/screens/main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    final authController = Provider.of<AuthController>(context, listen: false);
    final UserRole? role = await authController.restoreCurrentUserRole();
    if (!mounted) {
      return;
    }

    if (role == UserRole.lecturer) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => const LecturerDashboardScreen(),
          ),
        );
      }
      return;
    }

    if (role != null) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => MainShell(userRole: role)),
        );
      }
      return;
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: Center(
          child: Image.asset(
            'assets/Logo.png',
            width: 180,
            height: 180,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
