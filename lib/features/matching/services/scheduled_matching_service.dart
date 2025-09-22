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

  ScheduledMatch({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.matchDate,
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

      final today = DateTime.now();
      final startOfToday = DateTime(today.year, today.month, today.day);
      final endOfToday = startOfToday.add(const Duration(days: 1));

      debugPrint('Fetching matches for user $userId from ${startOfToday.toIso8601String()} to ${endOfToday.toIso8601String()}');

      // Get scheduled matches for today only
      final response = await _supabaseService
          .from(TableNames.scheduledMatches)
          .select('*')
          .or('user1_id.eq.$userId,user2_id.eq.$userId')
          .gte('match_date', startOfToday.toIso8601String().split('T')[0])
          .lt('match_date', endOfToday.toIso8601String().split('T')[0])
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

      final today = DateTime.now();
      final startOfToday = DateTime(today.year, today.month, today.day);
      final oneWeekAgo = startOfToday.subtract(const Duration(days: 7));

      debugPrint('Fetching past matches for user $userId from ${oneWeekAgo.toIso8601String()} to ${startOfToday.toIso8601String()}');

      // Get scheduled matches from last week up to today (excluding today)
      final response = await _supabaseService
          .from(TableNames.scheduledMatches)
          .select('*')
          .or('user1_id.eq.$userId,user2_id.eq.$userId')
          .gte('match_date', oneWeekAgo.toIso8601String().split('T')[0])
          .lt('match_date', startOfToday.toIso8601String().split('T')[0])
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
}