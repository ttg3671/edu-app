import 'package:edu_gym/core/theme/app_color.dart';
import 'package:edu_gym/core/utils/convert.dart';
import 'package:edu_gym/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void showWorkoutInstructionsModal(
  BuildContext context, {
  required String title,
  required String htmlContent,
  String? subtitle,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => WorkoutInstructionsModal(
      title: title,
      htmlContent: htmlContent,
      subtitle: subtitle,
    ),
  );
}

void showWorkoutInstructionsDialog(
  BuildContext context, {
  required String title,
  required String htmlContent,
  String? subtitle,
}) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: WorkoutInstructionsModal(
          title: title,
          htmlContent: htmlContent,
          subtitle: subtitle,
        ),
      ),
    ),
  );
}

class WorkoutInstructionsModal extends StatelessWidget {
  final String title;
  final String htmlContent;
  final String? subtitle;

  const WorkoutInstructionsModal({
    super.key,
    required this.title,
    required this.htmlContent,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
        minHeight: 200.h,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColor.background : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 10.h),

            // Top drag handle
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 12.h),

            // Header Row: Info icon + Title + Subtitle + Close button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 18.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Info icon in soft circular container
                  Container(
                    width: 38.r,
                    height: 38.r,
                    decoration: BoxDecoration(
                      color: AppColor.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.info_outline_rounded,
                        size: 22.sp,
                        color: AppColor.primary,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),

                  // Title and Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subtitle ??
                              (localizations?.workoutInstructions ??
                                  'Workout Instructions'),
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: AppColor.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          Convert.toTitleCase(title),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColor.text,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Close icon
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      size: 24.sp,
                      color: AppColor.text.withValues(alpha: 0.6),
                    ),
                    splashRadius: 20.r,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            Divider(height: 20.h, color: AppColor.secondary),

            // Html instructions body
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                physics: const BouncingScrollPhysics(),
                child: Html(
                  data: htmlContent,
                  style: {
                    'body': Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      fontSize: FontSize(15.sp),
                      color: AppColor.text,
                      lineHeight: const LineHeight(1.5),
                    ),
                    'p': Style(
                      margin: Margins.only(bottom: 8.h),
                      padding: HtmlPaddings.zero,
                      fontSize: FontSize(15.sp),
                      color: AppColor.text,
                      lineHeight: const LineHeight(1.5),
                    ),
                    'ul': Style(
                      margin: Margins.only(bottom: 10.h),
                      padding: HtmlPaddings.only(left: 18.w),
                    ),
                    'ol': Style(
                      margin: Margins.only(bottom: 10.h),
                      padding: HtmlPaddings.only(left: 18.w),
                    ),
                    'li': Style(
                      margin: Margins.only(bottom: 6.h),
                      fontSize: FontSize(15.sp),
                      color: AppColor.text,
                      lineHeight: const LineHeight(1.4),
                    ),
                    'strong': Style(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    'b': Style(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    'h1': Style(
                      fontSize: FontSize(18.sp),
                      fontWeight: FontWeight.bold,
                      color: AppColor.primary,
                      margin: Margins.only(bottom: 8.h),
                    ),
                    'h2': Style(
                      fontSize: FontSize(17.sp),
                      fontWeight: FontWeight.bold,
                      color: AppColor.primary,
                      margin: Margins.only(bottom: 8.h),
                    ),
                    'h3': Style(
                      fontSize: FontSize(16.sp),
                      fontWeight: FontWeight.bold,
                      color: AppColor.primary,
                      margin: Margins.only(bottom: 6.h),
                    ),
                  },
                ),
              ),
            ),
            SizedBox(height: 15.h),
          ],
        ),
      ),
    );
  }
}
