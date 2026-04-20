import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/supabase/supabase_bootstrap.dart';
import 'core/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/models/user_role.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/welcome_screen.dart';
import 'features/home/screens/lecturer_dashboard_screen.dart';
import 'features/navigation/screens/main_shell.dart';

class IctuCommunityApp extends StatefulWidget {
  const IctuCommunityApp({super.key});

  @override
  State<IctuCommunityApp> createState() => _IctuCommunityAppState();
}

class _IctuCommunityAppState extends State<IctuCommunityApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<AuthState>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    if (SupabaseBootstrap.isConfigured && _hasInitializedSupabase) {
      _authStateSubscription = Supabase
          .instance
          .client
          .auth
          .onAuthStateChange
          .listen((AuthState authState) {
            if (authState.event == AuthChangeEvent.signedIn) {
              _routeToRoleHome();
            }
          });
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _routeToRoleHome() async {
    final NavigatorState? navigator = _navigatorKey.currentState;
    if (navigator == null ||
        !mounted ||
        !SupabaseBootstrap.isConfigured ||
        !_hasInitializedSupabase) {
      return;
    }

    final authController = Provider.of<AuthController>(context, listen: false);
    final UserRole? role = await authController.restoreCurrentUserRole();
    if (!mounted) {
      return;
    }

    if (role == null) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
        (Route<dynamic> route) => false,
      );
      return;
    }

    if (role == UserRole.lecturer) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute<void>(
          builder: (_) => const LecturerDashboardScreen(),
        ),
        (Route<dynamic> route) => false,
      );
      return;
    }

    navigator.pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => MainShell(userRole: role)),
      (Route<dynamic> route) => false,
    );
  }

  bool get _hasInitializedSupabase {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'ICTU Community',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const SplashScreen(),
    );
  }
}
