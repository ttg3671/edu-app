import 'package:edu_gym/core/common/widgets/custom_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AccountDetailsShimmer extends StatelessWidget {
  const AccountDetailsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CustomShimmer(
          height: 60.h,
          width: 60.w,
          shape: BoxShape.circle,
        ),
        SizedBox(width: 20.w,),
        Expanded(
          child: Column(
            spacing: 2.h,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomShimmer(height: 15.h,borderRadius: BorderRadius.zero,),
              CustomShimmer(height: 14.h,borderRadius: BorderRadius.zero,),
            ],
          ),
        ),
      ],
    );
  }
}
