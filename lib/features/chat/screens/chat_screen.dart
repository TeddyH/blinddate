import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../services/chat_service.dart';
import '../../matching/services/scheduled_matching_service.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoomId;

  const ChatScreen({
    super.key,
    required this.chatRoomId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ChatService _chatService;
  ChatRoom? _chatRoom;
  Map<String, dynamic>? _otherUserProfile;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService();
    _loadChatData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChatData() async {
    try {
      // Load messages
      await _chatService.getMessages(widget.chatRoomId);

      // Get chat room details to find other user
      final response = await _chatService.getChatRoomWithMatchDetails(widget.chatRoomId);

      _chatRoom = ChatRoom.fromJson(response);

      // Get other user profile
      final currentUserId = _chatService.userId;
      final matchData = response['match_data'];

      if (matchData != null) {
        // ScheduledMatchingService를 사용해서 상대방 프로필 가져오기
        final matchingService = context.read<ScheduledMatchingService>();
        final scheduledMatch = ScheduledMatch(
          id: matchData['id'],
          user1Id: matchData['user1_id'],
          user2Id: matchData['user2_id'],
          matchDate: DateTime.parse(matchData['match_date']),
          expiresAt: DateTime.parse(matchData['expires_at']),
          status: matchData['status'],
          user1Profile: matchData['user1_profile'] ?? {},
          user2Profile: matchData['user2_profile'] ?? {},
        );

        _otherUserProfile = scheduledMatch.otherUserProfile;
      }

      setState(() {});
      _scrollToBottom();

    } catch (e) {
      debugPrint('Error loading chat data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('채팅을 불러오는 중 오류가 발생했습니다: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();

    final sentMessage = await _chatService.sendMessage(widget.chatRoomId, message);
    if (sentMessage != null) {
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final otherUserName = _otherUserProfile?['nickname'] ?? '채팅 상대';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          otherUserName,
          style: AppTextStyles.h3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.1),
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Consumer<ChatService>(
              builder: (context, chatService, child) {
                if (chatService.isLoading && chatService.messages.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  );
                }

                if (chatService.messages.isEmpty) {
                  return _buildEmptyState();
                }

                return _buildMessagesList(chatService.messages);
              },
            ),
          ),

          // Message input
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
              '첫 메시지를 보내보세요! 💕',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '서로 좋아요를 누른 특별한 인연이에요.\n자연스럽게 대화를 시작해보세요!',
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

  Widget _buildMessagesList(List<ChatMessage> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == _chatService.userId;
        final showTime = index == 0 ||
          messages[index - 1].createdAt.difference(message.createdAt).inMinutes.abs() > 5;

        return _buildMessageBubble(message, isMe, showTime);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe, bool showTime) {
    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (showTime) ...[
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                _formatTime(message.createdAt),
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
        Container(
          margin: EdgeInsets.only(
            left: isMe ? 50 : 0,
            right: isMe ? 0 : 50,
            bottom: AppSpacing.xs,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isMe ? AppColors.accent : Colors.white,
            borderRadius: BorderRadius.circular(16).copyWith(
              bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
              bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Text(
            message.message,
            style: AppTextStyles.body1.copyWith(
              color: isMe ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: '메시지를 입력하세요...',
                  hintStyle: AppTextStyles.body1.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: AppColors.accent,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              decoration: BoxDecoration(
                color: AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _sendMessage,
                icon: const Icon(
                  Icons.send,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inDays > 0) {
      return '${dateTime.month}월 ${dateTime.day}일 ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}