import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/constants/table_names.dart';

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
    final now = DateTime.now();
    final koreaTimeZone = Duration(hours: 9); // KST is UTC+9
    final nowKST = now.add(koreaTimeZone);

    var nextReveal = DateTime(nowKST.year, nowKST.month, nowKST.day, 12, 0); // Noon KST

    // If we're past noon today, next reveal is tomorrow noon
    if (nowKST.isAfter(nextReveal)) {
      nextReveal = nextReveal.add(const Duration(days: 1));
    }

    final nextRevealUTC = nextReveal.subtract(koreaTimeZone);
    return nextRevealUTC.difference(now);
  }

  // Check if current time is during reveal window (noon KST)
  bool isRevealTime() {
    final now = DateTime.now();
    final koreaTimeZone = Duration(hours: 9);
    final nowKST = now.add(koreaTimeZone);

    // Reveal window: 12:00 PM to 11:59 PM KST
    final noonToday = DateTime(nowKST.year, nowKST.month, nowKST.day, 12, 0);
    final midnightTonight = DateTime(nowKST.year, nowKST.month, nowKST.day + 1, 0, 0);

    return nowKST.isAfter(noonToday) && nowKST.isBefore(midnightTonight);
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
}