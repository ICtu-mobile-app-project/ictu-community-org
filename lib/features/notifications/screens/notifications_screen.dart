import 'package:flutter/material.dart';

import 'package:ictu_community_org/core/theme/app_colors.dart';
import 'package:ictu_community_org/core/widgets/ambient_background.dart';
import 'package:ictu_community_org/core/widgets/app_top_bar.dart';
import 'package:ictu_community_org/core/widgets/glass_card.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: const AppTopBar(showBack: true, title: 'Notifications'),
      body: AmbientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: const [
              _NotificationTile(
                title: 'Assignment Reminder',
                message:
                    'Mobile Development assignment due tomorrow at 11:59 PM.',
                time: '10m ago',
                icon: Icons.assignment_rounded,
              ),
              _NotificationTile(
                title: 'New Announcement',
                message: 'ICT Summit registration is now open for all students.',
                time: '1h ago',
                icon: Icons.campaign_rounded,
              ),
              _NotificationTile(
                title: 'Schedule Update',
                message: 'Database Systems class moved to Room 305 for Friday.',
                time: 'Yesterday',
                icon: Icons.schedule_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.title,
    required this.message,
    required this.time,
    required this.icon,
  });

  final String title;
  final String message;
  final String time;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.primaryContainer.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: AppColors.primaryContainer, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: const TextStyle(
                    color: AppColors.primaryContainer,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}
