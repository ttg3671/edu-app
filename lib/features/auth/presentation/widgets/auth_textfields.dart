import 'package:edu_gym/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/common/constant/image_constant.dart';


class AuthTextFields extends StatelessWidget {

  final String text;
  final Icon? icon;
  final TextEditingController textEditingController;
  final bool? isObscureText;
  final VoidCallback? onTap;
  final TextInputType keyboardType;
  final String? prefixIcon;

  const AuthTextFields({super.key, required this.text, this.icon,
    required this.textEditingController, this.isObscureText, this.onTap, required this.keyboardType, this.prefixIcon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).brightness==Brightness.light?
        Colors.black12 : Colors.white12,
        borderRadius: BorderRadius.circular(10.r),
      ),
      padding: EdgeInsets.symmetric(horizontal: 15.w,vertical: Responsive.isTablet? 10.h : 5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if(prefixIcon!=null)
            SvgPicture.asset(
              prefixIcon!,
              height: 20.h,
              width: 20.w,
            ),

          Expanded(
            child: TextFormField(
              controller: textEditingController,
              obscureText: isObscureText ?? false,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: text,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10.w),
              ),
              style: TextStyle(
                  color: Theme.of(context).brightness==Brightness.light?
                  Colors.black : Colors.white,
                  fontFamily: GoogleFonts.poppins().fontFamily,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold

              ),
            ),
          ),

          if(icon!=null)
            InkWell(
              onTap: onTap,
              child: icon,
            ),
          SizedBox(width: 5.w,),
        ],
      ),
    );
  }
}
