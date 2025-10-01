import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';

class ProfileMenuSection extends StatelessWidget {
  final Map<String, dynamic> profile;

  const ProfileMenuSection({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Color(0xFF252836),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '정보',
            style: AppTextStyles.h3.copyWith(
              color: Colors.white.withOpacity(0.95),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Privacy Policy
          _buildMenuTile(
            icon: Icons.privacy_tip_outlined,
            title: '개인정보 처리방침',
            onTap: () {
              _showPrivacyPolicy(context);
            },
          ),

          // Terms of Service
          _buildMenuTile(
            icon: Icons.description_outlined,
            title: '이용약관',
            onTap: () {
              _showTermsOfService(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? titleColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            Icon(
              icon,
              color: titleColor ?? Colors.white.withOpacity(0.7),
              size: 24,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body1.copyWith(
                      color: titleColor ?? Colors.white.withOpacity(0.95),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withOpacity(0.7),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }


  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('개인정보 처리방침'),
          content: const SingleChildScrollView(
            child: Text(
              '개인정보 처리방침\n\n'
              '1. 개인정보의 처리 목적\n'
              '- 회원 가입 및 관리\n'
              '- 매칭 서비스 제공\n'
              '- 채팅 서비스 제공\n\n'
              '2. 개인정보의 처리 및 보유 기간\n'
              '- 회원 탈퇴 시까지\n\n'
              '3. 개인정보의 제3자 제공\n'
              '- 원칙적으로 제3자에게 제공하지 않습니다\n\n'
              '4. 개인정보처리의 위탁\n'
              '- 서비스 제공을 위해 필요한 경우에만 위탁합니다\n\n'
              '자세한 내용은 앱 내 설정에서 확인하실 수 있습니다.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  void _showTermsOfService(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('이용약관'),
          content: const SingleChildScrollView(
            child: Text(
              '이용약관\n\n'
              '제1조 (목적)\n'
              '본 약관은 Hearty 앱의 이용과 관련하여 회사와 이용자 간의 권리, 의무 및 책임사항을 규정함을 목적으로 합니다.\n\n'
              '제2조 (정의)\n'
              '1. "서비스"란 Hearty 매칭 앱을 의미합니다.\n'
              '2. "이용자"란 본 약관에 따라 서비스를 이용하는 회원을 의미합니다.\n\n'
              '제3조 (약관의 효력 및 변경)\n'
              '본 약관은 서비스 화면에 게시하거나 기타의 방법으로 이용자에게 공지함으로써 효력이 발생합니다.\n\n'
              '제4조 (서비스의 제공 및 변경)\n'
              '회사는 다음과 같은 서비스를 제공합니다:\n'
              '- 매칭 서비스\n'
              '- 채팅 서비스\n'
              '- 프로필 관리 서비스\n\n'
              '자세한 내용은 앱 내 설정에서 확인하실 수 있습니다.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }
}