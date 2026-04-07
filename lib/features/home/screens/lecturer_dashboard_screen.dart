import 'package:flutter/material.dart';

import '../../auth/models/user_role.dart';
import '../../navigation/screens/main_shell.dart';

class LecturerDashboardScreen extends StatelessWidget {
  const LecturerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainShell(userRole: UserRole.lecturer);
  }
}

