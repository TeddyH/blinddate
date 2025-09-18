class TableNames {
  static const String prefix = 'blinddate_';

  // Main Tables
  static const String users = '${prefix}users';
  static const String userProfiles = '${prefix}user_profiles';
  static const String matches = '${prefix}matches';
  static const String dailyRecommendations = '${prefix}daily_recommendations';
  static const String userActions = '${prefix}user_actions';
  static const String messages = '${prefix}messages';
  static const String adminActions = '${prefix}admin_actions';

  // Scheduled Matching Tables
  static const String scheduledMatches = '${prefix}scheduled_matches';
  static const String dailyMatchProcessing = '${prefix}daily_match_processing';
  static const String userMatchPreferences = '${prefix}user_match_preferences';
  static const String matchInteractions = '${prefix}match_interactions';

  // Storage Buckets
  static const String profileImagesBucket = 'blinddate-profile-images';
}