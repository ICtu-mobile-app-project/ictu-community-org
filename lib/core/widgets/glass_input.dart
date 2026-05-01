import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class GlassInput extends StatelessWidget {
  const GlassInput({
    super.key,
    required this.label,
    required this.controller,
    this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.placeholder,
    this.suffix,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final IconData? icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? placeholder;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppTextStyles.labelSm),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: AppTextStyles.bodyMd,
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.35),
            ),
            prefixIcon: icon != null
                ? Icon(icon, color: AppColors.secondary.withValues(alpha: 0.9), size: 20)
                : null,
            suffixIcon: suffix,
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.25),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryContainer),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}


