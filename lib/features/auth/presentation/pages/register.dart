import 'dart:io';

import 'package:edu_gym/features/auth/presentation/widgets/auth_btn.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/common/constant/image_constant.dart';
import '../../../../main.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/login_cubit.dart';
import '../widgets/auth_textfields.dart';
import '../widgets/bottom_rich_text.dart';
import '../widgets/terms_richText.dart';
import 'login.dart';
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
                        SizedBox(height: 20.h),
                        Text(
                          localizations?.heyThere ?? 'Hey there,',
                          style: textTheme.bodyMedium?.copyWith(fontSize: 15.sp),
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          localizations?.createAccount ?? 'Create an Account',
                          style: textTheme.titleMedium?.copyWith(fontSize: 20.sp),
                        ),
                        SizedBox(height: 10.h),
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
                        SizedBox(height: 30.h),
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
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (builder) => MyHomePage()),
                          (Route<dynamic> route) => false,
                        );
                      }
                    },
                    builder: (context, state) {
                      if (state is AuthFailed) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                state.errorMsg,
                                style: GoogleFonts.poppins(color: Colors.white),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        });
                      } else if (state is AuthLoading) {
                        return const CircularProgressIndicator();
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
                              bgColor: const Color(0xFFE7B584),
                              textColor: Colors.white,
                              onTap: () {
                                FocusManager.instance.primaryFocus?.unfocus();
                                final email = _emailController.text;
                                final password = _passController.text;
                                final confirmPassword = _confirmPassController.text;

                                if (password != confirmPassword) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        localizations?.translate('passwords_not_match') ??
                                            'Passwords do not match',
                                        style: GoogleFonts.poppins(color: Colors.white),
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

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
