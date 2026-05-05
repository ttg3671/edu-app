import 'package:cached_network_image/cached_network_image.dart';
import 'package:edu_gym/core/common/widgets/custom_shimmer.dart';
import 'package:edu_gym/core/utils/convert.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../utils/convert_utils.dart';
import '../../../../utils/utils.dart';

class SearchWidget extends StatelessWidget {
  final int id;
  final String? image;
  final String? title;
  final String? description;
  final int videoLength;
  const SearchWidget({super.key, required this.id, this.image, this.title, this.description, required this.videoLength,});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: CachedNetworkImage(
                memCacheWidth: 300,
                fit: BoxFit.fill,
                height: 100.h,
                width: 120.w,
                // memCacheHeight: 200,
                placeholder: (context, url){
                  return const CustomShimmer();
                },
                errorWidget: (context,s,d){
                  return const CustomShimmer();
                },
                imageUrl: image??'',
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.only(bottomRight: Radius.circular(10.r)),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 2.h,horizontal: 5.w),
                  child: Text(Convert.formatSeconds(videoLength),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            )
          ],
        ),
        SizedBox(width: 20.w,),
        Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title??'',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 16.sp
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(description??'',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12.sp
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            )
        )
      ],
    );
  }
}
