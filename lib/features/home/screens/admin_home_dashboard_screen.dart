import 'package:flutter/material.dart';

import 'package:ictu_community_org/core/utils/string_utils.dart';
import 'package:ictu_community_org/features/profile/controllers/profile_controller.dart';
import 'package:ictu_community_org/core/theme/app_colors.dart';
import 'package:ictu_community_org/core/widgets/ambient_background.dart';
import 'package:ictu_community_org/features/auth/models/user_role.dart';
import 'package:ictu_community_org/features/courses/screens/admin_timetable_management_screen.dart';
import 'package:ictu_community_org/features/courses/screens/timetable_screen.dart';

class AdminHomeDashboardScreen extends StatefulWidget {
  const AdminHomeDashboardScreen({
    super.key,
    required this.onOpenMenu,
  });

  final VoidCallback onOpenMenu;

  @override
  State<AdminHomeDashboardScreen> createState() => _AdminHomeDashboardScreenState();
}

class _AdminHomeDashboardScreenState extends State<AdminHomeDashboardScreen> {
  final ProfileController _profileController = ProfileController();

  @override
  void initState() {
    super.initState();
    _profileController.loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _profileController,
            builder: (context, _) {
              final profile = _profileController.profileData;
              final fullName = profile?['full_name'] ?? 'System Admin';

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: widget.onOpenMenu,
                        child: Container(
                          width: 48,
                          height: 48,
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primaryContainer,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            backgroundColor: const Color(0xFF1E293B),
                            child: Text(
                              initialsFromName(fullName),
                              style: const TextStyle(
                                color: Color(0xFFF58220),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName,
                            style: const TextStyle(
                              color: Color(0xFFF1F5F9),
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Text(
                            'University Management',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Management Tools',
                    style: TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _AdminActionCard(
                    title: 'Master Timetable',
                    subtitle: 'Upload and manage course schedules',
                    icon: Icons.calendar_month_rounded,
                    color: const Color(0xFFF59E0B),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminTimetableManagementScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _AdminActionCard(
                    title: 'User Management',
                    subtitle: 'Manage students, lecturers and roles',
                    icon: Icons.people_alt_rounded,
                    color: const Color(0xFF60A5FA),
                    onTap: () {
                      // To be implemented
                    },
                  ),
                  const SizedBox(height: 16),
                  _AdminActionCard(
                    title: 'System Logs',
                    subtitle: 'Monitor system activity and errors',
                    icon: Icons.analytics_rounded,
                    color: const Color(0xFF10B981),
                    onTap: () {
                      // To be implemented
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AdminActionCard extends StatelessWidget {
  const _AdminActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withValues(alpha: 0.03),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: color.withValues(alpha: 0.1),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ],
        ),
      ),
    );
  }
}
