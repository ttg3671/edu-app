import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/common/widgets/custom_shimmer.dart';

class HomeShimmerLoading extends StatelessWidget {
  const HomeShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Skeleton
          Padding(
            padding: EdgeInsets.only(top: 10.h, left: 10.w, right: 10.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomShimmer(height: 40.h, width: 40.w, borderRadius: BorderRadius.circular(20.r)),
                CustomShimmer(height: 30.h, width: 120.w, borderRadius: BorderRadius.circular(5.r)),
                CustomShimmer(height: 40.h, width: 40.w, borderRadius: BorderRadius.circular(20.r)),
              ],
            ),
          ),
          
          SizedBox(height: 20.h),

          // Nav Pills Skeleton
          SizedBox(
            height: 40.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              itemCount: 5,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(right: 10.w),
                  child: CustomShimmer(
                    height: 40.h,
                    width: 100.w,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 30.h),

          // Sections Skeleton
          ...List.generate(3, (index) {
            return Padding(
              padding: EdgeInsets.only(bottom: 30.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Title Skeleton
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: CustomShimmer(
                      height: 20.h,
                      width: 150.w,
                      borderRadius: BorderRadius.circular(5.r),
                    ),
                  ),
                  SizedBox(height: 15.h),

                  // Horizontal 16:9 Cards Skeleton
                  SizedBox(
                    height: 180.h,
                    child: ListView.builder(
                      itemCount: 3,
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 15.w),
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 5.w),
                          child: CustomShimmer(
                            height: 180.h,
                            width: 280.w, // Match the card width in NewHomeScreen
                            borderRadius: BorderRadius.circular(15.r),
                          ),
                        );
                      },
                    ),
                  )
                ],
              ),
            );
          })
        ],
      ),
    );
  }
}
