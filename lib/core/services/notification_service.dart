import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'supabase_service.dart';
import 'unread_message_service.dart';

// 처리된 메시지 ID 저장 (중복 방지)
final Set<String> _processedMessageIds = <String>{};

// 백그라운드 메시지 핸들러 (최상위 함수여야 함)
@pragma('vm:entry-point')
Future<void> _handleBackgroundMessage(RemoteMessage message) async {
  debugPrint('백그라운드 메시지 수신: ${message.messageId}');

  // 중복 메시지 방지 - 강화된 로직
  final messageId = message.messageId ?? '';
  debugPrint('🔍 메시지 ID 체크: $messageId (이미 처리된 수: ${_processedMessageIds.length})');

  if (messageId.isNotEmpty) {
    if (_processedMessageIds.contains(messageId)) {
      debugPrint('⚠️ 이미 처리된 메시지 ID: $messageId - 스킵');
      return;
    }
    _processedMessageIds.add(messageId);
    debugPrint('✅ 새로운 메시지 ID 추가: $messageId');
  } else {
    debugPrint('⚠️ 메시지 ID가 비어있음 - 처리 진행');
  }

  // Set 크기 제한 (메모리 누수 방지)
  if (_processedMessageIds.length > 100) {
    _processedMessageIds.clear();
  }

  final data = message.data;
  final notificationType = data['type'];

  debugPrint('📨 백그라운드 메시지 데이터: $data');

  if (notificationType == 'daily_match') {
    // Android data-only 메시지이므로 로컬 알림 표시
    await _showBackgroundMatchNotification(data);
  }
}

