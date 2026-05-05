import 'package:edu_gym/core/common/constant/image_constant.dart';
import 'package:edu_gym/core/utils/custom_snackbar.dart';
import 'package:edu_gym/features/auth/presentation/cubit/forgot_password_cubit.dart';
import 'package:edu_gym/features/auth/presentation/pages/reset_password.dart';
import 'package:edu_gym/features/auth/presentation/widgets/auth_btn.dart';
import 'package:edu_gym/features/auth/presentation/widgets/auth_textfields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BlocProvider(
      create: (create) => ForgotPasswordCubit(),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, size: 24.sp),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20.h),

                  Text(
                    'Forgot Password',
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: 25.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10.h),

                  BlocBuilder<ForgotPasswordCubit, ForgotPasswordState>(
                    builder: (context, state) {
                      if (state is ForgotPasswordOtpSent) {
                        return Text(
                          'Enter the OTP sent to ${_emailController.text}',
                          style: textTheme.bodyMedium?.copyWith(
                            fontSize: 14.sp,
                            color: Colors.grey.shade600,
                          ),
                        );
                      }
                      return Text(
                        'Enter your email address to receive an OTP',
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 14.sp,
                          color: Colors.grey.shade600,
                        ),
                      );
                    },
                  ),

                  SizedBox(height: 40.h),

                  BlocBuilder<ForgotPasswordCubit, ForgotPasswordState>(
                    builder: (context, state) {
                      // Show email input if OTP not sent yet
                      if (state is! ForgotPasswordOtpSent) {
                        return Column(
                          children: [
                            AuthTextFields(
                              text: 'Email',
                              textEditingController: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              prefixIcon: SvgConstant.email,
                            ),
                            SizedBox(height: 30.h),
                          ],
                        );
                      }

                      // Show OTP input after OTP is sent
                      return Column(
                        children: [
                          AuthTextFields(
                            text: 'OTP',
                            textEditingController: _otpController,
                            keyboardType: TextInputType.number,
                            prefixIcon: SvgConstant.lock,
                          ),
                          SizedBox(height: 20.h),
                          Align(
                            alignment: Alignment.centerRight,
                            child: InkWell(
                              onTap: () {
                                // Resend OTP
                                context.read<ForgotPasswordCubit>().sendOtp(_emailController.text);
                              },
                              child: Text(
                                'Resend OTP',
                                style: textTheme.bodySmall?.copyWith(
                                  fontSize: 14.sp,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 30.h),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 20.w),
          child: BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
            builder: (BuildContext context, ForgotPasswordState state) {
              return AuthBtn(
                text: state is ForgotPasswordOtpSent ? 'Verify OTP' : 'Send OTP',
                isLoading: state is ForgotPasswordLoading,
                width: double.infinity,
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();

                  if (state is ForgotPasswordOtpSent) {
                    // Verify OTP
                    if (_otpController.text.trim().isEmpty) {
                      CustomSnackBar.show(
                        context: context,
                        message: 'Please enter OTP',
                      );
                      return;
                    }
                    context.read<ForgotPasswordCubit>().verifyOtp(_otpController.text);
                  } else {
                    // Send OTP
                    if (_emailController.text.trim().isEmpty) {
                      CustomSnackBar.show(
                        context: context,
                        message: 'Please enter your email',
                      );
                      return;
                    }
                    context.read<ForgotPasswordCubit>().sendOtp(_emailController.text);
                  }
                },
              );
            },
            listener: (BuildContext context, ForgotPasswordState state) {
              if (state is ForgotPasswordOtpSent) {
                CustomSnackBar.show(
                  context: context,
                  message: 'OTP sent to your email',
                );
              } else if (state is ForgotPasswordSuccess) {
                CustomSnackBar.show(
                  context: context,
                  message: 'OTP verified successfully',
                );
                // Navigate to reset password screen
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ResetPassword(),
                  ),
                );
              } else if (state is ForgotPasswordFailed) {
                CustomSnackBar.show(
                  context: context,
                  message: state.errorMsg,
                );
              }
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    super.dispose();
  }
}
