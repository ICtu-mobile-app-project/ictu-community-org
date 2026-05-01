import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ictu_community_org/core/theme/app_colors.dart';
import 'package:ictu_community_org/core/theme/app_text_styles.dart';

class GlassSegmentedTab extends StatelessWidget {
  const GlassSegmentedTab({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(100),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Stack(
            children: [
              // Animated Background Indicator
              LayoutBuilder(
                builder: (context, constraints) {
                  final double tabWidth = constraints.maxWidth / labels.length;
                  return AnimatedAlign(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    alignment: Alignment(
                      -1.0 + (selectedIndex * (2.0 / (labels.length - 1))),
                      0,
                    ),
                    child: Container(
                      width: tabWidth,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryContainer.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              // Tab Labels
              Row(
                children: List.generate(
                  labels.length,
                  (index) => Expanded(
                    child: GestureDetector(
                      onTap: () => onTabChanged(index),
                      behavior: HitTestBehavior.opaque,
                      child: Center(
                        child: Text(
                          labels[index].toUpperCase(),
                          style: AppTextStyles.labelSm.copyWith(
                            color: selectedIndex == index
                                ? Colors.white
                                : Colors.white60,
                            fontWeight: selectedIndex == index
                                ? FontWeight.w700
                                : FontWeight.w500,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
