import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_constants.dart';
import '../../../app/routes.dart';
import '../services/auth_service.dart';

class ApprovalWaitingScreen extends StatefulWidget {
  const ApprovalWaitingScreen({super.key});

  @override
  State<ApprovalWaitingScreen> createState() => _ApprovalWaitingScreenState();
}

class _ApprovalWaitingScreenState extends State<ApprovalWaitingScreen> {
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    // Check approval status periodically
    _checkApprovalStatus();
  }

  Future<void> _checkApprovalStatus() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
    });

    try {
      final authService = context.read<AuthService>();
      final profile = await authService.getUserProfile(forceRefresh: true);

      if (mounted) {
        if (profile == null) {
          // 프로필이 없는 경우 프로필 설정으로 이동
          debugPrint('No profile found, redirecting to profile setup');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('프로필을 찾을 수 없습니다. 프로필을 다시 설정해주세요.'),
              backgroundColor: Colors.orange,
            ),
          );
          context.go(AppRoutes.profileSetup);
          return;
        }

        final status = profile['approval_status'] as String;
        debugPrint('Current approval status: $status');

        if (status == AppConstants.approvalApproved) {
          // Navigate to main app
          context.go(AppRoutes.home);
        } else if (status == AppConstants.approvalRejected) {
          // Navigate to rejection screen
          context.go(AppRoutes.approvalRejected);
        } else {
          // Still pending - show message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('아직 검토 중입니다. 조금만 더 기다려주세요.'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking approval status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('상태 확인 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    try {
      final authService = context.read<AuthService>();
      await authService.signOut();
      if (mounted) {
        context.go(AppRoutes.emailAuth);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('로그아웃 중 오류가 발생했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('승인 대기'),
        actions: [
          TextButton(
            onPressed: _signOut,
            child: const Text('로그아웃'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                         MediaQuery.of(context).padding.top -
                         MediaQuery.of(context).padding.bottom -
                         kToolbarHeight - 32, // AppBar height + padding
            ),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.xl),

                  // Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.hourglass_empty_outlined,
                      size: 60,
                      color: AppColors.accent,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Title
                  Text(
                    '프로필 검토 중입니다',
                    style: AppTextStyles.h1.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Description
                  Text(
                    '안전한 만남을 위해 모든 프로필을 검토하고 있습니다.\n승인이 완료되면 알림을 보내드릴게요!',
                    style: AppTextStyles.body1.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Info cards
                  _buildInfoCard(
                    icon: Icons.security_outlined,
                    title: '철저한 검증',
                    description: '모든 프로필 사진과 정보를 꼼꼼히 확인합니다',
                  ),

                  const SizedBox(height: AppSpacing.md),

                  _buildInfoCard(
                    icon: Icons.schedule_outlined,
                    title: '빠른 처리',
                    description: '보통 24시간 이내에 검토가 완료됩니다',
                  ),

                  const SizedBox(height: AppSpacing.md),

                  _buildInfoCard(
                    icon: Icons.notifications_outlined,
                    title: '즉시 알림',
                    description: '승인 완료 시 앱과 이메일로 알려드립니다',
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  const Spacer(),

                  // Refresh button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isChecking ? null : _checkApprovalStatus,
                      icon: _isChecking
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                      label: Text(_isChecking ? '확인 중...' : '승인 상태 확인'),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.surfaceVariant,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 24,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.body2.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}