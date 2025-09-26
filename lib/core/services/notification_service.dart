import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'supabase_service.dart';

// 백그라운드 메시지 핸들러 (최상위 함수여야 함)
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('백그라운드 메시지 수신: ${message.messageId}');
}

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();

  NotificationService._();

  FirebaseMessaging? _firebaseMessaging;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final SupabaseService _supabaseService = SupabaseService.instance;

  // Firebase Messaging 인스턴스 (lazy 초기화)
  FirebaseMessaging? get _messaging {
    if (!isFirebaseAvailable) return null;
    return _firebaseMessaging ??= FirebaseMessaging.instance;
  }

  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  String? _currentChatRoomId; // 현재 열려있는 채팅방 ID
  bool _isInitialized = false;

  // 현재 채팅방 설정
  void setCurrentChatRoom(String? chatRoomId) {
    _currentChatRoomId = chatRoomId;
    debugPrint('현재 채팅방 설정: $_currentChatRoomId');
  }

  // Firebase가 사용 가능한지 확인
  bool get isFirebaseAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // 알림 초기화
  Future<void> initialize() async {
    if (_isInitialized) return;

    if (!isFirebaseAvailable) {
      debugPrint('⚠️ Firebase가 초기화되지 않았습니다. 알림 서비스를 건너뜁니다.');
      _isInitialized = true;
      return;
    }

    try {
      debugPrint('🔔 알림 서비스 초기화 시작');

      final messaging = _messaging;
      if (messaging == null) {
        debugPrint('❌ Firebase Messaging을 사용할 수 없습니다.');
        return;
      }

      // 알림 권한 요청
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ 알림 권한 허용됨');
      } else {
        debugPrint('❌ 알림 권한 거부됨');
        return;
      }

      // FCM 토큰 가져오기
      _fcmToken = await messaging.getToken();
      debugPrint('📱 FCM Token: $_fcmToken');

      // 로컬 알림 초기화
      await _initializeLocalNotifications();

      // 포그라운드 메시지 처리
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 백그라운드 메시지 처리 등록
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

      // 앱이 알림으로 열렸을 때 처리
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // 앱이 종료된 상태에서 알림으로 열렸을 때
      RemoteMessage? initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      // FCM 토큰 갱신 처리
      messaging.onTokenRefresh.listen((token) async {
        _fcmToken = token;
        debugPrint('🔄 FCM Token refreshed: $token');
        await _saveFcmTokenToDatabase();
      });

      // 사용자가 로그인되어 있다면 토큰 저장
      if (_fcmToken != null && _supabaseService.isAuthenticated) {
        await _saveFcmTokenToDatabase();
      }

      _isInitialized = true;
      debugPrint('✅ 알림 서비스 초기화 완료');

    } catch (e) {
      debugPrint('❌ 알림 초기화 오류: $e');
    }
  }

  // 로그인 후 FCM 토큰 저장
  Future<void> onUserLogin() async {
    if (!isFirebaseAvailable) return;

    if (_fcmToken != null && _supabaseService.isAuthenticated) {
      await _saveFcmTokenToDatabase();
    }
  }

  // 로그아웃 시 FCM 토큰 제거
  Future<void> onUserLogout() async {
    if (!isFirebaseAvailable) return;

    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId != null) {
        await _supabaseService.client
            .from('blinddate_users')
            .update({'fcm_token': null})
            .eq('id', userId);
        debugPrint('✅ FCM 토큰 제거 완료');
      }
    } catch (e) {
      debugPrint('❌ FCM 토큰 제거 오류: $e');
    }
  }

  // 로컬 알림 초기화
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleLocalNotificationTap,
    );

    // Android 채널 생성
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'chat_channel',
      '채팅 알림',
      description: '새 채팅 메시지 알림',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    debugPrint('📱 로컬 알림 초기화 완료');
  }

  // FCM 토큰을 데이터베이스에 저장
  Future<void> _saveFcmTokenToDatabase() async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null || _fcmToken == null) return;

      await _supabaseService.client
          .from('blinddate_users')
          .update({'fcm_token': _fcmToken})
          .eq('id', userId);

      debugPrint('✅ FCM 토큰 저장 완료');
    } catch (e) {
      debugPrint('❌ FCM 토큰 저장 오류: $e');
    }
  }

  // 포그라운드에서 메시지 수신 처리
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📨 포그라운드 메시지 수신: ${message.notification?.title}');

    final data = message.data;
    if (data['type'] == 'chat_message') {
      final messageChatRoomId = data['chatRoomId'];

      // 현재 열려있는 채팅방과 같은 방의 메시지라면 알림 표시 안함
      if (_currentChatRoomId == messageChatRoomId) {
        debugPrint('🔇 현재 열려있는 채팅방의 메시지 - 알림 표시 안함');
        return;
      }

      // 다른 채팅방이거나 채팅방이 아닌 화면에 있을 때 알림 표시
      _showLocalNotification(message);
    }
  }

  // 로컬 알림 표시
  Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'chat_channel',
      '채팅 알림',
      channelDescription: '새 채팅 메시지 알림',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFEF476F),
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? '새 메시지',
      message.notification?.body ?? '',
      details,
      payload: message.data['chatRoomId'],
    );

    debugPrint('📱 로컬 알림 표시됨: ${message.notification?.title}');
  }

  // 알림 탭 처리 (FCM)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 FCM 알림 탭됨: ${message.data}');

    final data = message.data;
    if (data['type'] == 'chat_message' && data['chatRoomId'] != null) {
      _navigateToChatRoom(data['chatRoomId']);
    }
  }

  // 로컬 알림 탭 처리
  void _handleLocalNotificationTap(NotificationResponse response) {
    debugPrint('👆 로컬 알림 탭됨: ${response.payload}');
    if (response.payload != null) {
      _navigateToChatRoom(response.payload!);
    }
  }

  // 채팅방으로 이동 (나중에 GoRouter 연동)
  void _navigateToChatRoom(String chatRoomId) {
    debugPrint('🚀 채팅방으로 이동 요청: $chatRoomId');
    // TODO: GoRouter를 사용하여 채팅방으로 이동
    // NavigationService.instance.navigateTo('/chat/$chatRoomId');
  }

  // 알림 권한 상태 확인
  Future<bool> isNotificationEnabled() async {
    if (!isFirebaseAvailable) return false;

    final messaging = _messaging;
    if (messaging == null) return false;

    final settings = await messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  // 알림 설정 화면으로 이동
  Future<void> openNotificationSettings() async {
    if (!isFirebaseAvailable) return;

    final messaging = _messaging;
    if (messaging == null) return;

    await messaging.requestPermission();
  }

  // 읽지 않은 메시지 수 가져오기
  Future<int> getUnreadMessageCount() async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) return 0;

      final result = await _supabaseService.client
          .rpc('get_unread_message_count', params: {'user_id': userId});

      return result as int? ?? 0;
    } catch (e) {
      debugPrint('❌ 읽지 않은 메시지 수 조회 오류: $e');
      return 0;
    }
  }
}