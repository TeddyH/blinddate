import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/storage_service.dart';
import '../../../app/routes.dart';
import '../../../shared/widgets/image_picker_grid.dart';
import '../../../shared/widgets/interest_chip_input.dart';
import '../../../shared/widgets/profile_section_card.dart';
import '../../../shared/models/image_source.dart' as model;
import '../services/auth_service.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();
  final _formKey1 = GlobalKey<FormState>();
  List<model.ProfileImageSource> _images = [];
  List<String> _interests = [];
  String? _selectedGender;
  bool _isLoading = false;
  bool _isLoadingData = true;
  bool _isUpdating = false; // Track if this is an update vs create
  final ImagePicker _imagePicker = ImagePicker();

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
    _nicknameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingProfile() async {
    try {
      final authService = context.read<AuthService>();
      final profile = await authService.getUserProfile();

      debugPrint('=== PROFILE SETUP DEBUG ===');
      debugPrint('Profile data: $profile');

      if (profile != null) {
        // Load existing images from URLs
        final storageService = StorageService.instance;
        final imageUrls = storageService.getImageUrlsFromProfile(profile);
        final imageSources = imageUrls.map((url) => model.NetworkImageSource(url)).toList();

        debugPrint('Image URLs: $imageUrls');
        debugPrint('Image sources count: ${imageSources.length}');
        debugPrint('Nickname: ${profile['nickname']}');
        debugPrint('Bio: ${profile['bio']}');
        debugPrint('Interests: ${profile['interests']}');
        debugPrint('Gender: ${profile['gender']}');

        setState(() {
          _isUpdating = true;
          _nicknameController.text = profile['nickname'] ?? '';
          _bioController.text = profile['bio'] ?? '';
          _interests = List<String>.from(profile['interests'] ?? []);
          _selectedGender = profile['gender'];
          _images = imageSources;
        });
      } else {
        debugPrint('Profile is null');
      }
    } catch (e) {
      debugPrint('Error loading existing profile: $e');
    } finally {
      setState(() {
        _isLoadingData = false;
      });
    }
  }

  Future<void> _showImagePickerOptions() async {
    if (_images.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('최대 3장까지만 업로드 가능합니다'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              '사진 추가',
              style: AppTextStyles.h3.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImagePickerOption(
                  icon: Icons.camera_alt,
                  label: '카메라로 촬영',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                _buildImagePickerOption(
                  icon: Icons.photo_library,
                  label: '갤러리에서 선택',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePickerOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 32,
              color: AppColors.primary,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: AppTextStyles.body2.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context); // Close bottom sheet

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1080,
        maxHeight: 1080,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        setState(() {
          _images.add(model.FileImageSource(file));
          _imageError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지를 선택하는 중 오류가 발생했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
  }

  bool _validateForm() {
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

    // Validate interests
    if (_interests.isEmpty) {
      setState(() {
        _interestError = '최소 1개의 관심사를 선택해주세요.';
      });
      isValid = false;
    }

    return isValid;
  }


  Future<void> _submitProfile() async {
    if (!_validateForm()) return;

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
        // Default birth date for age 25
        final birthDate = DateTime.now().subtract(const Duration(days: 365 * 25));

        await authService.createUserProfile(
          nickname: _nicknameController.text.trim(),
          country: 'KR', // Default to Korea
          birthDate: birthDate,
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
      return Scaffold(
        backgroundColor: AppColors.background,
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
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

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
                _isUpdating ? '프로필 수정' : '프로필 설정',
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
        actions: [
          // 로그아웃 버튼 (개발용)
          IconButton(
            icon: Icon(
              Icons.logout,
              color: AppColors.accent,
            ),
            onPressed: () async {
              final authService = context.read<AuthService>();
              await authService.signOut();
              if (mounted) {
                context.go(AppRoutes.emailAuth);
              }
            },
            tooltip: '로그아웃',
          ),
        ],
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
        child: SafeArea(
          child: Column(
            children: [
              // Page content
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Form(
                    key: _formKey1,
                    child: Column(
                      children: [
                        // Profile Images Section
                        _buildProfileImagesSection(),
                        const SizedBox(height: AppSpacing.lg),

                        // Basic Info Section
                        _buildBasicInfoSection(),
                        const SizedBox(height: AppSpacing.lg),

                        // Additional Info Section
                        _buildAdditionalInfoSection(),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom navigation
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg).copyWith(
                  top: AppSpacing.md,
                  bottom: AppSpacing.lg,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      offset: const Offset(0, -2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _isUpdating ? '수정 완료' : '프로필 등록',
                          style: AppTextStyles.body1.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImagesSection() {
    return ProfileSectionCard(
      title: '프로필 사진',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 1,
            ),
            itemCount: 3,
            itemBuilder: (context, index) {
              final hasImage = index < _images.length;

              return Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: InkWell(
                  onTap: hasImage ? null : _showImagePickerOptions,
                  borderRadius: BorderRadius.circular(12),
                  child: hasImage
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _buildImageWidget(_images[index]),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_a_photo_outlined,
                            color: AppColors.primary,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '사진 추가',
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                ),
              );
            },
          ),

          const SizedBox(height: AppSpacing.sm),
          Text(
            '최대 3장까지 업로드 가능합니다',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (_imageError != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _imageError!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return ProfileSectionCard(
      title: '기본 정보',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nickname
          TextFormField(
            controller: _nicknameController,
            decoration: InputDecoration(
              labelText: '닉네임',
              hintText: '다른 사람들에게 보여질 이름을 입력하세요',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '닉네임을 입력해주세요';
              }
              if (value.trim().length < 2) {
                return '닉네임은 2글자 이상이어야 합니다';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Bio
          TextFormField(
            controller: _bioController,
            maxLines: 8,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: '자기소개',
              hintText: '자신을 매력적으로 소개해보세요 (최소 100자)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '자기소개를 입력해주세요';
              }
              if (value.trim().length < 100) {
                return '자기소개는 최소 100자 이상 작성해주세요';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Gender
          Text(
            '성별',
            style: AppTextStyles.body1.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('남성'),
                  value: 'male',
                  groupValue: _selectedGender,
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('여성'),
                  value: 'female',
                  groupValue: _selectedGender,
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoSection() {
    return ProfileSectionCard(
      title: '관심사',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Interests
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              '영화/드라마', '음악', '독서', '여행', '운동', '요리',
              '사진', '게임', '카페', '맛집', '쇼핑', '전시회',
              '콘서트', '스포츠', '등산', '바다', '반려동물', '술',
              '커피', '디저트', '패션', '뷰티', '자동차', '바이크',
            ].map((interest) {
              final isSelected = _interests.contains(interest);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _interests.remove(interest);
                      _interestError = null;
                    } else {
                      if (_interests.length < 5) {
                        _interests.add(interest);
                        _interestError = null;
                      } else {
                        _interestError = '최대 5개까지 선택할 수 있습니다';
                      }
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.surfaceVariant.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.3)
                          : AppColors.surfaceVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    interest,
                    style: AppTextStyles.caption.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          if (_interests.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '선택된 관심사: ${_interests.length}/5개',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],

          if (_interestError != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _interestError!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.error,
              ),
            ),
          ],
        ],
      ),
    );
  }


  Widget _buildImageWidget(model.ProfileImageSource imageSource) {
    if (imageSource is model.NetworkImageSource) {
      return Image.network(
        imageSource.url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image,
                color: AppColors.textSecondary,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                '이미지 오류',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          );
        },
      );
    } else if (imageSource is model.FileImageSource) {
      return Image.file(
        imageSource.file,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.broken_image,
                color: AppColors.textSecondary,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                '이미지 오류',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          );
        },
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.photo_outlined,
            color: AppColors.textSecondary,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            '사진 없음',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
    }
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