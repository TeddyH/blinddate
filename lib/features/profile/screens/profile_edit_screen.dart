import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/profile_section_card.dart';
import '../../../shared/models/image_source.dart' as model;
import '../services/profile_service.dart';
import '../../auth/services/auth_service.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  final _bioController = TextEditingController();

  List<String> _selectedInterests = [];
  List<String> _profileImages = [];
  List<File> _newImages = [];
  String? _selectedGender = 'male';
  int? _selectedBirthYear = 2000;
  String? _currentApprovalStatus;
  final List<String> _availableInterests = [
    '영화/드라마', '음악', '독서', '여행', '운동', '요리',
    '사진', '게임', '카페', '맛집', '쇼핑', '전시회',
    '콘서트', '스포츠', '등산', '바다', '반려동물', '술',
    '커피', '디저트', '패션', '뷰티', '자동차', '바이크',
  ];

  bool _isLoading = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentProfile() async {
    final profileService = context.read<ProfileService>();
    final profile = profileService.currentUserProfile;

    if (profile != null) {
      _nicknameController.text = profile['nickname'] ?? '';
      _bioController.text = profile['bio'] ?? '';

      final interests = profile['interests'];
      if (interests is List) {
        _selectedInterests = List<String>.from(interests);
      }

      final imageUrls = profile['profile_image_urls'];
      if (imageUrls is List) {
        _profileImages = List<String>.from(imageUrls);
      }

      // Load gender
      _selectedGender = profile['gender'] ?? 'male';

      // Load current approval status
      _currentApprovalStatus = profile['approval_status'] ?? AppConstants.approvalPending;

      // Load birth year from birth_date
      if (profile['birth_date'] != null) {
        try {
          final birthDate = DateTime.parse(profile['birth_date']);
          _selectedBirthYear = birthDate.year;
        } catch (e) {
          debugPrint('Error parsing birth_date: $e');
        }
      }

      setState(() {});
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = context.read<AuthService>();

      // Convert birth year to birth date (using July 1st as default date)
      final birthDate = DateTime(_selectedBirthYear!, 7, 1);

      // Convert File images to ImageSource models
      final imageSources = _newImages.map((file) => model.FileImageSource(file)).toList();
      final allImageSources = [
        ..._profileImages.map((url) => model.NetworkImageSource(url)),
        ...imageSources,
      ];

      // Determine approval status based on current status
      String newApprovalStatus;
      String successMessage;

      if (_currentApprovalStatus == AppConstants.approvalApproved) {
        // Keep approved status for already approved users
        newApprovalStatus = AppConstants.approvalApproved;
        successMessage = '프로필이 성공적으로 수정되었습니다.';
      } else {
        // Set to pending for new users or rejected users
        newApprovalStatus = AppConstants.approvalPending;
        successMessage = '프로필이 성공적으로 수정되었습니다. 관리자 재검토를 기다려주세요.';
      }

      // Update existing profile with all image sources
      await authService.updateUserProfile({
        'nickname': _nicknameController.text.trim(),
        'bio': _bioController.text.trim(),
        'birth_date': birthDate.toIso8601String().split('T')[0], // Format as YYYY-MM-DD
        'interests': _selectedInterests,
        'gender': _selectedGender,
        'approval_status': newApprovalStatus,
        'rejection_reason': _currentApprovalStatus == AppConstants.approvalApproved ? null : null, // Clear rejection reason only if not approved
      }, imageSources: allImageSources.isNotEmpty ? allImageSources : null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('프로필 수정 중 오류가 발생했습니다: $e'),
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

  Future<void> _showImagePickerOptions() async {
    final totalImages = _profileImages.length + _newImages.length;
    if (totalImages >= 3) {
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
          _newImages.add(file);
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

  void _removeImage(int index, bool isNew) {
    setState(() {
      if (isNew) {
        _newImages.removeAt(index - _profileImages.length);
      } else {
        _profileImages.removeAt(index);
      }
    });
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
                '프로필 편집',
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
                    key: _formKey,
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

              // Bottom save button
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
                    onPressed: _isLoading ? null : _saveProfile,
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
                          '수정 완료',
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
              final totalImages = _profileImages.length + _newImages.length;
              final hasOldImage = index < _profileImages.length;
              final hasNewImage = !hasOldImage && (index - _profileImages.length) < _newImages.length;
              final hasImage = hasOldImage || hasNewImage;

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
                            child: hasOldImage
                              ? Image.network(
                                  _profileImages[index],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
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
                                )
                              : Image.file(
                                  _newImages[index - _profileImages.length],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
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
                                ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index, !hasOldImage),
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
                return '닉네임을 입력해주세요';
              }
              if (value.trim().length < 2) {
                return '닉네임은 2자 이상 입력해주세요';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Bio
          TextFormField(
            controller: _bioController,
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
            maxLines: 8,
            maxLength: 500,
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
              final isSelected = _selectedInterests.contains(interest);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedInterests.remove(interest);
                    } else {
                      if (_selectedInterests.length < 5) {
                        _selectedInterests.add(interest);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('최대 5개까지 선택할 수 있습니다'),
                            backgroundColor: Colors.orange,
                          ),
                        );
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

          if (_selectedInterests.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '선택된 관심사: ${_selectedInterests.length}/5개',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}