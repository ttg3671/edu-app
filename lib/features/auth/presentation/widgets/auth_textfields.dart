import 'package:edu_gym/responsive.dart';
import 'package:edu_gym/core/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthTextFields extends StatefulWidget {
  final String text;
  final TextEditingController textEditingController;
  final TextInputType keyboardType;
  final String? prefixIcon;

  /// When true, renders as a password field with its own obscure/show toggle.
  final bool isPassword;

  const AuthTextFields(
      {super.key,
      required this.text,
      required this.textEditingController,
      required this.keyboardType,
      this.prefixIcon,
      this.isPassword = false});

  @override
  State<AuthTextFields> createState() => _AuthTextFieldsState();
}

class _AuthTextFieldsState extends State<AuthTextFields> {
  // Kept as widget-local state (not a Bloc rebuild) so toggling visibility
  // never rebuilds - and drops focus off of - the TextFormField underneath
  // it while the user is actively typing.
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColor.secondary,
        borderRadius: BorderRadius.circular(10.r),
      ),
      padding: EdgeInsets.symmetric(
          horizontal: 15.w, vertical: Responsive.isTablet ? 10.h : 5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (widget.prefixIcon != null)
            SvgPicture.asset(
              widget.prefixIcon!,
              height: 20.h,
              width: 20.w,
              colorFilter:
                  const ColorFilter.mode(AppColor.primary, BlendMode.srcIn),
            ),
          Expanded(
            child: TextFormField(
              controller: widget.textEditingController,
              obscureText: widget.isPassword && _obscureText,
              keyboardType: widget.keyboardType,
              autocorrect: !widget.isPassword,
              enableSuggestions: !widget.isPassword,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: widget.text,
                hintStyle: TextStyle(color: AppColor.text.withOpacity(0.4)),
                contentPadding: EdgeInsets.symmetric(horizontal: 10.w),
              ),
              style: TextStyle(
                  color: AppColor.text,
                  fontFamily: GoogleFonts.openSans().fontFamily,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold),
            ),
          ),
          if (widget.isPassword)
            InkWell(
              onTap: () => setState(() => _obscureText = !_obscureText),
              child: Icon(
                _obscureText ? Icons.visibility_off : Icons.visibility,
                size: 22.sp,
              ),
            ),
          SizedBox(
            width: 5.w,
          ),
        ],
      ),
    );
  }
}
