import 'package:edu_gym/core/theme/app_color.dart';
import 'package:edu_gym/features/auth/presentation/pages/login.dart';
import 'package:edu_gym/features/auth/presentation/pages/register.dart';
import 'package:edu_gym/features/auth/presentation/widgets/auth_btn.dart';
import 'package:edu_gym/features/auth/presentation/widgets/bottom_rich_text.dart';
import 'package:edu_gym/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TrainingAuthPromptScreen extends StatelessWidget {
  const TrainingAuthPromptScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColor.text),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              const Spacer(),

              // Center Heading Text
              Text(
                localizations?.translate('to_follow_training_program') ??
                    'To follow training program with Edu Garcia',
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.text,
                  height: 1.35,
                ),
              ),
              SizedBox(height: 16.h),

              // Subheading Text
              Text(
                localizations?.translate('sign_up_or_log_in') ?? 'Sign up or Log in',
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w500,
                  color: AppColor.text.withValues(alpha: 0.6),
                ),
              ),

              const Spacer(),

              // Sign up button
              AuthBtn(
                text: localizations?.signUp ?? 'Sign up',
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

              // Have an account? Log in
              BottomRichText(
                text1: localizations?.translate('have_an_account') ?? 'Have an account?',
                text2: localizations?.logIn ?? 'Log in',
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
            ],
          ),
        ),
      ),
    );
  }
}
