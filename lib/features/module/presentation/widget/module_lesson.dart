import 'package:cached_network_image/cached_network_image.dart';
import 'package:edu_gym/core/theme/app_color.dart';
import 'package:edu_gym/core/utils/convert.dart';
import 'package:edu_gym/modal/lesson.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/common/widgets/custom_shimmer.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../responsive.dart';
import 'workout_instructions_modal.dart';

class ModuleLesson extends StatelessWidget {
  final int index;
  final VoidCallback onTap;
  final EdgeInsets? padding;
  final Lesson lesson;
  final bool isLocked;
  final bool isModuleFree;

  const ModuleLesson({
    super.key,
    required this.index,
    required this.onTap,
    this.padding,
    required this.lesson,
    this.isLocked = false,
    this.isModuleFree = false,
  });

  @override
  Widget build(BuildContext context) {
    final isComingSoon = (isModuleFree || lesson.isFree) && lesson.hasNullVideoIds;
    final localizations = AppLocalizations.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: padding ?? EdgeInsets.symmetric(vertical: 10.h, horizontal: 20.w),
        child: Row(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: CachedNetworkImage(
                    memCacheWidth: 300,
                    fit: BoxFit.fill,
                    height: Responsive.isTablet ? 100.h : 80.h,
                    width: 120.w,
                    placeholder: (context, url) => const CustomShimmer(),
                    errorWidget: (context, s, d) => const CustomShimmer(),
                    imageUrl: lesson.lessonImage ?? '',
                  ),
                ),
                if (isLocked)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.lock,
                        color: AppColor.primary,
                        size: 24.sp,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 15.w,),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${index + 1}. ${Convert.toTitleCase(lesson.lessonTitle)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontSize: 20.sp,
                      color: (isLocked || isComingSoon) ? AppColor.text.withValues(alpha: 0.5) : AppColor.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isComingSoon)
                    Text(
                      localizations?.stayTuned ?? 'Stay tuned',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 14.sp,
                        color: AppColor.primary.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                    )
                  else
                    Text(Convert.formatSeconds(lesson.lessonVideoLength ?? 0),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontSize: 14.sp,
                          color: AppColor.text.withValues(alpha: 0.5),
                      ),
                      maxLines: 1,
                    ),
                ],
              ),
            ),
            // Playing / In-Progress Music Equalizer Icon (when lesson has video_id || last_position_ms)
            if (lesson.hasVideoIdOrLastPosition) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                margin: EdgeInsets.only(right: 8.w),
                decoration: BoxDecoration(
                  color: AppColor.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Icon(
                  Icons.graphic_eq_rounded,
                  size: 18.sp,
                  color: AppColor.primary,
                ),
              ),
            ],

            // Workout instructions info button (if available)
            if (lesson.hasWorkoutInstructions) ...[
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  showWorkoutInstructionsModal(
                    context,
                    title: lesson.lessonTitle ?? 'Lesson',
                    htmlContent: lesson.workoutInstructions!,
                    subtitle: localizations?.workoutInstructions ?? 'Workout Instructions',
                  );
                },
                child: Container(
                  padding: EdgeInsets.all(6.r),
                  margin: EdgeInsets.only(right: 8.w),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 18.sp,
                    color: AppColor.primary,
                  ),
                ),
              ),
            ],

            if (isLocked)
              const SizedBox.shrink()
            else if (isComingSoon)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColor.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColor.primary.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  localizations?.comingSoon ?? 'Coming Soon',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColor.primary,
                  ),
                ),
              )
            else
              Icon(
                Icons.play_circle_outline,
                color: AppColor.primary,
                size: 28.sp,
              ),
          ],
        ),
      ),
    );
  }
}
