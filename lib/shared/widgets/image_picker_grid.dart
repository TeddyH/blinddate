import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../models/image_source.dart' as model;
import '../utils/image_compression_utils.dart';

class ImagePickerGrid extends StatefulWidget {
  final List<model.ProfileImageSource> images;
  final Function(List<model.ProfileImageSource>) onImagesChanged;
  final String? errorText;

  const ImagePickerGrid({
    super.key,
    required this.images,
    required this.onImagesChanged,
    this.errorText,
  });

  @override
  State<ImagePickerGrid> createState() => _ImagePickerGridState();
}

class _ImagePickerGridState extends State<ImagePickerGrid> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    if (widget.images.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('최대 5장까지만 선택할 수 있습니다.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        await _processAndAddImage(File(image.path));
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
    final updatedImages = List<model.ProfileImageSource>.from(widget.images);
    updatedImages.removeAt(index);
    widget.onImagesChanged(updatedImages);
  }

  void _showImageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('갤러리에서 선택'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('카메라로 촬영'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromCamera() async {
    if (widget.images.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('최대 5장까지만 선택할 수 있습니다.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null) {
        await _processAndAddImage(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('사진을 촬영하는 중 오류가 발생했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  /// 이미지 처리 및 압축 후 목록에 추가
  Future<void> _processAndAddImage(File imageFile) async {
    try {
      // 로딩 표시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('이미지 처리 중...'),
              ],
            ),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // 원본 파일 크기 확인
      final double originalSizeKB = await ImageCompressionUtils.getFileSizeKB(imageFile);

      // 압축 처리 (100KB 이하면 압축하지 않음)
      final File processedImage = await ImageCompressionUtils.compressImageIfNeeded(imageFile);

      // 처리된 파일 크기 확인
      final double finalSizeKB = await ImageCompressionUtils.getFileSizeKB(processedImage);

      // 이미지 목록에 추가
      if (mounted) {
        widget.onImagesChanged([...widget.images, model.FileImageSource(processedImage)]);

        // 압축 결과 알림 (100KB를 넘었던 경우만)
        if (originalSizeKB > 100) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '이미지가 압축되었습니다: ${originalSizeKB.toStringAsFixed(1)}KB → ${finalSizeKB.toStringAsFixed(1)}KB',
              ),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지 처리 중 오류가 발생했습니다: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grid of images + add button
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: AppSpacing.sm,
            mainAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.0,
          ),
          itemCount: widget.images.length + (widget.images.length < 5 ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < widget.images.length) {
              // Image item
              return Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _buildImageWidget(widget.images[index]),
                    ),
                  ),
                  // Delete button
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                  // Main photo indicator
                  if (index == 0)
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '메인',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            } else {
              // Add button
              return GestureDetector(
                onTap: () => _showImageOptions(context),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: AppColors.surfaceVariant,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 32,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '사진 추가',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        ),

        const SizedBox(height: AppSpacing.sm),

        // Helper text
        Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '첫 번째 사진이 메인 프로필 사진이 됩니다. 최소 1장, 최대 5장까지 선택 가능합니다.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),

        // Error text
        if (widget.errorText != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            widget.errorText!,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.error,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImageWidget(model.ProfileImageSource imageSource) {
    if (imageSource is model.FileImageSource) {
      return Image.file(
        imageSource.file,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else if (imageSource is model.NetworkImageSource) {
      return Image.network(
        imageSource.url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: AppColors.surfaceVariant,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: AppColors.surfaceVariant,
            child: Icon(
              Icons.broken_image,
              color: AppColors.textSecondary,
              size: 32,
            ),
          );
        },
      );
    } else {
      return Container(
        color: AppColors.surfaceVariant,
        child: Icon(
          Icons.image,
          color: AppColors.textSecondary,
          size: 32,
        ),
      );
    }
  }
}