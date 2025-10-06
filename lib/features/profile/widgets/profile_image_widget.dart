import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../services/profile_service.dart';

class ProfileImageWidget extends StatelessWidget {
  final Map<String, dynamic> profile;

  const ProfileImageWidget({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final profileService = context.read<ProfileService>();

    // Get profile images directly from profile data
    final imageUrls = (profile['profile_image_urls'] as List?)?.cast<String>() ?? <String>[];
    final mainImageUrl = imageUrls.isNotEmpty ? imageUrls.first : null;

    return Container(
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
        children: [
          // Profile images grid
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1,
              ),
              itemCount: 3,
              itemBuilder: (context, index) {
                if (index < imageUrls.length) {
                  // 이미지가 있는 경우
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrls[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.white.withOpacity(0.6),
                            size: 24,
                          ),
                        );
                      },
                    ),
                  );
                } else {
                  // 이미지가 없는 경우
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_outlined,
                          color: Colors.white.withOpacity(0.6),
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '사진 없음',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white.withOpacity(0.6),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),

          // Profile info overlay
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                // Name
                Text(
                  profile['nickname'] ?? '사용자',
                  style: AppTextStyles.h2.copyWith(
                    color: Colors.white.withOpacity(0.95),
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // Additional info (age, job_category, location, mbti)
                if (profile['birth_date'] != null || profile['job_category'] != null || profile['location'] != null || profile['mbti'] != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (profile['birth_date'] != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.cake,
                              size: 14,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${profileService.calculateAge(profile['birth_date'])}세',
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      if (profile['job_category'] != null && profile['job_category'].toString().isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.work_outline,
                              size: 14,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              profile['job_category'],
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      if (profile['location'] != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              profile['location'],
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      if (profile['mbti'] != null)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.psychology,
                              size: 14,
                              color: Colors.white.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              profile['mbti'],
                              style: AppTextStyles.caption.copyWith(
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person,
            size: 48,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '프로필 사진 없음',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}