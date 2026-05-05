import 'package:edu_gym/core/common/constant/image_constant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/auth/presentation/cubit/login_cubit.dart';
import 'features/auth/presentation/pages/login.dart';
import 'features/auth/presentation/pages/register.dart';
import 'features/auth/presentation/widgets/auth_btn.dart';
import 'features/auth/presentation/widgets/auth_textfields.dart';
import 'features/auth/presentation/widgets/bottom_rich_text.dart';
import 'features/auth/presentation/widgets/terms_richText.dart';
import 'features/auth/presentation/widgets/top_text.dart';
import 'main.dart';

class Sample extends StatefulWidget {
  const Sample({super.key});

  @override
  State<Sample> createState() => _SampleState();
}

class _SampleState extends State<Sample> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final textTheme= Theme.of(context).textTheme;

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
                SizedBox(height: 20.h,),

                Text('Hey there,',
                  style: textTheme.bodyMedium?.copyWith(
                      fontSize: 15.sp
                  ),
                ),
                SizedBox(height: 5.h,),
                Text('Create an Account',
                  style: textTheme.titleMedium?.copyWith(
                      fontSize: 20.sp
                  ),
                ),
                SizedBox(height: 30.h,),
                AuthTextFields(
                    text: 'Email',
                    textEditingController: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  prefixIcon: SvgConstant.email,
                ),
                SizedBox(height: 20.h,),

                BlocBuilder<PasswordCubit,PasswordState>(
                  builder: (context,state){
                    return AuthTextFields(
                        text: 'Password',
                        textEditingController: _passController,
                        isObscureText: state is PasswordInvisible,
                        icon: Icon(state is PasswordInvisible? Icons.visibility_off: Icons.visibility),
                        onTap: ()=>context.read<PasswordCubit>().toggle(),
                        keyboardType: TextInputType.text,
                      prefixIcon: SvgConstant.lock,
                    );
                  },
                ),

                SizedBox(height: 30.h,),

                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      BlocBuilder<AuthCubit,AuthState>(
                          builder: (context,state){
                            if(state is AuthFailed){
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
                            }
                            else if(state is AuthSuccess){
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                // Navigator.push(context, MaterialPageRoute(builder: (builder)=>
                                //     Profile(email: _emailController.text, password: _passController.text, isUserExist: false)));
                              });
                            }
                            else if(state is AuthLoading){
                              return const CircularProgressIndicator();
                            }
                            return SizedBox(
                              width: double.infinity,
                              child: AuthBtn(
                                  text: 'Sign Up',
                                  onTap: (){
                                    FocusManager.instance.primaryFocus?.unfocus();
                                    context.read<AuthCubit>().validate(_emailController.text, _passController.text);
                                  }
                              ),
                            );
                          }
                      ),

                      SizedBox(height: 10.h,),

                      const TermsRichText(),

                      SizedBox(height: 30.h,),

                      BottomRichText(
                        text1: "Already have an account?",
                        text2: "Log in",
                        onTap: (){
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (builder)=>const Login()));
                        },
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );;
  }
}
