import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  /// Optional override for tab items.
  final List<AppBottomNavItem>? items;

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final navItems =
        items ?? AppBottomNavDefaults.defaults; // fall back to standard set

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
        child: Container(
          height: 80 + bottomInset,
          padding: EdgeInsets.only(bottom: bottomInset),
          decoration: BoxDecoration(
            color: AppColors.topBarBg.withValues(alpha: 0.80),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.50),
                blurRadius: 40,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navItems.length, (i) {
              final active = i == currentIndex;
              final item = navItems[i];

              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        active ? item.filledIcon : item.icon,
                        color:
                            active ? AppColors.primaryContainer : Colors.white38,
                        shadows: active
                            ? [
                                Shadow(
                                  color: AppColors.primaryContainer
                                      .withValues(alpha: 0.70),
                                  blurRadius: 10,
                                ),
                              ]
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: AppTextStyles.labelSm.copyWith(
                          fontSize: 10,
                          color: active
                              ? AppColors.primaryContainer
                              : Colors.white38,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class AppBottomNavItem {
  const AppBottomNavItem({
    required this.icon,
    required this.filledIcon,
    required this.label,
  });

  final IconData icon;
  final IconData filledIcon;
  final String label;
}

class AppBottomNavDefaults {
  AppBottomNavDefaults._();

  static const defaults = <AppBottomNavItem>[
    AppBottomNavItem(
      icon: Icons.home_outlined,
      filledIcon: Icons.home,
      label: 'Home',
    ),
    AppBottomNavItem(
      icon: Icons.notifications_outlined,
      filledIcon: Icons.notifications,
      label: 'Alerts',
    ),
    AppBottomNavItem(
      icon: Icons.dynamic_feed_outlined,
      filledIcon: Icons.dynamic_feed,
      label: 'Feeds',
    ),
    AppBottomNavItem(
      icon: Icons.person_outline,
      filledIcon: Icons.person,
      label: 'Profile',
    ),
  ];
}

