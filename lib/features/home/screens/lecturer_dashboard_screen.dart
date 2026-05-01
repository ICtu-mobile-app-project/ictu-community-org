import 'package:flutter/material.dart';

import 'package:ictu_community_org/features/auth/models/user_role.dart';
import 'package:ictu_community_org/features/navigation/screens/main_shell.dart';

class LecturerDashboardScreen extends StatelessWidget {
  const LecturerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainShell(userRole: UserRole.lecturer);
  }
}

