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

    // Get data from profile
    final interests = (profile['interests'] as List?)?.cast<String>() ?? <String>[];
    final personalityTraits = (profile['personality_traits'] as List?)?.cast<String>() ?? <String>[];
    final othersSayAboutMe = (profile['others_say_about_me'] as List?)?.cast<String>() ?? <String>[];
    final idealTypeTraits = (profile['ideal_type_traits'] as List?)?.cast<String>() ?? <String>[];
    final dateStyle = (profile['date_style'] as List?)?.cast<String>() ?? <String>[];

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

          // Gender
          if (profile['gender'] != null) ...[
            _buildInfoRow(
              icon: Icons.person_outline,
              label: '성별',
              value: profile['gender'] == 'male' ? '남성' : '여성',
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Drinking
          if (profile['drinking_style'] != null) ...[
            _buildInfoRow(
              icon: Icons.local_bar_outlined,
              label: '음주',
              value: _getDrinkingText(profile['drinking_style']),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Smoking
          if (profile['smoking_status'] != null) ...[
            _buildInfoRow(
              icon: Icons.smoke_free_outlined,
              label: '흡연',
              value: _getSmokingText(profile['smoking_status']),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Personality traits
          if (personalityTraits.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildTagSection('💫 성격/매력', personalityTraits),
            const SizedBox(height: AppSpacing.md),
          ],

          // Others say about me
          if (othersSayAboutMe.isNotEmpty) ...[
            _buildTagSection('👂 주변평가', othersSayAboutMe),
            const SizedBox(height: AppSpacing.md),
          ],

          // Ideal type
          if (idealTypeTraits.isNotEmpty) ...[
            _buildTagSection('❤️ 이상형', idealTypeTraits),
            const SizedBox(height: AppSpacing.md),
          ],

          // Date style
          if (dateStyle.isNotEmpty) ...[
            _buildTagSection('🎯 데이트 스타일', dateStyle),
            const SizedBox(height: AppSpacing.md),
          ],

          // Interests
          if (interests.isNotEmpty) ...[
            _buildTagSection('🎨 관심사', interests),
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
                height: 1.4,
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

  Widget _buildTagSection(String title, List<String> tags) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.body1.copyWith(
            color: Colors.white.withOpacity(0.95),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: 4,
          children: tags.map((tag) {
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
                tag,
                style: AppTextStyles.caption.copyWith(
                  color: Color(0xFFf093fb),
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  int _calculateAge(String birthDateStr) {
    try {
      final birthDate = DateTime.parse(birthDateStr);
      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }

  String _getSmokingText(String smoking) {
    switch (smoking) {
      case 'non_smoker':
        return '비흡연';
      case 'smoker':
        return '흡연';
      default:
        return smoking;
    }
  }

  String _getDrinkingText(String drinking) {
    switch (drinking) {
      case 'none':
        return '전혀 안 마셔요';
      case 'sometimes':
        return '가끔 마셔요';
      case 'often':
        return '자주 마셔요';
      case 'social':
        return '분위기에 따라요';
      default:
        return drinking;
    }
  }

  bool _hasNoAdditionalInfo() {
    return (profile['bio'] == null || profile['bio'].toString().isEmpty) &&
           (profile['job_category'] == null || profile['job_category'].toString().isEmpty) &&
           profile['drinking_style'] == null &&
           profile['smoking_status'] == null &&
           (profile['personality_traits'] == null || (profile['personality_traits'] as List).isEmpty) &&
           (profile['others_say_about_me'] == null || (profile['others_say_about_me'] as List).isEmpty) &&
           (profile['ideal_type_traits'] == null || (profile['ideal_type_traits'] as List).isEmpty) &&
           (profile['date_style'] == null || (profile['date_style'] as List).isEmpty) &&
           (profile['interests'] == null || (profile['interests'] as List).isEmpty);
  }
}
