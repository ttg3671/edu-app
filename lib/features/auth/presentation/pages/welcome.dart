import 'dart:io';

import 'package:edu_gym/features/auth/presentation/widgets/auth_btn.dart';
import 'package:edu_gym/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../l10n/app_localizations.dart';

class Welcome extends StatelessWidget {
  final String? name;
  const Welcome({super.key, this.name});

  @override
  Widget build(BuildContext context) {
    final textTheme= Theme.of(context).textTheme;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            children: [
              Center(
                child: SvgPicture.asset(
                  'assets/images/welcome.svg',
                  height: 390.h,
                ),
              ),
              SizedBox(height: 30.h,),
              Text(localizations?.translate('welcome_user', params: {'name': name ?? 'User'}) ?? 'Welcome, $name',
                style: textTheme.titleMedium?.copyWith(
                    fontSize: 32.sp
                ),
              ),
              SizedBox(height: 5.h,),
              Text(
                localizations?.translate('all_set_message') ?? 'You are all set now, let\'s reach your goals together with us',
                style: textTheme.bodyMedium?.copyWith(
                    fontSize: 18.sp,
                ),
                textAlign: TextAlign.center,
              ),

              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: AuthBtn(
                    width: double.infinity,
                      text: localizations?.continueBtn ?? 'Continue',
                      onTap: (){
                      Navigator.pushAndRemoveUntil(context,
                          MaterialPageRoute(builder: (builder)=>MyHomePage()), (Route<dynamic> route) => false);
                      }
                  ),
                ),
              ),
              if(Platform.isAndroid)
                SizedBox(height: 20.h,),
            ],
          ),
        ),
      ),
    );
  }
}
