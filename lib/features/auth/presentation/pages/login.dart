import 'dart:io';

import 'package:edu_gym/core/common/constant/image_constant.dart';
import 'package:edu_gym/core/utils/custom_snackbar.dart';
import 'package:edu_gym/features/auth/presentation/pages/forgot_password.dart';
import 'package:edu_gym/features/auth/presentation/pages/profile.dart';
import 'package:edu_gym/features/auth/presentation/pages/register.dart';
import 'package:edu_gym/features/auth/presentation/widgets/auth_btn.dart';
import '../../../../sample.dart';
import '../cubit/auth_cubit.dart';
import '../widgets/auth_textfields.dart';
import '../widgets/bottom_rich_text.dart';
import '../widgets/terms_richText.dart';
import '../widgets/top_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../main.dart';
import '../cubit/login_cubit.dart';
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
    final textTheme= Theme.of(context).textTheme;
    final localizations = AppLocalizations.of(context);

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (create)=>PasswordCubit()),
        BlocProvider(create: (create)=>AuthCubit()),
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
                        SizedBox(height: 20.h,),

                        // const TopText(text1: 'Log', text2: 'In'),
                        Text(localizations?.heyThere ?? 'Hey there,',
                          style: textTheme.bodyMedium?.copyWith(
                              fontSize: 15.sp
                          ),
                        ),
                        SizedBox(height: 5.h,),
                        Text(localizations?.welcomeBack ?? 'Welcome Back',
                          style: textTheme.titleMedium?.copyWith(
                              fontSize: 20.sp
                          ),
                        ),
                        SizedBox(height: 10.h,),
                        BottomRichText(
                          text1: localizations?.dontHaveAccount ?? "Don\'t have an account?",
                          text2: localizations?.signUp ?? "Sign up",
                          onTap: (){
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (builder)=>const Register()));
                          },
                        ),
                        SizedBox(height: 30.h,),
                        AuthTextFields(
                          text: localizations?.email ?? 'Email',
                          textEditingController: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: SvgConstant.email,
                        ),
                        SizedBox(height: 20.h,),
                        BlocBuilder<PasswordCubit,PasswordState>(
                          builder: (context,state){
                            return AuthTextFields(
                              text: localizations?.password ?? 'Password',
                              textEditingController: _passController,
                              isObscureText: state is PasswordInvisible,
                              icon: Icon(state is PasswordInvisible? Icons.visibility_off: Icons.visibility,
                                size: 22.sp,),
                              onTap: ()=>context.read<PasswordCubit>().toggle(),
                              keyboardType: TextInputType.text,
                              prefixIcon: SvgConstant.lock,
                            );
                          },
                        ),

                        SizedBox(height: 20.h,),
                        GestureDetector(
                          onTap: () {
                            print('Forgot password tapped');
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ForgotPassword(),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
                            child: Text(
                              localizations?.forgotPassword ?? 'Forgot your password?',
                              style: textTheme.bodySmall?.copyWith(
                                fontSize: 16.sp,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h,),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 15.h),
                  child: BlocConsumer<AuthCubit,AuthState>(
                    builder: (context,state){
                      if(state is AuthFailed){
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          CustomSnackBar.show(context: context, message: state.errorMsg);
                        });
                      }
                      else if(state is AuthLoading){
                        return const CircularProgressIndicator();
                      }
                      return AuthBtn(
                          text: localizations?.login ?? 'Login',
                          width: double.infinity,
                          bgColor: Colors.black,
                          textColor: Colors.white,
                          onTap: (){
                            FocusManager.instance.primaryFocus?.unfocus();
                            context.read<AuthCubit>().login(_emailController.text, _passController.text);
                          }
                      );
                    },
                    listener: (context,state){
                      if(state is AuthSuccess){
                        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (builder)=>MyHomePage()),(Route<dynamic> route) => false);
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
