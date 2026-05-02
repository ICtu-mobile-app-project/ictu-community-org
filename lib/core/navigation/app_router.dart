import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:ictu_community_org/core/navigation/app_routes.dart';
import 'package:ictu_community_org/features/auth/models/user_role.dart';
import 'package:ictu_community_org/features/auth/screens/login_screen.dart';
import 'package:ictu_community_org/features/auth/screens/signup_screen.dart';
import 'package:ictu_community_org/features/auth/screens/splash_screen.dart';
import 'package:ictu_community_org/features/auth/screens/welcome_screen.dart';
import 'package:ictu_community_org/features/home/screens/lecturer_dashboard_screen.dart';
import 'package:ictu_community_org/features/navigation/screens/main_shell.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        name: AppRoutes.splash,
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return const SplashScreen();
        },
      ),
      GoRoute(
        name: AppRoutes.welcome,
        path: '/welcome',
        builder: (BuildContext context, GoRouterState state) {
          return const WelcomeScreen();
        },
      ),
      GoRoute(
        name: AppRoutes.login,
        path: '/login/:role',
        builder: (BuildContext context, GoRouterState state) {
          final String roleValue = state.pathParameters['role'] ?? 'student';
          return LoginScreen(initialRole: UserRole.fromDb(roleValue));
        },
      ),
      GoRoute(
        name: AppRoutes.signup,
        path: '/signup/:role',
        builder: (BuildContext context, GoRouterState state) {
          final String roleValue = state.pathParameters['role'] ?? 'student';
          return SignupScreen(initialRole: UserRole.fromDb(roleValue));
        },
      ),
      GoRoute(
        name: AppRoutes.lecturerHome,
        path: '/lecturer',
        builder: (BuildContext context, GoRouterState state) {
          return const LecturerDashboardScreen();
        },
      ),
      GoRoute(
        name: AppRoutes.appShell,
        path: '/app/:role',
        builder: (BuildContext context, GoRouterState state) {
          final String roleValue = state.pathParameters['role'] ?? 'student';
          final UserRole role = UserRole.fromDb(roleValue);
          return MainShell(userRole: role);
        },
      ),
    ],
  );
}

