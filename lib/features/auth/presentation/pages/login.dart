import 'package:edu_gym/core/theme/app_color.dart';
import 'package:edu_gym/core/common/constant/image_constant.dart';
import 'package:edu_gym/features/auth/presentation/pages/forgot_password.dart';
import 'package:edu_gym/features/auth/presentation/pages/register.dart';
import 'package:edu_gym/features/auth/presentation/pages/verify_email.dart';
import 'package:edu_gym/features/auth/presentation/widgets/auth_btn.dart';
import '../cubit/auth_cubit.dart';
import '../widgets/auth_textfields.dart';
import '../widgets/bottom_rich_text.dart';
import 'package:edu_gym/api/socket_service.dart';
import 'package:edu_gym/features/account/presentation/cubit/account_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../main.dart';
import '../../../../l10n/app_localizations.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final localizations = AppLocalizations.of(context);

    return MultiBlocProvider(
      providers: [
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
                          localizations?.welcomeBack ?? 'Welcome Back',
                          style: textTheme.titleMedium?.copyWith(
                            fontSize: 26.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColor.text,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        BottomRichText(
                          text1: localizations?.dontHaveAccount ??
                              "Don't have an account?",
                          text2: localizations?.signUp ?? "Sign up",
                          onTap: () {
                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (builder) => const Register()));
                          },
                        ),
                        SizedBox(height: 35.h),

                        // Error message container
                        BlocBuilder<AuthCubit, AuthState>(
                          builder: (context, state) {
                            if (state is AuthFailed &&
                                state.errorMsg.isNotEmpty) {
                              return Container(
                                width: double.infinity,
                                padding: EdgeInsets.all(12.r),
                                margin: EdgeInsets.only(bottom: 20.h),
                                decoration: BoxDecoration(
                                  color: Colors.red.withValues(alpha: 0.1),
                                  border:
                                      Border.all(color: Colors.red, width: 1.5),
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
                        SizedBox(
                          height: 20.h,
                        ),
                        AuthTextFields(
                          text: localizations?.password ?? 'Password',
                          textEditingController: _passController,
                          isPassword: true,
                          keyboardType: TextInputType.text,
                          prefixIcon: SvgConstant.lock,
                        ),

                        SizedBox(height: 15.h),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ForgotPassword(),
                                ),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: 6.h, horizontal: 4.w),
                              child: Text(
                                localizations?.forgotPassword ??
                                    'Forgot your password?',
                                style: textTheme.bodySmall?.copyWith(
                                  fontSize: 16.sp,
                                  color: AppColor.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 25.h),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 15.h),
                  child: BlocConsumer<AuthCubit, AuthState>(
                    builder: (context, state) {
                      if (state is AuthLoading) {
                        return const CircularProgressIndicator(
                            color: AppColor.primary);
                      }
                      return AuthBtn(
                          text: localizations?.login ?? 'Login',
                          width: double.infinity,
                          bgColor: AppColor.primary,
                          textColor: AppColor.background,
                          onTap: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            context.read<AuthCubit>().login(
                                _emailController.text, _passController.text);
                          });
                    },
                    listener: (context, state) async {
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

                        // Initialize session (Socket and Account Details)
                        final prefs = await SharedPreferences.getInstance();
                        final deviceId = prefs.getString('Device_Id') ?? '';
                        SocketService().initSocket(deviceId);

                        if (context.mounted) {
                          context.read<AccountCubit>().getAccountDetails();
                          Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (builder) => MyHomePage()),
                              (Route<dynamic> route) => false);
                        }
                      }
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
    super.dispose();
  }
}
