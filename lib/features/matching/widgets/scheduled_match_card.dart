import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../app/routes.dart';
import '../services/scheduled_matching_service.dart';

class ScheduledMatchCard extends StatefulWidget {
  final ScheduledMatch match;
  final VoidCallback onLike;
  final VoidCallback onPass;

  const ScheduledMatchCard({
    super.key,
    required this.match,
    required this.onLike,
    required this.onPass,
  });

  @override
  State<ScheduledMatchCard> createState() => _ScheduledMatchCardState();
}

class _ScheduledMatchCardState extends State<ScheduledMatchCard> {
  late PageController _photoPageController;
  Timer? _photoTimer;
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _photoPageController = PageController();
    _startPhotoTimer();
  }

  @override
  void dispose() {
    _photoTimer?.cancel();
    _photoPageController.dispose();
    super.dispose();
  }

  void _startPhotoTimer() {
    // Get photo count
    final otherUser = widget.match.otherUserProfile;
    final photos = otherUser['profile_image_urls'] as List<dynamic>? ??
                   otherUser['photos'] as List<dynamic>? ?? [];

    // Only start timer if there are multiple photos
    if (photos.length > 1) {
      _photoTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
        if (mounted && _photoPageController.hasClients) {
          _currentPhotoIndex = (_currentPhotoIndex + 1) % photos.length;
          _photoPageController.animateToPage(
            _currentPhotoIndex,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final otherUser = widget.match.otherUserProfile;
    final isMutualLike = widget.match.status == 'mutual_like';
    final receivedLike = widget.match.receivedLike;
    final sentLike = widget.match.sentLike;

    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF252836),
        borderRadius: BorderRadius.circular(20),
        border: isMutualLike ? Border.all(
          color: AppColors.accent,
          width: 2,
        ) : null,
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
          // Mutual match banner
          if (isMutualLike)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.accent, Colors.pink],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '서로 좋아해요! 💕',
                    style: AppTextStyles.body1.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // Received like banner
          if (!isMutualLike && receivedLike)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.withValues(alpha: 0.8), Colors.deepOrange.withValues(alpha: 0.9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: isMutualLike ? BorderRadius.zero : const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '이분이 당신에게 관심을 표현했어요! 💕',
                    style: AppTextStyles.body2.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Sent like banner
          if (!isMutualLike && !receivedLike && sentLike)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.withValues(alpha: 0.8), Colors.deepPurple.withValues(alpha: 0.9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_outline,
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '당신이 관심을 표현했어요! 💝',
                    style: AppTextStyles.body2.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Profile content
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile images
                _buildProfileImages(otherUser),

                const SizedBox(height: AppSpacing.lg),

                // Basic info
                _buildBasicInfo(otherUser),

                const SizedBox(height: AppSpacing.md),

                // Bio
                if (otherUser['bio'] != null && otherUser['bio'].isNotEmpty)
                  _buildBio(otherUser['bio']),

                const SizedBox(height: AppSpacing.md),

                // Personality traits
                if (otherUser['personality_traits'] != null && (otherUser['personality_traits'] as List).isNotEmpty)
                  _buildProfileSection('💫 성격/매력', otherUser['personality_traits']),

                // Others say about me
                if (otherUser['others_say_about_me'] != null && (otherUser['others_say_about_me'] as List).isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _buildProfileSection('👂 주변평가', otherUser['others_say_about_me']),
                ],

                // Ideal type
                if (otherUser['ideal_type_traits'] != null && (otherUser['ideal_type_traits'] as List).isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _buildProfileSection('❤️ 이상형', otherUser['ideal_type_traits']),
                ],

                // Date style
                if (otherUser['date_style'] != null && (otherUser['date_style'] as List).isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _buildProfileSection('🎯 데이트', otherUser['date_style']),
                ],

                // Lifestyle (drinking & smoking)
                if (otherUser['drinking_style'] != null || otherUser['smoking_status'] != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _buildLifestyleInfo(otherUser),
                ],

                // Interests
                if (otherUser['interests'] != null && (otherUser['interests'] as List).isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _buildProfileSection('🎨 관심사', otherUser['interests']),
                ],

                const SizedBox(height: AppSpacing.lg),

                // Action buttons (only show if not mutual like)
                if (!isMutualLike) sentLike ? _buildSentLikeStatus() : _buildActionButtons(),

                // Selection deadline countdown (only show if not mutual like)
                if (!isMutualLike) ...[
                  const SizedBox(height: AppSpacing.md),
                  _buildSelectionDeadline(),
                ],

                // Chat button (only show if mutual like)
                if (isMutualLike) _buildMutualMatchSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImages(Map<String, dynamic> user) {
    final photos = user['profile_image_urls'] as List<dynamic>? ?? user['photos'] as List<dynamic>? ?? [];

    if (photos.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person,
                size: 80,
                color: AppColors.textSecondary,
              ),
              const SizedBox(height: 16),
              Text(
                '곧 공개됩니다!',
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _photoPageController,
            onPageChanged: (index) {
              setState(() {
                _currentPhotoIndex = index;
              });
            },
            itemCount: photos.length,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: NetworkImage(photos[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
        // Photo indicators (only show if multiple photos)
        if (photos.length > 1)
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(photos.length, (index) {
                return Container(
                  margin: const EdgeInsets.only(left: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPhotoIndex == index
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.4),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildBasicInfo(Map<String, dynamic> user) {
    // Handle empty user data
    if (user.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '특별한 인연',
            style: AppTextStyles.h2.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '매칭 정보를 준비하고 있어요',
            style: AppTextStyles.body2.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
    }

    final nickname = user['nickname'] ?? '특별한 인연';

    // Calculate age from birth_date
    String age = '';
    if (user['birth_date'] != null) {
      try {
        final birthDate = DateTime.parse(user['birth_date']);
        final now = DateTime.now();
        int calculatedAge = now.year - birthDate.year;
        if (now.month < birthDate.month ||
            (now.month == birthDate.month && now.day < birthDate.day)) {
          calculatedAge--;
        }
        age = calculatedAge.toString();
      } catch (e) {
        debugPrint('Error parsing birth_date: $e');
      }
    }
    // Fallback to age field if exists
    if (age.isEmpty && user['age'] != null) {
      age = user['age'].toString();
    }

    final mbti = user['mbti'];
    final location = user['location'];
    final jobCategory = user['job_category'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Nickname only
        Text(
          nickname,
          style: AppTextStyles.h2.copyWith(
            color: Colors.white.withOpacity(0.95),
            fontWeight: FontWeight.bold,
          ),
        ),

        // Additional info (age, job, location, mbti)
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: [
            if (age.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cake,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${age}세',
                    style: AppTextStyles.body2.copyWith(
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            if (jobCategory != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.work_outline,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    jobCategory,
                    style: AppTextStyles.body2.copyWith(
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            if (location != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    location,
                    style: AppTextStyles.body2.copyWith(
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            if (mbti != null)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.psychology,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    mbti,
                    style: AppTextStyles.body2.copyWith(
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBio(String bio) {
    return Text(
      bio,
      style: AppTextStyles.body2.copyWith(
        color: Colors.white.withOpacity(0.9),
        height: 1.4,
      ),
    );
  }

  Widget _buildInterests(List<dynamic> interests) {
    if (interests.isEmpty) return const SizedBox.shrink();

    return Wrap(
          spacing: AppSpacing.xs,
          runSpacing: 4,
          children: interests.take(6).map((interest) {
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
                interest.toString(),
                style: AppTextStyles.caption.copyWith(
                  color: Color(0xFFf093fb),
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildProfileSection(String title, List<dynamic> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.body2.copyWith(
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: 4,
          children: items.map((item) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Color(0xFFf093fb).withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.toString(),
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

  Widget _buildLifestyleInfo(Map<String, dynamic> user) {
    final drinkingStyle = user['drinking_style'];
    final smokingStatus = user['smoking_status'];

    final drinkingLabels = {
      'none': '전혀 안 마셔요',
      'sometimes': '가끔 마셔요',
      'often': '자주 마셔요',
      'social': '분위기에 따라요',
    };

    final smokingLabels = {
      'non_smoker': '비흡연',
      'smoker': '흡연',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🍺 라이프스타일',
          style: AppTextStyles.body2.copyWith(
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: 4,
          children: [
            if (drinkingStyle != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Color(0xFFf093fb).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_bar,
                      size: 12,
                      color: Color(0xFFf093fb),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      drinkingLabels[drinkingStyle] ?? drinkingStyle,
                      style: AppTextStyles.caption.copyWith(
                        color: Color(0xFFf093fb),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            if (smokingStatus != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: Color(0xFFf093fb).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      smokingStatus == 'smoker' ? Icons.smoking_rooms : Icons.smoke_free,
                      size: 12,
                      color: Color(0xFFf093fb),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      smokingLabels[smokingStatus] ?? smokingStatus,
                      style: AppTextStyles.caption.copyWith(
                        color: Color(0xFFf093fb),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            onTap: widget.onLike,
            label: 'LIKE',
            icon: Icons.favorite_outline,
            backgroundColor: AppColors.accent,
            textColor: Colors.white,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildActionButton(
            onTap: widget.onPass,
            label: 'PASS',
            icon: Icons.thumb_down_alt_outlined,
            backgroundColor: AppColors.textSecondary,
            textColor: Colors.white,
            borderColor: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSentLikeStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite,
            color: Colors.purple,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '관심을 표현했어요',
            style: AppTextStyles.body1.copyWith(
              color: Colors.purple,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMutualMatchSection() {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            context.go(AppRoutes.chatList);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: AppTextStyles.body1.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          child: const Text('💬 채팅하기'),
        ),
      ),
    );
  }

  Widget _buildChatButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // TODO: Navigate to chat screen
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text('💬 대화 시작하기'),
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onTap,
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
    Color? borderColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: borderColor != null
              ? Border.all(color: borderColor)
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: textColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.body1.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionDeadline() {
    final now = DateTime.now();
    // If current time is before 12:00 PM today, deadline is today 12:00 PM
    final todayDeadline = DateTime(now.year, now.month, now.day, 12, 0, 0);
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 12, 0, 0);
    final actualDeadline = now.isBefore(todayDeadline) ? todayDeadline : tomorrow;
    final actualTimeLeft = actualDeadline.difference(now);

    if (actualTimeLeft.isNegative) return const SizedBox.shrink();

    final hours = actualTimeLeft.inHours;
    final minutes = actualTimeLeft.inMinutes.remainder(60);
    final seconds = actualTimeLeft.inSeconds.remainder(60);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.schedule,
            color: AppColors.accent,
            size: 16,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '선택 마감까지 ',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.bold,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}