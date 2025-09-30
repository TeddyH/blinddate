import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // Supabase Configuration
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? 'YOUR_SUPABASE_URL';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? 'YOUR_SUPABASE_ANON_KEY';

  // App Configuration
  static const String appName = 'Hearty';
  static const String appVersion = '1.0.0';

  // Development Configuration
  static const bool isDevelopment = true;
  static const String testOtpCode = '123456'; // 개발용 고정 OTP

  // Matching Configuration
  static const int dailyRecommendationLimit = 1;
  static const int maxProfilePhotos = 5;
  static const int maxBioLength = 500;

  // Message Configuration
  static const int maxMessageLength = 1000;
  static const int dailyMessageLimit = 5;

  // Default Values
  static const int minAge = 18;
  static const int maxAge = 65;
  static const double maxDistance = 50.0; // km

  // Approval Status
  static const String approvalPending = 'pending';
  static const String approvalApproved = 'approved';
  static const String approvalRejected = 'rejected';

  // Match Actions
  static const String actionLike = 'liked';
  static const String actionPass = 'passed';
}