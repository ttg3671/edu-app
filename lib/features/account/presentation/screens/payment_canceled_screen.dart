import 'package:edu_gym/api/token_api.dart';
import 'package:edu_gym/core/theme/app_color.dart';
import 'package:edu_gym/features/account/presentation/screens/subscription_screen.dart';
import 'package:edu_gym/features/auth/presentation/widgets/auth_btn.dart';
import 'package:edu_gym/l10n/app_localizations.dart';
import 'package:edu_gym/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

typedef SubscriptionStatusScreen = PaymentCanceledScreen;

class PaymentCanceledScreen extends StatelessWidget {
  const PaymentCanceledScreen({super.key});

  void _navigateToSubscription(BuildContext context) {
    if (TokenApi.user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SubscriptionScreen(userDetails: TokenApi.user!),
        ),
      );
    } else {
      _navigateToHome(context);
    }
  }

  void _navigateToHome(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (builder) => const MyHomePage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 45.h),

                      // Warm Icon with circular border and soft glow
                      Container(
                        width: 100.r,
                        height: 100.r,
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.amber.shade400, width: 2.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.15),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.sentiment_dissatisfied_outlined,
                            size: 56.sp,
                            color: Colors.amber.shade800,
                          ),
                        ),
                      ),
                      SizedBox(height: 25.h),

                      // Heading
                      Text(
                        localizations?.subscriptionCancelledHeading ?? "SUBSCRIPTION CANCELLED",
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: Colors.amber.shade900,
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // Subtitle / Message
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        child: Text(
                          localizations?.subscriptionCancelledMsg ??
                              'It seems you have canceled the subscription. We hope our services were not disappointing you.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            fontSize: 15.sp,
                            color: Colors.grey.shade700,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(height: 30.h),

                      // Reassuring Card
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(20.r),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, size: 20.sp, color: AppColor.primary),
                                SizedBox(width: 8.w),
                                Text(
                                  'We are here for you',
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColor.text,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12.h),
                            Divider(color: Colors.grey.shade200, height: 1),
                            SizedBox(height: 12.h),
                            Text(
                              'Your account data and progress are safe with us. If you ever want to get back to training, rejoining takes only a moment.',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.grey.shade600,
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),

              // Bottom Action Buttons
              Padding(
                padding: EdgeInsets.only(bottom: 24.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Changed your mind? Need a subscription? button -> takes to account subscription_screen
                    AuthBtn(
                      text: localizations?.changedMindNeedSubscription ?? 'Changed your mind? Need a subscription?',
                      width: double.infinity,
                      bgColor: AppColor.primary,
                      textColor: AppColor.background,
                      onTap: () => _navigateToSubscription(context),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 8.h, bottom: 8.h),
                      child: TextButton(
                        onPressed: () => _navigateToHome(context),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: AppColor.text,
                          elevation: 0,
                          shadowColor: Colors.transparent,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                            side: BorderSide.none,
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 24.w),
                        ),
                        child: Text(
                          localizations?.backToHome ?? 'Back to Home',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColor.text,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
