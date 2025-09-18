import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_constants.dart';
import '../../../app/routes.dart';
import '../services/auth_service.dart';

class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isSignUp = false; // false = 로그인, true = 회원가입

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = context.read<AuthService>();

      if (_isSignUp) {
        // 회원가입
        await authService.signUpWithEmail(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('회원가입이 완료되었습니다. 이메일을 확인해주세요.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        // 로그인
        await authService.signInWithEmailPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (mounted) {
          // 프로필 확인 후 적절한 화면으로 이동
          final profile = await authService.getUserProfile();

          if (profile == null) {
            context.go(AppRoutes.profileSetup);
          } else {
            final approvalStatus = profile['approval_status'] as String;
            switch (approvalStatus) {
              case AppConstants.approvalPending:
                context.go(AppRoutes.approvalWaiting);
                break;
              case AppConstants.approvalApproved:
                context.go(AppRoutes.home);
                break;
              case AppConstants.approvalRejected:
                context.go(AppRoutes.profileSetup);
                break;
              default:
                context.go(AppRoutes.profileSetup);
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = '오류가 발생했습니다.';

        if (e.toString().contains('Invalid login credentials')) {
          errorMessage = '이메일 또는 비밀번호가 올바르지 않습니다.';
        } else if (e.toString().contains('User already registered')) {
          errorMessage = '이미 가입된 이메일입니다.';
        } else if (e.toString().contains('Email not confirmed')) {
          errorMessage = '이메일 인증을 완료해주세요.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignUp ? '회원가입' : '로그인'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: AppLayout.screenPadding,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                const SizedBox(height: AppSpacing.xl),

                // Header
                Text(
                  _isSignUp ? '새 계정 만들기' : '다시 오신 것을 환영합니다',
                  style: AppTextStyles.h2.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                Text(
                  _isSignUp
                    ? '이메일과 비밀번호로 계정을 만드세요.'
                    : '이메일과 비밀번호로 로그인하세요.',
                  style: AppTextStyles.body1.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: '이메일',
                    hintText: 'example@email.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '이메일을 입력해주세요.';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return '올바른 이메일 형식을 입력해주세요.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.lg),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: '비밀번호',
                    hintText: '비밀번호를 입력하세요',
                    prefixIcon: Icon(Icons.lock_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '비밀번호를 입력해주세요.';
                    }
                    if (_isSignUp && value.length < 6) {
                      return '비밀번호는 최소 6자리 이상이어야 합니다.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.xl),

                // Auth Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleAuth,
                  child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(_isSignUp ? '회원가입' : '로그인'),
                ),

                const SizedBox(height: AppSpacing.md),

                // Toggle Sign Up/Sign In
                TextButton(
                  onPressed: _isLoading ? null : () {
                    setState(() {
                      _isSignUp = !_isSignUp;
                      _passwordController.clear();
                    });
                  },
                  child: Text(
                    _isSignUp
                      ? '이미 계정이 있으신가요? 로그인'
                      : '계정이 없으신가요? 회원가입',
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                // Terms
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Text(
                    '계속 진행하시면 이용약관 및 개인정보처리방침에\n동의하는 것으로 간주됩니다.',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // 키보드 올라올 때를 위한 추가 여백
                SizedBox(height: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}