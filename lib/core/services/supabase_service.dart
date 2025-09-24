import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();

  SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  // Auth Methods
  User? get currentUser => client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  Stream<AuthState> get authStateStream => client.auth.onAuthStateChange;

  Future<void> signInWithEmail(String email) async {
    await client.auth.signInWithOtp(email: email);
  }

  Future<AuthResponse> verifyOTP({
    required String email,
    required String token,
  }) async {
    return await client.auth.verifyOTP(
      type: OtpType.email,
      email: email,
      token: token,
    );
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      // 이메일 확인 링크를 정상적으로 보내도록 수정
    );
  }

  Future<AuthResponse> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Database Methods
  SupabaseQueryBuilder from(String table) {
    return client.from(table);
  }

  // Storage Methods
  SupabaseStorageClient get storage => client.storage;

  Future<String> uploadFile({
    required String bucket,
    required String path,
    required Uint8List fileBytes,
  }) async {
    await storage.from(bucket).uploadBinary(path, fileBytes);
    return storage.from(bucket).getPublicUrl(path);
  }

  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    await storage.from(bucket).remove([path]);
  }

  // Real-time Methods
  RealtimeChannel subscribeToChannel(String channelName) {
    return client.channel(channelName);
  }
}