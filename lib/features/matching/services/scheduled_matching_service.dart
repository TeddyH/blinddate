import 'package:flutter/foundation.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/constants/table_names.dart';
import '../../../core/constants/app_constants.dart';

class ScheduledMatch {
  final String id;
  final String user1Id;
  final String user2Id;
  final DateTime matchDate;
  final DateTime revealTime;
  final DateTime? revealedAt;
  final DateTime expiresAt;
  final String status;
  final Map<String, dynamic> user1Profile;
  final Map<String, dynamic> user2Profile;

  ScheduledMatch({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.matchDate,
    required this.revealTime,
    this.revealedAt,
    required this.expiresAt,
    required this.status,
    required this.user1Profile,
    required this.user2Profile,
  });

  factory ScheduledMatch.fromJson(Map<String, dynamic> json) {
    return ScheduledMatch(
      id: json['id'],
      user1Id: json['user1_id'],
      user2Id: json['user2_id'],
      matchDate: DateTime.parse(json['match_date']),
      revealTime: DateTime.parse(json['reveal_time']),
      revealedAt: json['revealed_at'] != null ? DateTime.parse(json['revealed_at']) : null,
      expiresAt: DateTime.parse(json['expires_at']),
      status: json['status'],
      user1Profile: json['user1_profile'] ?? {},
      user2Profile: json['user2_profile'] ?? {},
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

  bool get isRevealed => status == 'revealed' || revealedAt != null;
  bool get isPending => status == 'pending';
  bool get isExpired => status == 'expired' || DateTime.now().isAfter(expiresAt);
}

class ScheduledMatchingService extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService.instance;

  List<ScheduledMatch> _todaysMatches = [];
  List<ScheduledMatch> get todaysMatches => _todaysMatches;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Get recent matches for the current user (yesterday and today)
  Future<List<ScheduledMatch>> getTodaysMatches() async {
    try {
      _setLoading(true);
      _clearError();

      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final startOfYesterday = DateTime(yesterday.year, yesterday.month, yesterday.day);
      final endOfToday = DateTime(today.year, today.month, today.day).add(const Duration(days: 1));

      debugPrint('Fetching matches for user $userId from ${startOfYesterday.toIso8601String()} to ${endOfToday.toIso8601String()}');

      // Get scheduled matches for yesterday and today
      final response = await _supabaseService
          .from(TableNames.scheduledMatches)
          .select('*')
          .or('user1_id.eq.$userId,user2_id.eq.$userId')
          .gte('match_date', startOfYesterday.toIso8601String().split('T')[0])
          .lt('match_date', endOfToday.toIso8601String().split('T')[0])
          .order('reveal_time', ascending: false);

      debugPrint('Scheduled matches response: $response');

      if (response == null || (response as List).isEmpty) {
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

        matches.add(ScheduledMatch(
          id: json['id'],
          user1Id: user1Id,
          user2Id: user2Id,
          matchDate: DateTime.parse(json['match_date']),
          revealTime: DateTime.parse(json['reveal_time']),
          revealedAt: json['revealed_at'] != null ? DateTime.parse(json['revealed_at']) : null,
          expiresAt: DateTime.parse(json['expires_at']),
          status: json['status'],
          user1Profile: user1Response ?? {},
          user2Profile: user2Response ?? {},
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
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) return [];

      final now = DateTime.now();

      // Get matches that should be revealed but haven't been marked as revealed yet
      final response = await _supabaseService
          .from(TableNames.scheduledMatches)
          .select('*')
          .or('user1_id.eq.$userId,user2_id.eq.$userId')
          .eq('status', 'pending')
          .lte('reveal_time', now.toIso8601String());

      final revealedMatches = (response as List)
          .map((json) => ScheduledMatch(
            id: json['id'],
            user1Id: json['user1_id'],
            user2Id: json['user2_id'],
            matchDate: DateTime.parse(json['match_date']),
            revealTime: DateTime.parse(json['reveal_time']),
            revealedAt: json['revealed_at'] != null ? DateTime.parse(json['revealed_at']) : null,
            expiresAt: DateTime.parse(json['expires_at']),
            status: json['status'],
            user1Profile: {},
            user2Profile: {},
          ))
          .toList();

      // Update local cache
      if (revealedMatches.isNotEmpty) {
        await getTodaysMatches(); // Refresh the full list
      }

      return revealedMatches;
    } catch (e) {
      debugPrint('Error checking for revealed matches: $e');
      return [];
    }
  }

  // Record user interaction with a match
  Future<void> recordMatchInteraction({
    required String matchId,
    required String action, // 'viewed', 'liked', 'passed', 'chatted'
  }) async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabaseService.from(TableNames.matchInteractions).upsert({
        'scheduled_match_id': matchId,
        'user_id': userId,
        'action': action,
      });

      // If both users liked, update match status
      if (action == 'liked') {
        await _checkForMutualLike(matchId);
      }

      debugPrint('Recorded interaction: $action for match $matchId');
    } catch (e) {
      debugPrint('Error recording match interaction: $e');
      throw Exception('상호작용 기록 중 오류가 발생했습니다: $e');
    }
  }

  // Check if both users liked each other
  Future<void> _checkForMutualLike(String matchId) async {
    try {
      // Get the match details
      final matchResponse = await _supabaseService
          .from(TableNames.scheduledMatches)
          .select('user1_id, user2_id')
          .eq('id', matchId)
          .single();

      final user1Id = matchResponse['user1_id'];
      final user2Id = matchResponse['user2_id'];

      // Check if both users have liked
      final interactionsResponse = await _supabaseService
          .from(TableNames.matchInteractions)
          .select('user_id')
          .eq('scheduled_match_id', matchId)
          .eq('action', 'liked');

      final likedUsers = (interactionsResponse as List)
          .map((interaction) => interaction['user_id'] as String)
          .toSet();

      // If both users liked, update match status
      if (likedUsers.contains(user1Id) && likedUsers.contains(user2Id)) {
        await _supabaseService
            .from(TableNames.scheduledMatches)
            .update({'status': 'mutual_like'})
            .eq('id', matchId);

        debugPrint('Mutual like detected for match $matchId');

        // Refresh local cache
        await getTodaysMatches();
      }
    } catch (e) {
      debugPrint('Error checking for mutual like: $e');
    }
  }

  // Get user's match preferences
  Future<Map<String, dynamic>?> getUserMatchPreferences() async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) return null;

      final response = await _supabaseService
          .from(TableNames.userMatchPreferences)
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Error fetching user match preferences: $e');
      return null;
    }
  }

  // Update user's match preferences
  Future<void> updateUserMatchPreferences({
    int? minAge,
    int? maxAge,
    int? preferredDistanceKm,
    bool? notifyOnMatch,
    bool? active,
  }) async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final updates = <String, dynamic>{
        'user_id': userId,
      };

      if (minAge != null) updates['min_age'] = minAge;
      if (maxAge != null) updates['max_age'] = maxAge;
      if (preferredDistanceKm != null) updates['preferred_distance_km'] = preferredDistanceKm;
      if (notifyOnMatch != null) updates['notify_on_match'] = notifyOnMatch;
      if (active != null) updates['active'] = active;

      await _supabaseService
          .from(TableNames.userMatchPreferences)
          .upsert(updates);

      debugPrint('Updated match preferences for user $userId');
    } catch (e) {
      debugPrint('Error updating match preferences: $e');
      throw Exception('매칭 설정 업데이트 중 오류가 발생했습니다: $e');
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
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}