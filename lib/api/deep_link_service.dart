import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:edu_gym/api/api.dart';
import 'package:edu_gym/api/token_api.dart';
import 'package:edu_gym/cubits/navigation_cubit.dart';
import 'package:edu_gym/features/account/presentation/cubit/account_cubit.dart';
import 'package:edu_gym/features/account/presentation/screens/subscription_screen.dart';
import 'package:edu_gym/features/auth/presentation/pages/email_verified.dart';
import 'package:edu_gym/features/home/presentation/cubit/new_home_cubit.dart';
import 'package:edu_gym/main.dart';
import 'package:edu_gym/modal/subscription_details.dart';
import 'package:edu_gym/modal/user_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:edu_gym/features/account/presentation/screens/payment_canceled_screen.dart';
import 'package:edu_gym/features/account/presentation/screens/payment_success_screen.dart';
import 'package:edu_gym/features/home/presentation/screen/continue_watching_screen.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  String? _lastHandledUri;
  DateTime? _lastHandledTime;

  void init() {
    // 1. Handle links when app is in background or terminated (cold start)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    }).catchError((err) {
      debugPrint('⚠️ DeepLink getInitialLink error: $err');
    });

    // 2. Handle links when app is running (foreground or background resume)
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint('⚠️ DeepLink uriLinkStream error: $err');
    });
  }

  Future<void> _ensureNavigatorReady() async {
    int attempts = 0;
    while (navigatorKey.currentState == null && attempts < 50) {
      await Future.delayed(const Duration(milliseconds: 100));
      attempts++;
    }
  }

  bool _isDuplicate(Uri uri) {
    final uriStr = uri.toString().trim();
    final now = DateTime.now();
    if (_lastHandledUri == uriStr &&
        _lastHandledTime != null &&
        now.difference(_lastHandledTime!) < const Duration(milliseconds: 1500)) {
      return true;
    }
    _lastHandledUri = uriStr;
    _lastHandledTime = now;
    return false;
  }

  void _handleDeepLink(Uri uri) async {
    debugPrint('🔗 Deep Link Received: $uri');

    if (_isDuplicate(uri)) {
      debugPrint('ℹ️ Ignoring duplicate deep link: $uri');
      return;
    }

    await _ensureNavigatorReady();
    if (navigatorKey.currentState == null) {
      debugPrint('⚠️ DeepLink: NavigatorState not available after waiting.');
      return;
    }
    
    final uriStr = uri.toString().toLowerCase().trim();
    final scheme = uri.scheme.toLowerCase().trim();
    final host = uri.host.toLowerCase().trim();
    final path = uri.path.toLowerCase().replaceAll('/', '').trim();
    final screenParam = (uri.queryParameters['screen'] ??
                         uri.queryParameters['target'] ??
                         uri.queryParameters['page'] ??
                         uri.queryParameters['name'] ?? '').toLowerCase().trim();
    final statusParam = (uri.queryParameters['status'] ?? '').toLowerCase().trim();
    final sessionId = uri.queryParameters['session_id'] ?? uri.queryParameters['sessionId'];

    final isSpecialHost = host.isEmpty || host == 'screen' || host == 'app' || host == 'callback';
    final target = (scheme == 'edugarciamovimiento' || scheme == 'edugym') && !isSpecialHost
        ? host
        : (screenParam.isNotEmpty ? screenParam : path);

    debugPrint('🎯 Deep Link Target identified: "$target" (host: "$host", path: "$path", screenParam: "$screenParam", statusParam: "$statusParam", sessionId: "$sessionId")');

    // 1. Email Verified Link Handling
    final isEmailVerifiedLink = _matchesRoute(target, path, ['email_verified', 'email-verified', 'emailverified', 'verified']) ||
        uriStr.contains('email_verified') ||
        uriStr.contains('email-verified') ||
        uriStr.contains('emailverified') ||
        (uriStr.contains('email') && statusParam == 'success') ||
        (uriStr.contains('verify') && statusParam == 'success');

    if (isEmailVerifiedLink) {
      _navigateToEmailVerified();
      return;
    }

    // 2. Payment Success
    if (_matchesRoute(target, path, ['payment-success', 'payment_success', 'paymentsuccess', 'success']) ||
        screenParam == 'payment-success' ||
        screenParam == 'payment_success' ||
        (uriStr.contains('payment') && statusParam == 'success')) {
      _navigateToPaymentSuccess(sessionId: sessionId);
      return;
    }

    // 3. Payment Canceled / Cancelled
    if (_matchesRoute(target, path, [
      'payment-canceled',
      'payment_canceled',
      'paymentcanceled',
      'payment-cancelled',
      'payment_cancelled',
      'paymentcancelled',
      'canceled',
      'cancelled',
      'cancel'
    ]) ||
        screenParam == 'payment-canceled' ||
        screenParam == 'payment_canceled' ||
        screenParam == 'payment-cancelled' ||
        screenParam == 'payment_cancelled' ||
        (uriStr.contains('payment') && (statusParam == 'cancel' || statusParam == 'canceled' || statusParam == 'cancelled'))) {
      _navigateToPaymentCanceled();
      return;
    }

    // 4. Subscriptions
    if (_matchesRoute(target, path, ['subscription', 'subscriptions'])) {
      _navigateToSubscription();
      return;
    }

    // 5. Continue Watching
    if (_matchesRoute(target, path, ['continue-watching', 'continuewatching', 'continue_watching', 'history'])) {
      _navigateToContinueWatching();
      return;
    }
  }

  bool _matchesRoute(String target, String path, List<String> patterns) {
    return patterns.contains(target) || patterns.contains(path);
  }

  void _navigateToContinueWatching() {
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (context) => const ContinueWatchingScreen(),
        ),
      );
    }
  }

  void _navigateToEmailVerified() async {
    debugPrint('🎉 DeepLink: Email verified successfully. Navigating to EmailVerified screen.');
    
    // Update local user email verified state if user is logged in
    if (TokenApi.user != null) {
      final updatedUser = UserDetails(
        email: TokenApi.user!.email,
        name: TokenApi.user!.name,
        bio: TokenApi.user!.bio,
        avatarUrl: TokenApi.user!.avatarUrl,
        isSubscribed: TokenApi.user!.isSubscribed,
        isReviewer: TokenApi.user!.isReviewer,
        subscriptionDetails: TokenApi.user!.subscriptionDetails,
        emailVerified: true,
      );
      await TokenApi().saveUserData(updatedUser);
    }

    try {
      final context = navigatorKey.currentContext;
      if (context != null) {
        context.read<NavigationCubit>().updateIndex(0);
        if (TokenApi.isUserLoggedIn()) {
          context.read<AccountCubit>().getAccountDetails();
          context.read<NewHomeCubit>().loadHome();
        }
      }
    } catch (_) {}

    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const EmailVerified(),
        ),
        (route) => false,
      );
    }
  }

  void _navigateToPaymentSuccess({String? sessionId}) async {
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (context) => PaymentSuccessScreen(sessionId: sessionId),
        ),
      );
    }
  }

  void _navigateToPaymentCanceled() {
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (context) => const PaymentCanceledScreen(),
        ),
      );
    }
  }

  Future<void> _refreshSubscriptionData() async {
    if (!TokenApi.isUserLoggedIn()) return;
    try {
      final result = await Api.instance.getLatestSubscription();
      
      await result.fold(
        (failure) async => debugPrint('❌ DeepLink: Failed to fetch latest subscription: ${failure.message}'),
        (data) async {
          if (data['isSuccess'] == true && data['data']?['subscription'] != null) {
            final subJson = data['data']['subscription'];
            final latestSub = SubscriptionDetails.fromJson(subJson);
            
            await TokenApi().updateSubscriptionDetails(latestSub);
            
            try {
              final context = navigatorKey.currentContext;
              if (context != null && context.mounted) {
                context.read<AccountCubit>().getAccountDetails();
                context.read<NewHomeCubit>().loadHome();
              }
            } catch (e) {
              debugPrint('⚠️ DeepLink: Could not refresh Cubits: $e');
            }
          }
        }
      );
    } catch (e) {
      debugPrint('⚠️ DeepLink: Exception refreshing subscription: $e');
    }
  }

  void _navigateToSubscription() async {
    await _refreshSubscriptionData();
    if (navigatorKey.currentState != null && TokenApi.user != null) {
      navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (context) => SubscriptionScreen(userDetails: TokenApi.user!),
        ),
      );
    }
  }

  void _navigateToHomePage() async {
    if (navigatorKey.currentState != null) {
      try {
        final context = navigatorKey.currentContext;
        if (context != null) {
          context.read<NavigationCubit>().updateIndex(0);
          if (TokenApi.isUserLoggedIn()) {
            context.read<AccountCubit>().getAccountDetails();
            context.read<NewHomeCubit>().loadHome();
          }
        }
      } catch (_) {}

      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const MyHomePage(),
        ),
        (route) => false,
      );
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
