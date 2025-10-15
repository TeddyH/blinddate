import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;

class LocaleService extends ChangeNotifier {
  static const String _localeKey = 'app_locale';
  Locale? _locale; // Will be initialized based on system or saved preference

  Locale get locale => _locale ?? _getSystemLocale();

  LocaleService() {
    _loadLocale();
  }

  /// Get the system locale and return 'ko' if Korean, otherwise 'en'
  Locale _getSystemLocale() {
    final systemLocale = ui.PlatformDispatcher.instance.locale;
    // Check if system language is Korean
    if (systemLocale.languageCode == 'ko') {
      return const Locale('ko');
    }
    // Default to English for all other languages
    return const Locale('en');
  }

  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final localeCode = prefs.getString(_localeKey);
      if (localeCode != null) {
        // User has explicitly set a language preference
        _locale = Locale(localeCode);
      } else {
        // No saved preference, use system locale
        _locale = _getSystemLocale();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading locale: $e');
      // Fallback to system locale on error
      _locale = _getSystemLocale();
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    _locale = locale;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, locale.languageCode);
    } catch (e) {
      debugPrint('Error saving locale: $e');
    }
  }

  bool get isKorean => _locale.languageCode == 'ko';
  bool get isEnglish => _locale.languageCode == 'en';
}
