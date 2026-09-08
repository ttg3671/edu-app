import 'dart:async';
import 'package:edu_gym/core/theme/app_color.dart';
import 'package:edu_gym/features/auth/presentation/widgets/auth_btn.dart';
import 'package:edu_gym/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../main.dart';

class EmailVerified extends StatefulWidget {
  const EmailVerified({super.key});

  @override
  State<EmailVerified> createState() => _EmailVerifiedState();
}

class _EmailVerifiedState extends State<EmailVerified> {
  Timer? _timer;
  int _secondsRemaining = 5;

  @override
  void initState() {
    super.initState();
    _startAutoRedirect();
  }

  void _startAutoRedirect() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (_secondsRemaining > 1) {
          setState(() {
            _secondsRemaining--;
          });
        } else {
          timer.cancel();
          _navigateToHome();
        }
      }
    });
  }

  void _navigateToHome() {
    _timer?.cancel();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (builder) => MyHomePage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // Success Verified Icon
              Container(
                width: 90.r,
                height: 90.r,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green.shade300, width: 2),
                ),
                child: Center(
                  child: Icon(
                    Icons.mark_email_read_outlined,
                    size: 50.sp,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
              SizedBox(height: 25.h),

              // Title: EMAIL VERIFIED
              Text(
                localizations?.emailVerifiedHeading ?? 'EMAIL VERIFIED',
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: AppColor.text,
                ),
              ),
              SizedBox(height: 12.h),

              // Success message: Email verification successful. Continue watching.
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.w),
                child: Text(
                  '${localizations?.emailVerificationSuccessful ?? 'Email verification successful.'} ${localizations?.continueWatching ?? 'Continue watching'}.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    fontSize: 15.sp,
                    color: Colors.grey.shade700,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              // Auto redirect countdown badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 16.sp,
                      color: AppColor.primary,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      localizations?.redirectingInSeconds(_secondsRemaining) ??
                          'Redirecting to home in ${_secondsRemaining}s...',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppColor.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Continue Watching button (Immediate navigation)
              AuthBtn(
                text: localizations?.continueWatching ?? 'Continue Watching',
                width: double.infinity,
                bgColor: AppColor.primary,
                textColor: AppColor.background,
                onTap: _navigateToHome,
              ),
              SizedBox(height: 30.h),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
