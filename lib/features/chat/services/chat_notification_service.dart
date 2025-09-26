import 'package:flutter/foundation.dart';
import '../../../core/services/supabase_service.dart';

class ChatNotificationService {
  static ChatNotificationService? _instance;
  static ChatNotificationService get instance => _instance ??= ChatNotificationService._();

  ChatNotificationService._();

  final SupabaseService _supabaseService = SupabaseService.instance;

  // 메시지 전송 시 알림 발송
  Future<void> sendMessageNotification({
    required String chatRoomId,
    required String senderId,
    required String senderName,
    required String message,
  }) async {
    try {
      debugPrint('알림 발송 시작: chatRoomId=$chatRoomId, sender=$senderName');

      // Supabase Edge Function 호출
      final response = await _supabaseService.client.functions.invoke(
        'send-chat-notification',
        body: {
          'chatRoomId': chatRoomId,
          'senderId': senderId,
          'senderName': senderName,
          'message': message,
        },
      );

      if (response.status == 200) {
        debugPrint('✅ 알림 발송 성공');
      } else {
        debugPrint('❌ 알림 발송 실패: ${response.status}');
      }

    } catch (e) {
      debugPrint('❌ 알림 발송 오류: $e');
    }
  }

  // 읽지 않은 메시지 수 업데이트
  Future<void> updateUnreadCount(String userId) async {
    try {
      // 읽지 않은 메시지 수 계산
      final result = await _supabaseService.client
          .rpc('get_unread_message_count', params: {'user_id': userId});

      final unreadCount = result as int? ?? 0;
      debugPrint('읽지 않은 메시지 수: $unreadCount');

      // 앱 배지 업데이트 (iOS)
      // 안드로이드는 별도 처리 필요
      if (unreadCount > 0) {
        // TODO: 배지 업데이트 로직
      }

    } catch (e) {
      debugPrint('읽지 않은 메시지 수 업데이트 오류: $e');
    }
  }

  // 메시지 읽음 처리 시 알림 제거
  Future<void> markMessagesAsRead(String chatRoomId, String userId) async {
    try {
      // 해당 채팅방의 모든 메시지를 읽음 처리
      await _supabaseService.client
          .from('blinddate_chat_messages')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('chat_room_id', chatRoomId)
          .neq('sender_id', userId)
          .isFilter('read_at', null);

      debugPrint('메시지 읽음 처리 완료: chatRoomId=$chatRoomId');

      // 읽지 않은 메시지 수 업데이트
      await updateUnreadCount(userId);

    } catch (e) {
      debugPrint('메시지 읽음 처리 오류: $e');
    }
  }
}