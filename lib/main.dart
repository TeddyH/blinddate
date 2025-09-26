import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/services/supabase_service.dart';
import 'core/services/notification_service.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Supabase
  await SupabaseService.initialize();

  // Initialize Firebase (optional - only if configuration exists)
  try {
    await Firebase.initializeApp();
    // Initialize Notifications only if Firebase is available
    await NotificationService.instance.initialize();
    print('🔥 Firebase 및 알림 서비스 초기화 완료');
  } catch (e) {
    print('⚠️  Firebase 설정 파일이 없습니다. 푸시 알림이 비활성화됩니다.');
    print('Firebase 설정 후 푸시 알림을 사용할 수 있습니다: $e');
  }

  // Initialize deep link handling
  // Note: This will be automatically handled by Supabase for auth callbacks

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const BlindDateApp());
}