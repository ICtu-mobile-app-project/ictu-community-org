import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:ictu_community_org/core/utils/string_utils.dart';
import 'package:ictu_community_org/features/profile/controllers/profile_controller.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppTopBar extends StatefulWidget implements PreferredSizeWidget {
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
  State<AppTopBar> createState() => _AppTopBarState();
}

class _AppTopBarState extends State<AppTopBar> {
  final ProfileController _profileController = ProfileController();

  @override
  void initState() {
    super.initState();
    _profileController.loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: widget.preferredSize.height,
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
              if (widget.showBack)
                const SizedBox(width: 48, height: 48)
              else
                IconButton(
                  onPressed: widget.onMenuTap,
                  icon: const Icon(Icons.menu, color: Colors.white54),
                ),
              Expanded(
                child: Text(
                  (widget.title ?? 'ICTU COMMUNITY').toUpperCase(),
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
                onTap: widget.onAvatarTap,
                child: AnimatedBuilder(
                  animation: _profileController,
                  builder: (context, _) {
                    final profile = _profileController.profileData;
                    final initials = initialsFromName(profile?['full_name']);
                    
                    return CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF1E293B),
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Color(0xFFF58220),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

