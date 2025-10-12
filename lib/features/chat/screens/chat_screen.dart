import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/unread_message_service.dart';
import '../../../l10n/app_localizations.dart';
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
  ChatRoom? _chatRoom;
  Map<String, dynamic>? _otherUserProfile;
  int _previousMessageCount = 0;
  ChatService? _chatService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadChatData();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // 채팅방 나가기 및 실시간 구독 해제
    _chatService?.exitChatRoom();
    _chatService?.unsubscribeFromMessages();
    super.dispose();
  }

  Future<void> _loadChatData() async {
    try {
      final chatService = context.read<ChatService>();
      final unreadService = context.read<UnreadMessageService>();
      _chatService = chatService;

      // 채팅방 진입
      chatService.enterChatRoom(widget.chatRoomId);

      // Load messages
      await chatService.getMessages(widget.chatRoomId);

      // Mark this chat room as read
      await unreadService.markChatAsRead(widget.chatRoomId);

      // Get chat room details to find other user
      final response = await chatService.getChatRoomWithMatchDetails(widget.chatRoomId);

      _chatRoom = ChatRoom.fromJson(response);

      // Get other user profile
      final matchData = response['match_data'];

      if (matchData != null) {
        // ScheduledMatch 객체 생성하여 상대방 프로필 가져오기
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

      // 채팅방 진입 및 실시간 메시지 구독 시작
      debugPrint('=== Starting realtime subscription ===');
      debugPrint('Chat room ID: ${widget.chatRoomId}');
      debugPrint('Current user ID: ${_chatService?.userId}');

      // 현재 채팅방 설정 (알림 중복 방지용)
      _chatService?.enterChatRoom(widget.chatRoomId);

      // 실시간 구독 시작
      await _chatService?.subscribeToMessages(widget.chatRoomId);

      // 메시지 읽음 처리
      await _chatService?.markMessagesAsRead(widget.chatRoomId);

      debugPrint('=== Subscription setup completed ===');

    } catch (e) {
      debugPrint('Error loading chat data: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorChatLoad(e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
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

    final chatService = context.read<ChatService>();
    final sentMessage = await chatService.sendMessage(widget.chatRoomId, message);
    if (sentMessage != null) {
      _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final otherUserName = _otherUserProfile?['nickname'] ?? l10n.chatPartner;

    return Scaffold(
      backgroundColor: Color.fromRGBO(6, 13, 24, 1),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
          otherUserName,
          style: AppTextStyles.h3.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: Consumer<ChatService>(
              builder: (context, chatService, child) {
                // 새 메시지가 추가되었을 때 자동 스크롤
                if (chatService.messages.length > _previousMessageCount) {
                  _previousMessageCount = chatService.messages.length;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });
                }

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
    final l10n = AppLocalizations.of(context)!;

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
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline,
                size: 40,
                color: Color(0xFFf093fb),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.sendFirstMessage,
              style: AppTextStyles.h3.copyWith(
                color: Colors.white.withOpacity(0.95),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.sendFirstMessageDesc,
              style: AppTextStyles.body1.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessagesList(List<ChatMessage> messages) {
    return Consumer<ChatService>(
      builder: (context, chatService, child) {
        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            final isMe = message.senderId == chatService.userId;

            // 시간 표시 조건 (5분 이상 차이)
            final showTime = index == 0 ||
              messages[index - 1].createdAt.difference(message.createdAt).inMinutes.abs() > 5;

            // 날짜 변경 확인
            final showDateSeparator = index == 0 || _isDifferentDay(
              messages[index - 1].createdAt,
              message.createdAt
            );

            return Column(
              children: [
                if (showDateSeparator) _buildDateSeparator(message.createdAt),
                ..._buildMessageBubbleWithTime(message, isMe, showTime),
              ],
            );
          },
        );
      },
    );
  }

  List<Widget> _buildMessageBubbleWithTime(ChatMessage message, bool isMe, bool showTime) {
    return [
      if (showTime)
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Text(
              _formatTime(message.createdAt),
              style: AppTextStyles.caption.copyWith(
                color: Colors.white.withOpacity(0.6),
              ),
            ),
          ),
        ),
      Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
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
            color: isMe ? AppColors.accent : Color(0xFF252836),
            borderRadius: BorderRadius.circular(16).copyWith(
              bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
              bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            message.message,
            style: AppTextStyles.body1.copyWith(
              color: Colors.white,
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Color.fromRGBO(6, 13, 24, 1),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
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
                style: AppTextStyles.body1.copyWith(
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.enterMessage,
                  hintStyle: AppTextStyles.body1.copyWith(
                    color: Colors.white.withOpacity(0.5),
                  ),
                  filled: true,
                  fillColor: Color(0xFF252836),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
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

  // 두 날짜가 다른 날인지 확인 (한국 시간 기준)
  bool _isDifferentDay(DateTime date1, DateTime date2) {
    final korean1 = date1.toUtc().add(const Duration(hours: 9));
    final korean2 = date2.toUtc().add(const Duration(hours: 9));

    return korean1.year != korean2.year ||
           korean1.month != korean2.month ||
           korean1.day != korean2.day;
  }

  // 날짜 구분선 위젯
  Widget _buildDateSeparator(DateTime dateTime) {
    final l10n = AppLocalizations.of(context)!;
    final koreanTime = dateTime.toUtc().add(const Duration(hours: 9));
    final now = DateTime.now().toUtc().add(const Duration(hours: 9));

    final messageDate = DateTime(koreanTime.year, koreanTime.month, koreanTime.day);
    final todayDate = DateTime(now.year, now.month, now.day);
    final diffDays = todayDate.difference(messageDate).inDays;

    String dateText;
    if (diffDays == 0) {
      dateText = l10n.today;
    } else if (diffDays == 1) {
      dateText = l10n.yesterday;
    } else if (diffDays < 7) {
      final weekdays = [l10n.sun, l10n.mon, l10n.tue, l10n.wed, l10n.thu, l10n.fri, l10n.sat];
      final weekday = weekdays[koreanTime.weekday % 7];
      dateText = l10n.weekdayFormat(weekday);
    } else if (koreanTime.year == now.year) {
      dateText = l10n.monthDay(koreanTime.month, koreanTime.day);
    } else {
      dateText = l10n.yearMonthDay(koreanTime.year, koreanTime.month, koreanTime.day);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                dateText,
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white.withOpacity(0.6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: Colors.white.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final l10n = AppLocalizations.of(context)!;
    // UTC를 한국 시간(GMT+9)으로 변환
    final koreanTime = dateTime.toUtc().add(const Duration(hours: 9));
    final now = DateTime.now().toUtc().add(const Duration(hours: 9));

    // 날짜 차이 계산
    final messageDate = DateTime(koreanTime.year, koreanTime.month, koreanTime.day);
    final todayDate = DateTime(now.year, now.month, now.day);
    final diffDays = todayDate.difference(messageDate).inDays;

    final timeStr = '${koreanTime.hour}:${koreanTime.minute.toString().padLeft(2, '0')}';

    if (diffDays == 0) {
      // 오늘 - 시간만 표시
      return timeStr;
    } else if (diffDays == 1) {
      // 어제 - "어제 시간" 형태
      return l10n.yesterdayTime(timeStr);
    } else if (diffDays < 7) {
      // 일주일 이내 - "요일 시간" 형태
      final weekdays = [l10n.sun, l10n.mon, l10n.tue, l10n.wed, l10n.thu, l10n.fri, l10n.sat];
      final weekday = weekdays[koreanTime.weekday % 7];
      return l10n.weekdayTime(weekday, timeStr);
    } else if (koreanTime.year == now.year) {
      // 올해 - "월일 시간" 형태
      return l10n.monthDayTime(koreanTime.month, koreanTime.day, timeStr);
    } else {
      // 작년 이전 - "년월일 시간" 형태
      return l10n.yearMonthDayTime(koreanTime.year, koreanTime.month, koreanTime.day, timeStr);
    }
  }
}