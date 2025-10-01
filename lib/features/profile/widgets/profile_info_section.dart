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
        color: Color(0xFF252836),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '프로필 정보',
            style: AppTextStyles.h3.copyWith(
              color: Colors.white.withOpacity(0.95),
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
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // MBTI
          if (profile['mbti'] != null && profile['mbti'].toString().isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.psychology_outlined,
              label: 'MBTI',
              value: profile['mbti'],
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Location
          if (profile['location'] != null && profile['location'].toString().isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.location_on_outlined,
              label: '거주지역',
              value: profile['location'],
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
                color: Colors.white.withOpacity(0.95),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: 4,
              children: interests.map((interest) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Color(0xFFf093fb).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    interest,
                    style: AppTextStyles.caption.copyWith(
                      color: Color(0xFFf093fb),
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
                    color: Colors.white.withOpacity(0.6),
                    size: 32,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '추가 정보를 입력해보세요',
                    style: AppTextStyles.body2.copyWith(
                      color: Colors.white.withOpacity(0.7),
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
                color: Colors.white.withOpacity(0.7),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: AppTextStyles.body2.copyWith(
                  color: Colors.white.withOpacity(0.7),
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
                color: Colors.white.withOpacity(0.9),
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
          color: Colors.white.withOpacity(0.7),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          label,
          style: AppTextStyles.body2.copyWith(
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.body2.copyWith(
              color: Colors.white.withOpacity(0.9),
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