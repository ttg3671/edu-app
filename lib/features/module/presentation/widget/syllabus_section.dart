import 'package:edu_gym/core/theme/app_color.dart';
import 'package:edu_gym/core/utils/convert.dart';
import 'package:edu_gym/modal/lesson.dart';
import 'package:edu_gym/modal/syllabus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../l10n/app_localizations.dart';
import 'workout_instructions_modal.dart';

class SyllabusSection extends StatefulWidget {
  final Syllabus syllabus;
  final int index;
  final Function(Lesson)? onPlayLesson;
  final VoidCallback? onLoadMore;
  final bool isLoadingMore;
  final bool isLocked;
  final bool isModuleFree;

  const SyllabusSection({
    super.key,
    required this.syllabus,
    required this.index,
    this.onPlayLesson,
    this.onLoadMore,
    this.isLoadingMore = false,
    this.isLocked = false,
    this.isModuleFree = false,
  });

  @override
  State<SyllabusSection> createState() => _SyllabusSectionState();
}

class _SyllabusSectionState extends State<SyllabusSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    // Expand the first syllabus by default
    _isExpanded = widget.index == 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        border: Border.all(color: AppColor.secondary),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        children: [
          // Syllabus Header - Clickable to expand/collapse
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 15.h),
              decoration: BoxDecoration(
                color: AppColor.secondary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10.r),
                  topRight: Radius.circular(10.r),
                  bottomLeft: _isExpanded ? Radius.zero : Radius.circular(10.r),
                  bottomRight: _isExpanded ? Radius.zero : Radius.circular(10.r),
                ),
              ),
              child: Row(
                children: [
                  // Syllabus Order/Number
                  Container(
                    width: 30.w,
                    height: 30.h,
                    decoration: BoxDecoration(
                      color: AppColor.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${widget.index + 1}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColor.primary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),

                  // Syllabus Title and Lesson Count
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Convert.toTitleCase(widget.syllabus.syllabusTitle),
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColor.text,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          localizations?.translate('lessons_count', params: {'count': '${widget.syllabus.lessonCount ?? widget.syllabus.lessons?.length ?? 0}'}) ?? '${widget.syllabus.lessonCount ?? widget.syllabus.lessons?.length ?? 0} lessons',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 13.sp,
                            color: AppColor.text.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Workout instructions info icon for syllabus
                  if (widget.syllabus.hasWorkoutInstructions) ...[
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        showWorkoutInstructionsModal(
                          context,
                          title: widget.syllabus.syllabusTitle,
                          htmlContent: widget.syllabus.workoutInstructions!,
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

                  // Expand/Collapse Icon
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 24.sp,
                    color: AppColor.text.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          ),

          // Lessons List - Show when expanded
          if (_isExpanded && widget.syllabus.lessons != null && widget.syllabus.lessons!.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: AppColor.background,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10.r),
                  bottomRight: Radius.circular(10.r),
                ),
              ),
              child: Column(
                children: [
                  Divider(height: 1.h, color: AppColor.secondary),
                  ...widget.syllabus.lessons!.asMap().entries.map((entry) {
                    final lessonIndex = entry.key;
                    final lesson = entry.value;
                    return _buildLessonItem(lesson, lessonIndex);
                  }),

                  // Load More Button
                  if (widget.syllabus.hasMore == true)
                    Container(
                      margin: EdgeInsets.only(bottom: 15.h),
                      padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 15.w),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: AppColor.secondary,
                            width: 1,
                          ),
                        ),
                      ),
                      child: widget.isLoadingMore
                          ? Center(
                              child: SizedBox(
                                width: 24.w,
                                height: 24.h,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColor.primary,
                                ),
                              ),
                            )
                          : InkWell(
                              onTap: widget.onLoadMore,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_circle_outline,
                                    size: 20.sp,
                                    color: AppColor.primary,
                                  ),
                                  SizedBox(width: 10.w),
                                  Text(
                                    localizations?.translate('load_more_lessons') ?? 'Load More Lessons',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColor.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLessonItem(Lesson lesson, int lessonIndex) {
    final theme = Theme.of(context);
    final isReleased = lesson.isReleased ?? true;
    final isLocked = widget.isLocked;
    final isComingSoon = (widget.isModuleFree || lesson.isFree) && lesson.hasNullVideoIds;
    final localizations = AppLocalizations.of(context);

    return InkWell(
      onTap: widget.onPlayLesson != null
          ? () {
              widget.onPlayLesson!(lesson);
            }
          : null,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 12.h),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: lessonIndex == widget.syllabus.lessons!.length - 1
                  ? Colors.transparent
                  : AppColor.secondary,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Lesson Thumbnail (if available) or Number
            if (lesson.lessonImage != null && lesson.lessonImage!.isNotEmpty)
              Container(
                width: 60.w,
                height: 40.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6.r),
                  image: DecorationImage(
                    image: NetworkImage(lesson.lessonImage!),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                width: 24.w,
                height: 24.h,
                decoration: BoxDecoration(
                  color: AppColor.secondary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${lessonIndex + 1}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: AppColor.text.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            SizedBox(width: 12.w),

            // Lesson Title and Duration / Stay Tuned
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Convert.toTitleCase(lesson.lessonTitle).isEmpty
                        ? 'Untitled Lesson'
                        : Convert.toTitleCase(lesson.lessonTitle),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: (!isComingSoon && isReleased && !isLocked)
                          ? AppColor.text
                          : AppColor.text.withValues(alpha: 0.4),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4.h),
                  if (isComingSoon)
                    Text(
                      localizations?.stayTuned ?? 'Stay tuned',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12.sp,
                        color: AppColor.primary.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    )
                  else if (lesson.lessonVideoLength != null && lesson.lessonVideoLength! > 0)
                    Text(
                      _formatDuration(lesson.lessonVideoLength!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12.sp,
                        color: AppColor.text.withValues(alpha: 0.4),
                      ),
                    ),
                ],
              ),
            ),

            // Playing / In-Progress Music Equalizer Icon (when lesson has video_id || last_position_ms)
            if (lesson.hasVideoIdOrLastPosition) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.h),
                margin: EdgeInsets.only(right: 6.w),
                decoration: BoxDecoration(
                  color: AppColor.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Icon(
                  Icons.graphic_eq_rounded,
                  size: 16.sp,
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
                  padding: EdgeInsets.all(5.r),
                  margin: EdgeInsets.only(right: 8.w),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 16.sp,
                    color: AppColor.primary,
                  ),
                ),
              ),
            ],

            // Play/Lock/Coming Soon Icon
            if (isLocked)
              Icon(
                Icons.lock_outline,
                size: 20.sp,
                color: AppColor.primary.withValues(alpha: 0.5),
              )
            else if (isComingSoon)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
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
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColor.primary,
                  ),
                ),
              )
            else if (isReleased)
              Icon(
                Icons.play_circle_outline,
                size: 22.sp,
                color: AppColor.primary,
              )
            else
              Icon(
                Icons.lock_clock_outlined,
                size: 20.sp,
                color: AppColor.text.withOpacity(0.3),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      return '${hours}h ${remainingMinutes}m';
    }
    return '${minutes}m ${remainingSeconds}s';
  }
}
