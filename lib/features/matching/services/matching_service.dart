import 'package:flutter/material.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/table_names.dart';
import '../../../core/services/storage_service.dart';

class MatchingService with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService.instance;
  final StorageService _storageService = StorageService.instance;

  // Get daily recommendations for current user
  Future<List<Map<String, dynamic>>> getDailyRecommendations() async {
    if (!_supabaseService.isAuthenticated) {
      throw Exception('User not authenticated');
    }

    try {
      final currentUserId = _supabaseService.currentUser!.id;
      final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD

      // Check if user already has recommendations for today
      final existingRecommendations = await _supabaseService
          .from(TableNames.dailyRecommendations)
          .select('*')
          .eq('user_id', currentUserId)
          .eq('date', today);

      if (existingRecommendations.isNotEmpty) {
        // Return existing recommendations
        return await _getRecommendationDetails(existingRecommendations);
      }

      // Generate new recommendations for today
      final recommendations = await _generateDailyRecommendations(currentUserId, today);
      return recommendations;
    } catch (e) {
      debugPrint('Error getting daily recommendations: $e');

      // 테이블이 없는 경우 친화적인 메시지로 변경
      if (e.toString().contains('does not exist') || e.toString().contains('relation') || e.toString().contains('table')) {
        throw Exception('데이터베이스 테이블이 설정되지 않았습니다. 관리자에게 문의하세요.');
      }

      rethrow;
    }
  }

  // Generate new daily recommendations
  Future<List<Map<String, dynamic>>> _generateDailyRecommendations(
    String userId,
    String date
  ) async {
    try {
      debugPrint('=== GENERATING RECOMMENDATIONS DEBUG ===');
      debugPrint('User ID: $userId');
      debugPrint('Date: $date');

      // Get current user's profile
      final userProfile = await _supabaseService
          .from(TableNames.users)
          .select()
          .eq('id', userId)
          .single();

      debugPrint('Current user profile: $userProfile');

      // Get current user's gender for opposite gender filtering
      final currentUserGender = userProfile['gender'] as String?;
      if (currentUserGender == null) {
        throw Exception('사용자의 성별 정보가 없습니다. 프로필을 다시 설정해주세요.');
      }
      final targetGender = currentUserGender == 'male' ? 'female' : 'male';
      debugPrint('Current user gender: $currentUserGender, Target gender: $targetGender');

      // Debug: 각 조건을 단계별로 테스트
      debugPrint('Testing each query condition...');

      // 1. 전체 사용자 수 (RLS 정책 확인용)
      final allUsers = await _supabaseService
          .from(TableNames.users)
          .select();
      debugPrint('Total users in table: ${allUsers.length}');
      debugPrint('All users query result: $allUsers');

      // 2. approved 사용자 수
      final approvedUsers = await _supabaseService
          .from(TableNames.users)
          .select()
          .eq('approval_status', AppConstants.approvalApproved);
      debugPrint('Approved users count: ${approvedUsers.length}');
      debugPrint('Approved users: ${approvedUsers.map((u) => '${u["nickname"]} (${u["approval_status"]})')}');

      // 3. 한국 사용자 중 approved
      final krApprovedUsers = await _supabaseService
          .from(TableNames.users)
          .select()
          .eq('approval_status', AppConstants.approvalApproved)
          .eq('country', 'KR');
      debugPrint('KR + Approved users count: ${krApprovedUsers.length}');

      // 4. 현재 사용자가 테이블에 존재하는지 확인
      final currentUserExists = await _supabaseService
          .from(TableNames.users)
          .select()
          .eq('id', userId);
      debugPrint('Current user exists in table: ${currentUserExists.isNotEmpty}');
      debugPrint('Current user data: $currentUserExists');

      // 5. 최종 조건 (현재 사용자 제외, 이성만 포함)
      final potentialMatches = await _supabaseService
          .from(TableNames.users)
          .select()
          .eq('approval_status', AppConstants.approvalApproved)
          .eq('country', 'KR')
          .eq('gender', targetGender)
          .neq('id', userId);

      debugPrint('Final potential matches count: ${potentialMatches.length}');
      debugPrint('Potential matches: $potentialMatches');

      if (potentialMatches.isEmpty) {
        return [];
      }

      // Filter out users already seen/matched
      final filteredMatches = await _filterAlreadySeenUsers(userId, potentialMatches);

      if (filteredMatches.isEmpty) {
        return [];
      }

      // Select random 2 users for daily recommendations
      filteredMatches.shuffle();
      final selectedMatches = filteredMatches.take(AppConstants.dailyRecommendationLimit).toList();

      // Save recommendations to database
      final recommendationsToSave = selectedMatches.map((match) => {
        'user_id': userId,
        'recommended_user_id': match['id'],
        'date': date,
        'created_at': DateTime.now().toIso8601String(),
      }).toList();

      await _supabaseService
          .from(TableNames.dailyRecommendations)
          .insert(recommendationsToSave);

      return selectedMatches;
    } catch (e) {
      debugPrint('Error generating daily recommendations: $e');
      rethrow;
    }
  }

  // Filter out users already seen or matched
  Future<List<Map<String, dynamic>>> _filterAlreadySeenUsers(
    String userId,
    List<Map<String, dynamic>> potentialMatches,
  ) async {
    try {
      debugPrint('Filtering already seen users...');

      // Get all user IDs that have been seen before
      final seenUsers = await _supabaseService
          .from(TableNames.dailyRecommendations)
          .select('recommended_user_id')
          .eq('user_id', userId);

      debugPrint('Seen users: $seenUsers');

      final seenUserIds = seenUsers.map((seen) => seen['recommended_user_id'] as String).toSet();

      // Get all user IDs that have been matched
      final matches = await _supabaseService
          .from(TableNames.matches)
          .select('user1_id, user2_id')
          .or('user1_id.eq.$userId,user2_id.eq.$userId');

      debugPrint('Matches: $matches');

      final matchedUserIds = <String>{};
      for (final match in matches) {
        if (match['user1_id'] == userId) {
          matchedUserIds.add(match['user2_id']);
        } else {
          matchedUserIds.add(match['user1_id']);
        }
      }

      debugPrint('Seen user IDs: $seenUserIds');
      debugPrint('Matched user IDs: $matchedUserIds');

      // Filter out seen and matched users
      final filteredMatches = potentialMatches.where((user) {
        final userIdToCheck = user['id'] as String;
        final isNotSeen = !seenUserIds.contains(userIdToCheck);
        final isNotMatched = !matchedUserIds.contains(userIdToCheck);
        debugPrint('User ${user['nickname']} ($userIdToCheck): notSeen=$isNotSeen, notMatched=$isNotMatched');
        return isNotSeen && isNotMatched;
      }).toList();

      debugPrint('Filtered matches count: ${filteredMatches.length}');
      return filteredMatches;
    } catch (e) {
      debugPrint('Error filtering seen users: $e');
      return potentialMatches; // Return all if filtering fails
    }
  }

  // Get detailed information for recommendations
  Future<List<Map<String, dynamic>>> _getRecommendationDetails(
    List<Map<String, dynamic>> recommendations
  ) async {
    try {
      final userIds = recommendations.map((rec) => rec['recommended_user_id'] as String).toList();

      final users = await _supabaseService
          .from(TableNames.users)
          .select()
          .inFilter('id', userIds);

      return users;
    } catch (e) {
      debugPrint('Error getting recommendation details: $e');
      rethrow;
    }
  }

  // Record user action (like/pass)
  Future<void> recordUserAction({
    required String targetUserId,
    required String action, // 'like' or 'pass'
  }) async {
    if (!_supabaseService.isAuthenticated) {
      throw Exception('User not authenticated');
    }

    try {
      final currentUserId = _supabaseService.currentUser!.id;

      // Save the action
      await _supabaseService.from(TableNames.userActions).insert({
        'user_id': currentUserId,
        'target_user_id': targetUserId,
        'action': action,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Check if this creates a match (both users liked each other)
      if (action == AppConstants.actionLike) {
        await _checkForMatch(currentUserId, targetUserId);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error recording user action: $e');
      rethrow;
    }
  }

  // Check if two users matched
  Future<void> _checkForMatch(String userId1, String userId2) async {
    try {
      // Check if the target user also liked this user
      final reciprocalLike = await _supabaseService
          .from(TableNames.userActions)
          .select()
          .eq('user_id', userId2)
          .eq('target_user_id', userId1)
          .eq('action', AppConstants.actionLike);

      if (reciprocalLike.isNotEmpty) {
        // It's a match! Create match record
        await _supabaseService.from(TableNames.matches).insert({
          'user1_id': userId1,
          'user2_id': userId2,
          'created_at': DateTime.now().toIso8601String(),
        });

        debugPrint('Match created between $userId1 and $userId2');
      }
    } catch (e) {
      debugPrint('Error checking for match: $e');
    }
  }

  // Get user's profile images
  List<String> getUserImages(Map<String, dynamic> user) {
    return _storageService.getImageUrlsFromProfile(user);
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
}