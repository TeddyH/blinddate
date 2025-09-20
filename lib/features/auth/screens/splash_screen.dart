import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_constants.dart';
import '../../../app/routes.dart';
import '../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkAuthStatus();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authService = context.read<AuthService>();

    if (!authService.isAuthenticated) {
      context.go(AppRoutes.emailAuth);
      return;
    }

    try {
      final profile = await authService.getUserProfile();
      debugPrint('Profile check result: $profile');

      if (profile == null) {
        debugPrint('No profile found, redirecting to profile setup');
        context.go(AppRoutes.profileSetup);
        return;
      }

      // Cache the profile for later use
      authService.setCachedProfile(profile);

      final approvalStatus = profile['approval_status'] as String;
      debugPrint('Approval status: $approvalStatus');

      switch (approvalStatus) {
        case AppConstants.approvalPending:
          context.go(AppRoutes.approvalWaiting);
          break;
        case AppConstants.approvalApproved:
          context.go(AppRoutes.home);
          break;
        case AppConstants.approvalRejected:
          context.go(AppRoutes.approvalRejected);
          break;
        default:
          context.go(AppRoutes.emailAuth);
      }
    } catch (e) {
      debugPrint('Auth check error: $e');
      context.go(AppRoutes.emailAuth);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo/Icon
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.pink,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite,
                    size: 60,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // App Name
                Text(
                  AppConstants.appName,
                  style: AppTextStyles.h1.copyWith(
                    color: Colors.pink,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // App Tagline
                Text(
                  '하루 1명, 특별한 만남',
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Loading Indicator
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.pink),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}