import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:ictu_community_org/core/navigation/app_routes.dart';
import 'package:ictu_community_org/core/theme/app_colors.dart';
import 'package:ictu_community_org/core/theme/app_text_styles.dart';
import 'package:ictu_community_org/core/widgets/ambient_background.dart';
import 'package:ictu_community_org/core/widgets/glass_card.dart';
import 'package:ictu_community_org/core/widgets/glass_segmented_tab.dart';
import 'package:ictu_community_org/core/widgets/primary_button.dart';
import 'package:ictu_community_org/features/auth/models/user_role.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int _selectedRoleIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isCompact = constraints.maxHeight < 700;
              final double outerPad = isCompact ? 16 : 22;
              final double logoSize = isCompact ? 96 : 112;
              final double innerPad = isCompact ? 16 : 22;
              final double gapSm = isCompact ? 8 : 12;
              final double gapMd = isCompact ? 12 : 16;
              final double gapLg = isCompact ? 16 : 24;

              return SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(outerPad),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: GlassCard(
                      padding: EdgeInsets.all(innerPad),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: Container(
                              width: logoSize,
                              height: logoSize,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.10),
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(isCompact ? 14 : 16),
                                child: Image.asset('assets/Logo.png'),
                              ),
                            ),
                          ),
                          SizedBox(height: gapMd),
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 320),
                              child: GlassSegmentedTab(
                                labels: const ['Student', 'Staff'],
                                selectedIndex: _selectedRoleIndex,
                                onTabChanged: (index) {
                                  setState(() {
                                    _selectedRoleIndex = index;
                                  });
                                },
                              ),
                            ),
                          ),
                          SizedBox(height: gapSm),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedRoleIndex == 0
                                      ? 'STUDENT COMMUNITY'
                                      : 'STAFF PORTAL',
                                  style: AppTextStyles.labelSm.copyWith(
                                    color: AppColors.primaryContainer,
                                    letterSpacing: 2.0,
                                    fontWeight: FontWeight.w800,
                                    shadows: [
                                      Shadow(
                                        color: AppColors.primaryContainer
                                            .withValues(alpha: 0.4),
                                        blurRadius: 10,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: isCompact ? 6 : 8),
                                Container(
                                  width: 40,
                                  height: 2,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        AppColors.primaryContainer,
                                        Colors.transparent,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primaryContainer
                                            .withValues(alpha: 0.45),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: gapLg),
                          Text(
                            'Welcome to ICTU',
                            style: (isCompact
                                    ? AppTextStyles.h2
                                    : AppTextStyles.h1)
                                .copyWith(fontSize: isCompact ? 26 : null),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isCompact ? 6 : 8),
                          Text(
                            'Your gateway to academic excellence',
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          SizedBox(height: gapMd),
                          AnimatedCrossFade(
                            firstChild: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: const [
                                _FeatureTile(
                                  icon: Icons.menu_book_rounded,
                                  title: 'Access courses anywhere',
                                  subtitle:
                                      'View lectures, assignments, and materials on the go.',
                                ),
                                SizedBox(height: 12),
                                _FeatureTile(
                                  icon: Icons.campaign_rounded,
                                  title: 'Stay updated',
                                  subtitle:
                                      'Get alerts for deadlines and campus updates.',
                                ),
                                SizedBox(height: 12),
                                _FeatureTile(
                                  icon: Icons.groups_rounded,
                                  title: 'Connect with the community',
                                  subtitle:
                                      'Chat with peers and collaborate with faculty.',
                                ),
                              ],
                            ),
                            secondChild: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: const [
                                _FeatureTile(
                                  icon: Icons.dashboard_rounded,
                                  title: 'Manage your courses',
                                  subtitle:
                                      'Organize lectures, notes, and track student progress.',
                                ),
                                SizedBox(height: 12),
                                _FeatureTile(
                                  icon: Icons.analytics_rounded,
                                  title: 'Performance insights',
                                  subtitle:
                                      'Monitor student engagement and course effectiveness.',
                                ),
                                SizedBox(height: 12),
                                _FeatureTile(
                                  icon: Icons.forum_rounded,
                                  title: 'Direct communication',
                                  subtitle:
                                      'Interact directly with students and share announcements.',
                                ),
                              ],
                            ),
                            crossFadeState: _selectedRoleIndex == 0
                                ? CrossFadeState.showFirst
                                : CrossFadeState.showSecond,
                            duration: const Duration(milliseconds: 250),
                          ),
                          SizedBox(height: gapMd),
                          PrimaryButton(
                            label: 'Get started',
                            height: isCompact ? 50 : 52,
                            onTap: () {
                              final UserRole role = _selectedRoleIndex == 0
                                  ? UserRole.student
                                  : UserRole.lecturer;
                              context.pushNamed(
                                AppRoutes.login,
                                pathParameters: <String, String>{'role': role.dbValue},
                              );
                            },
                          ),
                          SizedBox(height: isCompact ? 4 : 8),
                          TextButton(
                            onPressed: () {
                              final UserRole role = _selectedRoleIndex == 0
                                  ? UserRole.student
                                  : UserRole.lecturer;
                              context.pushNamed(
                                AppRoutes.signup,
                                pathParameters: <String, String>{'role': role.dbValue},
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
                ),
              );
            },
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Icon(icon, color: AppColors.primaryContainer, size: 20),
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
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
