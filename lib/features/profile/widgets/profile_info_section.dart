import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../services/profile_service.dart';

class ProfileInfoSection extends StatelessWidget {
  final Map<String, dynamic> profile;

  const ProfileInfoSection({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final profileService = context.read<ProfileService>();

    // Get interests directly from profile data
    final interests = (profile['interests'] as List?)?.cast<String>() ?? <String>[];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '프로필 정보',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Bio
          if (profile['bio'] != null && profile['bio'].toString().isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.description_outlined,
              label: '자기소개',
              value: profile['bio'],
              isMultiline: true,
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Occupation
          if (profile['occupation'] != null && profile['occupation'].toString().isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.work_outline,
              label: '직업',
              value: profile['occupation'],
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // School
          if (profile['school'] != null && profile['school'].toString().isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.school_outlined,
              label: '학교',
              value: profile['school'],
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Gender
          if (profile['gender'] != null) ...[
            _buildInfoRow(
              icon: Icons.person_outline,
              label: '성별',
              value: profile['gender'] == 'male' ? '남성' : '여성',
              isMultiline: true,
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Height
          if (profile['height'] != null) ...[
            _buildInfoRow(
              icon: Icons.height_outlined,
              label: '키',
              value: '${profile['height']}cm',
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Religion
          if (profile['religion'] != null && profile['religion'].toString().isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.church_outlined,
              label: '종교',
              value: profile['religion'],
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Smoking
          if (profile['smoking'] != null) ...[
            _buildInfoRow(
              icon: Icons.smoke_free_outlined,
              label: '흡연',
              value: _getSmokingText(profile['smoking']),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Drinking
          if (profile['drinking'] != null) ...[
            _buildInfoRow(
              icon: Icons.local_bar_outlined,
              label: '음주',
              value: _getDrinkingText(profile['drinking']),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Interests
          if (interests.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '관심사',
              style: AppTextStyles.body1.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: interests.map((interest) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    interest,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // If no additional info
          if (_hasNoAdditionalInfo()) ...[
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.textSecondary,
                    size: 32,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '추가 정보를 입력해보세요',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    bool isMultiline = false,
  }) {
    if (isMultiline) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(left: 28), // Icon width + spacing
            child: Text(
              value,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.textSecondary,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: AppTextStyles.body2.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getSmokingText(String smoking) {
    switch (smoking) {
      case 'never':
        return '비흡연';
      case 'sometimes':
        return '가끔';
      case 'regularly':
        return '흡연';
      default:
        return smoking;
    }
  }

  String _getDrinkingText(String drinking) {
    switch (drinking) {
      case 'never':
        return '금주';
      case 'sometimes':
        return '가끔';
      case 'regularly':
        return '자주';
      default:
        return drinking;
    }
  }

  bool _hasNoAdditionalInfo() {
    return (profile['bio'] == null || profile['bio'].toString().isEmpty) &&
           (profile['occupation'] == null || profile['occupation'].toString().isEmpty) &&
           (profile['school'] == null || profile['school'].toString().isEmpty) &&
           (profile['religion'] == null || profile['religion'].toString().isEmpty) &&
           profile['smoking'] == null &&
           profile['drinking'] == null &&
           (profile['interests'] == null || (profile['interests'] as List).isEmpty);
  }
}