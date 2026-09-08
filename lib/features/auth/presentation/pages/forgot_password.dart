import 'package:edu_gym/core/common/constant/image_constant.dart';
import 'package:edu_gym/core/theme/app_color.dart';
import 'package:edu_gym/core/utils/custom_snackbar.dart';
import 'package:edu_gym/features/auth/presentation/cubit/forgot_password_cubit.dart';
import 'package:edu_gym/features/auth/presentation/pages/verify_otp.dart';
import 'package:edu_gym/features/auth/presentation/widgets/auth_btn.dart';
import 'package:edu_gym/features/auth/presentation/widgets/auth_textfields.dart';
import 'package:edu_gym/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ForgotPassword extends StatefulWidget {
  final String? initialEmail;

  const ForgotPassword({super.key, this.initialEmail});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final localizations = AppLocalizations.of(context);

    return BlocProvider(
      create: (create) => ForgotPasswordCubit(),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, size: 24.sp),
            onPressed: () => Navigator.pop(context),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
              listener: (BuildContext context, ForgotPasswordState state) {
                if (state is ForgotPasswordOtpSent) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VerifyOtp(
                        email: _emailController.text.trim(),
                      ),
                    ),
                  );
                }
              },
              builder: (BuildContext context, ForgotPasswordState state) {
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 20.h),

                      // Centered Title: "Forgot Password?"
                      Text(
                        localizations?.forgotPasswordQuestion ?? 'Forgot Password?',
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColor.text,
                        ),
                      ),
                      SizedBox(height: 10.h),

                      // Centered Subtitle: "ENTER EMAIL"
                      Text(
                        localizations?.enterEmailUppercase ?? 'ENTER EMAIL',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyLarge?.copyWith(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: AppColor.text,
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // Centered Instruction text: "Please enter the email address registered with this app to receive your 6-digit OTP."
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        child: Text(
                          localizations?.forgotPasswordInstruction ??
                              'Please enter the email address registered with this app to receive your 6-digit OTP.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodyMedium?.copyWith(
                            fontSize: 14.sp,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                      ),
                      SizedBox(height: 35.h),

                      // Error message container
                      if (state is ForgotPasswordFailed) ...[
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

                      // Submit button
                      AuthBtn(
                        text: localizations?.submitBtn ?? 'Submit',
                        isLoading: state is ForgotPasswordLoading,
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
                              .read<ForgotPasswordCubit>()
                              .sendOtp(_emailController.text.trim());
                        },
                      ),

                      SizedBox(height: 16.h),

                      // Back to Login button
                      Center(
                        child: TextButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back,
                            size: 18.sp,
                            color: AppColor.text,
                          ),
                          label: Text(
                            localizations?.backToLogin ?? 'Back to Login',
                            style: TextStyle(
                              fontSize: 15.sp,
                              color: AppColor.text,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
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

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
