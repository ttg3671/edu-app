import 'package:edu_gym/api/token_api.dart';
import 'package:edu_gym/core/theme/app_color.dart';
import 'package:edu_gym/core/common/constant/image_constant.dart';
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
    if (TokenApi.isUserLoggedIn()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => MyHomePage()),
          (route) => false,
        );
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final textTheme = Theme.of(context).textTheme;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColor.background,
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

              // Create New Account Button - Primary Brand Color
              AuthBtn(
                text: localizations?.createNewAccount ?? 'Create New Account',
                width: double.infinity,
                bgColor: AppColor.primary,
                textColor: AppColor.background,
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

              // Log In Button - Light Grey
              AuthBtn(
                text: localizations?.login ?? 'Log In',
                width: double.infinity,
                bgColor: Colors.grey.shade200,
                textColor: AppColor.text,
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

              // Explore without an account button with transparent bg and generous click area
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyHomePage(),
                      ),
                      (Route<dynamic> route) => false,
                    );
                  },
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                  ),
                  child: Container(
                    padding: EdgeInsets.only(bottom: 2.h),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppColor.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                    child: Text(
                      localizations?.exploreWithoutAccount ?? 'Explore without an account',
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColor.text,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 30.h),
            ],
          ),
        ),
      ),
    );
  }
}
