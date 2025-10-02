import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../app/routes.dart';
import '../services/auth_service.dart';

class ApprovalRejectedScreen extends StatefulWidget {
  const ApprovalRejectedScreen({super.key});

  @override
  State<ApprovalRejectedScreen> createState() => _ApprovalRejectedScreenState();
}

class _ApprovalRejectedScreenState extends State<ApprovalRejectedScreen> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final authService = context.read<AuthService>();
      final profile = await authService.getUserProfile();
      setState(() {
        _profileData = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('Error loading profile data: $e');
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

  void _editProfile() {
    context.go(AppRoutes.profileSetup);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color.fromRGBO(6, 13, 24, 1),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFf093fb)),
          ),
        ),
      );
    }

    final rejectionReason = _profileData?['rejection_reason'] as String?;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(6, 13, 24, 1),
      appBar: AppBar(
        title: const Text(
          '프로필 승인 거부',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _signOut,
            child: const Text(
              '로그아웃',
              style: TextStyle(color: Color(0xFFf093fb)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.xl),

              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cancel_outlined,
                  size: 60,
                  color: AppColors.error,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Title
              Text(
                '프로필 승인이 거부되었습니다',
                style: AppTextStyles.h1.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.md),

              // Description
              Text(
                '안전한 서비스 운영을 위해 일부 프로필이 승인되지 않을 수 있습니다.\n아래 가이드라인을 참고하여 프로필을 수정해주세요.',
                style: AppTextStyles.body1.copyWith(
                  color: Colors.white.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xl),

              // Rejection reason (if available)
              if (rejectionReason != null && rejectionReason.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 20,
                            color: AppColors.error,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '거부 사유',
                            style: AppTextStyles.body1.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        rejectionReason,
                        style: AppTextStyles.body2.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              // Guidelines
              _buildGuidelineCard(
                icon: Icons.photo_camera_outlined,
                title: '프로필 사진 가이드라인',
                points: [
                  '본인의 얼굴이 명확히 보이는 사진',
                  '선명하고 적절한 화질의 사진',
                  '부적절한 내용이 포함되지 않은 사진',
                  '타인의 사진이 아닌 본인 사진',
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              _buildGuidelineCard(
                icon: Icons.edit_outlined,
                title: '프로필 정보 가이드라인',
                points: [
                  '진실한 정보로만 작성',
                  '부적절한 언어 사용 금지',
                  '개인정보 보호 준수',
                  '타인에게 불쾌감을 주지 않는 내용',
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // Action buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _editProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFf093fb),
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.edit),
                      label: const Text('프로필 수정하기'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Implement support contact
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('고객센터 연결 기능은 준비 중입니다.'),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFf093fb),
                        side: const BorderSide(color: Color(0xFFf093fb)),
                      ),
                      icon: const Icon(Icons.support_agent_outlined),
                      label: const Text('고객센터 문의'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuidelineCard({
    required IconData icon,
    required String title,
    required List<String> points,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF252836),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFf093fb).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: const Color(0xFFf093fb),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final point in points) Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    point,
                    style: AppTextStyles.body2.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
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