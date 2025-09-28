import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/services/unread_message_service.dart';
import '../../../core/constants/table_names.dart';

class ChatRoom {
  final String id;
  final String? matchId;
  final String user1Id;
  final String user2Id;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatRoom({
    required this.id,
    this.matchId,
    required this.user1Id,
    required this.user2Id,
    this.lastMessage,
    this.lastMessageAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'],
      matchId: json['match_id'],
      user1Id: json['user1_id'],
      user2Id: json['user2_id'],
      lastMessage: json['last_message'],
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  String getOtherUserId(String currentUserId) {
    return currentUserId == user1Id ? user2Id : user1Id;
  }
}

class ChatMessage {
  final String id;
  final String chatRoomId;
  final String senderId;
  final String message;
  final String messageType;
  final DateTime? readAt;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.chatRoomId,
    required this.senderId,
    required this.message,
    this.messageType = 'text',
    this.readAt,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      chatRoomId: json['chat_room_id'],
      senderId: json['sender_id'],
      message: json['message'],
      messageType: json['message_type'] ?? 'text',
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chat_room_id': chatRoomId,
      'sender_id': senderId,
      'message': message,
      'message_type': messageType,
    };
  }

  bool get isRead => readAt != null;
}

class ChatService extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService.instance;
  final NotificationService _notificationService = NotificationService.instance;

  List<ChatRoom> _chatRooms = [];
  List<ChatRoom> get chatRooms => _chatRooms;

  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  RealtimeChannel? _messagesSubscription;
  String? _currentChatRoomId; // 현재 열려있는 채팅방 ID

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }


  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  String get userId => _supabaseService.currentUser?.id ?? '';

  // 매칭 성공시 채팅방 생성 또는 조회
  Future<ChatRoom?> createOrGetChatRoom(String matchId, String user1Id, String user2Id) async {
    try {
      _setLoading(true);
      _clearError();

      // 기존 채팅방 확인
      final existingRoom = await _supabaseService.client
          .from(TableNames.chatRooms)
          .select()
          .eq('match_id', matchId)
          .maybeSingle();

      if (existingRoom != null) {
        debugPrint('Existing chat room found: ${existingRoom['id']}');
        return ChatRoom.fromJson(existingRoom);
      }

      // 새 채팅방 생성
      final response = await _supabaseService.client
          .from(TableNames.chatRooms)
          .insert({
            'match_id': matchId,
            'user1_id': user1Id,
            'user2_id': user2Id,
          })
          .select()
          .single();

      debugPrint('New chat room created: ${response['id']}');
      return ChatRoom.fromJson(response);

    } catch (e) {
      debugPrint('Error creating/getting chat room: $e');
      _setError('채팅방을 생성하는 중 오류가 발생했습니다: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // 사용자의 모든 채팅방 조회
  Future<List<ChatRoom>> getChatRooms() async {
    try {
      _setLoading(true);
      _clearError();

      final currentUserId = userId;
      if (currentUserId.isEmpty) {
        throw Exception('User not authenticated');
      }

      final response = await _supabaseService.client
          .from(TableNames.chatRooms)
          .select()
          .or('user1_id.eq.$currentUserId,user2_id.eq.$currentUserId')
          .order('updated_at', ascending: false);

      _chatRooms = response.map<ChatRoom>((json) => ChatRoom.fromJson(json)).toList();
      debugPrint('Loaded ${_chatRooms.length} chat rooms');

      return _chatRooms;

    } catch (e) {
      debugPrint('Error loading chat rooms: $e');
      _setError('채팅방을 불러오는 중 오류가 발생했습니다: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // 채팅방의 메시지 조회
  Future<List<ChatMessage>> getMessages(String chatRoomId) async {
    try {
      _setLoading(true);
      _clearError();

      final response = await _supabaseService.client
          .from(TableNames.chatMessages)
          .select()
          .eq('chat_room_id', chatRoomId)
          .order('created_at', ascending: true);

      _messages = response.map<ChatMessage>((json) => ChatMessage.fromJson(json)).toList();
      debugPrint('Loaded ${_messages.length} messages for room $chatRoomId');

      return _messages;

    } catch (e) {
      debugPrint('Error loading messages: $e');
      _setError('메시지를 불러오는 중 오류가 발생했습니다: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // 메시지 전송
  Future<ChatMessage?> sendMessage(String chatRoomId, String message) async {
    try {
      final currentUserId = userId;
      if (currentUserId.isEmpty) {
        throw Exception('User not authenticated');
      }

      if (message.trim().isEmpty) {
        throw Exception('Message cannot be empty');
      }

      debugPrint('Sending message: $message');

      // 메시지 생성 (실시간 구독에서 자동으로 받아질 것이므로 여기서는 로컬에 추가하지 않음)
      final response = await _supabaseService.client
          .from(TableNames.chatMessages)
          .insert({
            'chat_room_id': chatRoomId,
            'sender_id': currentUserId,
            'message': message.trim(),
            'message_type': 'text',
          })
          .select()
          .single();

      final newMessage = ChatMessage.fromJson(response);
      debugPrint('Message sent with ID: ${newMessage.id}');

      // 메시지를 즉시 로컬 리스트에 추가 (UX 향상)
      // 실시간 구독에서 중복 체크로 방지됨
      _messages.add(newMessage);
      notifyListeners();

      // 채팅방의 last_message 업데이트
      final now = DateTime.now();
      await _supabaseService.client
          .from(TableNames.chatRooms)
          .update({
            'last_message': message.trim(),
            'last_message_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .eq('id', chatRoomId);

      // 로컬 채팅방 리스트도 업데이트
      final chatRoomIndex = _chatRooms.indexWhere((room) => room.id == chatRoomId);
      if (chatRoomIndex != -1) {
        final updatedChatRoom = ChatRoom(
          id: _chatRooms[chatRoomIndex].id,
          matchId: _chatRooms[chatRoomIndex].matchId,
          user1Id: _chatRooms[chatRoomIndex].user1Id,
          user2Id: _chatRooms[chatRoomIndex].user2Id,
          lastMessage: message.trim(),
          lastMessageAt: now,
          createdAt: _chatRooms[chatRoomIndex].createdAt,
          updatedAt: now,
        );
        _chatRooms[chatRoomIndex] = updatedChatRoom;

        // 채팅방을 맨 위로 이동 (최근 메시지 순서대로)
        _chatRooms.removeAt(chatRoomIndex);
        _chatRooms.insert(0, updatedChatRoom);

        notifyListeners();
      }

      // 알림은 데이터베이스 트리거에서 자동으로 처리됩니다

      return newMessage;

    } catch (e) {
      debugPrint('Error sending message: $e');
      _setError('메시지를 전송하는 중 오류가 발생했습니다: $e');
      return null;
    }
  }

  // 매치 ID로 채팅방 조회
  Future<ChatRoom?> getChatRoomByMatchId(String matchId) async {
    try {
      final response = await _supabaseService.client
          .from(TableNames.chatRooms)
          .select()
          .eq('match_id', matchId)
          .maybeSingle();

      if (response != null) {
        return ChatRoom.fromJson(response);
      }
      return null;

    } catch (e) {
      debugPrint('Error getting chat room by match ID: $e');
      return null;
    }
  }

  // 메시지 읽음 처리
  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _supabaseService.client
          .from(TableNames.chatMessages)
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('id', messageId);

      // 로컬 메시지 업데이트
      final messageIndex = _messages.indexWhere((msg) => msg.id == messageId);
      if (messageIndex != -1) {
        final updatedMessage = ChatMessage(
          id: _messages[messageIndex].id,
          chatRoomId: _messages[messageIndex].chatRoomId,
          senderId: _messages[messageIndex].senderId,
          message: _messages[messageIndex].message,
          messageType: _messages[messageIndex].messageType,
          readAt: DateTime.now(),
          createdAt: _messages[messageIndex].createdAt,
        );
        _messages[messageIndex] = updatedMessage;
        notifyListeners();
      }

    } catch (e) {
      debugPrint('Error marking message as read: $e');
    }
  }

  // 채팅방과 매치 정보를 함께 조회
  Future<Map<String, dynamic>> getChatRoomWithMatchDetails(String chatRoomId) async {
    try {
      // 먼저 채팅방 정보만 조회
      final chatRoomResponse = await _supabaseService.client
          .from(TableNames.chatRooms)
          .select('*')
          .eq('id', chatRoomId)
          .single();

      debugPrint('Chat room response: $chatRoomResponse');

      // 매치 ID로 매치 정보 조회
      if (chatRoomResponse['match_id'] != null) {
        final matchResponse = await _supabaseService.client
            .from(TableNames.scheduledMatches)
            .select('*')
            .eq('id', chatRoomResponse['match_id'])
            .single();

        debugPrint('Match response: $matchResponse');

        // 사용자 프로필들 조회
        final user1Id = matchResponse['user1_id'];
        final user2Id = matchResponse['user2_id'];

        final user1Profile = await _supabaseService.client
            .from(TableNames.users)
            .select('*')
            .eq('id', user1Id)
            .maybeSingle();

        final user2Profile = await _supabaseService.client
            .from(TableNames.users)
            .select('*')
            .eq('id', user2Id)
            .maybeSingle();

        debugPrint('User1 profile: $user1Profile');
        debugPrint('User2 profile: $user2Profile');

        // 결합된 응답 반환
        return {
          ...chatRoomResponse,
          'match_data': {
            ...matchResponse,
            'user1_profile': user1Profile ?? {},
            'user2_profile': user2Profile ?? {},
          },
        };
      }

      return chatRoomResponse;
    } catch (e) {
      debugPrint('Error getting chat room with match details: $e');
      throw Exception('채팅방 정보를 불러오는 중 오류가 발생했습니다: $e');
    }
  }

  // 특정 채팅방의 실시간 메시지 구독 시작
  Future<void> subscribeToMessages(String chatRoomId) async {
    try {
      // 기존 구독이 있다면 해제
      await unsubscribeFromMessages();

      debugPrint('Starting message subscription for room: $chatRoomId');

      // 실시간 구독을 위한 더 간단한 채널명 사용
      final channelName = 'messages_$chatRoomId';
      debugPrint('Creating channel: $channelName');

      _messagesSubscription = _supabaseService.client
          .channel(channelName)
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'blinddate_chat_messages',  // 실제 테이블명 사용
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'chat_room_id',
              value: chatRoomId,
            ),
            callback: (payload) {
              debugPrint('=== Realtime Message Received ===');
              debugPrint('Event: ${payload.eventType}');
              debugPrint('Table: ${payload.table}');
              debugPrint('Schema: ${payload.schema}');
              debugPrint('Payload: ${payload.newRecord}');

              try {
                final newMessage = ChatMessage.fromJson(payload.newRecord);
                debugPrint('Parsed message ID: ${newMessage.id}');
                debugPrint('Sender ID: ${newMessage.senderId}');
                debugPrint('Current user ID: $userId');
                debugPrint('Message text: ${newMessage.message}');

                // 중복 메시지 확인 (이미 존재하는 메시지인지 체크)
                final existingMessageIndex = _messages.indexWhere((msg) => msg.id == newMessage.id);
                if (existingMessageIndex == -1) {
                  _messages.add(newMessage);
                  debugPrint('✅ New message added to list. Total messages: ${_messages.length}');

                  // 내가 보낸 메시지가 아니고, 현재 채팅방에 있지 않다면 읽지 않은 메시지 수 업데이트
                  if (newMessage.senderId != userId && _currentChatRoomId != newMessage.chatRoomId) {
                    UnreadMessageService.instance.fetchUnreadCount();
                  }

                  notifyListeners();
                } else {
                  debugPrint('⚠️ Message already exists, skipping duplicate');
                }
              } catch (e, stackTrace) {
                debugPrint('❌ Error processing new message: $e');
                debugPrint('Stack trace: $stackTrace');
              }
            },
          );

      // 구독 시작
      _messagesSubscription!.subscribe((status, error) {
        debugPrint('✅ Subscription status: $status');
        if (status == RealtimeSubscribeStatus.subscribed) {
          debugPrint('✅ Successfully subscribed to channel: $channelName');
          debugPrint('✅ Listening for INSERT events on blinddate_chat_messages table');
        } else if (status == RealtimeSubscribeStatus.channelError) {
          debugPrint('❌ Subscription error: $error');
        } else if (status == RealtimeSubscribeStatus.closed) {
          debugPrint('⚠️ Subscription closed');
        }
      });

    } catch (e, stackTrace) {
      debugPrint('❌ Error starting message subscription: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  // 실시간 메시지 구독 해제
  Future<void> unsubscribeFromMessages() async {
    try {
      if (_messagesSubscription != null) {
        debugPrint('Unsubscribing from messages');
        await _supabaseService.client.removeChannel(_messagesSubscription!);
        _messagesSubscription = null;
        debugPrint('Message subscription removed successfully');
      }
    } catch (e) {
      debugPrint('Error unsubscribing from messages: $e');
    }
  }

  // 모든 상태 초기화
  void clearAll() {
    _chatRooms.clear();
    _messages.clear();
    _errorMessage = null;
    _isLoading = false;
    // 구독 해제도 함께 처리
    unsubscribeFromMessages();
    notifyListeners();
  }

  // 알림 전송 (비동기) - 현재 사용 안함, 데이터베이스 트리거에서 처리
  /*
  void _sendNotificationAsync(String chatRoomId, String senderId, String message) {
    // 백그라운드에서 실행하여 메시지 전송 속도에 영향 없음
    Future(() async {
      try {
        debugPrint('📨 알림 전송 시작');

        // 채팅방 정보와 상대방 정보 가져오기
        final chatRoomData = await getChatRoomWithMatchDetails(chatRoomId);
        final matchData = chatRoomData['match_data'];

        if (matchData == null) {
          debugPrint('❌ 매치 정보를 찾을 수 없습니다');
          return;
        }

        // 상대방 ID 찾기
        final user1Id = matchData['user1_id'] as String;
        final user2Id = matchData['user2_id'] as String;
        final recipientId = senderId == user1Id ? user2Id : user1Id;

        // 발신자 정보 가져오기
        final senderProfile = senderId == user1Id
            ? matchData['user1_profile']
            : matchData['user2_profile'];

        final senderName = senderProfile?['nickname'] ?? '알 수 없는 사용자';

        debugPrint('👤 발신자: $senderName, 수신자: $recipientId');

        // 상대방의 FCM 토큰 가져오기
        final recipientData = await _supabaseService.client
            .from(TableNames.users)
            .select('fcm_token, nickname')
            .eq('id', recipientId)
            .maybeSingle();

        if (recipientData == null || recipientData['fcm_token'] == null) {
          debugPrint('❌ 상대방의 FCM 토큰을 찾을 수 없습니다');
          return;
        }

        // Supabase Edge Function으로 알림 전송
        final response = await _supabaseService.client.functions.invoke(
          'send-chat-notification',
          body: {
            'chatRoomId': chatRoomId,
            'senderId': senderId,
            'senderName': senderName,
            'recipientId': recipientId,
            'recipientToken': recipientData['fcm_token'],
            'message': message,
          },
        );

        if (response.status == 200) {
          debugPrint('✅ 알림 전송 성공');
        } else {
          debugPrint('❌ 알림 전송 실패: ${response.status} - ${response.data}');
        }

      } catch (e) {
        debugPrint('❌ 알림 전송 오류: $e');
      }
    });
  }
  */

  // 채팅방 진입 시 호출 (현재 채팅방 설정)
  void enterChatRoom(String chatRoomId) {
    _currentChatRoomId = chatRoomId;
    _notificationService.setCurrentChatRoom(chatRoomId);
    UnreadMessageService.instance.setCurrentChatRoom(chatRoomId);
    debugPrint('🏠 채팅방 진입: $chatRoomId');
  }

  // 채팅방 나갈 때 호출
  void exitChatRoom() {
    _currentChatRoomId = null;
    _notificationService.setCurrentChatRoom(null);
    UnreadMessageService.instance.setCurrentChatRoom(null);
    debugPrint('🚪 채팅방 나감');
  }

  // 메시지 읽음 처리 및 알림 제거
  Future<void> markMessagesAsRead(String chatRoomId) async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) return;

      // 해당 채팅방의 읽지 않은 메시지들을 읽음 처리
      await _supabaseService.client
          .from(TableNames.chatMessages)
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('chat_room_id', chatRoomId)
          .neq('sender_id', userId)
          .isFilter('read_at', null);

      debugPrint('✅ 메시지 읽음 처리 완료: $chatRoomId');

    } catch (e) {
      debugPrint('❌ 메시지 읽음 처리 오류: $e');
    }
  }

  @override
  void dispose() {
    unsubscribeFromMessages();
    super.dispose();
  }
}