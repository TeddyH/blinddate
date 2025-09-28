import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/unread_message_service.dart';
import '../../../app/routes.dart';
import '../../matching/services/scheduled_matching_service.dart';
import '../services/chat_service.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  Map<String, Map<String, dynamic>> _chatRoomProfiles = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMutualMatches();
      _loadUnreadCount();
      _loadChatRooms();
    });
  }

  Future<void> _loadMutualMatches() async {
    final service = context.read<ScheduledMatchingService>();
    await service.getTodaysMatches();
    await service.getPastMatches();
  }

  Future<void> _loadUnreadCount() async {
    final unreadService = context.read<UnreadMessageService>();
    await unreadService.fetchUnreadCount();
  }

  Future<void> _loadChatRooms() async {
    final chatService = context.read<ChatService>();
    await chatService.getChatRooms();
    await _loadChatRoomProfiles();
  }

  Future<void> _loadChatRoomProfiles() async {
    final chatService = context.read<ChatService>();

    for (final chatRoom in chatService.chatRooms) {
      try {
        if (chatRoom.matchId != null) {
          final matchDetails = await chatService.getChatRoomWithMatchDetails(chatRoom.id);
          final matchData = matchDetails['match_data'];

          if (matchData != null) {
            final currentUserId = chatService.userId;
            final otherUserId = chatRoom.getOtherUserId(currentUserId);

            Map<String, dynamic> otherUserProfile;
            if (otherUserId == matchData['user1_id']) {
              otherUserProfile = matchData['user1_profile'] ?? {};
            } else {
              otherUserProfile = matchData['user2_profile'] ?? {};
            }

            _chatRoomProfiles[chatRoom.id] = otherUserProfile;
          }
        }
      } catch (e) {
        debugPrint('프로필 로딩 오류: $e');
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '💕 Hearty',
              style: AppTextStyles.h1.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                '채팅',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.accent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              AppColors.accent.withValues(alpha: 0.03),
              AppColors.accent.withValues(alpha: 0.08),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Consumer2<ChatService, UnreadMessageService>(
            builder: (context, chatService, unreadService, child) {
          if (chatService.isLoading) {
            return _buildLoadingState();
          }

          final chatRooms = chatService.chatRooms;

          if (chatRooms.isEmpty) {
            return _buildEmptyState();
          }

          return _buildChatRoomList(chatRooms, unreadService);
            },
          ),
        ),
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
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.pink,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              '아직 채팅할 상대가 없어요',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
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

  Widget _buildChatRoomList(List<ChatRoom> chatRooms, UnreadMessageService unreadService) {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadChatRooms();
        await _loadUnreadCount();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: chatRooms.length,
        itemBuilder: (context, index) {
        final chatRoom = chatRooms[index];
        final unreadCount = unreadService.getUnreadCountForRoom(chatRoom.id);
        final otherUserProfile = _chatRoomProfiles[chatRoom.id] ?? {};
        final otherUserName = otherUserProfile['nickname'] ?? '채팅 상대';
        final matchingService = context.read<ScheduledMatchingService>();
        final profileImages = matchingService.getUserImages(otherUserProfile);

        return Container(
          margin: EdgeInsets.only(
            bottom: index < chatRooms.length - 1 ? AppSpacing.md : 0,
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
              child: profileImages.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        profileImages.first,
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
              otherUserName,
              style: AppTextStyles.body1.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              chatRoom.lastMessage ?? '대화를 시작해보세요!',
              style: AppTextStyles.body2.copyWith(
                color: unreadCount > 0 ? AppColors.textPrimary : AppColors.textSecondary,
                fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
              ],
            ),
            onTap: () {
              context.push('${AppRoutes.chat}/${chatRoom.id}');
            },
          ),
        );
      },
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
            onTap: () async {
              try {
                final chatService = ChatService();
                final chatRoom = await chatService.getChatRoomByMatchId(match.id);

                if (chatRoom != null) {
                  context.push('${AppRoutes.chat}/${chatRoom.id}');
                } else {
                  // 채팅방이 없으면 생성
                  final newChatRoom = await chatService.createOrGetChatRoom(
                    match.id,
                    match.user1Id,
                    match.user2Id
                  );

                  if (newChatRoom != null) {
                    context.push('${AppRoutes.chat}/${newChatRoom.id}');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('채팅방을 생성하는 중 오류가 발생했습니다.'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('채팅을 시작하는 중 오류가 발생했습니다: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
          ),
        );
      },
    );
  }
}