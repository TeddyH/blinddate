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
  String? _selectedGender = 'male'; // Default to male
  int? _selectedBirthYear = 2000; // Default to 2000
  String? _selectedMbti;
  String? _selectedLocation;
  bool _isLoading = false;
  bool _isLoadingData = true;
  bool _isUpdating = false; // Track if this is an update vs create
  String? _currentApprovalStatus;
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
        debugPrint('Birth date: ${profile['birth_date']}');
        debugPrint('MBTI: ${profile['mbti']}');
        debugPrint('Location: ${profile['location']}');

        // Extract birth year from birth_date
        int? birthYear;
        if (profile['birth_date'] != null) {
          try {
            final birthDate = DateTime.parse(profile['birth_date']);
            birthYear = birthDate.year;
          } catch (e) {
            debugPrint('Error parsing birth_date: $e');
          }
        }

        setState(() {
          _isUpdating = true;
          _nicknameController.text = profile['nickname'] ?? '';
          _bioController.text = profile['bio'] ?? '';
          _selectedBirthYear = birthYear;
          _interests = List<String>.from(profile['interests'] ?? []);
          _selectedGender = profile['gender'];
          _selectedMbti = profile['mbti'];
          _selectedLocation = profile['location'];
          _currentApprovalStatus = profile['approval_status'] ?? AppConstants.approvalPending;
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
        imageQuality: 85,
        maxWidth: 800,
        maxHeight: 800,
        preferredCameraDevice: CameraDevice.rear,
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
        // Calculate birth date from birth year (using July 1st as default date)
        final birthDate = DateTime(_selectedBirthYear!, 7, 1);

        // Determine approval status based on current status
        String newApprovalStatus;
        if (_currentApprovalStatus == AppConstants.approvalApproved) {
          // Keep approved status for already approved users
          newApprovalStatus = AppConstants.approvalApproved;
        } else {
          // Set to pending for new users or rejected users
          newApprovalStatus = AppConstants.approvalPending;
        }

        // Update existing profile with all image sources
        await authService.updateUserProfile({
          'nickname': _nicknameController.text.trim(),
          'bio': _bioController.text.trim(),
          'birth_date': birthDate.toIso8601String().split('T')[0], // Format as YYYY-MM-DD
          'interests': _interests,
          'gender': _selectedGender,
          'mbti': _selectedMbti,
          'location': _selectedLocation,
          'approval_status': newApprovalStatus,
          'rejection_reason': _currentApprovalStatus == AppConstants.approvalApproved ? null : null, // Clear rejection reason
        }, imageSources: _images.isNotEmpty ? _images : null);
      } else {
        // Extract File images for new profile creation
        final files = _images
            .whereType<model.FileImageSource>()
            .map((source) => source.file)
            .toList();

        // Create new profile
        // Calculate birth date from birth year (using July 1st as default date)
        final birthDate = DateTime(_selectedBirthYear!, 7, 1);

        await authService.createUserProfile(
          nickname: _nicknameController.text.trim(),
          country: 'KR', // Default to Korea
          birthDate: birthDate,
          bio: _bioController.text.trim(),
          interests: _interests,
          gender: _selectedGender!,
          profileImages: files.isNotEmpty ? files : null,
          mbti: _selectedMbti,
          location: _selectedLocation,
        );
      }

      if (mounted) {
        // Show success message based on approval status
        String successMessage;
        if (_isUpdating && _currentApprovalStatus == AppConstants.approvalApproved) {
          successMessage = '프로필이 성공적으로 수정되었습니다.';
        } else if (_isUpdating) {
          successMessage = '프로필이 성공적으로 수정되었습니다. 관리자 재검토를 기다려주세요.';
        } else {
          successMessage = '프로필이 성공적으로 생성되었습니다. 관리자 승인을 기다려주세요.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: AppColors.success,
          ),
        );

        // Navigate appropriately based on approval status
        if (_isUpdating && _currentApprovalStatus == AppConstants.approvalApproved) {
          // For already approved users, go back to previous screen
          Navigator.of(context).pop();
        } else {
          // For new users or pending/rejected users, go to approval waiting screen
          context.go(AppRoutes.approvalWaiting);
        }
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
              AppColors.accent.withValues(alpha: 0.02),
              AppColors.accent.withValues(alpha: 0.05),
            ],
            stops: const [0.0, 0.7, 1.0],
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

                        // Additional Info Section (Interests)
                        _buildAdditionalInfoSection(),
                        const SizedBox(height: AppSpacing.lg),

                        // Physical & Personal Info Section
                        _buildPhysicalPersonalInfoSection(),
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
                            child: SizedBox(
                              width: double.infinity,
                              height: double.infinity,
                              child: _buildImageWidget(_images[index]),
                            ),
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
          // Nickname and MBTI Row
          Row(
            children: [
              // Nickname
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _nicknameController,
                  decoration: InputDecoration(
                    labelText: '닉네임',
                    hintText: '닉네임을 입력하세요',
                    filled: true,
                    fillColor: AppColors.surface.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
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
              ),
              const SizedBox(width: AppSpacing.md),
              // MBTI
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _selectedMbti,
                  decoration: InputDecoration(
                    labelText: 'MBTI',
                    hintText: '선택',
                    filled: true,
                    fillColor: AppColors.surface.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                  items: _generateMbtiItems(),
                  onChanged: (value) {
                    setState(() {
                      _selectedMbti = value;
                    });
                  },
                  isExpanded: true,
                ),
              ),
            ],
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
              filled: true,
              fillColor: AppColors.surface.withValues(alpha: 0.5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  width: 2,
                ),
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

          // Gender and Birth Year Row
          Row(
            children: [
              // Gender (smaller width)
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '성별',
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surface.withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'male',
                          child: Text('남성'),
                        ),
                        DropdownMenuItem(
                          value: 'female',
                          child: Text('여성'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '성별을 선택해주세요';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Birth Year (larger width)
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '생년월일',
                      style: AppTextStyles.body1.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<int>(
                      value: _selectedBirthYear,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surface.withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 16,
                        ),
                      ),
                      items: _generateBirthYearItems(),
                      onChanged: (value) {
                        setState(() {
                          _selectedBirthYear = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return '생년월일을 선택해주세요';
                        }
                        final currentYear = DateTime.now().year;
                        final age = currentYear - value;
                        if (age < 18 || age > 80) {
                          return '18세~80세만 가입 가능합니다';
                        }
                        return null;
                      },
                      isExpanded: true, // Prevent overflow
                    ),
                  ],
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
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.surface.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.4)
                          : AppColors.surfaceVariant.withValues(alpha: 0.3),
                      width: isSelected ? 1.5 : 1,
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
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        alignment: Alignment.center,
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
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        alignment: Alignment.center,
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

  List<DropdownMenuItem<int>> _generateBirthYearItems() {
    final currentYear = DateTime.now().year;
    final minYear = currentYear - 80; // 최대 80세
    final maxYear = currentYear - 18; // 최소 18세

    List<DropdownMenuItem<int>> items = [];

    // 년도를 내림차순으로 정렬 (최근 년도부터)
    for (int year = maxYear; year >= minYear; year--) {
      final age = currentYear - year;
      items.add(
        DropdownMenuItem<int>(
          value: year,
          child: Text('$year년 (${age}세)'),
        ),
      );
    }

    return items;
  }

  Widget _buildPhysicalPersonalInfoSection() {
    return ProfileSectionCard(
      title: '추가 정보',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Location
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '거주지역',
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                value: _selectedLocation,
                decoration: InputDecoration(
                  hintText: '지역 선택 (선택사항)',
                  filled: true,
                  fillColor: AppColors.surface.withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.surfaceVariant.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                ),
                items: _generateLocationItems(),
                onChanged: (value) {
                  setState(() {
                    _selectedLocation = value;
                  });
                },
                isExpanded: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<DropdownMenuItem<String>> _generateMbtiItems() {
    const mbtiTypes = [
      'ISTJ', 'ISFJ', 'INFJ', 'INTJ',
      'ISTP', 'ISFP', 'INFP', 'INTP',
      'ESTP', 'ESFP', 'ENFP', 'ENTP',
      'ESTJ', 'ESFJ', 'ENFJ', 'ENTJ',
    ];

    return mbtiTypes.map((mbti) {
      return DropdownMenuItem<String>(
        value: mbti,
        child: Text(mbti),
      );
    }).toList();
  }

  List<DropdownMenuItem<String>> _generateLocationItems() {
    const locations = [
      '서울',
      '인천',
      '경기 남부',
      '경기 북부',
      '강원',
      '충북',
      '충남',
      '경북',
      '경남',
      '전북',
      '전남',
      '제주',
    ];

    return locations.map((location) {
      return DropdownMenuItem<String>(
        value: location,
        child: Text(location),
      );
    }).toList();
  }

}