import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TopText extends StatelessWidget {
  final String text1;
  final String text2;
  const TopText({super.key, required this.text1, required this.text2,});

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
          text: text1.toUpperCase(),
          style: Theme.of(context).textTheme.titleMedium?.
          copyWith(
              fontSize: 35.sp,
              color: Colors.red
          ),
          children: [
            TextSpan(
              text: ' $text2'.toUpperCase(),
              style: Theme.of(context).textTheme.titleMedium?.
              copyWith(
                  fontSize: 35.sp,
                  color: const Color(0xff00e5fa)
              ),
            )
          ]
      ),
    );
  }
}
