import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
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
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isMutualLike ? AppColors.accent : AppColors.accent.withValues(alpha: 0.2),
          width: isMutualLike ? 2 : 1,
        ),
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

                // Interests
                if (otherUser['interests'] != null)
                  _buildInterests(otherUser['interests']),

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
    final age = user['age']?.toString() ?? '';
    final city = user['city'] ?? '';
    final job = user['job'] ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              nickname,
              style: AppTextStyles.h2.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (age.isNotEmpty) ...[
              const SizedBox(width: AppSpacing.sm),
              Text(
                age,
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),

        if (city.isNotEmpty || job.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              if (city.isNotEmpty) ...[
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  city,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (city.isNotEmpty && job.isNotEmpty) ...[
                const SizedBox(width: AppSpacing.md),
                Text(
                  '•',
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
              ],
              if (job.isNotEmpty) ...[
                Icon(
                  Icons.work_outline,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  job,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildBio(String bio) {
    return Text(
      bio,
      style: AppTextStyles.body2.copyWith(
        color: AppColors.textPrimary,
        height: 1.4,
      ),
    );
  }

  Widget _buildInterests(List<dynamic> interests) {
    if (interests.isEmpty) return const SizedBox.shrink();

    return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: interests.take(6).map((interest) {
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                interest.toString(),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            onTap: widget.onLike,
            label: '매칭하기',
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
            // TODO: Navigate to chat screen
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