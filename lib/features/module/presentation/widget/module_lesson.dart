import 'package:cached_network_image/cached_network_image.dart';
import 'package:edu_gym/core/utils/convert.dart';
import 'package:edu_gym/modal/lesson.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/common/widgets/custom_shimmer.dart';
import '../../../../responsive.dart';

class ModuleLesson extends StatelessWidget {
  final int index;
  final VoidCallback onTap;
  final EdgeInsets? padding;
  final Lesson lesson;
  const ModuleLesson({super.key, required this.index, required this.onTap, this.padding, required this.lesson});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: padding??EdgeInsets.symmetric(vertical:10.h, horizontal: 20.w),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: CachedNetworkImage(
                memCacheWidth: 300,
                fit: BoxFit.fill,
                height: Responsive.isTablet? 100.h :80.h,
                width: 120.w,
                placeholder: (context, url){
                  return const CustomShimmer(

                  );
                },
                errorWidget: (context,s,d){
                  return const CustomShimmer();
                },
                imageUrl: lesson.lessonImage??'',
              ),
            ),
            SizedBox(width: 15.w,),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${index+1}. ${lesson.lessonTitle}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: 20.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(Convert.formatSeconds(lesson.lessonVideoLength??0),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 14.sp,
                        color: Theme.of(context).brightness == Brightness.light?
                        Colors.black54 : Colors.white54
                    ),
                    maxLines: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
