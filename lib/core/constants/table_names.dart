class TableNames {
  static const String prefix = 'blinddate_';

  // Main Tables
  static const String users = '${prefix}users';
  static const String matches = '${prefix}matches';
  static const String userActions = '${prefix}user_actions';
  static const String messages = '${prefix}messages';

  // Scheduled Matching Tables
  static const String scheduledMatches = '${prefix}scheduled_matches';
  static const String dailyMatchProcessing = '${prefix}daily_match_processing';
  static const String matchInteractions = '${prefix}match_interactions';

  // Chat Tables
  static const String chatRooms = '${prefix}chat_rooms';
  static const String chatMessages = '${prefix}chat_messages';

  // Storage Buckets
  static const String profileImagesBucket = 'blinddate-profile-images';
}