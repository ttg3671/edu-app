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
  String get stayTuned => translate('stay_tuned');
  String get comingSoonStayTuned => translate('coming_soon_stay_tuned');
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
  String get forgotPasswordTitle => translate('forgot_password_title');
  String get forgotPasswordQuestion => translate('forgot_password_question');
  String get enterEmailUppercase => translate('enter_email_uppercase');
  String get enterOtpUppercase => translate('enter_otp_uppercase');
  String get forgotPasswordInstruction => translate('forgot_password_instruction');
  String get submitBtn => translate('submit');
  String get backToLogin => translate('back_to_login');
  String get enterYourEmail => translate('enter_your_email');
  String get enterEmailOtp => translate('enter_email_otp');
  String enterOtp(String email) => translate('enter_otp', params: {'email': email});
  String get verifyOtpHeading => translate('verify_otp_heading');
  String get sixDigitCodeSubheading => translate('six_digit_code_subheading');
  String get sentTo => translate('sent_to');
  String get emailSuccessfullySent => translate('email_successfully_sent');
  String get enterSixDigitOtp => translate('enter_six_digit_otp');
  String get verifyOtpButton => translate('verify_otp_button');
  String resendOtpIn(String time) => translate('resend_otp_in', params: {'time': time});
  String get pleaseEnterCompleteOtp => translate('please_enter_complete_otp');
  String get sendOtp => translate('send_otp');
  String get verifyOtp => translate('verify_otp');
  String get resendOtp => translate('resend_otp');
  String get otp => translate('otp');
  String get enterOtpHint => translate('enter_otp_hint');
  String get pleaseEnterEmail => translate('please_enter_email');
  String get pleaseEnterOtp => translate('please_enter_otp');
  String get otpSentToEmail => translate('otp_sent_to_email');
  String get otpVerifiedSuccess => translate('otp_verified_success');
  String get resetPasswordTitle => translate('reset_password_title');
  String get resetPasswordHeading => translate('reset_password_heading');
  String get changePasswordSubheading => translate('change_password_subheading');
  String get confirm => translate('confirm');
  String get enterNewPassword => translate('enter_new_password');
  String get newPassword => translate('new_password');
  String get resetPassword => translate('reset_password');
  String get pleaseEnterNewPassword => translate('please_enter_new_password');
  String get pleaseConfirmPassword => translate('please_confirm_password');
  String get passwordsNotMatch => translate('passwords_not_match');
  String get passwordMinLength => translate('password_min_length');
  String get passwordResetSuccess => translate('password_reset_success');
  String get verifyEmailHeading => translate('verify_email_heading');
  String get emailNotVerifiedYet => translate('email_not_verified_yet');
  String get clickButtonToReceiveNotification => translate('click_button_to_receive_notification');
  String get verifyEmailBtn => translate('verify_email_btn');
  String get verificationEmailSentSuccess => translate('verification_email_sent_success');
  String get emailVerifiedHeading => translate('email_verified_heading');
  String get emailVerifiedSubheading => translate('email_verified_subheading');
  String get emailVerificationSuccessful => translate('email_verification_successful');
  String get continueWatching => translate('continue_watching');
  String redirectingInSeconds(int seconds) =>
      translate('redirecting_in_seconds', params: {'seconds': seconds.toString()});
  String get continueToHome => translate('continue_to_home');
  String get workoutInstructions => translate('workout_instructions');
  String get paymentSuccessHeading => translate('payment_success_heading');
  String get paymentSuccessTitle => translate('payment_success_title');
  String get paymentSuccessSubtitle => translate('payment_success_subtitle');
  String get paymentCancelledHeading => translate('payment_cancelled_heading');
  String get paymentCancelledTitle => translate('payment_cancelled_title');
  String get paymentCancelledSubtitle => translate('payment_cancelled_subtitle');
  String get subscriptionCancelledHeading => translate('subscription_cancelled_heading');
  String get subscriptionCancelledMsg => translate('subscription_cancelled_msg');
  String get changedMindNeedSubscription => translate('changed_mind_need_subscription');
  String get tryAgain => translate('try_again');
  String get backToHome => translate('back_to_home');
  String get viewSubscription => translate('view_subscription');
  String get membershipActive => translate('membership_active');
  String get resume => translate('resume');
  String get completed => translate('completed');
  String get noContinueWatchingVideos => translate('no_continue_watching_videos');
  String get noContinueWatchingSubtitle => translate('no_continue_watching_subtitle');
  String get history => translate('history');
  String get watchHistory => translate('watch_history');
  String get startWatching => translate('start_watching');
  String get premium => translate('premium');
  String get emailMeAccessSteps => translate('email_me_access_steps');
  String get unlimitedFitnessAccess => translate('unlimited_fitness_access');
  String get getPremiumDesc => translate('get_premium_desc');
  String get cancelPremium => translate('cancel_premium');
  String get cancelPremiumTitle => translate('cancel_premium_title');
  String get cancelPremiumDialogContent => translate('cancel_premium_dialog_content');
  String get keepPremium => translate('keep_premium');
  String get yesCancel => translate('yes_cancel');
  String get noActivePremiumId => translate('no_active_premium_id');
  String get failedToCancelPremium => translate('failed_to_cancel_premium');
  String get premiumCancelledSuccess => translate('premium_cancelled_success');
  String get emailSentSuccess => translate('email_sent_success');
  String get failedToSendAccessSteps => translate('failed_to_send_access_steps');
  String get failedToRefreshMembership => translate('failed_to_refresh_membership');
  String get reviewerMode => translate('reviewer_mode');
  String get membershipExpired => translate('membership_expired');
  String get activeFitnessPass => translate('active_fitness_pass');
  String get reviewerAccess => translate('reviewer_access');
  String get premiumAccess => translate('premium_access');
  String get never => translate('never');
  String get active => translate('active');
  String get unlimited => translate('unlimited');
  String get free => translate('free');
  String get lifetime => translate('lifetime');
  String expiredOn(String date) => translate('expired_on', params: {'date': date});
  String expiresOn(String date) => translate('expires_on', params: {'date': date});
  String get statusLabel => translate('status');
  String get devicesAllowedPerAccount => translate('devices_allowed_per_account');
  String get planDuration => translate('plan_duration');
  String get price => translate('price');
  String get reviewer => translate('reviewer');
  String get expired => translate('expired');
  String get month => translate('month');
  String get months => translate('months');
  String get year => translate('year');
  String get years => translate('years');
  String get refreshPageToViewStatus => translate('refresh_page_to_view_status');
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
