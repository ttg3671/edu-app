import 'package:edu_gym/core/common/constant/image_constant.dart';
import 'package:edu_gym/core/utils/custom_snackbar.dart';
import 'package:edu_gym/features/auth/presentation/cubit/reset_password_cubit.dart';
import 'package:edu_gym/features/auth/presentation/widgets/auth_btn.dart';
import 'package:edu_gym/features/auth/presentation/widgets/auth_textfields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../cubit/login_cubit.dart';
import '../../../../main.dart';

class ResetPassword extends StatefulWidget {
  const ResetPassword({super.key});

  @override
  State<ResetPassword> createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (create) => PasswordCubit()),
        BlocProvider(create: (create) => ResetPasswordCubit()),
      ],
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
                    'Reset Password',
                    style: textTheme.titleMedium?.copyWith(
                      fontSize: 25.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10.h),

                  Text(
                    'Enter your new password',
                    style: textTheme.bodyMedium?.copyWith(
                      fontSize: 14.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  SizedBox(height: 40.h),

                  BlocBuilder<PasswordCubit, PasswordState>(
                    builder: (context, state) {
                      return AuthTextFields(
                        text: 'New Password',
                        textEditingController: _newPasswordController,
                        isObscureText: state is PasswordInvisible,
                        icon: Icon(
                          state is PasswordInvisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 22.sp,
                        ),
                        onTap: () => context.read<PasswordCubit>().toggle(),
                        keyboardType: TextInputType.text,
                        prefixIcon: SvgConstant.lock,
                      );
                    },
                  ),
                  SizedBox(height: 20.h),

                  BlocBuilder<PasswordCubit, PasswordState>(
                    builder: (context, state) {
                      return AuthTextFields(
                        text: 'Confirm Password',
                        textEditingController: _confirmPasswordController,
                        isObscureText: state is PasswordInvisible,
                        icon: Icon(
                          state is PasswordInvisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 22.sp,
                        ),
                        onTap: () => context.read<PasswordCubit>().toggle(),
                        keyboardType: TextInputType.text,
                        prefixIcon: SvgConstant.lock,
                      );
                    },
                  ),
                  SizedBox(height: 30.h),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 20.w),
          child: BlocConsumer<ResetPasswordCubit, ResetPasswordState>(
            builder: (BuildContext context, ResetPasswordState state) {
              return AuthBtn(
                text: 'Reset Password',
                isLoading: state is ResetPasswordLoading,
                width: double.infinity,
                onTap: () {
                  FocusManager.instance.primaryFocus?.unfocus();

                  final newPassword = _newPasswordController.text.trim();
                  final confirmPassword = _confirmPasswordController.text.trim();

                  if (newPassword.isEmpty) {
                    CustomSnackBar.show(
                      context: context,
                      message: 'Please enter new password',
                    );
                    return;
                  }

                  if (confirmPassword.isEmpty) {
                    CustomSnackBar.show(
                      context: context,
                      message: 'Please confirm your password',
                    );
                    return;
                  }

                  if (newPassword != confirmPassword) {
                    CustomSnackBar.show(
                      context: context,
                      message: 'Passwords do not match',
                    );
                    return;
                  }

                  if (newPassword.length < 6) {
                    CustomSnackBar.show(
                      context: context,
                      message: 'Password must be at least 6 characters',
                    );
                    return;
                  }

                  context.read<ResetPasswordCubit>().resetPassword(newPassword);
                },
              );
            },
            listener: (BuildContext context, ResetPasswordState state) {
              if (state is ResetPasswordSuccess) {
                CustomSnackBar.show(
                  context: context,
                  message: 'Password reset successfully! You are now logged in.',
                );
                // Navigate to home screen (user is logged in)
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (builder) => MyHomePage()),
                  (Route<dynamic> route) => false,
                );
              } else if (state is ResetPasswordFailed) {
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
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
