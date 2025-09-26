import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/services/supabase_service.dart';
import '../core/services/unread_message_service.dart';
import '../features/auth/services/auth_service.dart';
import '../features/matching/services/scheduled_matching_service.dart';
import '../features/profile/services/profile_service.dart';
import '../features/chat/services/chat_service.dart';
import 'routes.dart';

class BlindDateApp extends StatelessWidget {
  const BlindDateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AuthService(),
        ),
        ChangeNotifierProvider(
          create: (context) => ScheduledMatchingService(),
        ),
        ChangeNotifierProvider(
          create: (context) => ProfileService(),
        ),
        ChangeNotifierProvider(
          create: (context) => ChatService(),
        ),
        ChangeNotifierProvider(
          create: (context) => UnreadMessageService.instance,
        ),
        Provider<SupabaseService>(
          create: (context) => SupabaseService.instance,
        ),
      ],
      child: MaterialApp.router(
        title: 'Hearty',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRoutes.router,
      ),
    );
  }
}