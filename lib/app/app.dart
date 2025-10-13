import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/services/supabase_service.dart';
import '../core/services/unread_message_service.dart';
import '../core/services/locale_service.dart';
import '../features/auth/services/auth_service.dart';
import '../features/matching/services/scheduled_matching_service.dart';
import '../features/profile/services/profile_service.dart';
import '../features/chat/services/chat_service.dart';
import '../l10n/app_localizations.dart';
import 'routes.dart';

class BlindDateApp extends StatelessWidget {
  const BlindDateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => LocaleService(),
        ),
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
      child: Consumer<LocaleService>(
        builder: (context, localeService, child) {
          return MaterialApp.router(
            title: 'Hearty',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            locale: localeService.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
              Locale('ko'), // Korean
            ],
            routerConfig: AppRoutes.router,
          );
        },
      ),
    );
  }
}