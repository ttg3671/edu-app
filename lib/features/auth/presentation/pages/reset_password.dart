import 'package:edu_gym/api/token_api.dart';
import 'package:edu_gym/core/common/constant/image_constant.dart';
import 'package:edu_gym/core/theme/app_color.dart';
import 'package:edu_gym/core/utils/custom_snackbar.dart';
import 'package:edu_gym/features/account/presentation/cubit/account_cubit.dart';
import 'package:edu_gym/features/auth/presentation/cubit/reset_password_cubit.dart';
import 'package:edu_gym/features/auth/presentation/pages/verify_email.dart';
import 'package:edu_gym/features/auth/presentation/widgets/auth_btn.dart';
import 'package:edu_gym/features/auth/presentation/widgets/auth_textfields.dart';
import 'package:edu_gym/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../main.dart';

class ResetPassword extends StatefulWidget {
  const ResetPassword({super.key});

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final localizations = AppLocalizations.of(context);

    return BlocProvider(
      create: (create) => ResetPasswordCubit(),
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
            child: BlocConsumer<ResetPasswordCubit, ResetPasswordState>(
              listener: (BuildContext context, ResetPasswordState state) {
                if (state is ResetPasswordSuccess) {
                  // If user.email_verified is false, send to verify email page like we do after auth
                  if (!state.emailVerified) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => VerifyEmail(
                          email: state.email.isNotEmpty
                              ? state.email
                              : (TokenApi.user?.email ?? ''),
                        ),
                      ),
                    );
                    return;
                  }

                  CustomSnackBar.show(
                    context: context,
                    message: localizations?.passwordResetSuccess ??
                        'Password reset successfully! You are now logged in.',
                  );
                  try {
                    context.read<AccountCubit>().getAccountDetails();
                  } catch (_) {}
                  // Redirect to homepage (user is logged in)
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (builder) => const MyHomePage()),
                    (Route<dynamic> route) => false,
                  );
                }
              },
              builder: (BuildContext context, ResetPasswordState state) {
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 20.h),

                      // Centered Title: "RESET PASSWORD"
                      Text(
                        localizations?.resetPasswordHeading ?? 'RESET PASSWORD',
                        textAlign: TextAlign.center,
                        style: textTheme.titleMedium?.copyWith(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: AppColor.text,
                        ),
                      ),
                      SizedBox(height: 10.h),

                      // Centered Subtitle: "Change your password here."
                      Text(
                        localizations?.changePasswordSubheading ??
                            'Change your password here.',
                        textAlign: TextAlign.center,
                        style: textTheme.bodyMedium?.copyWith(
                          fontSize: 15.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 35.h),

                      // Error message container
                      if (state is ResetPasswordFailed) ...[
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

                      // New Password Input
                      AuthTextFields(
                        text: localizations?.newPassword ?? 'New Password',
                        textEditingController: _newPasswordController,
                        isObscureText: _obscureNewPassword,
                        icon: Icon(
                          _obscureNewPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 22.sp,
                        ),
                        onTap: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                        keyboardType: TextInputType.text,
                        prefixIcon: SvgConstant.lock,
                      ),
                      SizedBox(height: 20.h),

                      // Confirm Password Input
                      AuthTextFields(
                        text: localizations?.confirmPassword ?? 'Confirm Password',
                        textEditingController: _confirmPasswordController,
                        isObscureText: _obscureConfirmPassword,
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 22.sp,
                        ),
                        onTap: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                        keyboardType: TextInputType.text,
                        prefixIcon: SvgConstant.lock,
                      ),
                      SizedBox(height: 35.h),

                      // Confirm Button
                      AuthBtn(
                        text: localizations?.confirm ?? 'Confirm',
                        isLoading: state is ResetPasswordLoading,
                        width: double.infinity,
                        bgColor: AppColor.primary,
                        textColor: AppColor.background,
                        onTap: () {
                          FocusManager.instance.primaryFocus?.unfocus();

                          final newPassword = _newPasswordController.text.trim();
                          final confirmPassword =
                              _confirmPasswordController.text.trim();

                          if (newPassword.isEmpty) {
                            CustomSnackBar.show(
                              context: context,
                              message: localizations?.pleaseEnterNewPassword ??
                                  'Please enter new password',
                            );
                            return;
                          }

                          if (confirmPassword.isEmpty) {
                            CustomSnackBar.show(
                              context: context,
                              message: localizations?.pleaseConfirmPassword ??
                                  'Please confirm your password',
                            );
                            return;
                          }

                          if (newPassword != confirmPassword) {
                            CustomSnackBar.show(
                              context: context,
                              message: localizations?.passwordsNotMatch ??
                                  'Passwords do not match',
                            );
                            return;
                          }

                          if (newPassword.length < 6) {
                            CustomSnackBar.show(
                              context: context,
                              message: localizations?.passwordMinLength ??
                                  'Password must be at least 6 characters',
                            );
                            return;
                          }

                          context.read<ResetPasswordCubit>().resetPassword(
                            newPassword: newPassword,
                            confirmPassword: confirmPassword,
                          );
                        },
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

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
