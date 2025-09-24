import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../app/routes.dart';
import '../services/profile_service.dart';
import '../widgets/profile_image_widget.dart';
import '../widgets/profile_info_section.dart';
import '../widgets/profile_menu_section.dart';
import 'profile_edit_screen.dart';
import 'app_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfileData();
    });
  }

  Future<void> _loadProfileData() async {
    final profileService = context.read<ProfileService>();
    await profileService.getCurrentUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '💕 Hearty',
              style: AppTextStyles.h1.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                '프로필',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.background,
              AppColors.accent.withValues(alpha: 0.03),
              AppColors.accent.withValues(alpha: 0.08),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: Consumer<ProfileService>(
        builder: (context, profileService, child) {
          if (profileService.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (profileService.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 48,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    profileService.errorMessage!,
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton(
                    onPressed: _loadProfileData,
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          final profile = profileService.currentUserProfile;
          if (profile == null) {
            return const Center(
              child: Text('프로필 정보를 불러올 수 없습니다'),
            );
          }

          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                // Profile action icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileEditScreen(),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.edit,
                        color: AppColors.accent,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AppSettingsScreen(),
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.settings_outlined,
                        color: AppColors.accent,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _showLogoutDialog(context);
                      },
                      icon: Icon(
                        Icons.logout_outlined,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ProfileImageWidget(profile: profile),
                const SizedBox(height: AppSpacing.xl),
                ProfileInfoSection(profile: profile),
                const SizedBox(height: AppSpacing.xl),
                ProfileMenuSection(profile: profile),
              ],
            ),
          );
        },
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('로그아웃'),
          content: const Text('정말로 로그아웃하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();

                final profileService = context.read<ProfileService>();
                final success = await profileService.signOut();

                if (success && context.mounted) {
                  // Navigate to login screen
                  context.go(AppRoutes.emailAuth);
                } else if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('로그아웃 중 오류가 발생했습니다'),
                    ),
                  );
                }
              },
              child: Text(
                '로그아웃',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
  }
}