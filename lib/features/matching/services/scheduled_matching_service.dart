import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/constants/table_names.dart';
import '../../chat/services/chat_service.dart';

class ScheduledMatch {
  final String id;
  final String user1Id;
  final String user2Id;
  final DateTime matchDate;
  final DateTime expiresAt;
  final String status;
  final Map<String, dynamic> user1Profile;
  final Map<String, dynamic> user2Profile;
  final bool receivedLike;
  final bool sentLike;

  ScheduledMatch({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.matchDate,
    required this.expiresAt,
    required this.status,
    required this.user1Profile,
    required this.user2Profile,
    this.receivedLike = false,
    this.sentLike = false,
  });

  factory ScheduledMatch.fromJson(Map<String, dynamic> json, {bool receivedLike = false, bool sentLike = false}) {
    return ScheduledMatch(
      id: json['id'],
      user1Id: json['user1_id'],
      user2Id: json['user2_id'],
      matchDate: DateTime.parse(json['match_date']),
      expiresAt: DateTime.parse(json['expires_at']),
      status: json['status'],
      user1Profile: json['user1_profile'] ?? {},
      user2Profile: json['user2_profile'] ?? {},
      receivedLike: receivedLike,
      sentLike: sentLike,
    );
  }

  Map<String, dynamic> get otherUserProfile {
    final currentUserId = SupabaseService.instance.currentUser?.id;
    if (currentUserId == user1Id) {
      return user2Profile;
    } else {
      return user1Profile;
    }
  }

  String get otherUserId {
    final currentUserId = SupabaseService.instance.currentUser?.id;
    return currentUserId == user1Id ? user2Id : user1Id;
  }

  bool get isRevealed => status == 'revealed';
  bool get isPending => status == 'pending';
  bool get isExpired => status == 'expired' || DateTime.now().isAfter(expiresAt);
}

