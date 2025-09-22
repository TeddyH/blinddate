import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/email_auth_screen.dart';
import '../features/auth/screens/profile_setup_screen.dart';
import '../features/auth/screens/approval_waiting_screen.dart';
import '../features/auth/screens/approval_rejected_screen.dart';
import '../features/matching/screens/scheduled_home_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/chat/screens/chat_list_screen.dart';
import '../features/chat/screens/chat_screen.dart';
import '../features/matching/screens/match_history_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String emailAuth = '/email-auth';
  static const String profileSetup = '/profile-setup';
  static const String approvalWaiting = '/approval-waiting';
  static const String approvalRejected = '/approval-rejected';
  static const String home = '/home';
  static const String recommendations = '/recommendations';
  static const String profile = '/profile';
  static const String matchHistory = '/match-history';
  static const String chatList = '/chat-list';
  static const String chat = '/chat';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      // Auth Routes
      GoRoute(
        path: splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: emailAuth,
        name: 'email-auth',
        builder: (context, state) => const EmailAuthScreen(),
      ),
      GoRoute(
        path: profileSetup,
        name: 'profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: approvalWaiting,
        name: 'approval-waiting',
        builder: (context, state) => const ApprovalWaitingScreen(),
      ),
      GoRoute(
        path: approvalRejected,
        name: 'approval-rejected',
        builder: (context, state) => const ApprovalRejectedScreen(),
      ),

      // Main App Routes with Shell Route for Bottom Navigation
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigationWrapper(child: child);
        },
        routes: [
          GoRoute(
            path: home,
            name: 'home',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: recommendations,
            name: 'recommendations',
            builder: (context, state) => const ScheduledHomeScreen(),
          ),
          GoRoute(
            path: matchHistory,
            name: 'match-history',
            builder: (context, state) => const MatchHistoryScreen(),
          ),
          GoRoute(
            path: profile,
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Chat Detail Route (outside of shell)
      GoRoute(
        path: '$chat/:chatId',
        name: 'chat',
        builder: (context, state) {
          final chatId = state.pathParameters['chatId']!;
          return ChatScreen(chatId: chatId);
        },
      ),
    ],
  );
}

class MainNavigationWrapper extends StatefulWidget {
  final Widget child;

  const MainNavigationWrapper({
    super.key,
    required this.child,
  });

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.recommendations);
        break;
      case 2:
        context.go(AppRoutes.matchHistory);
        break;
      case 3:
        context.go(AppRoutes.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Update selected index based on current route
    final currentRoute = GoRouterState.of(context).fullPath;
    if (currentRoute == AppRoutes.home) _selectedIndex = 0;
    if (currentRoute == AppRoutes.recommendations) _selectedIndex = 1;
    if (currentRoute == AppRoutes.matchHistory) _selectedIndex = 2;
    if (currentRoute == AppRoutes.profile) _selectedIndex = 3;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: '추천',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            activeIcon: Icon(Icons.history),
            label: '기록',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: '프로필',
          ),
        ],
      ),
    );
  }
}