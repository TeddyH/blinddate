import 'dart:io';
import 'package:flutter/foundation.dart';
import 'supabase_service.dart';
import '../../shared/models/image_source.dart' as model;

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static StorageService get instance => _instance;

  final SupabaseService _supabaseService = SupabaseService.instance;

  // Upload profile images
  Future<List<String>> uploadProfileImages({
    required String userId,
    required List<File> images,
  }) async {
    if (images.isEmpty) return [];

    final List<String> uploadedUrls = [];

    try {
      // Debug logging
      debugPrint('=== STORAGE UPLOAD DEBUG ===');
      debugPrint('User ID: $userId');
      debugPrint('Current user: ${_supabaseService.currentUser?.id}');
      debugPrint('Is authenticated: ${_supabaseService.isAuthenticated}');
      debugPrint('Images count: ${images.length}');
      for (int i = 0; i < images.length; i++) {
        final file = images[i];
        final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final path = 'profiles/$userId/$fileName';

        debugPrint('Uploading to path: $path');

        // Upload file to Supabase Storage
        await _supabaseService.storage
            .from('profile-images')
            .upload(path, file);

        // Get public URL
        final publicUrl = _supabaseService.storage
            .from('profile-images')
            .getPublicUrl(path);

        uploadedUrls.add(publicUrl);
        debugPrint('Uploaded image $i: $publicUrl');
      }

      return uploadedUrls;
    } catch (e) {
      debugPrint('Error uploading images: $e');
      // Clean up any partially uploaded images
      await _cleanupPartialUploads(userId, uploadedUrls);
      rethrow;
    }
  }

  // Delete profile images
  Future<void> deleteProfileImages({
    required String userId,
    required List<String> imageUrls,
  }) async {
    if (imageUrls.isEmpty) return;

    try {
      final List<String> pathsToDelete = [];

      for (final url in imageUrls) {
        // Extract path from public URL
        final uri = Uri.parse(url);
        final pathSegments = uri.pathSegments;

        // Find the path after 'profile-images'
        final profileImagesIndex = pathSegments.indexOf('profile-images');
        if (profileImagesIndex != -1 && profileImagesIndex < pathSegments.length - 1) {
          final path = pathSegments.sublist(profileImagesIndex + 1).join('/');
          pathsToDelete.add(path);
        }
      }

      if (pathsToDelete.isNotEmpty) {
        await _supabaseService.storage
            .from('profile-images')
            .remove(pathsToDelete);
        debugPrint('Deleted ${pathsToDelete.length} images');
      }
    } catch (e) {
      debugPrint('Error deleting images: $e');
      // Don't rethrow deletion errors as they shouldn't block the main operation
    }
  }

  // Clean up partially uploaded images in case of error
  Future<void> _cleanupPartialUploads(String userId, List<String> uploadedUrls) async {
    if (uploadedUrls.isNotEmpty) {
      await deleteProfileImages(userId: userId, imageUrls: uploadedUrls);
    }
  }

  // Update profile images with mixed sources
  Future<List<String>> updateProfileImagesFromSources({
    required String userId,
    required List<String> currentImageUrls,
    required List<dynamic> imageSources, // List of ImageSource
  }) async {
    try {
      final List<String> finalImageUrls = [];
      final List<File> newFilesToUpload = [];

      // Process each image source
      for (final source in imageSources) {
        if (source is model.NetworkImageSource) {
          // Keep existing network image
          finalImageUrls.add(source.url);
        } else if (source is model.FileImageSource) {
          // Collect new files for upload
          newFilesToUpload.add(source.file);
        }
      }

      // Upload new files
      if (newFilesToUpload.isNotEmpty) {
        final uploadedUrls = await uploadProfileImages(
          userId: userId,
          images: newFilesToUpload,
        );
        finalImageUrls.addAll(uploadedUrls);
      }

      // Delete unused old images
      final urlsToDelete = currentImageUrls
          .where((oldUrl) => !finalImageUrls.contains(oldUrl))
          .toList();

      if (urlsToDelete.isNotEmpty) {
        await deleteProfileImages(userId: userId, imageUrls: urlsToDelete);
      }

      return finalImageUrls;
    } catch (e) {
      debugPrint('Error updating profile images from sources: $e');
      rethrow;
    }
  }

  // Update profile images (delete old ones and upload new ones)
  Future<List<String>> updateProfileImages({
    required String userId,
    required List<String> oldImageUrls,
    required List<File> newImages,
  }) async {
    try {
      // Delete old images first
      if (oldImageUrls.isNotEmpty) {
        await deleteProfileImages(userId: userId, imageUrls: oldImageUrls);
      }

      // Upload new images
      return await uploadProfileImages(userId: userId, images: newImages);
    } catch (e) {
      debugPrint('Error updating profile images: $e');
      rethrow;
    }
  }

  // Get image URLs from profile data
  List<String> getImageUrlsFromProfile(Map<String, dynamic>? profile) {
    if (profile == null) return [];

    final imageUrls = profile['profile_image_urls'];
    if (imageUrls == null) return [];

    if (imageUrls is List) {
      return List<String>.from(imageUrls);
    } else if (imageUrls is String && imageUrls.isNotEmpty) {
      // For backward compatibility if stored as single URL
      return [imageUrls];
    }

    return [];
  }
}