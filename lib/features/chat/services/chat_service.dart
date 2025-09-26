import 'package:flutter/foundation.dart';
import '../../../core/services/supabase_service.dart';
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

  List<ChatRoom> _chatRooms = [];
  List<ChatRoom> get chatRooms => _chatRooms;

  List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

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
          .from('chat_rooms')
          .select()
          .eq('match_id', matchId)
          .maybeSingle();

      if (existingRoom != null) {
        debugPrint('Existing chat room found: ${existingRoom['id']}');
        return ChatRoom.fromJson(existingRoom);
      }

      // 새 채팅방 생성
      final response = await _supabaseService.client
          .from('chat_rooms')
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
          .from('chat_rooms')
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
          .from('chat_messages')
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

      // 메시지 생성
      final response = await _supabaseService.client
          .from('chat_messages')
          .insert({
            'chat_room_id': chatRoomId,
            'sender_id': currentUserId,
            'message': message.trim(),
            'message_type': 'text',
          })
          .select()
          .single();

      final newMessage = ChatMessage.fromJson(response);
      _messages.add(newMessage);

      // 채팅방의 last_message 업데이트
      await _supabaseService.client
          .from('chat_rooms')
          .update({
            'last_message': message.trim(),
            'last_message_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', chatRoomId);

      debugPrint('Message sent: ${newMessage.id}');
      notifyListeners();
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
          .from('chat_rooms')
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
          .from('chat_messages')
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
          .from('chat_rooms')
          .select('*')
          .eq('id', chatRoomId)
          .single();

      debugPrint('Chat room response: $chatRoomResponse');

      // 매치 ID로 매치 정보 조회
      if (chatRoomResponse['match_id'] != null) {
        final matchResponse = await _supabaseService.client
            .from('blinddate_scheduled_matches')
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

  // 모든 상태 초기화
  void clearAll() {
    _chatRooms.clear();
    _messages.clear();
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }
}