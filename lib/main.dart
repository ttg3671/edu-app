import 'package:edu_gym/api/api.dart';
import 'package:edu_gym/api/token_api.dart';
import 'package:edu_gym/core/common/constant/image_constant.dart';
import 'package:edu_gym/core/common/widgets/linear_gradient_mask.dart';
import 'package:edu_gym/features/account/presentation/cubit/account_cubit.dart';
import 'package:edu_gym/features/account/presentation/screens/account.dart';
import 'package:edu_gym/features/search/presentation/screens/search.dart';
import 'package:edu_gym/modal/user_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/theme.dart';
import 'cubits/navigation_cubit.dart';
import 'cubits/pageview_cubit.dart';
import 'cubits/language_cubit.dart';
import 'features/home/presentation/cubit/new_home_cubit.dart';
import 'features/home/presentation/screen/new_home_screen.dart';
import 'features/search/presentation/cubit/search_cubit.dart';
import 'features/auth/presentation/pages/login.dart';
import 'features/auth/presentation/pages/starting_screen.dart';
import 'l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TokenApi.clearOnFreshInstall();
  await TokenApi.getCookie();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.white,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isLoggedIn = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Check if user has valid authentication
    final isLoggedIn = TokenApi.isUserLoggedIn();

    // Also verify the token is still valid
    if (isLoggedIn) {
      final token = await TokenApi().getAccessToken();
      setState(() {
        _isLoggedIn = token != null && token.isNotEmpty;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoggedIn = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LanguageCubit(),
      child: BlocBuilder<LanguageCubit, Locale>(
        builder: (context, locale) {
          return ScreenUtilInit(
            designSize: const Size(430, 932),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (_, child) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Edu Gym',
                theme: lightTheme,
                locale: locale,
                supportedLocales: const [
                  Locale('en'), // English
                  Locale('es'), // Spanish
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
                    ? MyHomePage()
                    : const StartingScreen(),
          );
        },
      ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  // ✅ Using New Home screen with your real API
  final List<Widget> list = [const NewHomeScreen(), const Search(), const Account()];

  MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    // SystemChrome.setPreferredOrientations([
    //   DeviceOrientation.portraitUp,
    // ]);
    // Api.instance.login(email: 'email', password: 'password');
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (create)=>NavigationCubit()),
        BlocProvider(create: (create)=>NewHomeCubit()..loadHome()),
        BlocProvider(create: (create){
          final cubit = AccountCubit();
          // Only fetch account details if user is logged in
          if(TokenApi.isUserLoggedIn()){
            cubit.getAccountDetails();
          }
          return cubit;
        }),
        BlocProvider(create: (create)=>SearchCubit()..loadPrefs()),
        BlocProvider(create: (create)=>PageViewCubit()),
      ],
      child: BlocBuilder<NavigationCubit,int>(
        builder: (context,index){
          return Scaffold(
            body: SafeArea(
              child: IndexedStack(
                  index: index,
                  children: list
              ),
            ),
            bottomNavigationBar: BottomNavigationBar(
              items: [
                BottomNavigationBarItem(
                    icon: LinearGradientMask(
                      child: SvgPicture.asset(
                        SvgConstant.home,
                        colorFilter: ColorFilter.mode(
                          _getItemColor(index, 0),
                            BlendMode.srcIn
                        ),
                      ),
                    ),
                    label: localizations?.home ?? "Home"
                ),
                BottomNavigationBarItem(
                    icon: LinearGradientMask(
                      child: SvgPicture.asset(
                        SvgConstant.search,
                        colorFilter: ColorFilter.mode(
                            _getItemColor(index, 1),
                            BlendMode.srcIn
                        ),
                      ),
                    ),
                    label: localizations?.search ?? "Search"
                ),
                BottomNavigationBarItem(
                    icon: LinearGradientMask(
                      child: SvgPicture.asset(
                        SvgConstant.profile,
                        colorFilter: ColorFilter.mode(
                            _getItemColor(index, 2),
                            BlendMode.srcIn
                        ),
                      ),
                    ),
                    label: localizations?.profile ?? "Profile"
                ),
              ],
              currentIndex: index,
              onTap: (index){
                context.read<NavigationCubit>().changeIndex(index);
              },
            ),
          );
        },
      ),
    );
  }

  Color _getItemColor(int currentIndex, int itemIndex){
    return currentIndex==itemIndex? Colors.blue : Colors.grey;
  }
}
