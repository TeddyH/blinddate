import 'package:flutter/foundation.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/constants/table_names.dart';

class ProfileService extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService.instance;

  Map<String, dynamic>? _currentUserProfile;
  Map<String, dynamic>? get currentUserProfile => _currentUserProfile;
  set currentUserProfile(Map<String, dynamic>? profile) {
    _currentUserProfile = profile;
    notifyListeners();
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Get current user's profile
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    try {
      _setLoading(true);
      _clearError();

      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabaseService
          .from(TableNames.users)
          .select()
          .eq('id', userId)
          .single();

      _currentUserProfile = response;
      notifyListeners();
      return response;
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      _setError('프로필 정보를 불러오는 중 오류가 발생했습니다: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Update user profile
  Future<bool> updateUserProfile({
    String? nickname,
    String? bio,
    String? occupation,
    String? school,
    List<String>? interests,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final updateData = <String, dynamic>{};
      if (nickname != null) updateData['nickname'] = nickname;
      if (bio != null) updateData['bio'] = bio;
      if (occupation != null) updateData['occupation'] = occupation;
      if (school != null) updateData['school'] = school;
      if (interests != null) updateData['interests'] = interests;

      updateData['updated_at'] = DateTime.now().toIso8601String();

      await _supabaseService
          .from(TableNames.users)
          .update(updateData)
          .eq('id', userId);

      // Refresh local profile data
      await getCurrentUserProfile();

      debugPrint('Profile updated successfully');
      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      _setError('프로필 업데이트 중 오류가 발생했습니다: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Upload profile image
  Future<String?> uploadProfileImage(String filePath, String fileName) async {
    try {
      _setLoading(true);
      _clearError();

      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final imageBytes = await _readFileAsBytes(filePath);
      final storagePath = 'profile_images/$userId/$fileName';

      await _supabaseService.storage
          .from('profile-images')
          .uploadBinary(storagePath, Uint8List.fromList(imageBytes));

      final imageUrl = _supabaseService.storage
          .from('profile-images')
          .getPublicUrl(storagePath);

      debugPrint('Image uploaded: $imageUrl');
      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      _setError('이미지 업로드 중 오류가 발생했습니다: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Update profile images
  Future<bool> updateProfileImages(List<String> imageUrls) async {
    try {
      _setLoading(true);
      _clearError();

      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _supabaseService
          .from(TableNames.users)
          .update({
            'profile_image_urls': imageUrls,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      // Refresh local profile data
      await getCurrentUserProfile();

      debugPrint('Profile images updated successfully');
      return true;
    } catch (e) {
      debugPrint('Error updating profile images: $e');
      _setError('프로필 이미지 업데이트 중 오류가 발생했습니다: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete account
  Future<bool> deleteAccount() async {
    try {
      _setLoading(true);
      _clearError();

      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Mark user as deleted instead of actually deleting
      await _supabaseService
          .from(TableNames.users)
          .update({
            'approval_status': 'deleted',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      // Sign out user
      await _supabaseService.signOut();

      debugPrint('Account deleted successfully');
      return true;
    } catch (e) {
      debugPrint('Error deleting account: $e');
      _setError('계정 삭제 중 오류가 발생했습니다: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<bool> signOut() async {
    try {
      _setLoading(true);
      _clearError();

      await _supabaseService.signOut();
      _currentUserProfile = null;
      notifyListeners();

      debugPrint('Signed out successfully');
      return true;
    } catch (e) {
      debugPrint('Error signing out: $e');
      _setError('로그아웃 중 오류가 발생했습니다: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Helper method to read file as bytes (placeholder)
  Future<List<int>> _readFileAsBytes(String filePath) async {
    // This would need to be implemented based on your file picking method
    // For now, return empty list
    return <int>[];
  }

  // Calculate age from birth date
  int calculateAge(String? birthDateString) {
    if (birthDateString == null) return 0;

    try {
      final birthDate = DateTime.parse(birthDateString);
      final today = DateTime.now();
      int age = today.year - birthDate.year;

      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }

      return age;
    } catch (e) {
      return 0;
    }
  }

  // Get profile image URLs
  List<String> getProfileImages() {
    final imageUrls = _currentUserProfile?['profile_image_urls'];
    if (imageUrls == null) return [];

    if (imageUrls is List) {
      return imageUrls.cast<String>();
    }

    return [];
  }

  // Get user interests
  List<String> getUserInterests() {
    final interests = _currentUserProfile?['interests'];
    if (interests == null) return [];

    if (interests is List) {
      return interests.cast<String>();
    }

    return [];
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}