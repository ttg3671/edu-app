import 'package:edu_gym/modal/lesson.dart';
import 'package:edu_gym/modal/syllabus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../screens/lesson_details.dart';
import '../../../../l10n/app_localizations.dart';

class SyllabusSection extends StatefulWidget {
  final Syllabus syllabus;
  final int index;
  final Function(Lesson)? onPlayLesson;
  final VoidCallback? onLoadMore;
  final bool isLoadingMore;

  const SyllabusSection({
    super.key,
    required this.syllabus,
    required this.index,
    this.onPlayLesson,
    this.onLoadMore,
    this.isLoadingMore = false,
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
        border: Border.all(color: Colors.grey.shade300),
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
                color: Colors.grey.shade50,
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
                      color: Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${widget.index + 1}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
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
                          widget.syllabus.syllabusTitle,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          localizations?.translate('lessons_count', params: {'count': '${widget.syllabus.lessonCount ?? widget.syllabus.lessons?.length ?? 0}'}) ?? '${widget.syllabus.lessonCount ?? widget.syllabus.lessons?.length ?? 0} lessons',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 13.sp,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Expand/Collapse Icon
                  Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 24.sp,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          // Lessons List - Show when expanded
          if (_isExpanded && widget.syllabus.lessons != null && widget.syllabus.lessons!.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10.r),
                  bottomRight: Radius.circular(10.r),
                ),
              ),
              child: Column(
                children: [
                  Divider(height: 1.h, color: Colors.grey.shade300),
                  ...widget.syllabus.lessons!.asMap().entries.map((entry) {
                    final lessonIndex = entry.key;
                    final lesson = entry.value;
                    return _buildLessonItem(lesson, lessonIndex);
                  }).toList(),

                  // Load More Button
                  if (widget.syllabus.hasMore == true)
                    Container(
                      margin: EdgeInsets.only(bottom: 15.h),
                      padding: EdgeInsets.symmetric(vertical: 15.h, horizontal: 15.w),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Colors.grey.shade200,
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.green.shade700,
                                  ),
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
                                    color: Colors.green.shade700,
                                  ),
                                  SizedBox(width: 10.w),
                                  Text(
                                    localizations?.translate('load_more_lessons') ?? 'Load More Lessons',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green.shade700,
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
    final isReleased = lesson.isReleased ?? true; // Default to true

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
                  : Colors.grey.shade200,
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
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${lessonIndex + 1}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            SizedBox(width: 12.w),

            // Lesson Title and Duration
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.lessonTitle ?? 'Untitled Lesson',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: isReleased ? Colors.black : Colors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (lesson.lessonVideoLength != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      _formatDuration(lesson.lessonVideoLength!),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12.sp,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Play Icon - Only show if lesson is released
            if (isReleased)
              Icon(
                Icons.play_circle_outline,
                size: 22.sp,
                color: Colors.greenAccent,
              )
            else
              Icon(
                Icons.lock_outline,
                size: 20.sp,
                color: Colors.grey,
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
