import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import '../../../utils/utils.dart';

class CustomShimmer extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxShape? shape;
  const CustomShimmer({super.key, this.width, this.height, this.borderRadius, this.shape});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
        gradient: Theme.of(context).brightness==Brightness.dark?
        darkGradient : lightGradient,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
              borderRadius: borderRadius,
                  // BorderRadius.only(topLeft: Radius.circular(10.r),
                  // topRight: Radius.circular(10.r)),
              color: Colors.black,
            shape: shape?? BoxShape.rectangle
          ),
        ));
  }
}