class ScheduledMatchingService extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService.instance;

  List<ScheduledMatch> _todaysMatches = [];
  List<ScheduledMatch> get todaysMatches => _todaysMatches;

  List<ScheduledMatch> _pastMatches = [];
  List<ScheduledMatch> get pastMatches => _pastMatches;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // 알림 전송한 매칭 ID들 저장 (중복 방지)
  final Set<String> _notifiedMatchIds = {};

  // 중복 LIKE 알림 방지
  final Set<String> _sentLikeNotifications = {};

  // 중복 상호 매칭 알림 방지
  final Set<String> _sentMutualMatchNotifications = {};

  // Get today's matches for the current user
  Future<List<ScheduledMatch>> getTodaysMatches() async {
    try {
      _setLoading(true);
      _clearError();

      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();
      // If it's before noon, show yesterday's matches. If after noon, show today's matches.
      final currentHour = now.hour;
      final targetDate = currentHour < 12 ? now.subtract(const Duration(days: 1)) : now;

      final startOfTargetDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
      final endOfTargetDay = startOfTargetDay.add(const Duration(days: 1));

      debugPrint('Fetching matches for user $userId from ${startOfTargetDay.toIso8601String()} to ${endOfTargetDay.toIso8601String()}');

      // Get scheduled matches for the target day
      final response = await _supabaseService
          .from(TableNames.scheduledMatches)
          .select('*')
          .or('user1_id.eq.$userId,user2_id.eq.$userId')
          .gte('match_date', startOfTargetDay.toIso8601String().split('T')[0])
          .lt('match_date', endOfTargetDay.toIso8601String().split('T')[0])
          .order('created_at', ascending: false);

      debugPrint('Scheduled matches response: $response');

      if ((response as List).isEmpty) {
        _todaysMatches = [];
        notifyListeners();
        return [];
      }

      // Fetch profile data for each match
      final List<ScheduledMatch> matches = [];

      for (final json in response as List) {
        final user1Id = json['user1_id'];
        final user2Id = json['user2_id'];

        // Fetch user profiles
        final user1Response = await _supabaseService
            .from(TableNames.users)
            .select()
            .eq('id', user1Id)
            .single();

        final user2Response = await _supabaseService
            .from(TableNames.users)
            .select()
            .eq('id', user2Id)
            .single();

        // Check if the other user has liked me and if I have liked them
        final otherUserId = userId == user1Id ? user2Id : user1Id;
        final receivedLike = await hasReceivedLikeFromUser(otherUserId);
        final sentLike = await hasSentLikeToUser(otherUserId);

        matches.add(ScheduledMatch(
          id: json['id'],
          user1Id: user1Id,
          user2Id: user2Id,
          matchDate: DateTime.parse(json['match_date']),
          expiresAt: DateTime.parse(json['expires_at']),
          status: json['status'],
          user1Profile: user1Response,
          user2Profile: user2Response,
          receivedLike: receivedLike,
          sentLike: sentLike,
        ));
      }

      _todaysMatches = matches;
      notifyListeners();

      return matches;
    } catch (e) {
      debugPrint('Error fetching today\'s matches: $e');
      _setError('매칭 정보를 불러오는 중 오류가 발생했습니다: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }


  // Check if there are any matches ready to be revealed
  Future<List<ScheduledMatch>> checkForRevealedMatches() async {
    // Since all matches are now created as 'revealed', this function is no longer needed
    // Just refresh the matches list
    await getTodaysMatches();
    return _todaysMatches;
  }

  // Record user interaction with a match
  Future<void> recordMatchInteraction({
    required String matchId,
    required String action, // 'viewed', 'like', 'pass', 'chatted'
  }) async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get match info to find target user
      final matchResponse = await _supabaseService
          .from(TableNames.scheduledMatches)
          .select('user1_id, user2_id')
          .eq('id', matchId)
          .single();

      final user1Id = matchResponse['user1_id'];
      final user2Id = matchResponse['user2_id'];
      final targetUserId = userId == user1Id ? user2Id : user1Id;

      debugPrint('recordMatchInteraction: Recording $action from $userId to $targetUserId for match $matchId');

      await _supabaseService.from(TableNames.userActions).upsert({
        'user_id': userId,
        'target_user_id': targetUserId,
        'action': action,
      });

      debugPrint('recordMatchInteraction: Successfully recorded $action');

      // If both users liked, update match status
      if (action == 'like') {
        debugPrint('recordMatchInteraction: Like recorded, checking for mutual like...');
        await _checkForMutualLike(matchId);

        // 상대방에게 LIKE 받았다는 알림 보내기
        await _sendLikeNotificationToTargetUser(targetUserId, userId);
      }

      debugPrint('recordMatchInteraction: Interaction recording completed');
    } catch (e) {
      debugPrint('Error recording match interaction: $e');
      throw Exception('상호작용 기록 중 오류가 발생했습니다: $e');
    }
  }

  // Check if both users liked each other
  Future<void> _checkForMutualLike(String matchId) async {
    try {
      debugPrint('_checkForMutualLike: Checking mutual like for match $matchId');

      // Get the match details
      final matchResponse = await _supabaseService
          .from(TableNames.scheduledMatches)
          .select('user1_id, user2_id')
          .eq('id', matchId)
          .single();

      final user1Id = matchResponse['user1_id'];
      final user2Id = matchResponse['user2_id'];

      debugPrint('_checkForMutualLike: user1Id=$user1Id, user2Id=$user2Id');

      // Check if both users have liked each other
      final user1LikedUser2 = await _supabaseService
          .from(TableNames.userActions)
          .select('id')
          .eq('user_id', user1Id)
          .eq('target_user_id', user2Id)
          .eq('action', 'like');

      final user2LikedUser1 = await _supabaseService
          .from(TableNames.userActions)
          .select('id')
          .eq('user_id', user2Id)
          .eq('target_user_id', user1Id)
          .eq('action', 'like');

      debugPrint('_checkForMutualLike: user1LikedUser2=${user1LikedUser2.length}, user2LikedUser1=${user2LikedUser1.length}');

      // If both users liked each other, update match status to mutual_like
      if ((user1LikedUser2 as List).isNotEmpty && (user2LikedUser1 as List).isNotEmpty) {
        debugPrint('_checkForMutualLike: Mutual like detected! Updating match status to mutual_like');

        final updateResult = await _supabaseService
            .from(TableNames.scheduledMatches)
            .update({'status': 'mutual_like'})
            .eq('id', matchId)
            .select();

        debugPrint('_checkForMutualLike: Update result: $updateResult');

        // Verify the update by fetching the specific match
        final verifyResult = await _supabaseService
            .from(TableNames.scheduledMatches)
            .select('status')
            .eq('id', matchId)
            .single();

        debugPrint('_checkForMutualLike: Verification result: $verifyResult');

        // Create chat room for the matched users
        String? chatRoomId;
        try {
          final chatService = ChatService();
          final chatRoom = await chatService.createOrGetChatRoom(matchId, user1Id, user2Id);
          if (chatRoom != null) {
            chatRoomId = chatRoom.id;
            debugPrint('_checkForMutualLike: Chat room created/found: ${chatRoom.id}');
          } else {
            debugPrint('_checkForMutualLike: Failed to create chat room');
          }
        } catch (chatError) {
          debugPrint('_checkForMutualLike: Error creating chat room: $chatError');
          // Don't throw error here as match is still successful
        }

        // 상호 매칭 성공 알림 보내기
        await _sendMutualMatchNotification(user1Id, user2Id, chatRoomId);

        // Refresh local cache
        await getTodaysMatches();
        debugPrint('_checkForMutualLike: Local cache refreshed');
      } else {
        debugPrint('_checkForMutualLike: No mutual like detected yet');
      }
    } catch (e) {
      debugPrint('Error checking for mutual like: $e');
    }
  }

  // Calculate time until next reveal (noon KST)
  Duration getTimeUntilNextReveal() {
    final now = DateTime.now(); // This is local time in Korea (KST)

    var nextReveal = DateTime(now.year, now.month, now.day, 12, 0); // Noon KST

    // If we're past noon today, next reveal is tomorrow noon
    if (now.isAfter(nextReveal)) {
      nextReveal = nextReveal.add(const Duration(days: 1));
    }

    return nextReveal.difference(now);
  }

  // Check if current time is during reveal window (noon KST)
  bool isRevealTime() {
    final now = DateTime.now(); // This is local time in Korea (KST)

    // Reveal window: 12:00 PM to 11:59 PM KST
    final noonToday = DateTime(now.year, now.month, now.day, 12, 0);
    final midnightTonight = DateTime(now.year, now.month, now.day + 1, 0, 0);

    return now.isAfter(noonToday) && now.isBefore(midnightTonight);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    // Use addPostFrameCallback to avoid setState during build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void _setError(String error) {
    _errorMessage = error;
    // Use addPostFrameCallback to avoid setState during build
    SchedulerBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Utility functions moved from MatchingService

  // Get user's profile images
  List<String> getUserImages(Map<String, dynamic> user) {
    final imageUrls = user['profile_image_urls'];
    if (imageUrls == null) return [];

    if (imageUrls is List) {
      final urls = imageUrls.cast<String>();
      // Filter out known broken URLs
      return urls.where((url) {
        // Filter out the broken default avatar URL
        if (url.contains('default-avatar.png')) {
          return false;
        }
        // Filter out any obviously invalid URLs
        if (url.isEmpty || !url.startsWith('http')) {
          return false;
        }
        return true;
      }).toList();
    }

    return [];
  }

  // Calculate age from birth date
  int calculateAge(String birthDateString) {
    try {
      final birthDate = DateTime.parse(birthDateString);
      final today = DateTime.now();
      int age = today.year - birthDate.year;

      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }

      return age;
    } catch (e) {
      return 25; // Default age if parsing fails
    }
  }

  // Get past matches for the current user (recent week only, excluding today)
  Future<List<ScheduledMatch>> getPastMatches({int limit = 50}) async {
    try {
      _setLoading(true);
      _clearError();

      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final now = DateTime.now();
      final currentHour = now.hour;

      // Apply same logic as getTodaysMatches: exclude current target date from history
      // If it's before noon, target date is yesterday (exclude yesterday from history)
      // If it's after noon, target date is today (exclude today from history)
      final currentTargetDate = currentHour < 12 ? now.subtract(const Duration(days: 1)) : now;
      final endOfHistory = DateTime(currentTargetDate.year, currentTargetDate.month, currentTargetDate.day);
      final oneWeekAgo = endOfHistory.subtract(const Duration(days: 7));

      debugPrint('Fetching past matches for user $userId from ${oneWeekAgo.toIso8601String()} to ${endOfHistory.toIso8601String()}');

      // Get scheduled matches from last week up to the history cutoff (excluding current target date)
      final response = await _supabaseService
          .from(TableNames.scheduledMatches)
          .select('*')
          .or('user1_id.eq.$userId,user2_id.eq.$userId')
          .gte('match_date', oneWeekAgo.toIso8601String().split('T')[0])
          .lt('match_date', endOfHistory.toIso8601String().split('T')[0])
          .order('match_date', ascending: false)
          .limit(limit);

      debugPrint('Past matches response: $response');

      if ((response as List).isEmpty) {
        _pastMatches = [];
        notifyListeners();
        return [];
      }

      // Fetch profile data for each match
      final List<ScheduledMatch> matches = [];

      for (final json in response as List) {
        final user1Id = json['user1_id'];
        final user2Id = json['user2_id'];

        // Fetch user profiles
        final user1Response = await _supabaseService
            .from(TableNames.users)
            .select()
            .eq('id', user1Id)
            .single();

        final user2Response = await _supabaseService
            .from(TableNames.users)
            .select()
            .eq('id', user2Id)
            .single();

        matches.add(ScheduledMatch(
          id: json['id'],
          user1Id: user1Id,
          user2Id: user2Id,
          matchDate: DateTime.parse(json['match_date']),
          expiresAt: DateTime.parse(json['expires_at']),
          status: json['status'],
          user1Profile: user1Response,
          user2Profile: user2Response,
        ));
      }

      _pastMatches = matches;
      notifyListeners();

      return matches;
    } catch (e) {
      debugPrint('Error fetching past matches: $e');
      _setError('최근 일주일 매칭 기록을 불러오는 중 오류가 발생했습니다: $e');
      return [];
    } finally {
      _setLoading(false);
    }
  }

  // Check if current user has sent a like to target user
  Future<bool> hasSentLikeToUser(String targetUserId) async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        return false;
      }

      try {
        final response = await _supabaseService.client.rpc('check_sent_like', params: {
          'current_user_id': userId,
          'target_user_id': targetUserId,
        });

        return response == true;
      } catch (e) {
        // RPC가 없으면 직접 쿼리 시도
        try {
          final response = await _supabaseService
              .from(TableNames.userActions)
              .select('id')
              .eq('user_id', userId)           // 내가
              .eq('target_user_id', targetUserId)  // 상대방에게
              .eq('action', 'like')            // 좋아요를 보냄
              .maybeSingle();

          return response != null;
        } catch (e2) {
          debugPrint('Error checking sent like: $e2');
          return false;
        }
      }
    } catch (e) {
      debugPrint('Error checking sent like: $e');
      return false;
    }
  }

  // Check if current user has received a like from target user
  Future<bool> hasReceivedLikeFromUser(String targetUserId) async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        debugPrint('hasReceivedLikeFromUser: current user is null');
        return false;
      }

      // RLS 정책 문제로 인해 직접 쿼리가 안 되므로, 함수나 RPC를 사용
      try {
        final response = await _supabaseService.client.rpc('check_received_like', params: {
          'current_user_id': userId,
          'target_user_id': targetUserId,
        });

        return response == true;
      } catch (e) {
        // RPC가 없으면 직접 쿼리 시도
        try {
          final response = await _supabaseService
              .from(TableNames.userActions)
              .select('id')
              .eq('user_id', targetUserId)
              .eq('target_user_id', userId)
              .eq('action', 'like')
              .maybeSingle();

          return response != null;
        } catch (e2) {
          debugPrint('Error checking received like: $e2');
          return false;
        }
      }
    } catch (e) {
      debugPrint('Error checking received like: $e');
      return false;
    }
  }

  // Send push notification for daily matches
  Future<void> sendDailyMatchNotification() async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) return;

      debugPrint('🔔 매일 매칭 알림 전송 시작');

      // 오늘의 매칭이 있는지 확인
      final matches = await getTodaysMatches();
      if (matches.isEmpty) {
        debugPrint('📭 오늘의 매칭이 없어서 알림을 보내지 않음');
        return;
      }

      // Supabase Edge Function을 호출하여 푸시 알림 전송
      try {
        await _supabaseService.client.functions.invoke(
          'send-daily-match-notification',
          body: {
            'userId': userId,
            'matchCount': matches.length,
          },
        );
        debugPrint('✅ 매일 매칭 알림 전송 완료');
      } catch (e) {
        debugPrint('❌ 매일 매칭 알림 전송 실패: $e');

        // Fallback: 로컬 알림으로 대체
        final notificationService = NotificationService.instance;
        if (await notificationService.isNotificationEnabled()) {
          // 임시로 로컬 알림 생성 (실제로는 FCM을 통해 보내야 함)
          debugPrint('🔄 로컬 알림으로 fallback');
        }
      }
    } catch (e) {
      debugPrint('❌ 매일 매칭 알림 처리 오류: $e');
    }
  }

  // Check for new matches and send notifications (anytime)
  Future<void> checkAndNotifyNewMatches() async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) return;

      // 시간 제한 없이 새로운 매칭 확인
      final matches = await getTodaysMatches();

      // 아직 알림을 보내지 않은 새로운 매칭만 필터링
      final newMatches = matches.where((match) => !_notifiedMatchIds.contains(match.id)).toList();

      if (newMatches.isNotEmpty) {
        debugPrint('💕 새로운 매칭 ${newMatches.length}개 발견, 알림 전송 (시간: ${DateTime.now()})');

        // 매칭별로 개별 알림 전송 (더 정확한 알림)
        for (final match in newMatches) {
          await _sendNotificationForMatch(match);
          _notifiedMatchIds.add(match.id);
        }
      } else {
        debugPrint('📭 새로운 매칭이 없거나 이미 알림 전송됨');
      }
    } catch (e) {
      debugPrint('❌ 새 매칭 확인 및 알림 오류: $e');
    }
  }

  // Send notification for a specific match
  Future<void> _sendNotificationForMatch(ScheduledMatch match) async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) return;

      // Supabase Edge Function을 호출하여 개별 매칭 알림 전송
      try {
        await _supabaseService.client.functions.invoke(
          'send-daily-match-notification',
          body: {
            'userId': userId,
            'matchId': match.id,
            'matchData': {
              'otherUser': match.otherUserProfile,
            },
          },
        );
        debugPrint('✅ 매칭 ${match.id} 알림 전송 완료 (Edge Function)');
      } catch (e) {
        debugPrint('❌ 매칭 ${match.id} Edge Function 알림 전송 실패: $e');

        // Fallback: 로컬 알림으로 대체
        await _sendLocalMatchNotification(match);
      }
    } catch (e) {
      debugPrint('❌ 개별 매칭 알림 처리 오류: $e');
    }
  }

  // Send local notification as fallback
  Future<void> _sendLocalMatchNotification(ScheduledMatch match) async {
    try {
      final notificationService = NotificationService.instance;

      // 알림 권한이 있는지 확인
      if (!await notificationService.isNotificationEnabled()) {
        debugPrint('⚠️ 알림 권한이 없어서 로컬 알림을 보낼 수 없음');
        return;
      }

      // 상대방 이름 가져오기
      final otherUser = match.otherUserProfile;
      final otherUserName = otherUser['nickname'] ?? '새로운 인연';

      // NotificationService의 public 메서드 사용
      await notificationService.showMatchNotificationDirect(
        title: '💕 새로운 인연이 도착했어요!',
        body: '$otherUserName님과의 새로운 매칭을 확인해보세요',
        payload: 'daily_match',
      );

      debugPrint('✅ 매칭 ${match.id} 로컬 알림 전송 완료 (Fallback)');
    } catch (e) {
      debugPrint('❌ 로컬 매칭 알림 전송 실패: $e');
    }
  }

  // 상대방에게 LIKE 받았다는 알림 보내기
  Future<void> _sendLikeNotificationToTargetUser(String targetUserId, String senderUserId) async {
    try {
      // 중복 알림 방지
      final notificationKey = '${senderUserId}_$targetUserId';
      if (_sentLikeNotifications.contains(notificationKey)) {
        debugPrint('⚠️ 이미 전송한 LIKE 알림: $notificationKey');
        return;
      }

      debugPrint('💕 LIKE 알림 전송 시작: $senderUserId -> $targetUserId');

      // 발신자 프로필 조회
      final senderProfile = await _supabaseService
          .from(TableNames.users)
          .select('nickname')
          .eq('id', senderUserId)
          .maybeSingle();

      final senderName = senderProfile?['nickname'] ?? '누군가';

      // 수신자 프로필 조회 (FCM 토큰 확인)
      final targetProfile = await _supabaseService
          .from(TableNames.users)
          .select('fcm_token, nickname')
          .eq('id', targetUserId)
          .maybeSingle();

      if (targetProfile == null || targetProfile['fcm_token'] == null) {
        debugPrint('❌ 수신자의 FCM 토큰을 찾을 수 없음: $targetUserId');
        return;
      }

      // Supabase Edge Function으로 푸시 알림 전송
      try {
        await _supabaseService.client.functions.invoke(
          'send-like-notification',
          body: {
            'targetUserId': targetUserId,
            'targetToken': targetProfile['fcm_token'],
            'senderUserId': senderUserId,
            'senderName': senderName,
          },
        );
        debugPrint('✅ LIKE 푸시 알림 전송 성공 (Edge Function)');

        // 성공적으로 전송했으므로 키 추가
        _sentLikeNotifications.add(notificationKey);

        // Set 크기 제한 (메모리 누수 방지)
        if (_sentLikeNotifications.length > 50) {
          final firstKey = _sentLikeNotifications.first;
          _sentLikeNotifications.remove(firstKey);
        }
      } catch (e) {
        debugPrint('❌ LIKE 푸시 알림 전송 실패: $e');

        // Fallback: 로컬 알림 (현재 사용자가 수신자인 경우에만)
        final currentUserId = _supabaseService.currentUser?.id;
        if (currentUserId == targetUserId) {
          final notificationService = NotificationService.instance;
          await notificationService.showReceivedLikeNotification(
            senderName: senderName,
          );
          debugPrint('✅ LIKE 로컬 알림 전송 완료 (Fallback)');
        } else {
          debugPrint('⚠️ 현재 사용자($currentUserId)는 수신자($targetUserId)가 아니므로 로컬 알림 생략');
        }
      }
    } catch (e) {
      debugPrint('❌ LIKE 알림 전송 오류: $e');
    }
  }

  // 상호 매칭 성공 알림 보내기
  Future<void> _sendMutualMatchNotification(String user1Id, String user2Id, String? chatRoomId) async {
    try {
      // 중복 알림 방지 (user ID 정렬해서 순서 상관없이 동일한 키 생성)
      final List<String> sortedUserIds = [user1Id, user2Id]..sort();
      final notificationKey = '${sortedUserIds[0]}_${sortedUserIds[1]}';
      if (_sentMutualMatchNotifications.contains(notificationKey)) {
        debugPrint('⚠️ 이미 전송한 상호 매칭 알림: $notificationKey');
        return;
      }

      debugPrint('🎉 상호 매칭 알림 전송 시작: $user1Id <-> $user2Id');

      // 두 사용자의 프로필 조회
      final user1Profile = await _supabaseService
          .from(TableNames.users)
          .select('fcm_token, nickname')
          .eq('id', user1Id)
          .maybeSingle();

      final user2Profile = await _supabaseService
          .from(TableNames.users)
          .select('fcm_token, nickname')
          .eq('id', user2Id)
          .maybeSingle();

      final user1Name = user1Profile?['nickname'] ?? '상대방';
      final user2Name = user2Profile?['nickname'] ?? '상대방';

      // user1에게 알림 보내기
      if (user1Profile != null && user1Profile['fcm_token'] != null) {
        try {
          await _supabaseService.client.functions.invoke(
            'send-mutual-match-notification',
            body: {
              'targetUserId': user1Id,
              'targetToken': user1Profile['fcm_token'],
              'matchedUserId': user2Id,
              'matchedUserName': user2Name,
              'chatRoomId': chatRoomId,
            },
          );
          debugPrint('✅ user1 상호 매칭 푸시 알림 전송 성공');
        } catch (e) {
          debugPrint('❌ user1 상호 매칭 푸시 알림 전송 실패: $e');

          // Fallback: 로컬 알림 (현재 사용자가 user1인 경우에만)
          final currentUserId = _supabaseService.currentUser?.id;
          if (currentUserId == user1Id) {
            final notificationService = NotificationService.instance;
            await notificationService.showMutualMatchNotification(
              matchedUserName: user2Name,
              chatRoomId: chatRoomId,
            );
            debugPrint('✅ user1 상호 매칭 로컬 알림 전송 완료 (Fallback)');
          }
        }
      }

      // user2에게 알림 보내기
      if (user2Profile != null && user2Profile['fcm_token'] != null) {
        try {
          await _supabaseService.client.functions.invoke(
            'send-mutual-match-notification',
            body: {
              'targetUserId': user2Id,
              'targetToken': user2Profile['fcm_token'],
              'matchedUserId': user1Id,
              'matchedUserName': user1Name,
              'chatRoomId': chatRoomId,
            },
          );
          debugPrint('✅ user2 상호 매칭 푸시 알림 전송 성공');
        } catch (e) {
          debugPrint('❌ user2 상호 매칭 푸시 알림 전송 실패: $e');

          // Fallback: 로컬 알림 (현재 사용자가 user2인 경우에만)
          final currentUserId = _supabaseService.currentUser?.id;
          if (currentUserId == user2Id) {
            final notificationService = NotificationService.instance;
            await notificationService.showMutualMatchNotification(
              matchedUserName: user1Name,
              chatRoomId: chatRoomId,
            );
            debugPrint('✅ user2 상호 매칭 로컬 알림 전송 완료 (Fallback)');
          }
        }
      }

      // 성공적으로 처리했으므로 키 추가 (중복 방지)
      _sentMutualMatchNotifications.add(notificationKey);

      // Set 크기 제한 (메모리 누수 방지)
      if (_sentMutualMatchNotifications.length > 50) {
        final firstKey = _sentMutualMatchNotifications.first;
        _sentMutualMatchNotifications.remove(firstKey);
      }

      debugPrint('✅ 상호 매칭 알림 전송 완료 및 중복 방지 키 저장: $notificationKey');

    } catch (e) {
      debugPrint('❌ 상호 매칭 알림 전송 오류: $e');
    }
  }
}