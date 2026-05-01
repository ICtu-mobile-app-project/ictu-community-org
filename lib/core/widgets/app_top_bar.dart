import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    super.key,
    this.title,
    this.onBack,
    this.onMenuTap,
    this.onAvatarTap,
    this.showBack = false,
  });

  final String? title;
  final VoidCallback? onBack;
  final VoidCallback? onMenuTap;
  final VoidCallback? onAvatarTap;
  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: preferredSize.height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.topBarBg.withValues(alpha: 0.60),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showBack)
                IconButton(
                  onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white70),
                )
              else
                IconButton(
                  onPressed: onMenuTap,
                  icon: const Icon(Icons.menu, color: Colors.white54),
                ),
              Expanded(
                child: Text(
                  (title ?? 'ICTU COMMUNITY').toUpperCase(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h2.copyWith(
                    fontSize: 16,
                    letterSpacing: 3,
                    color: AppColors.primaryContainer,
                    shadows: [
                      Shadow(
                        color: AppColors.primaryContainer.withValues(alpha: 0.50),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: onAvatarTap,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.surfaceContainerHigh,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

