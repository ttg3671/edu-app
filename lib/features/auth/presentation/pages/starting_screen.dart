import 'package:edu_gym/core/common/constant/image_constant.dart';
import 'package:edu_gym/core/theme/app_color.dart';
import 'package:edu_gym/features/auth/presentation/pages/login.dart';
import 'package:edu_gym/features/auth/presentation/pages/register.dart';
import 'package:edu_gym/features/auth/presentation/widgets/auth_btn.dart';
import 'package:edu_gym/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../l10n/app_localizations.dart';

class StartingScreen extends StatelessWidget {
  const StartingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // App Logo in the center (round)
              Center(
                child: ClipOval(
                  child: Image.asset(
                    ImgConstant.logo,
                    height: 200.h,
                    width: 200.w,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const Spacer(),

              // Create New Account Button - Tan/Sand color
              AuthBtn(
                text: localizations?.createNewAccount ?? 'Create New Account',
                width: double.infinity,
                bgColor: const Color(0xFFE7B584),
                textColor: Colors.white,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Register(),
                    ),
                  );
                },
              ),

              SizedBox(height: 20.h),

              // Log In Button - Black
              AuthBtn(
                text: localizations?.login ?? 'Log In',
                width: double.infinity,
                bgColor: Colors.black,
                textColor: Colors.white,
                hasBorder: false,
                fontSize: 26.sp,
                letterSpacing: 0,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Login(),
                    ),
                  );
                },
              ),

              SizedBox(height: 30.h),

              // Explore without an account - Normal weight, black, custom underline with gap
              GestureDetector(
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyHomePage(),
                    ),
                    (Route<dynamic> route) => false,
                  );
                },
                child: Container(
                  padding: EdgeInsets.only(bottom: 2.h),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.black,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Text(
                    localizations?.exploreWithoutAccount ?? 'Explore without an account',
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }
}
