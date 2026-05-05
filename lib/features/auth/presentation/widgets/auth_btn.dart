import 'package:edu_gym/core/common/widgets/loader.dart';
import 'package:edu_gym/core/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AuthBtn extends StatelessWidget {

  final String text;
  final VoidCallback onTap;
  final Color? bgColor;
  final Color? textColor;
  final double? width;
  final bool? isLoading;
  final bool? hasBorder;
  final double? fontSize;
  final double? letterSpacing;

  const AuthBtn({
    super.key,
    required this.text,
    required this.onTap,
    this.bgColor,
    this.textColor,
    this.width,
    this.isLoading,
    this.hasBorder,
    this.fontSize,
    this.letterSpacing,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBgColor = bgColor ?? AppColor.primary;
    final effectiveTextColor = textColor ?? Colors.white;
    final showBorder = hasBorder ?? false;

    return isLoading??false?
    const Loader() :
    SizedBox(
      width: width,
      child: Material(
        elevation: showBorder ? 0 : 5,
        shadowColor: AppColor.gradient2,
        color: effectiveBgColor,
        borderRadius: BorderRadius.circular(30.r),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30.r),
            border: showBorder ? Border.all(color: AppColor.primary, width: 2) : null,
          ),
          child: TextButton(
            onPressed: onTap,
            style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(effectiveBgColor),
                padding: WidgetStateProperty.all(EdgeInsets.symmetric(vertical: 20.h,horizontal: 20.w)),
                shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.r),
                    )
                ),
            ),
            child: Text(text,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: effectiveTextColor,
                fontSize: fontSize ?? 22.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: letterSpacing,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
