import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class DeepLinkService {
  static DeepLinkService? _instance;
  static DeepLinkService get instance => _instance ??= DeepLinkService._();

  DeepLinkService._();

  static void initialize() {
    // Listen for auth state changes from deep links
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        debugPrint('User signed in via deep link');
      } else if (event == AuthChangeEvent.signedOut) {
        debugPrint('User signed out');
      }
    });
  }

  // Handle deep link URL
  static Future<void> handleDeepLink(String url) async {
    try {
      debugPrint('Handling deep link: $url');

      // Parse the URL and handle authentication
      final Uri uri = Uri.parse(url);

      // Check if this is an auth callback
      if (uri.fragment.isNotEmpty) {
        // Extract auth tokens from fragment
        final fragment = uri.fragment;
        final params = Uri.splitQueryString(fragment);

        if (params.containsKey('access_token')) {
          // Handle auth tokens
          await SupabaseService.instance.client.auth.getSessionFromUrl(uri);
          debugPrint('Authentication successful from deep link');
        }
      }
    } catch (e) {
      debugPrint('Deep link handling error: $e');
    }
  }
}