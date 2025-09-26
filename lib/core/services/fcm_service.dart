import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  // Firebase Server Key는 실제 운영에서는 환경변수나 보안 저장소에서 가져와야 함
  // 현재는 테스트용으로 하드코딩 (Firebase Console에서 확인 필요)
  static const String _serverKey = 'YOUR_FIREBASE_SERVER_KEY_HERE';
  static const String _fcmUrl = 'https://fcm.googleapis.com/fcm/send';

  /// FCM 푸시 알림 전송
  Future<bool> sendNotification({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    try {
      debugPrint('📱 FCM 알림 전송 시작');
      debugPrint('수신자 토큰: ${fcmToken.substring(0, 20)}...');
      debugPrint('제목: $title');
      debugPrint('내용: $body');

      final Map<String, dynamic> payload = {
        'to': fcmToken,
        'notification': {
          'title': title,
          'body': body,
          'sound': 'default',
          'badge': 1,
        },
        'data': data ?? {},
        'priority': 'high',
        'content_available': true,
      };

      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: json.encode(payload),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        debugPrint('✅ FCM 전송 성공: $responseData');

        // success가 1 이상이면 성공
        if (responseData['success'] != null && responseData['success'] > 0) {
          return true;
        } else {
          debugPrint('❌ FCM 전송 실패: ${responseData['results']}');
          return false;
        }
      } else {
        debugPrint('❌ FCM API 호출 실패: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ FCM 전송 오류: $e');
      return false;
    }
  }

  /// 채팅 메시지 알림 전송 (특화 메소드)
  Future<bool> sendChatNotification({
    required String recipientToken,
    required String senderName,
    required String message,
    required String chatRoomId,
    required String senderId,
  }) async {
    return await sendNotification(
      fcmToken: recipientToken,
      title: senderName,
      body: message,
      data: {
        'type': 'chat_message',
        'chatRoomId': chatRoomId,
        'senderId': senderId,
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      },
    );
  }
}