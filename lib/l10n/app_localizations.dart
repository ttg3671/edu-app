import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  final Locale locale;
  Map<String, String> _localizedStrings = {};

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  Future<bool> load() async {
    String jsonString =
        await rootBundle.loadString('lib/l10n/${locale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);

    _localizedStrings = jsonMap.map((key, value) {
      return MapEntry(key, value.toString());
    });

    return true;
  }

  String translate(String key, {Map<String, String>? params}) {
    String translation = _localizedStrings[key] ?? key;

    if (params != null) {
      params.forEach((paramKey, paramValue) {
        translation = translation.replaceAll('{$paramKey}', paramValue);
      });
    }

    return translation;
  }

  // Helper getters for commonly used translations
  String get appName => translate('app_name');
  String get heyThere => translate('hey_there');
  String get welcome => translate('welcome');
  String get welcomeBack => translate('welcome_back');
  String get createAccount => translate('create_account');
  String get dontHaveAccount => translate('dont_have_account');
  String get alreadyHaveAccount => translate('already_have_account');
  String get signUp => translate('sign_up');
  String get logIn => translate('log_in');
  String get email => translate('email');
  String get password => translate('password');
  String get confirmPassword => translate('confirm_password');
  String get forgotPassword => translate('forgot_password');
  String get login => translate('login');
  String get register => translate('register');
  String get home => translate('home');
  String get search => translate('search');
  String get profile => translate('profile');
  String get account => translate('account');
  String get personalDetails => translate('personal_details');
  String get subscription => translate('subscription');
  String get followUs => translate('follow_us');
  String get other => translate('other');
  String get privacyPolicy => translate('privacy_policy');
  String get termsConditions => translate('terms_conditions');
  String get cookiePolicy => translate('cookie_policy');
  String get legalNotice => translate('legal_notice');
  String get deleteAccount => translate('delete_account');
  String get logout => translate('logout');
  String get edit => translate('edit');
  String get name => translate('name');
  String get update => translate('update');
  String get next => translate('next');
  String get continueBtn => translate('continue');
  String get cancel => translate('cancel');
  String get delete => translate('delete');
  String get retry => translate('retry');
  String get language => translate('language');
  String get selectLanguage => translate('select_language');
  String get english => translate('english');
  String get spanish => translate('spanish');
  String get modules => translate('modules');
  String get lessons => translate('lessons');
  String get videos => translate('videos');
  String get viewAll => translate('view_all');
  String get about => translate('about');
  String get syllabus => translate('syllabus');
  String get description => translate('description');
  String get instructor => translate('instructor');
  String get duration => translate('duration');
  String get level => translate('level');
  String get startLearning => translate('start_learning');
  String get continueLearning => translate('continue_learning');
  String get lesson => translate('lesson');
  String get video => translate('video');
  String get watchNow => translate('watch_now');
  String get comingSoon => translate('coming_soon');
  String get newLabel => translate('new');
  String get popular => translate('popular');
  String get recommended => translate('recommended');
  String get categories => translate('categories');
  String get all => translate('all');
  String get courseContent => translate('course_content');
  String get readMore => translate('read_more');
  String get readLess => translate('read_less');
  String get quality => translate('quality');
  String get auto => translate('auto');
  String get playbackSpeed => translate('playback_speed');
  String get playbackError => translate('playback_error');
  String get createNewAccount => translate('create_new_account');
  String get exploreWithoutAccount => translate('explore_without_account');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'es'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
