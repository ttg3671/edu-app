import 'package:edu_gym/core/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


class ElevatedContainer extends StatelessWidget {
  final Widget child;
  final double width;
  final double? height;
  final BorderRadiusGeometry? borderRadius;
  final EdgeInsetsGeometry? padding;
  const ElevatedContainer({super.key, required this.child, this.width=double.infinity,this.height, this.borderRadius, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding??EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: AppColor.secondary,
        borderRadius: borderRadius?? BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 5,
            spreadRadius: 1.0,
          ),
        ],
      ),
      child: child,
    );
  }
}
