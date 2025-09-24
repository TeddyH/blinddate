import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../services/scheduled_matching_service.dart';
import '../../profile/services/profile_service.dart';
import 'package:provider/provider.dart';

class MatchSuccessDialog extends StatefulWidget {
  final ScheduledMatch match;
  final VoidCallback onStartChat;

  const MatchSuccessDialog({
    super.key,
    required this.match,
    required this.onStartChat,
  });

  @override
  State<MatchSuccessDialog> createState() => _MatchSuccessDialogState();
}

class _MatchSuccessDialogState extends State<MatchSuccessDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _scaleController.forward();
    _fadeController.forward();

    // 내 프로필이 로드되지 않았다면 로드하기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profileService = Provider.of<ProfileService>(context, listen: false);
      if (profileService.currentUserProfile == null) {
        profileService.getCurrentUserProfile();
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final otherUser = widget.match.otherUserProfile;
    final matchingService = Provider.of<ScheduledMatchingService>(context, listen: false);

    // 상대방 프로필 이미지 (matchingService의 getUserImages 함수 사용)
    final otherUserImages = matchingService.getUserImages(otherUser);

    debugPrint('MatchSuccessDialog: otherUser keys: ${otherUser.keys}');
    debugPrint('MatchSuccessDialog: otherUserImages: $otherUserImages');

    return Consumer<ProfileService>(
      builder: (context, profileService, child) {
        final myProfile = profileService.currentUserProfile;
        final myImages = myProfile != null ? matchingService.getUserImages(myProfile) : <String>[];

        debugPrint('MatchSuccessDialog: myProfile loaded: ${myProfile != null}');
        debugPrint('MatchSuccessDialog: myImages: $myImages');

        return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 축하 메시지
                    Text(
                      '🎉 매칭 성공! 🎉',
                      style: AppTextStyles.h1.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // 프로필 이미지들과 하트
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 상대방 프로필 이미지
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accent.withValues(alpha: 0.2),
                            border: Border.all(
                              color: AppColors.accent,
                              width: 3,
                            ),
                          ),
                          child: otherUserImages.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    otherUserImages.first,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      debugPrint('Error loading other user image: $error');
                                      return Icon(
                                        Icons.person,
                                        color: AppColors.accent,
                                        size: 40,
                                      );
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                          color: AppColors.accent,
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  color: AppColors.accent,
                                  size: 40,
                                ),
                        ),

                        const SizedBox(width: AppSpacing.lg),

                        // 하트 아이콘
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accent,
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),

                        const SizedBox(width: AppSpacing.lg),

                        // 내 프로필 이미지
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withValues(alpha: 0.2),
                            border: Border.all(
                              color: AppColors.primary,
                              width: 3,
                            ),
                          ),
                          child: myImages.isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    myImages.first,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      debugPrint('Error loading my image: $error');
                                      return Icon(
                                        Icons.person,
                                        color: AppColors.primary,
                                        size: 40,
                                      );
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                          color: AppColors.primary,
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  color: AppColors.primary,
                                  size: 40,
                                ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // 축하 메시지
                    Text(
                      '서로 관심을 표현했어요!',
                      style: AppTextStyles.h3.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.sm),

                    Text(
                      '이제 ${otherUser['nickname'] ?? '상대방'}님과 대화를 시작해보세요',
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // 액션 버튼들
                    Row(
                      children: [
                        // 채팅 시작하기 버튼
                        Expanded(
                          child: ElevatedButton(
                            onPressed: widget.onStartChat,
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
                            child: const Text('💬 채팅 시작하기'),
                          ),
                        ),

                        const SizedBox(width: AppSpacing.md),

                        // 닫기 버튼
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: BorderSide(color: AppColors.textSecondary.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('닫기'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
        );
      },
    );
  }
}