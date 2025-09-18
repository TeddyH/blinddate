import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/storage_service.dart';
import '../../../app/routes.dart';
import '../../../shared/widgets/image_picker_grid.dart';
import '../../../shared/widgets/interest_chip_input.dart';
import '../../../shared/models/image_source.dart' as model;
import '../services/auth_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final PageController _pageController = PageController();
  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  int _currentPage = 0;
  List<model.ProfileImageSource> _images = [];
  List<String> _interests = [];
  String? _selectedGender;
  bool _isLoading = false;
  bool _isLoadingData = true;
  bool _isUpdating = false; // Track if this is an update vs create

  // Error messages
  String? _imageError;
  String? _interestError;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nicknameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingProfile() async {
    try {
      final authService = context.read<AuthService>();
      final profile = await authService.getUserProfile();

      if (profile != null) {
        // Load existing images from URLs
        final storageService = StorageService.instance;
        final imageUrls = storageService.getImageUrlsFromProfile(profile);
        final imageSources = imageUrls.map((url) => model.NetworkImageSource(url)).toList();

        setState(() {
          _isUpdating = true;
          _nicknameController.text = profile['nickname'] ?? '';
          _bioController.text = profile['bio'] ?? '';
          _interests = List<String>.from(profile['interests'] ?? []);
          _selectedGender = profile['gender'];
          _images = imageSources;
        });
      }
    } catch (e) {
      debugPrint('Error loading existing profile: $e');
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  void _nextPage() {
    if (_validatePage1()) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  bool _validatePage1() {
    bool isValid = true;

    // Clear previous errors
    setState(() {
      _imageError = null;
      _interestError = null;
    });

    // Validate form
    if (!_formKey1.currentState!.validate()) {
      isValid = false;
    }

    // Validate images
    if (_images.isEmpty) {
      setState(() {
        _imageError = '최소 1장의 프로필 사진을 선택해주세요.';
      });
      isValid = false;
    }

    // Validate gender
    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('성별을 선택해주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      isValid = false;
    }

    return isValid;
  }

  bool _validatePage2() {
    return _formKey2.currentState!.validate();
  }

  Future<void> _submitProfile() async {
    if (!_validatePage2()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = context.read<AuthService>();

      if (_isUpdating) {
        // Update existing profile with all image sources
        await authService.updateUserProfile({
          'nickname': _nicknameController.text.trim(),
          'bio': _bioController.text.trim(),
          'interests': _interests,
          'gender': _selectedGender,
          'approval_status': AppConstants.approvalPending, // Reset to pending for re-review
          'rejection_reason': null, // Clear previous rejection reason
        }, imageSources: _images.isNotEmpty ? _images : null);
      } else {
        // Extract File images for new profile creation
        final files = _images
            .whereType<model.FileImageSource>()
            .map((source) => source.file)
            .toList();

        // Create new profile
        await authService.createUserProfile(
          nickname: _nicknameController.text.trim(),
          country: 'KR', // Default to Korea
          birthDate: DateTime.now().subtract(const Duration(days: 365 * 25)), // Default age 25
          bio: _bioController.text.trim(),
          interests: _interests,
          gender: _selectedGender!,
          profileImages: files.isNotEmpty ? files : null,
        );
      }

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isUpdating
              ? '프로필이 성공적으로 수정되었습니다. 관리자 재검토를 기다려주세요.'
              : '프로필이 성공적으로 생성되었습니다. 관리자 승인을 기다려주세요.'),
            backgroundColor: AppColors.success,
          ),
        );

        // Navigate to approval waiting screen
        context.go(AppRoutes.approvalWaiting);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로필 생성 중 오류가 발생했습니다: $e'),
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
    if (_isLoadingData) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isUpdating ? '프로필 수정' : '프로필 설정'),
        actions: [
          // 로그아웃 버튼 (개발용)
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final authService = context.read<AuthService>();
              await authService.signOut();
              if (mounted) {
                context.go(AppRoutes.emailAuth);
              }
            },
            tooltip: '로그아웃',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_currentPage + 1}/2',
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentPage + 1) / 2,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildPage1(),
                  _buildPage2(),
                ],
              ),
            ),

            // Bottom navigation
            Container(
              padding: AppLayout.screenPadding.copyWith(
                top: AppSpacing.md,
                bottom: AppSpacing.lg,
              ),
              child: Row(
                children: [
                  if (_currentPage > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        child: const Text('이전'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Expanded(
                    flex: _currentPage == 0 ? 1 : 1,
                    child: ElevatedButton(
                      onPressed: _isLoading
                        ? null
                        : (_currentPage == 0 ? _nextPage : _submitProfile),
                      child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(_currentPage == 0 ? '다음' : '완료'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage1() {
    return SingleChildScrollView(
      padding: AppLayout.screenPadding,
      child: Form(
        key: _formKey1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),

            // Header
            Text(
              _isUpdating ? '프로필 정보를 수정해주세요' : '기본 정보를 입력해주세요',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            Text(
              _isUpdating
                ? '수정된 프로필은 관리자 재검토를 거쳐 승인됩니다.'
                : '매력적인 프로필로 더 많은 매칭 기회를 만들어보세요.',
              style: AppTextStyles.body1.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Profile Images
            Text(
              '프로필 사진',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            ImagePickerGrid(
              images: _images,
              onImagesChanged: (images) {
                setState(() {
                  _images = images;
                  _imageError = null;
                });
              },
              errorText: _imageError,
            ),

            const SizedBox(height: AppSpacing.xl),

            // Nickname
            Text(
              '닉네임',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            TextFormField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                hintText: '다른 사용자에게 보여질 닉네임을 입력하세요',
                prefixIcon: Icon(Icons.person_outline),
              ),
              maxLength: 20,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '닉네임을 입력해주세요.';
                }
                if (value.trim().length < 2) {
                  return '닉네임은 최소 2자 이상이어야 합니다.';
                }
                return null;
              },
            ),

            const SizedBox(height: AppSpacing.xl),

            // Gender selection
            Text(
              '성별',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildGenderOption('male', '남성', Icons.male),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildGenderOption('female', '여성', Icons.female),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildPage2() {
    return SingleChildScrollView(
      padding: AppLayout.screenPadding,
      child: Form(
        key: _formKey2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),

            // Header
            Text(
              _isUpdating ? '자기소개와 관심사를 수정해주세요' : '자기소개와 관심사를 작성해주세요',
              style: AppTextStyles.h2.copyWith(
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            Text(
              _isUpdating
                ? '자기소개와 관심사로 더 나은 프로필을 만들어보세요!'
                : '자기소개와 관심사는 더 많은 관심을 받을 수 있어요.\n자신의 매력을 마음껏 어필해보세요!',
              style: AppTextStyles.body1.copyWith(
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Bio Section Header
            Text(
              '자기소개',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Bio input
            TextFormField(
              controller: _bioController,
              maxLines: 8,
              maxLength: AppConstants.maxBioLength,
              decoration: const InputDecoration(
                hintText: '• 자신의 성격이나 취미를 소개해주세요\n• 어떤 사람과 만나고 싶은지 알려주세요\n• 평소 좋아하는 활동이나 관심사를 적어주세요\n• 진솔하고 매력적인 모습을 보여주세요',
                alignLabelWithHint: true,
                contentPadding: EdgeInsets.all(AppSpacing.md),
              ),
              style: AppTextStyles.body1,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '자기소개를 입력해주세요.';
                }
                if (value.trim().length < 100) {
                  return '자기소개는 최소 100자 이상 작성해주세요.';
                }
                return null;
              },
              onChanged: (value) {
                setState(() {}); // For character counter
              },
            ),

            const SizedBox(height: AppSpacing.md),

            // Character counter and tip
            Row(
              children: [
                Text(
                  '${_bioController.text.length}/${AppConstants.maxBioLength}자',
                  style: AppTextStyles.caption.copyWith(
                    color: _bioController.text.length >= 100
                      ? AppColors.success
                      : AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                if (_bioController.text.length < 100)
                  Text(
                    '${100 - _bioController.text.length}자 더 입력해주세요',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Tips container
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 20,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '작성 팁',
                        style: AppTextStyles.body2.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '• 긍정적이고 밝은 내용으로 작성해보세요\n• 구체적인 경험이나 에피소드를 포함하면 좋아요\n• 상대방이 궁금해할 만한 내용을 담아보세요\n• 진부한 표현보다는 개성 있는 문체를 사용해보세요',
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Interests
            Text(
              '관심사',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            InterestChipInput(
              interests: _interests,
              onChanged: (interests) {
                setState(() {
                  _interests = interests;
                  _interestError = null;
                });
              },
              errorText: _interestError,
            ),

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderOption(String value, String label, IconData icon) {
    final isSelected = _selectedGender == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGender = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: AppTextStyles.body1.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}