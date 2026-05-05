import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/utils/language_manager.dart';

class LanguageCubit extends Cubit<Locale> {
  LanguageCubit() : super(const Locale('en')) {
    loadSavedLanguage();
  }

  // Load saved language on app start
  Future<void> loadSavedLanguage() async {
    final locale = await LanguageManager.getLocale();
    emit(locale);
  }

  // Change language
  Future<void> changeLanguage(String languageCode) async {
    final locale = Locale(languageCode);
    await LanguageManager.setLocale(locale);
    emit(locale);
  }

  // Get current language code
  String get currentLanguageCode => state.languageCode;

  // Get current language name
  String get currentLanguageName =>
      LanguageManager.getLanguageName(currentLanguageCode);
}
