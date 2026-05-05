import 'package:edu_gym/core/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BottomRichText extends StatelessWidget {
  final String text1;
  final String text2;
  final VoidCallback onTap;

  const BottomRichText({super.key, required this.text1, required this.text2, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
            text: text1,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 15.sp,
            ),
            children: [
              TextSpan(
                text: ' $text2'.toUpperCase(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 15.sp,
                  color: AppColor.green
                ),
              )
            ]
        ),
      ),
    );
  }
}
