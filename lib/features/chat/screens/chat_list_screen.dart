import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../matching/services/scheduled_matching_service.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMutualMatches();
    });
  }

  Future<void> _loadMutualMatches() async {
    final service = context.read<ScheduledMatchingService>();
    await service.getTodaysMatches();
    await service.getPastMatches();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '💬 채팅',
          style: AppTextStyles.h1.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Consumer<ScheduledMatchingService>(
        builder: (context, service, child) {
          if (service.isLoading) {
            return _buildLoadingState();
          }

          // 모든 매치에서 mutual_like 상태인 것들만 필터링
          final allMatches = [...service.todaysMatches, ...service.pastMatches];
          final mutualMatches = allMatches
              .where((match) => match.status == 'mutual_like')
              .toList();

          if (mutualMatches.isEmpty) {
            return _buildEmptyState();
          }

          return _buildChatList(mutualMatches);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            '채팅 목록을 불러오고 있어요...',
            style: AppTextStyles.body1.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              '아직 채팅할 상대가 없어요',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '추천받은 상대와 서로 좋아요를 누르면\n채팅을 시작할 수 있어요!',
              style: AppTextStyles.body1.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(List<ScheduledMatch> mutualMatches) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: mutualMatches.length,
      itemBuilder: (context, index) {
        final match = mutualMatches[index];
        final otherUser = match.otherUserProfile;
        final service = context.read<ScheduledMatchingService>();
        final userImages = service.getUserImages(otherUser);

        return Container(
          margin: EdgeInsets.only(
            bottom: index < mutualMatches.length - 1 ? AppSpacing.md : 0,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(AppSpacing.md),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.1),
              ),
              child: userImages.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        userImages.first,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            color: AppColors.primary,
                            size: 25,
                          );
                        },
                      ),
                    )
                  : Icon(
                      Icons.person,
                      color: AppColors.primary,
                      size: 25,
                    ),
            ),
            title: Text(
              otherUser['nickname'] ?? '매칭 상대',
              style: AppTextStyles.body1.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              '매칭 성공! 대화를 시작해보세요 💕',
              style: AppTextStyles.body2.copyWith(
                color: AppColors.accent,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 16,
            ),
            onTap: () {
              // TODO: Navigate to chat screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('채팅 기능이 곧 추가될 예정입니다! 🚀'),
                  backgroundColor: AppColors.primary,
                ),
              );
            },
          ),
        );
      },
    );
  }
}