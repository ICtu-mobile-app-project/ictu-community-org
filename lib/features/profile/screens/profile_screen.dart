import 'package:flutter/material.dart';
import 'package:ictu_community_org/features/profile/controllers/profile_controller.dart';

import 'package:ictu_community_org/core/theme/app_colors.dart';
import 'package:ictu_community_org/core/widgets/ambient_background.dart';
import 'package:ictu_community_org/core/widgets/app_top_bar.dart';
import 'package:ictu_community_org/core/widgets/glass_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileController _controller = ProfileController();

  @override
  void initState() {
    super.initState();
    _controller.loadProfile();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: const AppTopBar(showBack: true, title: 'Profile'),
      body: AmbientBackground(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (_controller.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryContainer),
              );
            }

            if (_controller.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _controller.error!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: _controller.loadProfile,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final data = _controller.profileData;
            if (data == null) {
              return const Center(
                child: Text(
                  'No profile data found',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            return SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryContainer,
                          width: 2,
                        ),
                      ),
                      child: const CircleAvatar(
                        backgroundImage: AssetImage('assets/students.jpg'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      data['full_name'] ?? 'Unknown User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _ProfileItem(
                    icon: Icons.school_rounded,
                    title: 'Program',
                    value: data['program'] ?? 'Not specified',
                  ),
                  _ProfileItem(
                    icon: Icons.business_rounded,
                    title: 'Faculty',
                    value: data['faculty'] ?? 'Not specified',
                  ),
                  _ProfileItem(
                    icon: Icons.layers_rounded,
                    title: 'Year Level',
                    value: 'Year ${data['year_level'] ?? 'N/A'}',
                  ),
                  _ProfileItem(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    value: data['email'] ?? 'Not specified',
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  const _ProfileItem({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
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
