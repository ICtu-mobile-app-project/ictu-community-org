import 'package:flutter/material.dart';

import 'package:ictu_community_org/core/theme/app_colors.dart';
import 'package:ictu_community_org/core/theme/app_text_styles.dart';
import 'package:ictu_community_org/core/widgets/ambient_background.dart';
import 'package:ictu_community_org/core/widgets/app_top_bar.dart';
import 'package:ictu_community_org/core/widgets/glass_card.dart';
import 'package:ictu_community_org/core/widgets/primary_button.dart';
import 'package:ictu_community_org/features/auth/screens/login_screen.dart';
import 'package:ictu_community_org/features/auth/screens/signup_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: const AppTopBar(title: 'Welcome'),
      body: AmbientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Image.asset('assets/Logo.png'),
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: GlassCard(
                    padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Welcome to ICTU',
                          style: AppTextStyles.h1,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your gateway to academic excellence',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const _FeatureTile(
                          icon: Icons.menu_book_rounded,
                          title: 'Access courses anywhere',
                          subtitle: 'View lectures, assignments, and materials on the go.',
                        ),
                        const SizedBox(height: 12),
                        const _FeatureTile(
                          icon: Icons.campaign_rounded,
                          title: 'Stay updated',
                          subtitle: 'Get alerts for deadlines and campus updates.',
                        ),
                        const SizedBox(height: 12),
                        const _FeatureTile(
                          icon: Icons.groups_rounded,
                          title: 'Connect with the community',
                          subtitle: 'Chat with peers and collaborate with faculty.',
                        ),
                        const SizedBox(height: 22),
                        PrimaryButton(
                          label: 'Get started',
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const SignupScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryContainer,
                            textStyle: AppTextStyles.labelSm.copyWith(
                              color: AppColors.primaryContainer,
                            ),
                          ),
                          child: const Text('New here? Create Account'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Icon(icon, color: AppColors.primaryContainer, size: 21),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.95),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
