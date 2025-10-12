import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_constants.dart';
import '../../../app/routes.dart';
import '../../../l10n/app_localizations.dart';
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
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.errorProfileNotFound),
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
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.approvalStillPending),
              backgroundColor: Colors.blue,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking approval status: $e');
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorCheckingStatus(e.toString())),
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
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorLogout),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(6, 13, 24, 1),
      appBar: AppBar(
        title: Text(
          l10n.approvalWaitingTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _signOut,
            child: Text(
              l10n.profileLogout,
              style: const TextStyle(color: Colors.white),
            ),
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
                      color: const Color(0xFFf093fb).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.hourglass_empty_outlined,
                      size: 60,
                      color: Color(0xFFf093fb),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Title
                  Text(
                    l10n.approvalWaitingMessage,
                    style: AppTextStyles.h1.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Description
                  Text(
                    l10n.approvalWaitingDesc,
                    style: AppTextStyles.body1.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Info cards
                  _buildInfoCard(
                    icon: Icons.security_outlined,
                    title: l10n.approvalInfoVerificationTitle,
                    description: l10n.approvalInfoVerificationDesc,
                  ),

                  const SizedBox(height: AppSpacing.md),

                  _buildInfoCard(
                    icon: Icons.schedule_outlined,
                    title: l10n.approvalInfoProcessTitle,
                    description: l10n.approvalInfoProcessDesc,
                  ),

                  const SizedBox(height: AppSpacing.md),

                  _buildInfoCard(
                    icon: Icons.notifications_outlined,
                    title: l10n.approvalInfoNotificationTitle,
                    description: l10n.approvalInfoNotificationDesc,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  const Spacer(),

                  // Refresh button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isChecking ? null : _checkApprovalStatus,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFf093fb),
                        side: const BorderSide(color: Color(0xFFf093fb)),
                      ),
                      icon: _isChecking
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFf093fb)),
                            ),
                          )
                        : const Icon(Icons.refresh),
                      label: Text(_isChecking ? l10n.checking : l10n.checkApprovalStatus),
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
        color: const Color(0xFF252836),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFf093fb).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 24,
              color: const Color(0xFFf093fb),
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
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.body2.copyWith(
                    color: Colors.white.withOpacity(0.7),
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