import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/table_names.dart';

// 커스텀 예외 클래스
class AuthEmailNotConfirmedException implements Exception {
  final String message;
  AuthEmailNotConfirmedException(this.message);

  @override
  String toString() => 'AuthEmailNotConfirmedException: $message';
}

class AuthService with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService.instance;
  final StorageService _storageService = StorageService.instance;
  final NotificationService _notificationService = NotificationService.instance;

  User? get currentUser => _supabaseService.currentUser;
  bool get isAuthenticated => _supabaseService.isAuthenticated;

  // Cache for user profile
  Map<String, dynamic>? _cachedProfile;
  DateTime? _cacheTimestamp;

  // Set cached profile (for when we already have the profile data)
  void setCachedProfile(Map<String, dynamic> profile) {
    _cachedProfile = profile;
    _cacheTimestamp = DateTime.now();
    debugPrint('Profile cached via setCachedProfile');
  }

  // Auth state stream
  Stream<AuthState> get authStateStream => _supabaseService.authStateStream;

  // Email confirmation is disabled - all users are considered confirmed
  bool get isEmailConfirmed => currentUser != null;

  // Email authentication
  Future<void> signInWithEmail(String email) async {
    try {
      await _supabaseService.signInWithEmail(email);
      notifyListeners();
    } catch (e) {
      debugPrint('Email sign in error: $e');
      rethrow;
    }
  }

  // Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabaseService.signUpWithEmail(
        email: email,
        password: password,
      );
      notifyListeners();
      return response;
    } catch (e) {
      debugPrint('Email sign up error: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabaseService.signInWithEmailPassword(
        email: email,
        password: password,
      );
      notifyListeners();
      return response;
    } catch (e) {
      debugPrint('Email password sign in error: $e');

      // 이메일 미인증 에러의 경우 더 자세한 로깅
      if (e is AuthApiException && e.code == 'email_not_confirmed') {
        debugPrint('Email not confirmed error detected - bypassing for app UX');
        debugPrint('Error details: $e');

        // 앱에서는 이메일 인증을 요구하지 않으므로 성공으로 간주
        // 하지만 실제로는 로그인되지 않은 상태이므로 특별한 처리가 필요
        throw AuthEmailNotConfirmedException('이메일 미인증 상태입니다.');
      }

      // 문자열로도 체크 (fallback)
      if (e.toString().contains('Email not confirmed')) {
        debugPrint('Email not confirmed error detected (fallback) - bypassing for app UX');
        debugPrint('Error details: $e');
        throw AuthEmailNotConfirmedException('이메일 미인증 상태입니다.');
      }

      rethrow;
    }
  }

  // Verify OTP
  Future<AuthResponse> verifyOTP({
    required String email,
    required String token,
  }) async {
    try {
      final response = await _supabaseService.verifyOTP(
        email: email,
        token: token,
      );

      // 로그인 성공 시 FCM 토큰 저장
      if (response.user != null) {
        await _notificationService.onUserLogin();
      }

      notifyListeners();
      return response;
    } catch (e) {
      debugPrint('OTP verification error: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // FCM 토큰 제거
      await _notificationService.onUserLogout();

      await _supabaseService.signOut();
      notifyListeners();
    } catch (e) {
      debugPrint('Sign out error: $e');
      rethrow;
    }
  }

  // Check user profile completion status
  Future<Map<String, dynamic>?> getUserProfile({bool forceRefresh = false}) async {
    if (!isAuthenticated) return null;

    // Return cached profile if available and not forcing refresh
    if (!forceRefresh &&
        _cachedProfile != null &&
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!).inMinutes < 5) {
      debugPrint('Returning cached profile');
      return _cachedProfile;
    }

    try {
      final response = await _supabaseService
          .from(TableNames.users)
          .select()
          .eq('id', currentUser!.id)
          .single();

      // Cache the profile
      _cachedProfile = response;
      _cacheTimestamp = DateTime.now();
      debugPrint('Profile cached successfully');

      return response;
    } catch (e) {
      debugPrint('Get user profile error: $e');
      // Return cached profile if network fails
      if (_cachedProfile != null) {
        debugPrint('Returning cached profile due to network error');
        return _cachedProfile;
      }
      return null;
    }
  }

  // Check approval status
  Future<String> getUserApprovalStatus() async {
    final profile = await getUserProfile();
    return profile?['approval_status'] ?? AppConstants.approvalPending;
  }

  // Create user profile
  Future<void> createUserProfile({
    required String nickname,
    required String country,
    required DateTime birthDate,
    required String bio,
    required List<String> interests,
    required String gender,
    List<File>? profileImages,
  }) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      // Upload images if provided
      List<String> imageUrls = [];
      if (profileImages != null && profileImages.isNotEmpty) {
        imageUrls = await _storageService.uploadProfileImages(
          userId: currentUser!.id,
          images: profileImages,
        );
      }

      await _supabaseService.from(TableNames.users).insert({
        'id': currentUser!.id,
        'email': currentUser!.email,
        'nickname': nickname,
        'country': country,
        'birth_date': birthDate.toIso8601String(),
        'bio': bio,
        'interests': interests,
        'gender': gender,
        'profile_image_urls': imageUrls,
        'approval_status': AppConstants.approvalPending,
      });

      // Invalidate cache to force refresh on next access
      _cachedProfile = null;
      _cacheTimestamp = null;

      notifyListeners();
    } catch (e) {
      debugPrint('Create user profile error: $e');
      rethrow;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(Map<String, dynamic> updates, {List<dynamic>? imageSources}) async {
    if (!isAuthenticated) throw Exception('User not authenticated');

    try {
      // Handle image updates if provided
      if (imageSources != null) {
        // Get current profile to find existing images
        final currentProfile = await getUserProfile();
        final currentImageUrls = _storageService.getImageUrlsFromProfile(currentProfile);

        // Update images using the new method
        final newImageUrls = await _storageService.updateProfileImagesFromSources(
          userId: currentUser!.id,
          currentImageUrls: currentImageUrls,
          imageSources: imageSources,
        );

        // Add image URLs to updates
        updates['profile_image_urls'] = newImageUrls;
      }

      await _supabaseService
          .from(TableNames.users)
          .update(updates)
          .eq('id', currentUser!.id);

      // Invalidate cache to force refresh on next access
      _cachedProfile = null;
      _cacheTimestamp = null;

      notifyListeners();
    } catch (e) {
      debugPrint('Update user profile error: $e');
      rethrow;
    }
  }
}