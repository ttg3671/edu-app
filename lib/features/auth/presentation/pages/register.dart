
import 'package:edu_gym/core/theme/app_color.dart';
import 'package:edu_gym/features/auth/presentation/widgets/auth_btn.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/common/constant/image_constant.dart';
import '../../../../main.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/login_cubit.dart';
import '../widgets/auth_textfields.dart';
import '../widgets/bottom_rich_text.dart';
import '../widgets/terms_richText.dart';
import 'login.dart';
import 'verify_email.dart';
import '../../../../l10n/app_localizations.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final localizations = AppLocalizations.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (create) => PasswordCubit()),
        BlocProvider(create: (create) => AuthCubit()),
      ],
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(height: 40.h),
                        Text(
                          localizations?.heyThere ?? 'Hey there,',
                          style: textTheme.bodyMedium?.copyWith(
                            fontSize: 16.sp,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          localizations?.createAccount ?? 'Create an Account',
                          style: textTheme.titleMedium?.copyWith(
                            fontSize: 26.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColor.text,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        BottomRichText(
                          text1: localizations?.alreadyHaveAccount ?? "Already have an account?",
                          text2: localizations?.logIn ?? "Log in",
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (builder) => const Login()),
                            );
                          },
                        ),
                        SizedBox(height: 35.h),

                        // Error message container
                        BlocBuilder<AuthCubit, AuthState>(
                          builder: (context, state) {
                            if (state is AuthFailed && state.errorMsg.isNotEmpty) {
                              return Container(
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
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),

                        AuthTextFields(
                          text: localizations?.email ?? 'Email',
                          textEditingController: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: SvgConstant.email,
                        ),
                        SizedBox(height: 20.h),
                        BlocBuilder<PasswordCubit, PasswordState>(
                          builder: (context, state) {
                            return AuthTextFields(
                              text: localizations?.password ?? 'Password',
                              textEditingController: _passController,
                              isObscureText: state is PasswordInvisible,
                              icon: Icon(
                                state is PasswordInvisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppColor.text,
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
                              text: localizations?.confirmPassword ?? 'Confirm Password',
                              textEditingController: _confirmPassController,
                              isObscureText: state is PasswordInvisible,
                              icon: Icon(
                                state is PasswordInvisible
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: AppColor.text,
                              ),
                              onTap: () => context.read<PasswordCubit>().toggle(),
                              keyboardType: TextInputType.text,
                              prefixIcon: SvgConstant.lock,
                            );
                          },
                        ),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 15.h),
                  child: BlocConsumer<AuthCubit, AuthState>(
                    listener: (context, state) {
                      if (state is AuthSuccess) {
                        if (!state.emailVerified) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VerifyEmail(
                                email: state.email.isNotEmpty
                                    ? state.email
                                    : _emailController.text.trim(),
                              ),
                            ),
                          );
                          return;
                        }

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (builder) => MyHomePage()),
                          (Route<dynamic> route) => false,
                        );
                      }
                    },
                    builder: (context, state) {
                      if (state is AuthLoading) {
                        return const CircularProgressIndicator(color: AppColor.primary);
                      }
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const TermsRichText(),
                          SizedBox(height: 20.h),
                          SizedBox(
                            width: double.infinity,
                            child: AuthBtn(
                              text: localizations?.signUp ?? 'Sign Up',
                              bgColor: AppColor.primary,
                              textColor: AppColor.background,
                              onTap: () {
                                FocusManager.instance.primaryFocus?.unfocus();
                                final email = _emailController.text;
                                final password = _passController.text;
                                final confirmPassword = _confirmPassController.text;

                                context.read<AuthCubit>().register(
                                  email,
                                  password,
                                  confirmPassword,
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }
}
