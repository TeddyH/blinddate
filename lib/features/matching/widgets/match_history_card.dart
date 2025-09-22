import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../services/scheduled_matching_service.dart';

class MatchHistoryCard extends StatelessWidget {
  final ScheduledMatch match;

  const MatchHistoryCard({
    super.key,
    required this.match,
  });

  @override
  Widget build(BuildContext context) {
    final scheduledMatchingService = context.read<ScheduledMatchingService>();
    final otherUser = match.otherUserProfile;
    final images = scheduledMatchingService.getUserImages(otherUser);
    final age = scheduledMatchingService.calculateAge(otherUser['birth_date'] ?? '');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Profile image
            _buildProfileImage(images),
            const SizedBox(width: AppSpacing.md),

            // Profile info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        otherUser['nickname'] ?? '익명',
                        style: AppTextStyles.body1.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '$age세',
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Bio preview
                  if (otherUser['bio'] != null && otherUser['bio'].toString().isNotEmpty)
                    Text(
                      otherUser['bio'],
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                  const SizedBox(height: AppSpacing.sm),

                  // Interests preview
                  if (otherUser['interests'] != null)
                    _buildInterestsPreview(otherUser['interests']),
                ],
              ),
            ),

            // Match status
            _buildMatchStatus(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage(List<String> images) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppColors.surfaceVariant,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: images.isNotEmpty
            ? Image.network(
                images.first,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildDefaultAvatar();
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildDefaultAvatar();
                },
              )
            : _buildDefaultAvatar(),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.person,
        size: 32,
        color: AppColors.textSecondary,
      ),
    );
  }

  Widget _buildInterestsPreview(dynamic interests) {
    if (interests is! List) return const SizedBox.shrink();

    final interestList = List<String>.from(interests);
    if (interestList.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: 4,
      children: interestList.take(3).map((interest) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            interest,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontSize: 10,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMatchStatus() {
    return Column(
      children: [
        _buildStatusIcon(),
        const SizedBox(height: 4),
        Text(
          _getStatusText(),
          style: AppTextStyles.caption.copyWith(
            color: _getStatusColor(),
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatusIcon() {
    switch (match.status) {
      case 'mutual_like':
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.favorite,
            size: 16,
            color: AppColors.accent,
          ),
        );
      case 'liked':
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.favorite_border,
            size: 16,
            color: AppColors.primary,
          ),
        );
      case 'passed':
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.close,
            size: 16,
            color: AppColors.textSecondary,
          ),
        );
      default:
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.schedule,
            size: 16,
            color: AppColors.textSecondary,
          ),
        );
    }
  }

  String _getStatusText() {
    switch (match.status) {
      case 'mutual_like':
        return '서로\n좋아요';
      case 'liked':
        return '좋아요\n보냄';
      case 'passed':
        return '넘김';
      default:
        return '확인\n안함';
    }
  }

  Color _getStatusColor() {
    switch (match.status) {
      case 'mutual_like':
        return AppColors.accent;
      case 'liked':
        return AppColors.primary;
      case 'passed':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }
}