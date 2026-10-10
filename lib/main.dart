import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:edu_gym/api/deep_link_service.dart';
import 'package:edu_gym/api/socket_service.dart';
import 'package:edu_gym/api/token_api.dart';
import 'package:edu_gym/core/common/constant/image_constant.dart';
import 'package:edu_gym/core/common/widgets/linear_gradient_mask.dart';
import 'package:edu_gym/features/account/presentation/cubit/account_cubit.dart';
import 'package:edu_gym/features/account/presentation/screens/account.dart';
import 'package:edu_gym/features/search/presentation/screens/search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/theme.dart';
import 'core/theme/app_color.dart';
import 'core/utils/device_util.dart';
import 'cubits/navigation_cubit.dart';
import 'cubits/pageview_cubit.dart';
import 'cubits/language_cubit.dart';
import 'features/home/presentation/cubit/new_home_cubit.dart';
import 'features/home/presentation/screen/new_home_screen.dart';
import 'features/home/presentation/screen/continue_watching_screen.dart';
import 'features/search/presentation/cubit/search_cubit.dart';
import 'features/auth/presentation/pages/starting_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:edu_gym/services/notification_service.dart';
import 'package:edu_gym/core/error/friendly_error.dart';
import 'package:edu_gym/features/quality_player/src/cast_bridge.dart';
import 'package:edu_gym/features/quality_player/src/cast_error_reporter.dart';
import 'l10n/app_localizations.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase & Push Notifications
  try {
    await Firebase.initializeApp();

    // Crashlytics: report Flutter framework errors and uncaught async errors
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    await NotificationService().init();
  } catch (e) {
    debugPrint('Firebase/Notification initialization error: $e');
  }

  await TokenApi.clearOnFreshInstall();
  await TokenApi.loadStoredData();

  // Initialize Deep Linking
  DeepLinkService().init();

  if (Platform.isAndroid || Platform.isIOS) {
    try {
      const appId = GoogleCastDiscoveryCriteria.kDefaultApplicationId;
      // The app can only control a session it started itself, so don't
      // leave the TV playing once the app is closed.
      final GoogleCastOptions options = Platform.isIOS
          ? IOSGoogleCastOptions(
              GoogleCastDiscoveryCriteriaInitialize.initWithApplicationID(
                  appId),
              stopCastingOnAppTerminated: true,
            )
          : GoogleCastOptionsAndroid(
              appId: appId,
              stopCastingOnAppTerminated: true,
            );
      await GoogleCastContext.instance.setSharedInstanceWithOptions(options);
    } catch (e, stack) {
      reportCastError(e, stack, 'initialization failed');
    }
    await CastBridge.instance.init();
  }

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  // Replaces Flutter's red/grey error box (shown when a widget fails to
  // build) with a plain message. The error itself is still reported through
  // FlutterError.onError above.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      child: Text(
        FriendlyError.networkError,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          decoration: TextDecoration.none,
        ),
      ),
    );
  };

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _isLoggedIn = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isLoggedIn = TokenApi.isUserLoggedIn();
    _checkAuthStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    DeepLinkService().dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // print("🚀 App Resumed - Reconnecting Socket and Refreshing Data");
      // Force socket to reconnect if user is logged in
      if (TokenApi.isUserLoggedIn()) {
        SocketService().socket?.connect();
        
        // Refresh account details globally
        try {
          final context = navigatorKey.currentContext;
          if (context != null) {
            context.read<AccountCubit>().getAccountDetails();
            context.read<NewHomeCubit>().loadHome();
          }
        } catch (e) {
          debugPrint('Error refreshing account on resume: $e');
        }
      }
    }
  }

  Future<void> _checkAuthStatus() async {
    final isLoggedIn = TokenApi.isUserLoggedIn();
    if (isLoggedIn) {
      final deviceId = await DeviceUtil.getDeviceId();
      SocketService().initSocket(deviceId);
      
      if (mounted) {
        setState(() {
          _isLoggedIn = true;
          _isLoading = false;
        });
      }
      
      // Proactively refresh token in background
      TokenApi().getAccessToken();
    } else {
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => LanguageCubit()),
        BlocProvider(create: (context) => NavigationCubit()),
        BlocProvider(create: (context) => NewHomeCubit()..loadHome()),
        BlocProvider(create: (context) {
          final cubit = AccountCubit();
          if (TokenApi.isUserLoggedIn()) {
            cubit.getAccountDetails();
          }
          return cubit;
        }),
        BlocProvider(create: (context) => SearchCubit()..loadPrefs()),
        BlocProvider(create: (context) => PageViewCubit()),
      ],
      child: BlocBuilder<LanguageCubit, Locale>(
        builder: (context, locale) {
          return ScreenUtilInit(
            designSize: const Size(430, 932),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (_, child) {
              return MaterialApp(
                navigatorKey: navigatorKey,
                debugShowCheckedModeBanner: false,
                title: 'EduMovimiento',
                theme: lightTheme,
                locale: locale,
                supportedLocales: const [
                  Locale('es'),
                  Locale('en'),
                ],
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                home: child,
              );
            },
            child: _isLoading
                ? const Scaffold(
                    body: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _isLoggedIn
                    ? const MyHomePage()
                    : const StartingScreen(),
          );
        },
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final bool isLoggedIn = TokenApi.isUserLoggedIn();

    final List<Widget> screens = isLoggedIn
        ? [
            const NewHomeScreen(),
            const Search(),
            const ContinueWatchingScreen(isFromBottomNav: true),
            const Account(),
          ]
        : [
            const NewHomeScreen(),
            const Search(),
            const Account(),
          ];

    return BlocBuilder<NavigationCubit, int>(
      builder: (context, index) {
        final safeIndex = index >= screens.length ? 0 : index;

        return Scaffold(
          body: SafeArea(
            child: IndexedStack(
              index: safeIndex,
              children: screens,
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColor.primary,
            unselectedItemColor: Colors.grey,
            items: isLoggedIn
                ? [
                    BottomNavigationBarItem(
                      icon: LinearGradientMask(
                        child: SvgPicture.asset(
                          SvgConstant.home,
                          colorFilter: ColorFilter.mode(
                            _getItemColor(safeIndex, 0),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      label: localizations?.home ?? "Home",
                    ),
                    BottomNavigationBarItem(
                      icon: LinearGradientMask(
                        child: SvgPicture.asset(
                          SvgConstant.search,
                          colorFilter: ColorFilter.mode(
                            _getItemColor(safeIndex, 1),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      label: localizations?.search ?? "Search",
                    ),
                    BottomNavigationBarItem(
                      icon: LinearGradientMask(
                        child: Icon(
                          Icons.history_rounded,
                          size: 24.sp,
                          color: _getItemColor(safeIndex, 2),
                        ),
                      ),
                      label: localizations?.history ?? "History",
                    ),
                    BottomNavigationBarItem(
                      icon: LinearGradientMask(
                        child: SvgPicture.asset(
                          SvgConstant.profile,
                          colorFilter: ColorFilter.mode(
                            _getItemColor(safeIndex, 3),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      label: localizations?.profile ?? "Profile",
                    ),
                  ]
                : [
                    BottomNavigationBarItem(
                      icon: LinearGradientMask(
                        child: SvgPicture.asset(
                          SvgConstant.home,
                          colorFilter: ColorFilter.mode(
                            _getItemColor(safeIndex, 0),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      label: localizations?.home ?? "Home",
                    ),
                    BottomNavigationBarItem(
                      icon: LinearGradientMask(
                        child: SvgPicture.asset(
                          SvgConstant.search,
                          colorFilter: ColorFilter.mode(
                            _getItemColor(safeIndex, 1),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      label: localizations?.search ?? "Search",
                    ),
                    BottomNavigationBarItem(
                      icon: LinearGradientMask(
                        child: SvgPicture.asset(
                          SvgConstant.profile,
                          colorFilter: ColorFilter.mode(
                            _getItemColor(safeIndex, 2),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      label: localizations?.profile ?? "Profile",
                    ),
                  ],
            currentIndex: safeIndex,
            onTap: (newIndex) {
              context.read<NavigationCubit>().changeIndex(newIndex);
            },
          ),
        );
      },
    );
  }

  Color _getItemColor(int currentIndex, int itemIndex) {
    return currentIndex == itemIndex ? AppColor.primary : Colors.grey;
  }
}
