import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_text_styles.dart';

class ActionButtons extends StatelessWidget {
  final VoidCallback onPass;
  final VoidCallback onLike;

  const ActionButtons({
    super.key,
    required this.onPass,
    required this.onLike,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Like button (왼쪽)
        Expanded(
          child: _buildActionButton(
            onTap: onLike,
            label: 'LIKE',
            icon: Icons.favorite_outline,
            color: Colors.white,
            backgroundColor: AppColors.accent,
            borderColor: AppColors.accent,
          ),
        ),

        const SizedBox(width: AppSpacing.lg),

        // Pass button (오른쪽)
        Expanded(
          child: _buildActionButton(
            onTap: onPass,
            label: 'PASS',
            icon: Icons.thumb_down_alt_outlined,
            color: AppColors.textSecondary,
            backgroundColor: Colors.white,
            borderColor: AppColors.surfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    required String label,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: borderColor,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: borderColor.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: AppTextStyles.body1.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}