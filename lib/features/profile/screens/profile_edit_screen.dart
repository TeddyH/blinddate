import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../shared/widgets/profile_section_card.dart';
import '../services/profile_service.dart';

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

    final profileService = context.read<ProfileService>();
    final success = await profileService.updateUserProfile(
      nickname: _nicknameController.text.trim(),
      bio: _bioController.text.trim(),
      interests: _selectedInterests,
    );

    setState(() {
      _isLoading = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('프로필이 성공적으로 업데이트되었습니다'),
        ),
      );
      Navigator.of(context).pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(profileService.errorMessage ?? '프로필 업데이트에 실패했습니다'),
        ),
      );
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
        imageQuality: 80,
        maxWidth: 1080,
        maxHeight: 1080,
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
        title: Text(
          '프로필 편집',
          style: AppTextStyles.h2.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text(
              '저장',
              style: TextStyle(
                color: _isLoading ? AppColors.textSecondary : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Images Section
              _buildProfileImagesSection(),
              const SizedBox(height: AppSpacing.xl),

              // Basic Info Section
              _buildBasicInfoSection(),
              const SizedBox(height: AppSpacing.xl),

              // Interests Section
              _buildInterestsSection(),
              const SizedBox(height: AppSpacing.xl),
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
              hintText: '다른 사용자에게 보여질 이름을 입력하세요',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
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
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
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
        ],
      ),
    );
  }

  Widget _buildInterestsSection() {
    return ProfileSectionCard(
      title: '관심사',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '최대 5개까지 선택 가능합니다',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: _availableInterests.map((interest) {
              final isSelected = _selectedInterests.contains(interest);
              return FilterChip(
                label: Text(interest),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      if (_selectedInterests.length < 5) {
                        _selectedInterests.add(interest);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('최대 5개까지만 선택할 수 있습니다'),
                          ),
                        );
                      }
                    } else {
                      _selectedInterests.remove(interest);
                    }
                  });
                },
                backgroundColor: Colors.grey[100],
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}