// 백그라운드에서 매칭 알림 표시
Future<void> _showBackgroundMatchNotification(Map<String, dynamic> data) async {
  final FlutterLocalNotificationsPlugin localNotifications = FlutterLocalNotificationsPlugin();

  const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'match_channel',
    '매칭 알림',
    channelDescription: '새로운 매칭 알림',
    importance: Importance.high,
    priority: Priority.high,
    color: Color(0xFFEF476F),
    icon: '@drawable/ic_stat_hearty',
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

  // FCM data에서 null 문자열 처리
  String getValidString(String? value) {
    if (value == null || value == 'null' || value.isEmpty) {
      return '';
    }
    return value;
  }

  final titleFromData = getValidString(data['title']);
  final bodyFromData = getValidString(data['body']);

  final title = titleFromData.isNotEmpty ? titleFromData : '💕 새로운 인연이 도착했어요!';
  final body = bodyFromData.isNotEmpty ? bodyFromData : '오늘의 추천을 확인해보세요';

  debugPrint('🔍 백그라운드 알림 데이터 확인:');
  debugPrint('  - Raw data: $data');
  debugPrint('  - title: "${data['title']}" -> "$title"');
  debugPrint('  - body: "${data['body']}" -> "$body"');
  debugPrint('  - type: "${data['type']}"');

  await localNotifications.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title,
    body,
    details,
    payload: 'daily_match',
  );

  debugPrint('💕 백그라운드 매칭 알림 표시됨: $title');
}

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();

  NotificationService._();

  FirebaseMessaging? _firebaseMessaging;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final SupabaseService _supabaseService = SupabaseService.instance;

  // 포그라운드에서 처리된 메시지 ID 저장 (중복 방지)
  final Set<String> _foregroundProcessedMessageIds = <String>{};

  // 알림 중복 방지를 위한 최근 표시된 알림 해시 저장
  final Set<String> _recentNotificationHashes = <String>{};

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

  // 알림 중복 체크 및 해시 생성
  bool _isDuplicateNotification(String type, Map<String, dynamic> data) {
    // 알림 데이터로 해시 생성
    String notificationHash;

    switch (type) {
      case 'received_like':
        notificationHash = '${type}_${data['senderUserId']}_${data['targetUserId']}';
        break;
      case 'mutual_match':
        // user ID 정렬해서 순서에 상관없이 같은 해시 생성
        final List<String> userIds = [data['targetUserId'], data['matchedUserId']]..sort();
        notificationHash = '${type}_${userIds[0]}_${userIds[1]}';
        break;
      case 'chat_message':
        notificationHash = '${type}_${data['chatRoomId']}_${data['senderId']}';
        break;
      default:
        notificationHash = '${type}_${DateTime.now().millisecondsSinceEpoch}';
    }

    // 중복 체크
    if (_recentNotificationHashes.contains(notificationHash)) {
      debugPrint('⚠️ 중복 알림 감지: $notificationHash');
      return true;
    }

    // 해시 추가 (최근 10개만 유지)
    _recentNotificationHashes.add(notificationHash);
    if (_recentNotificationHashes.length > 10) {
      final oldestHash = _recentNotificationHashes.first;
      _recentNotificationHashes.remove(oldestHash);
    }

    debugPrint('✅ 새로운 알림 허용: $notificationHash');
    return false;
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
        AndroidInitializationSettings('@drawable/ic_stat_hearty');

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
    const AndroidNotificationChannel chatChannel = AndroidNotificationChannel(
      'chat_channel',
      '채팅 알림',
      description: '새 채팅 메시지 알림',
      importance: Importance.high,
    );

    const AndroidNotificationChannel matchChannel = AndroidNotificationChannel(
      'match_channel',
      '매칭 알림',
      description: '새로운 매칭 알림',
      importance: Importance.high,
    );

    const AndroidNotificationChannel likeChannel = AndroidNotificationChannel(
      'like_channel',
      '좋아요 알림',
      description: '받은 좋아요 알림',
      importance: Importance.high,
    );

    const AndroidNotificationChannel mutualMatchChannel = AndroidNotificationChannel(
      'mutual_match_channel',
      '매칭 성공 알림',
      description: '상호 매칭 성공 알림',
      importance: Importance.max,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(chatChannel);
    await androidPlugin?.createNotificationChannel(matchChannel);
    await androidPlugin?.createNotificationChannel(likeChannel);
    await androidPlugin?.createNotificationChannel(mutualMatchChannel);

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
    debugPrint('📨 포그라운드 메시지 수신: ${message.messageId}');

    // 중복 메시지 방지
    if (_foregroundProcessedMessageIds.contains(message.messageId)) {
      debugPrint('⚠️ 이미 처리된 포그라운드 메시지 ID: ${message.messageId}');
      return;
    }
    _foregroundProcessedMessageIds.add(message.messageId ?? '');

    // Set 크기 제한 (메모리 누수 방지)
    if (_foregroundProcessedMessageIds.length > 100) {
      _foregroundProcessedMessageIds.clear();
    }

    final data = message.data;
    final notificationType = data['type'];

    debugPrint('📨 포그라운드 메시지 데이터: $data');

    if (notificationType == 'chat_message') {
      final messageChatRoomId = data['chatRoomId'];

      // 현재 열려있는 채팅방과 같은 방의 메시지라면 알림 표시 안함
      if (_currentChatRoomId == messageChatRoomId) {
        debugPrint('🔇 현재 열려있는 채팅방의 메시지 - 알림 표시 안함');
        return;
      }

      // 읽지 않은 메시지 수 다시 계산 (정확한 수 보장)
      UnreadMessageService.instance.fetchUnreadCount();

      // 다른 채팅방이거나 채팅방이 아닌 화면에 있을 때 알림 표시
      _showLocalNotification(message);
    } else if (notificationType == 'daily_match') {
      // 매칭 알림은 항상 표시 (data-only 메시지 처리)
      debugPrint('📨 포그라운드에서 매칭 알림 데이터 처리: $data');
      _showMatchNotificationFromData(data);
    } else if (notificationType == 'received_like') {
      // 중복 체크
      if (_isDuplicateNotification(notificationType, data)) {
        debugPrint('⚠️ 중복된 LIKE 알림 - 무시함');
        return;
      }
      // 받은 LIKE 알림 표시
      debugPrint('💕 포그라운드에서 받은 LIKE 알림 처리: $data');
      _showLikeNotificationFromData(data);
    } else if (notificationType == 'mutual_match') {
      // 중복 체크
      if (_isDuplicateNotification(notificationType, data)) {
        debugPrint('⚠️ 중복된 상호 매칭 알림 - 무시함');
        return;
      }
      // 상호 매칭 알림 표시
      debugPrint('💕 포그라운드에서 상호 매칭 알림 처리: $data');
      _showMutualMatchNotificationFromData(data);
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
      icon: '@drawable/ic_stat_hearty',
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

  // data-only 매칭 알림 표시
  Future<void> _showMatchNotificationFromData(Map<String, dynamic> data) async {
    // FCM data에서 null 문자열 처리
    String getValidString(String? value) {
      if (value == null || value == 'null' || value.isEmpty) {
        return '';
      }
      return value;
    }

    final titleFromData = getValidString(data['title']);
    final bodyFromData = getValidString(data['body']);

    final title = titleFromData.isNotEmpty ? titleFromData : '💕 새로운 인연이 도착했어요!';
    final body = bodyFromData.isNotEmpty ? bodyFromData : '오늘의 추천을 확인해보세요';

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'match_channel',
      '매칭 알림',
      channelDescription: '새로운 매칭 알림',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFEF476F),
      icon: '@drawable/ic_stat_hearty',
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
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: 'daily_match',
    );

    debugPrint('💕 포그라운드 매칭 알림 표시됨: $title');
  }

  // 받은 LIKE 알림 표시
  Future<void> _showLikeNotificationFromData(Map<String, dynamic> data) async {
    // FCM data에서 null 문자열 처리
    String getValidString(String? value) {
      if (value == null || value == 'null' || value.isEmpty) {
        return '';
      }
      return value;
    }

    final titleFromData = getValidString(data['title']);
    final bodyFromData = getValidString(data['body']);
    final senderName = getValidString(data['senderName']);

    final title = titleFromData.isNotEmpty ? titleFromData : '💕 누군가 당신을 좋아해요!';
    final body = bodyFromData.isNotEmpty ? bodyFromData :
        senderName.isNotEmpty ? '$senderName님이 당신에게 관심을 표했어요' : '새로운 관심 표현을 받았어요';

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'like_channel',
      '좋아요 알림',
      channelDescription: '받은 좋아요 알림',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFEF476F),
      icon: '@drawable/ic_stat_hearty',
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
      DateTime.now().millisecondsSinceEpoch ~/ 1000 + 1,
      title,
      body,
      details,
      payload: 'received_like',
    );

    debugPrint('💕 받은 LIKE 알림 표시됨: $title');
  }

  // 상호 매칭 알림 표시
  Future<void> _showMutualMatchNotificationFromData(Map<String, dynamic> data) async {
    // FCM data에서 null 문자열 처리
    String getValidString(String? value) {
      if (value == null || value == 'null' || value.isEmpty) {
        return '';
      }
      return value;
    }

    final titleFromData = getValidString(data['title']);
    final bodyFromData = getValidString(data['body']);
    final matchedUserName = getValidString(data['matchedUserName']);
    final chatRoomId = getValidString(data['chatRoomId']);

    final title = titleFromData.isNotEmpty ? titleFromData : '🎉 매칭 성공!';
    final body = bodyFromData.isNotEmpty ? bodyFromData :
        matchedUserName.isNotEmpty ? '$matchedUserName님과 매칭되었어요! 대화를 시작해보세요' : '새로운 매칭이 성사되었어요!';

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'mutual_match_channel',
      '매칭 성공 알림',
      channelDescription: '상호 매칭 성공 알림',
      importance: Importance.max,
      priority: Priority.max,
      color: Color(0xFFEF476F),
      icon: '@drawable/ic_stat_hearty',
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
      DateTime.now().millisecondsSinceEpoch ~/ 1000 + 2,
      title,
      body,
      details,
      payload: chatRoomId.isNotEmpty ? 'chat_$chatRoomId' : 'mutual_match',
    );

    debugPrint('🎉 상호 매칭 알림 표시됨: $title');
  }


  // 알림 탭 처리 (FCM)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('👆 FCM 알림 탭됨: ${message.data}');

    final data = message.data;
    final notificationType = data['type'];

    if (notificationType == 'chat_message' && data['chatRoomId'] != null) {
      _navigateToChatRoom(data['chatRoomId']);
    } else if (notificationType == 'daily_match') {
      _navigateToRecommendations();
    } else if (notificationType == 'received_like') {
      _navigateToRecommendations(); // 받은 LIKE는 추천 페이지로
    } else if (notificationType == 'mutual_match') {
      _navigateToChatRoom(data['chatRoomId'] ?? ''); // 상호 매칭은 채팅방으로
    }
  }

  // 로컬 알림 탭 처리
  void _handleLocalNotificationTap(NotificationResponse response) {
    debugPrint('👆 로컬 알림 탭됨: ${response.payload}');
    if (response.payload != null) {
      if (response.payload == 'daily_match') {
        _navigateToRecommendations();
      } else if (response.payload == 'received_like') {
        _navigateToRecommendations(); // 받은 LIKE는 추천 페이지로
      } else if (response.payload == 'mutual_match') {
        _navigateToRecommendations(); // 상호 매칭도 우선 추천 페이지로
      } else if (response.payload!.startsWith('chat_')) {
        // 채팅방 ID 추출 (chat_ 접두사 제거)
        final chatRoomId = response.payload!.substring(5);
        _navigateToChatRoom(chatRoomId);
      } else {
        _navigateToChatRoom(response.payload!);
      }
    }
  }

  // 채팅방으로 이동 (나중에 GoRouter 연동)
  void _navigateToChatRoom(String chatRoomId) {
    debugPrint('🚀 채팅방으로 이동 요청: $chatRoomId');
    // TODO: GoRouter를 사용하여 채팅방으로 이동
    // NavigationService.instance.navigateTo('/chat/$chatRoomId');
  }

  // 추천 페이지로 이동
  void _navigateToRecommendations() {
    debugPrint('💕 추천 페이지로 이동 요청');
    // TODO: GoRouter를 사용하여 추천 페이지로 이동
    // NavigationService.instance.navigateTo('/recommendations');
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

  // Public method to show match notification
  Future<void> showMatchNotificationDirect({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!isFirebaseAvailable) {
      debugPrint('⚠️ Firebase가 사용 불가능하여 알림을 표시할 수 없음');
      return;
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'match_channel',
      '매칭 알림',
      channelDescription: '새로운 매칭 알림',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFEF476F),
      icon: '@drawable/ic_stat_hearty',
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
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload ?? 'daily_match',
    );

    debugPrint('💕 매칭 알림 직접 표시됨: $title');
  }

  // 받은 LIKE 알림을 직접 표시하는 공개 메서드
  Future<void> showReceivedLikeNotification({
    required String senderName,
    String? customTitle,
    String? customBody,
  }) async {
    if (!isFirebaseAvailable) {
      debugPrint('⚠️ Firebase가 사용 불가능하여 알림을 표시할 수 없음');
      return;
    }

    final title = customTitle ?? '💕 누군가 당신을 좋아해요!';
    final body = customBody ?? '$senderName님이 당신에게 관심을 표했어요';

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'like_channel',
      '좋아요 알림',
      channelDescription: '받은 좋아요 알림',
      importance: Importance.high,
      priority: Priority.high,
      color: Color(0xFFEF476F),
      icon: '@drawable/ic_stat_hearty',
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
      DateTime.now().millisecondsSinceEpoch ~/ 1000 + 10,
      title,
      body,
      details,
      payload: 'received_like',
    );

    debugPrint('💕 받은 LIKE 알림 직접 표시됨: $title');
  }

  // 상호 매칭 알림을 직접 표시하는 공개 메서드
  Future<void> showMutualMatchNotification({
    required String matchedUserName,
    String? chatRoomId,
    String? customTitle,
    String? customBody,
  }) async {
    if (!isFirebaseAvailable) {
      debugPrint('⚠️ Firebase가 사용 불가능하여 알림을 표시할 수 없음');
      return;
    }

    final title = customTitle ?? '🎉 매칭 성공!';
    final body = customBody ?? '$matchedUserName님과 매칭되었어요! 대화를 시작해보세요';

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'mutual_match_channel',
      '매칭 성공 알림',
      channelDescription: '상호 매칭 성공 알림',
      importance: Importance.max,
      priority: Priority.max,
      color: Color(0xFFEF476F),
      icon: '@drawable/ic_stat_hearty',
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
      DateTime.now().millisecondsSinceEpoch ~/ 1000 + 20,
      title,
      body,
      details,
      payload: chatRoomId != null ? 'chat_$chatRoomId' : 'mutual_match',
    );

    debugPrint('🎉 상호 매칭 알림 직접 표시됨: $title');
  }
}