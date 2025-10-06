import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/profile_options.dart';
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
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  // Basic info
  List<model.ProfileImageSource> _images = [];
  String? _selectedGender = 'male';
  int? _selectedBirthYear = 2000;
  String? _selectedMbti = 'ISTJ';
  String? _selectedLocation = '서울';
  String? _selectedJobCategory = '무직';

  // New fields
  List<String> _personalityTraits = [];
  List<String> _othersSayAboutMe = [];
  List<String> _idealTypeTraits = [];
  List<String> _dateStyles = [];
  String? _drinkingStyle = 'none';
  String? _smokingStatus = 'non_smoker';
  List<String> _interests = [];

  // State
  bool _isLoading = false;
  bool _isLoadingData = true;
  bool _isUpdating = false;
  String? _currentApprovalStatus;

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

      if (profile != null) {
        final storageService = StorageService.instance;
        final imageUrls = storageService.getImageUrlsFromProfile(profile);
        final imageSources =
            imageUrls.map((url) => model.NetworkImageSource(url)).toList();

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
          _selectedGender = profile['gender'];
          _selectedMbti = profile['mbti'];
          _selectedLocation = profile['location'];
          _selectedJobCategory = profile['job_category'];
          _interests = List<String>.from(profile['interests'] ?? []);
          _personalityTraits =
              List<String>.from(profile['personality_traits'] ?? []);
          _othersSayAboutMe =
              List<String>.from(profile['others_say_about_me'] ?? []);
          _idealTypeTraits =
              List<String>.from(profile['ideal_type_traits'] ?? []);
          _dateStyles = List<String>.from(profile['date_style'] ?? []);
          _drinkingStyle = profile['drinking_style'];
          _smokingStatus = profile['smoking_status'];
          _currentApprovalStatus =
              profile['approval_status'] ?? AppConstants.approvalPending;
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
      backgroundColor: const Color(0xFF252836),
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
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              '사진 추가',
              style: AppTextStyles.h3.copyWith(
                color: Colors.white,
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
          color: const Color(0xFF1A1F2E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFf093fb).withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 32, color: const Color(0xFFf093fb)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              style: AppTextStyles.body2.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);

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

    setState(() {
      _imageError = null;
      _interestError = null;
    });

    if (!_formKey.currentState!.validate()) {
      isValid = false;
    }

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
        final birthDate = DateTime(_selectedBirthYear!, 7, 1);

        String newApprovalStatus;
        if (_currentApprovalStatus == AppConstants.approvalApproved) {
          newApprovalStatus = AppConstants.approvalApproved;
        } else {
          newApprovalStatus = AppConstants.approvalPending;
        }

        await authService.updateUserProfile({
          'nickname': _nicknameController.text.trim(),
          'bio': _bioController.text.trim(),
          'birth_date': birthDate.toIso8601String().split('T')[0],
          'interests': _interests,
          'gender': _selectedGender,
          'mbti': _selectedMbti,
          'location': _selectedLocation,
          'job_category': _selectedJobCategory,
          'personality_traits': _personalityTraits,
          'others_say_about_me': _othersSayAboutMe,
          'ideal_type_traits': _idealTypeTraits,
          'date_style': _dateStyles,
          'drinking_style': _drinkingStyle,
          'smoking_status': _smokingStatus,
          'approval_status': newApprovalStatus,
          'rejection_reason': _currentApprovalStatus ==
                  AppConstants.approvalApproved
              ? null
              : null,
        }, imageSources: _images.isNotEmpty ? _images : null);
      } else {
        final files = _images
            .whereType<model.FileImageSource>()
            .map((source) => source.file)
            .toList();

        final birthDate = DateTime(_selectedBirthYear!, 7, 1);

        await authService.createUserProfile(
          nickname: _nicknameController.text.trim(),
          country: 'KR',
          birthDate: birthDate,
          bio: _bioController.text.trim(),
          interests: _interests,
          gender: _selectedGender!,
          profileImages: files.isNotEmpty ? files : null,
          mbti: _selectedMbti,
          location: _selectedLocation,
          jobCategory: _selectedJobCategory,
          personalityTraits: _personalityTraits,
          othersSayAboutMe: _othersSayAboutMe,
          idealTypeTraits: _idealTypeTraits,
          dateStyle: _dateStyles,
          drinkingStyle: _drinkingStyle,
          smokingStatus: _smokingStatus,
        );
      }

      if (mounted) {
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

        if (_isUpdating && _currentApprovalStatus == AppConstants.approvalApproved) {
          Navigator.of(context).pop();
        } else {
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
        backgroundColor: const Color.fromRGBO(6, 13, 24, 1),
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFf093fb)),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color.fromRGBO(6, 13, 24, 1),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '💕 Hearty',
              style: AppTextStyles.h1.copyWith(
                color: const Color(0xFFf093fb),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                _isUpdating ? '프로필 수정' : '프로필 설정',
                style: AppTextStyles.body2.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFf093fb)),
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildProfileImagesSection(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildBasicInfoSection(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildPersonalitySection(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildIdealTypeSection(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildLifestyleSection(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildInterestsSection(),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),
          ),
          _buildBottomButton(),
        ],
      ),
    );
  }

  Widget _buildProfileImagesSection() {
    return ProfileSectionCard(
      title: '📸 프로필 사진',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  color: const Color(0xFF1A1F2E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFf093fb).withOpacity(0.3),
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
                            const Icon(
                              Icons.add_a_photo_outlined,
                              color: Color(0xFFf093fb),
                              size: 24,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '사진 추가',
                              style: AppTextStyles.caption.copyWith(
                                color: const Color(0xFFf093fb),
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
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return ProfileSectionCard(
      title: '📝 기본 정보',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nickname and MBTI Row
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _nicknameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration(
                    labelText: '닉네임',
                    hintText: '닉네임을 입력하세요',
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
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _selectedMbti,
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: const Color(0xFF252836),
                  icon: Icon(Icons.arrow_drop_down,
                      color: Colors.white.withOpacity(0.7)),
                  decoration: _inputDecoration(
                    labelText: 'MBTI',
                    hintText: '선택',
                  ),
                  items: ProfileOptions.mbtiTypes
                      .map((mbti) => DropdownMenuItem(
                            value: mbti,
                            child: Text(mbti),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedMbti = value),
                  isExpanded: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Bio (자기소개)
          TextFormField(
            controller: _bioController,
            maxLines: 5,
            maxLength: 500,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration(
              labelText: '자기소개',
              hintText: '자신을 매력적으로 소개해보세요 (50자 이상)',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '자기소개를 입력해주세요';
              }
              if (value.trim().length < 50) {
                return '자기소개는 최소 50자 이상 작성해주세요';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Gender and Birth Year
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '성별',
                      style: AppTextStyles.body1.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      style: const TextStyle(color: Colors.white),
                      dropdownColor: const Color(0xFF252836),
                      decoration: _inputDecoration(),
                      items: ProfileOptions.genders.entries
                          .map((entry) => DropdownMenuItem(
                                value: entry.key,
                                child: Text(entry.value),
                              ))
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedGender = value),
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
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '생년월일',
                      style: AppTextStyles.body1.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DropdownButtonFormField<int>(
                      value: _selectedBirthYear,
                      style: const TextStyle(color: Colors.white),
                      dropdownColor: const Color(0xFF252836),
                      decoration: _inputDecoration(),
                      items: _generateBirthYearItems(),
                      onChanged: (value) =>
                          setState(() => _selectedBirthYear = value),
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
                      isExpanded: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Location and Job Category
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedLocation,
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: const Color(0xFF252836),
                  icon: Icon(Icons.arrow_drop_down,
                      color: Colors.white.withOpacity(0.7)),
                  decoration: _inputDecoration(
                    labelText: '거주지역',
                    hintText: '선택사항',
                  ),
                  items: ProfileOptions.locations
                      .map((location) => DropdownMenuItem(
                            value: location,
                            child: Text(location),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedLocation = value),
                  isExpanded: true,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedJobCategory,
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: const Color(0xFF252836),
                  icon: Icon(Icons.arrow_drop_down,
                      color: Colors.white.withOpacity(0.7)),
                  decoration: _inputDecoration(
                    labelText: '직업군',
                    hintText: '선택사항',
                  ),
                  items: ProfileOptions.jobCategories
                      .map((job) => DropdownMenuItem(
                            value: job,
                            child: Text(job),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedJobCategory = value),
                  isExpanded: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Drinking and Smoking
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _drinkingStyle,
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: const Color(0xFF252836),
                  icon: Icon(Icons.arrow_drop_down,
                      color: Colors.white.withOpacity(0.7)),
                  decoration: _inputDecoration(
                    labelText: '음주',
                    hintText: '선택',
                  ),
                  items: ProfileOptions.drinkingStyles.entries
                      .map((entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _drinkingStyle = value),
                  isExpanded: true,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _smokingStatus,
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: const Color(0xFF252836),
                  icon: Icon(Icons.arrow_drop_down,
                      color: Colors.white.withOpacity(0.7)),
                  decoration: _inputDecoration(
                    labelText: '흡연',
                    hintText: '선택',
                  ),
                  items: ProfileOptions.smokingStatuses.entries
                      .map((entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _smokingStatus = value),
                  isExpanded: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalitySection() {
    return ProfileSectionCard(
      title: '💫 나의 성격/매력',
      subtitle: '최대 5개 선택',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTagSelector(
            options: ProfileOptions.personalityTraits,
            selectedTags: _personalityTraits,
            maxSelection: 5,
            onTagToggle: (tag) {
              setState(() {
                if (_personalityTraits.contains(tag)) {
                  _personalityTraits.remove(tag);
                } else if (_personalityTraits.length < 5) {
                  _personalityTraits.add(tag);
                } else {
                  _showMaxSelectionWarning(5);
                }
              });
            },
          ),
          if (_personalityTraits.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '선택: ${_personalityTraits.length}/5개',
              style: AppTextStyles.caption.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            '👂 주변에서 듣는 말',
            style: AppTextStyles.body1.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '최대 3개 선택',
            style: AppTextStyles.caption.copyWith(
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildTagSelector(
            options: ProfileOptions.othersSayAboutMe,
            selectedTags: _othersSayAboutMe,
            maxSelection: 3,
            onTagToggle: (tag) {
              setState(() {
                if (_othersSayAboutMe.contains(tag)) {
                  _othersSayAboutMe.remove(tag);
                } else if (_othersSayAboutMe.length < 3) {
                  _othersSayAboutMe.add(tag);
                } else {
                  _showMaxSelectionWarning(3);
                }
              });
            },
          ),
          if (_othersSayAboutMe.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '선택: ${_othersSayAboutMe.length}/3개',
              style: AppTextStyles.caption.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIdealTypeSection() {
    return ProfileSectionCard(
      title: '❤️ 이상형/원하는 스타일',
      subtitle: '최대 5개 선택',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTagSelector(
            options: ProfileOptions.idealTypeTraits,
            selectedTags: _idealTypeTraits,
            maxSelection: 5,
            onTagToggle: (tag) {
              setState(() {
                if (_idealTypeTraits.contains(tag)) {
                  _idealTypeTraits.remove(tag);
                } else if (_idealTypeTraits.length < 5) {
                  _idealTypeTraits.add(tag);
                } else {
                  _showMaxSelectionWarning(5);
                }
              });
            },
          ),
          if (_idealTypeTraits.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '선택: ${_idealTypeTraits.length}/5개',
              style: AppTextStyles.caption.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLifestyleSection() {
    return ProfileSectionCard(
      title: '🎯 데이트 스타일',
      subtitle: '최대 2개 선택',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTagSelector(
            options: ProfileOptions.dateStyles,
            selectedTags: _dateStyles,
            maxSelection: 2,
            onTagToggle: (tag) {
              setState(() {
                if (_dateStyles.contains(tag)) {
                  _dateStyles.remove(tag);
                } else if (_dateStyles.length < 2) {
                  _dateStyles.add(tag);
                } else {
                  _showMaxSelectionWarning(2);
                }
              });
            },
          ),
          if (_dateStyles.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '선택: ${_dateStyles.length}/2개',
              style: AppTextStyles.caption.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInterestsSection() {
    return ProfileSectionCard(
      title: '🎨 관심사',
      subtitle: '최소 1개, 최대 5개 선택',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTagSelector(
            options: ProfileOptions.interests,
            selectedTags: _interests,
            maxSelection: 5,
            onTagToggle: (tag) {
              setState(() {
                if (_interests.contains(tag)) {
                  _interests.remove(tag);
                  _interestError = null;
                } else if (_interests.length < 5) {
                  _interests.add(tag);
                  _interestError = null;
                } else {
                  _showMaxSelectionWarning(5);
                }
              });
            },
          ),
          if (_interests.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '선택: ${_interests.length}/5개',
              style: AppTextStyles.caption.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
          if (_interestError != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _interestError!,
              style: AppTextStyles.caption.copyWith(color: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTagSelector({
    required List<String> options,
    required List<String> selectedTags,
    required int maxSelection,
    required Function(String) onTagToggle,
  }) {
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: 4,
      children: options.map((tag) {
        final isSelected = selectedTags.contains(tag);
        return GestureDetector(
          onTap: () => onTagToggle(tag),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFFf093fb).withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              tag,
              style: AppTextStyles.caption.copyWith(
                color: isSelected
                    ? const Color(0xFFf093fb)
                    : Colors.white.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg).copyWith(
        top: AppSpacing.md,
        bottom: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF252836),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
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
            backgroundColor: const Color(0xFFf093fb),
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
              Icon(Icons.broken_image, color: AppColors.textSecondary, size: 24),
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
              Icon(Icons.broken_image, color: AppColors.textSecondary, size: 24),
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
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.photo_outlined, color: AppColors.textSecondary, size: 24),
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

  InputDecoration _inputDecoration({
    String? labelText,
    String? hintText,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
      filled: true,
      fillColor: const Color(0xFF1A1F2E),
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
        borderSide: const BorderSide(
          color: Color(0xFFf093fb),
          width: 2,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 16,
      ),
    );
  }

  List<DropdownMenuItem<int>> _generateBirthYearItems() {
    final currentYear = DateTime.now().year;
    final minYear = currentYear - 80;
    final maxYear = currentYear - 18;

    List<DropdownMenuItem<int>> items = [];

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

  void _showMaxSelectionWarning(int max) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('최대 $max개까지 선택할 수 있습니다'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
