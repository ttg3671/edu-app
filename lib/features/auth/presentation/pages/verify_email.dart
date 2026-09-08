import 'package:edu_gym/api/api.dart';
import 'package:edu_gym/api/token_api.dart';
import 'package:edu_gym/core/common/constant/image_constant.dart';
import 'package:edu_gym/core/theme/app_color.dart';
import 'package:edu_gym/core/utils/custom_snackbar.dart';
import 'package:edu_gym/features/auth/presentation/cubit/verify_email_cubit.dart';
import 'package:edu_gym/features/auth/presentation/pages/login.dart';
import 'package:edu_gym/features/auth/presentation/pages/starting_screen.dart';
import 'package:edu_gym/features/auth/presentation/widgets/auth_btn.dart';
import 'package:edu_gym/features/auth/presentation/widgets/auth_textfields.dart';
import 'package:edu_gym/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class VerifyEmail extends StatefulWidget {
  final String email;

  const VerifyEmail({super.key, required this.email});

  @override
  State<VerifyEmail> createState() => _VerifyEmailState();
}

class _VerifyEmailState extends State<VerifyEmail> {
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.email);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    try {
      await Api.instance.logout();
    } catch (_) {}
    await TokenApi().deleteCookie();
    await TokenApi.clearPreferencesExceptDeviceId();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const StartingScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final localizations = AppLocalizations.of(context);

    return BlocProvider(
      create: (create) => VerifyEmailCubit(),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, size: 24.sp),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const Login()),
                (route) => false,
              );
            },
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: BlocConsumer<VerifyEmailCubit, VerifyEmailState>(
              listener: (BuildContext context, VerifyEmailState state) {
                if (state is VerifyEmailSentSuccess) {
                  CustomSnackBar.show(
                    context: context,
                    message: state.message.isNotEmpty
                        ? state.message
                        : (localizations?.verificationEmailSentSuccess ??
                            'Verification email sent successfully.'),
                  );
                }
              },
              builder: (BuildContext context, VerifyEmailState state) {
                final isSent = state is VerifyEmailSentSuccess;

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 20.h),

                      // Mail Icon Center
                      Container(
                        width: 80.r,
                        height: 80.r,
                        decoration: BoxDecoration(
                          color: AppColor.primary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.mark_email_unread_outlined,
                            size: 44.sp,
                            color: AppColor.primary,
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // Heading: VERIFY EMAIL
                      Text(
                        localizations?.verifyEmailHeading ?? 'VERIFY EMAIL',
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: AppColor.text,
                        ),
                      ),
                      SizedBox(height: 10.h),

                      // Subtitle: YOUR EMAIL ADDRESS IS NOT VERIFIED YET.
                      Text(
                        localizations?.emailNotVerifiedYet ??
                            'YOUR EMAIL ADDRESS IS NOT VERIFIED YET.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColor.text,
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // Text: Click the button below to receive a notification email.
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: Text(
                          localizations?.clickButtonToReceiveNotification ??
                              'Click the button below to receive a notification email.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            fontSize: 14.sp,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                      ),
                      SizedBox(height: 25.h),

                      // Sent success notification badge
                      if (isSent) ...[
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 14.w, vertical: 8.h),
                          margin: EdgeInsets.only(bottom: 20.h),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 16.sp,
                                color: Colors.green.shade700,
                              ),
                              SizedBox(width: 6.w),
                              Flexible(
                                child: Text(
                                  state.message.isNotEmpty
                                      ? state.message
                                      : (localizations
                                              ?.verificationEmailSentSuccess ??
                                          'Verification email sent successfully.'),
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: Colors.green.shade800,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Error message container
                      if (state is VerifyEmailFailed) ...[
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12.r),
                          margin: EdgeInsets.only(bottom: 20.h),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            border: Border.all(color: Colors.red, width: 1.5),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            state.errorMsg,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],

                      // Email input form
                      AuthTextFields(
                        text: localizations?.email ?? 'Email',
                        textEditingController: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: SvgConstant.email,
                      ),
                      SizedBox(height: 30.h),

                      // Verify Email button
                      AuthBtn(
                        text: localizations?.verifyEmailBtn ?? 'VERIFY EMAIL',
                        isLoading: state is VerifyEmailLoading,
                        width: double.infinity,
                        bgColor: AppColor.primary,
                        textColor: AppColor.background,
                        onTap: () {
                          FocusManager.instance.primaryFocus?.unfocus();

                          if (_emailController.text.trim().isEmpty) {
                            CustomSnackBar.show(
                              context: context,
                              message: localizations?.pleaseEnterEmail ??
                                  'Please enter your email',
                            );
                            return;
                          }

                          context
                              .read<VerifyEmailCubit>()
                              .sendVerificationEmail(_emailController.text.trim());
                        },
                      ),
                      SizedBox(height: 24.h),

                      // Bottom Row: Left Back to Login, Right Logout
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Left side: Back to Login
                            InkWell(
                              onTap: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const Login(),
                                  ),
                                  (route) => false,
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.arrow_back,
                                    size: 16.sp,
                                    color: AppColor.text,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    localizations?.backToLogin ??
                                        'Back to Login',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: AppColor.text,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Right side: Logout
                            InkWell(
                              onTap: _logout,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.logout,
                                    size: 16.sp,
                                    color: Colors.red.shade700,
                                  ),
                                  SizedBox(width: 4.w),
                                  Text(
                                    localizations?.logout ?? 'Logout',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 25.h),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
