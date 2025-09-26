import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../core/services/unread_message_service.dart';
import '../core/widgets/badge_icon.dart';
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
            path: chatList,
            name: 'chat-list',
            builder: (context, state) => const ChatListScreen(),
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
        path: '$chat/:chatRoomId',
        name: 'chat',
        builder: (context, state) {
          final chatRoomId = state.pathParameters['chatRoomId']!;
          return ChatScreen(chatRoomId: chatRoomId);
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

  @override
  void initState() {
    super.initState();
    // UnreadMessageService 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final unreadService = context.read<UnreadMessageService>();
      unreadService.fetchUnreadCount();
    });
  }

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
        context.go(AppRoutes.chatList);
        break;
      case 3:
        context.go(AppRoutes.matchHistory);
        break;
      case 4:
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
    if (currentRoute == AppRoutes.chatList) _selectedIndex = 2;
    if (currentRoute == AppRoutes.matchHistory) _selectedIndex = 3;
    if (currentRoute == AppRoutes.profile) _selectedIndex = 4;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.95),
              AppColors.accent.withValues(alpha: 0.85),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white.withValues(alpha: 0.6),
          selectedFontSize: 12,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
          iconSize: 24,
          items: [
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Icon(
                  Icons.home_outlined,
                  size: _selectedIndex == 0 ? 26 : 24,
                ),
              ),
              activeIcon: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: const Icon(
                  Icons.home,
                  size: 26,
                ),
              ),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Icon(
                  Icons.favorite_border,
                  size: _selectedIndex == 1 ? 26 : 24,
                ),
              ),
              activeIcon: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: const Icon(
                  Icons.favorite,
                  size: 26,
                ),
              ),
              label: '추천',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Consumer<UnreadMessageService>(
                  builder: (context, unreadService, child) {
                    return BadgeIcon(
                      icon: Icon(
                        Icons.chat_bubble_outline,
                        size: _selectedIndex == 2 ? 26 : 24,
                      ),
                      badgeCount: unreadService.unreadCount,
                    );
                  },
                ),
              ),
              activeIcon: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Consumer<UnreadMessageService>(
                  builder: (context, unreadService, child) {
                    return BadgeIcon(
                      icon: const Icon(
                        Icons.chat_bubble,
                        size: 26,
                      ),
                      badgeCount: unreadService.unreadCount,
                    );
                  },
                ),
              ),
              label: '채팅',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Icon(
                  Icons.history,
                  size: _selectedIndex == 3 ? 26 : 24,
                ),
              ),
              activeIcon: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: const Icon(
                  Icons.history,
                  size: 26,
                ),
              ),
              label: '기록',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Icon(
                  Icons.person_outline,
                  size: _selectedIndex == 4 ? 26 : 24,
                ),
              ),
              activeIcon: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: const Icon(
                  Icons.person,
                  size: 26,
                ),
              ),
              label: '프로필',
            ),
          ],
        ),
      ),
    );
  }
}