import 'package:flutter/foundation.dart';
import 'supabase_service.dart';

class UnreadMessageService extends ChangeNotifier {
  static UnreadMessageService? _instance;
  static UnreadMessageService get instance => _instance ??= UnreadMessageService._();

  UnreadMessageService._();

  final SupabaseService _supabaseService = SupabaseService.instance;
  int _unreadCount = 0;

  int get unreadCount => _unreadCount;

  Map<String, int> _unreadCountPerRoom = {};
  Map<String, int> get unreadCountPerRoom => _unreadCountPerRoom;

  // 읽지 않은 메시지 수 가져오기
  Future<void> fetchUnreadCount() async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        _updateUnreadCount(0);
        return;
      }

      // 채팅방별 읽지 않은 메시지 수 계산
      final result = await _supabaseService.client
          .rpc('get_chat_rooms_with_unread', params: {'user_id': userId});

      int totalUnreadCount = 0;
      Map<String, int> newUnreadCountPerRoom = {};

      for (final row in result) {
        final chatRoomId = row['chat_room_id'].toString();
        final unreadCount = row['unread_count'] as int? ?? 0;

        newUnreadCountPerRoom[chatRoomId] = unreadCount;
        totalUnreadCount += unreadCount;
      }

      _unreadCountPerRoom = newUnreadCountPerRoom;
      _updateUnreadCount(totalUnreadCount);
    } catch (e) {
      debugPrint('❌ 읽지 않은 메시지 수 조회 오류: $e');
      _updateUnreadCount(0);
    }
  }

  // 특정 채팅방의 읽지 않은 메시지 수 조회
  int getUnreadCountForRoom(String chatRoomId) {
    return _unreadCountPerRoom[chatRoomId] ?? 0;
  }

  // 특정 채팅방의 메시지 읽음 처리
  Future<void> markChatAsRead(String chatRoomId) async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) return;

      // 해당 채팅방의 읽지 않은 메시지들을 읽음 처리
      await _supabaseService.client
          .from('blinddate_chat_messages')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('chat_room_id', chatRoomId)
          .neq('sender_id', userId)
          .isFilter('read_at', null);

      // 읽지 않은 메시지 수 다시 계산
      await fetchUnreadCount();
    } catch (e) {
      debugPrint('❌ 메시지 읽음 처리 오류: $e');
    }
  }

  // 새 메시지가 도착했을 때 카운트 증가
  void incrementUnreadCount() {
    _updateUnreadCount(_unreadCount + 1);
  }

  // 현재 채팅방에 있을 때는 카운트 증가하지 않음
  void onNewMessageReceived(String chatRoomId, String currentChatRoomId) {
    if (chatRoomId != currentChatRoomId) {
      incrementUnreadCount();
    }
  }

  // 카운트 업데이트 및 리스너 알림
  void _updateUnreadCount(int count) {
    if (_unreadCount != count) {
      _unreadCount = count;
      notifyListeners();
      debugPrint('📊 읽지 않은 메시지 수 업데이트: $_unreadCount');
    }
  }

  // 로그아웃 시 초기화
  void reset() {
    _updateUnreadCount(0);
  }
}