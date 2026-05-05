import 'package:edu_gym/core/common/widgets/custom_shimmer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../responsive.dart';

class LessonDetailsShimmer extends StatelessWidget {
  const LessonDetailsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h,horizontal: 10.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomShimmer(height: 20.h,borderRadius: BorderRadius.zero,),
          SizedBox(height: 15.h,),

          CustomShimmer(height: 16.h,borderRadius: BorderRadius.zero,),
          SizedBox(height: 10.h,),
          CustomShimmer(height: 16.h,borderRadius: BorderRadius.zero,),

          SizedBox(height: 10.h,),
          const Divider(),
          SizedBox(height: 10.h,),
          CustomShimmer(height: 15.h,borderRadius: BorderRadius.zero,),


          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: List.generate(5, (index){
                return Padding(
                  padding: EdgeInsets.symmetric(vertical:10.h, horizontal: 0.w),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10.r),
                        child: CustomShimmer(
                          height: Responsive.isTablet? 100.h :80.h,
                          width: 120.w,
                        ),
                      ),
                      SizedBox(width: 15.w,),
                      Expanded(
                        child: Column(
                          spacing: 4.h,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomShimmer(height: 20.h,borderRadius: BorderRadius.zero,),
                            CustomShimmer(height: 14.h,borderRadius: BorderRadius.zero,)
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
              ),
            ),
          )
        ],
      ),
    );
  }
}
