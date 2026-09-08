import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageManager {
  static const String _languageKey = 'selected_language';
  static const String _defaultLanguage = 'es';

  // Get saved language code
  static Future<String> getLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? _defaultLanguage;
  }

  // Save language code
  static Future<void> setLanguageCode(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }

  // Get locale from language code
  static Future<Locale> getLocale() async {
    String languageCode = await getLanguageCode();
    return Locale(languageCode);
  }

  // Save locale
  static Future<void> setLocale(Locale locale) async {
    await setLanguageCode(locale.languageCode);
  }

  // Get supported locales
  static List<Locale> getSupportedLocales() {
    return [
      const Locale('es'), // Spanish
      const Locale('en'), // English
    ];
  }

  // Get language name from code
  static String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'es':
        return 'Español';
      case 'en':
        return 'English';
      default:
        return 'Español';
    }
  }

  // Clear language preference (reset to default)
  static Future<void> clearLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_languageKey);
  }
}
