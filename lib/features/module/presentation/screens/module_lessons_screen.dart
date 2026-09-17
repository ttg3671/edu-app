import 'package:edu_gym/api/api.dart';
import 'package:edu_gym/core/theme/app_color.dart';
import 'package:edu_gym/core/common/widgets/loader.dart';
import 'package:edu_gym/core/cubit_states/data_state.dart';
import 'package:edu_gym/core/utils/convert.dart';
import 'package:edu_gym/core/utils/custom_snackbar.dart';
import 'package:edu_gym/features/module/presentation/cubit/module_cubit.dart';
import 'package:edu_gym/features/module/presentation/widget/module_description.dart';
import 'package:edu_gym/features/module/presentation/widget/module_lesson.dart';
import 'package:edu_gym/features/module/presentation/widget/syllabus_section.dart';
import 'package:edu_gym/modal/lesson.dart';
import 'package:edu_gym/modal/module.dart';
import 'package:edu_gym/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'landscape_video_player_screen.dart';
import 'vertical_video_player_screen.dart';
import '../../../account/presentation/screens/plans_screen.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../api/token_api.dart';
import '../../../auth/presentation/pages/login.dart';

class ModuleLessonsScreen extends StatefulWidget {
  final int moduleId;
  final String moduleTitle;
  const ModuleLessonsScreen({super.key, required this.moduleId, required this.moduleTitle});

  @override
  State<ModuleLessonsScreen> createState() => _ModuleLessonsScreenState();
}

class _ModuleLessonsScreenState extends State<ModuleLessonsScreen> {

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() {
    if (!TokenApi.isUserLoggedIn()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const Login()),
          (route) => false,
        );
      });
    }
  }

  Future<void> _onPlayLesson(Lesson lesson, Module module) async {
    final localizations = AppLocalizations.of(context);
    final comingSoonText = localizations?.comingSoonStayTuned ?? 'Coming Soon! Stay tuned.';

    // Only for FREE modules with missing video_provider_id
    final bool isComingSoon = (module.isFree || lesson.isFree) && lesson.hasNullVideoIds;
    if (isComingSoon) {
      CustomSnackBar.show(
        context: context,
        message: comingSoonText,
        color: AppColor.primary,
      );
      return;
    }

    final user = TokenApi.user;
    final bool isReviewer = user?.isReviewer == 1;
    final bool isSubscribed = user?.isSubscribed == 1;

    // Access logic:
    // 1. Reviewers always have access
    // 2. Free modules are always accessible
    // 3. Already owned modules (purchased) are accessible
    // 4. Subscribed users have access
    bool hasAccess = false;
    
    if (isReviewer) {
      hasAccess = true;
    } else if (module.isFree || module.alreadyOwned) {
      hasAccess = true;
    } else if (isSubscribed) {
      hasAccess = true;
    }

    if (!hasAccess) {
      // Module isn't free and the user isn't subscribed - let them pick a plan.
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PlansScreen()),
        );
      }
      return;
    }

    final videoProviderIdRaw = lesson.effectiveVideoProviderId ?? lesson.videoProviderId;
    final uiStyle = lesson.uiStyle ?? 'horizontal';

    if (videoProviderIdRaw == null || videoProviderIdRaw.isEmpty || videoProviderIdRaw == 'null') {
      if (module.isFree && lesson.isFree) {
        CustomSnackBar.show(
          context: context,
          message: comingSoonText,
          color: AppColor.primary,
        );
      } else {
        CustomSnackBar.show(
          context: context,
          message: 'Video currently unavailable',
        );
      }
      return;
    }

    // Explicitly parse to int as requested, then convert back to string for the API path
    final parsedId = int.tryParse(videoProviderIdRaw);
    if (parsedId == null || parsedId <= 0) {
      if (module.isFree && lesson.isFree) {
        CustomSnackBar.show(
          context: context,
          message: comingSoonText,
          color: AppColor.primary,
        );
      } else {
        CustomSnackBar.show(
          context: context,
          message: 'Video currently unavailable',
        );
      }
      return;
    }
    final videoProviderId = parsedId.toString();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: Loader()),
    );

    final result = await Api.instance.getLessonVideo(
      videoProviderId: videoProviderId,
      uiStyle: uiStyle,
    );

    // Hide loading
    if (mounted) Navigator.pop(context);

    result.fold(
      (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load video: ${failure.message}')),
        );
      },
      (jsonData) {
        final data = jsonData['data'];
        final List<dynamic> filesJson = data['files'] ?? [];
        final List<VideoFile> videoFiles = filesJson.map((f) => VideoFile.fromJson(f)).toList();
        
        if (videoFiles.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No video files found')),
          );
          return;
        }

        // Get HLS or first available
        final hlsVideo = videoFiles.firstWhere(
          (vf) => vf.quality.toLowerCase() == 'hls',
          orElse: () => videoFiles.first,
        );

        final videoUrl = hlsVideo.link;
        final responseUiStyle = data['ui_style'] ?? uiStyle;
        final rawApiThumbnail = (data['thumbnail'] ?? data['thumbnail_url'])?.toString();
        String? resolvedApiThumbnail;
        if (rawApiThumbnail != null && rawApiThumbnail.isNotEmpty) {
          if (rawApiThumbnail.startsWith('http://') || rawApiThumbnail.startsWith('https://')) {
            resolvedApiThumbnail = rawApiThumbnail;
          } else {
            final cleanPath = rawApiThumbnail.startsWith('/') ? rawApiThumbnail.substring(1) : rawApiThumbnail;
            final base = Api.imgBaseUrl.endsWith('/')
                ? Api.imgBaseUrl.substring(0, Api.imgBaseUrl.length - 1)
                : Api.imgBaseUrl;
            resolvedApiThumbnail = '$base/$cleanPath';
          }
        }
        final effectiveThumbnail = (resolvedApiThumbnail != null && resolvedApiThumbnail.isNotEmpty) 
            ? resolvedApiThumbnail 
            : lesson.lessonImage;

        // Parse watch_time or last_position_ms if available
        Duration? initialPos;
        final watchTime = data['watch_time'] ?? data['last_position_ms'];
        if (watchTime != null) {
          final int? watchSec = int.tryParse(watchTime.toString());
          if (watchSec != null && watchSec > 0) {
            initialPos = watchSec > 1000
                ? Duration(milliseconds: watchSec)
                : Duration(seconds: watchSec);
          }
        }

        final int? videoDuration = data['duration'] is int
            ? data['duration']
            : int.tryParse(data['duration']?.toString() ?? '');
        final effectiveVideoProviderId = data['id']?.toString() ?? data['video_provider_id']?.toString() ?? videoProviderId;

        if (responseUiStyle == 'vertical') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerticalVideoPlayerScreen(
                videoUrl: videoUrl,
                lessonTitle: lesson.lessonTitle ?? 'Video',
                videoFiles: videoFiles,
                thumbnailUrl: effectiveThumbnail,
                videoProviderId: effectiveVideoProviderId,
                totalDuration: videoDuration,
                moduleId: widget.moduleId,
                initialPosition: initialPos,
              ),
            ),
          );
        } else {
          // Landscape/Horizontal player
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LandscapeVideoPlayerScreen(
                videoUrl: videoUrl,
                lessonTitle: lesson.lessonTitle ?? 'Video',
                videoFiles: videoFiles,
                thumbnailUrl: effectiveThumbnail,
                videoProviderId: effectiveVideoProviderId,
                totalDuration: videoDuration,
                moduleId: widget.moduleId,
                initialPosition: initialPos,
              ),
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    return BlocProvider(
        create: (create)=>ModuleCubit()..loadData(widget.moduleId),
        child: Scaffold(
          appBar: AppBar(
            title: Text(Convert.toTitleCase(widget.moduleTitle),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: 15.sp
              ),
              maxLines: 1,
            ),
            centerTitle: false,
          ),
          body: BlocBuilder<ModuleCubit,DataState>(
              builder: (BuildContext context, DataState state) {
                if(state is DataLoaded<Module>){
                  return SafeArea(
                    child: CustomScrollView(
                      slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 5.h,horizontal: 20.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Material(
                                  elevation: 5,
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(10.r),
                                  child: Container(
                                    height: Responsive.isTablet? 300.h : 250.h,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10.r),
                                        image: DecorationImage(
                                            image: NetworkImage(state.data.moduleImage),
                                            fit: BoxFit.fill
                                        )
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 20.h,),
                              Text(Convert.toTitleCase(state.data.moduleTitle),
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontSize: 20.sp
                                ),
                              ),
                              SizedBox(height: 15.h,),
                              Row(
                                children: [
                                  Container(
                                    height: 40.h,
                                    width: 40.w,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColor.secondary,
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      color: AppColor.primary,
                                      size: 24.sp,
                                    ),
                                  ),
                                  10.horizontalSpace,
                                  Opacity(
                                    opacity: 0.5,
                                    child: Text('Edu Garcia',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontSize: 16.sp,
                                        color: AppColor.text,
                                      ),
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 15.h,),

                              // Pricing section - only show if not already owned
                              if (!state.data.alreadyOwned && (state.data.originalPrice != null || state.data.discountedPrice != null)) ...[
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                                  decoration: BoxDecoration(
                                    color: AppColor.secondary,
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(color: AppColor.primary.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.local_offer,
                                        color: AppColor.primary,
                                        size: 24.sp,
                                      ),
                                      SizedBox(width: 12.w),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (state.data.discountedPrice != null) ...[
                                            Row(
                                              children: [
                                                Text(
                                                  '\$${state.data.discountedPrice}',
                                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                    fontSize: 24.sp,
                                                    fontWeight: FontWeight.bold,
                                                    color: AppColor.primary,
                                                  ),
                                                ),
                                                SizedBox(width: 8.w),
                                                if (state.data.originalPrice != null)
                                                  Text(
                                                    '\$${state.data.originalPrice}',
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      fontSize: 16.sp,
                                                      decoration: TextDecoration.lineThrough,
                                                      color: AppColor.text.withValues(alpha: 0.5),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ] else if (state.data.originalPrice != null) ...[
                                              Text(
                                                '\$${state.data.originalPrice}',
                                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                                  fontSize: 24.sp,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColor.primary,
                                                ),
                                              ),
                                            ],
                                            SizedBox(height: 4.h),
                                            Text(
                                              localizations?.translate('lifetime_access') ?? 'Lifetime access',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                fontSize: 12.sp,
                                                color: AppColor.text.withValues(alpha: 0.7),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Spacer(),
                                        ElevatedButton(
                                          onPressed: () {
                                            // Handle purchase
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColor.primary,
                                            foregroundColor: AppColor.background,
                                            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8.r),
                                            ),
                                          ),
                                          child: Text(
                                            localizations?.translate('buy_now') ?? 'Buy Now',
                                            style: TextStyle(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 15.h),
                                ],

                                ModuleDescription(description: state.data.moduleDes??''),

                                SizedBox(height: 10.h,),
                                const Divider(),
                                SizedBox(height: 10.h,),

                                // Show syllabus count and total lessons
                                if (state.data.syllabus != null && state.data.syllabus!.isNotEmpty) ...[
                                  Row(
                                    children: [
                                      Icon(Icons.list_alt,size: 30.sp, color: AppColor.text,),
                                      SizedBox(width: 10.w,),
                                      Text(localizations?.courseContent ?? "Course Content",
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontSize: 16.sp,
                                            color: AppColor.primary,
                                            fontWeight: FontWeight.bold
                                        ),
                                      ),
                                      const Spacer(),
                                      Opacity(
                                        opacity: 0.5,
                                        child: Text(localizations?.translate('videos_count', params: {'count': '${_getTotalLessons(state.data)}'}) ?? "${_getTotalLessons(state.data)} videos",
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontSize: 16.sp,
                                            color: AppColor.text,
                                          ),
                                        ),
                                      ),

                                    ],
                                  ),
                                  SizedBox(height: 10.h,)
                                ] else if (state.data.lessons != null && state.data.lessons!.isNotEmpty) ...[
                                  Row(
                                    children: [
                                      Icon(Icons.list_alt,size: 30.sp, color: AppColor.text,),
                                      SizedBox(width: 10.w,),
                                      Text(localizations?.courseContent ?? "Course Content",
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontSize: 16.sp,
                                            color: AppColor.primary,
                                            fontWeight: FontWeight.bold
                                        ),
                                      ),
                                      const Spacer(),
                                      Opacity(
                                        opacity: 0.5,
                                        child: Text(localizations?.translate('videos_count', params: {'count': '${state.data.lessonCount ?? state.data.lessons!.length}'}) ?? "${state.data.lessonCount ?? state.data.lessons!.length} videos",
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            fontSize: 16.sp,
                                            color: AppColor.text,
                                          ),
                                        ),
                                      ),

                                    ],
                                  ),
                                  SizedBox(height: 10.h,)
                                ],
                              ],
                            ),
                          ),
                        ),

                        // Show syllabus sections if available, otherwise show lessons
                        if (state.data.syllabus != null && state.data.syllabus!.isNotEmpty)
                          SliverPadding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index){
                                  final syllabusId = state.data.syllabus![index].syllabusId;
                                  final isLoading = context.read<ModuleCubit>().isLoadingLessons(syllabusId);
                                  final user = TokenApi.user;
                                  final isReviewer = user?.isReviewer == 1;
                                  final isSubscribed = user?.isSubscribed == 1;
                                  final isLocked = !isReviewer && !state.data.isFree && !state.data.alreadyOwned && !isSubscribed;

                                  return SyllabusSection(
                                    syllabus: state.data.syllabus![index],
                                    index: index,
                                    isLoadingMore: isLoading,
                                    isLocked: isLocked,
                                    isModuleFree: state.data.isFree,
                                    onPlayLesson: (lesson) => _onPlayLesson(lesson, state.data),
                                    onLoadMore: () {
                                      // Load more lessons for this syllabus
                                      context.read<ModuleCubit>().loadMoreLessons(syllabusId);
                                    },
                                  );
                                },
                                childCount: state.data.syllabus!.length,
                              ),
                            ),
                          )
                        else if (state.data.lessons != null && state.data.lessons!.isNotEmpty)
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                                  (context, index){
                                final lesson = state.data.lessons![index];
                                final user = TokenApi.user;
                                final isReviewer = user?.isReviewer == 1;
                                final isSubscribed = user?.isSubscribed == 1;
                                final isLocked = !isReviewer && !state.data.isFree && !state.data.alreadyOwned && !isSubscribed;

                                return ModuleLesson(
                                  index: index,
                                  onTap: () => _onPlayLesson(lesson, state.data),
                                  lesson: lesson,
                                  isLocked: isLocked,
                                  isModuleFree: state.data.isFree,
                                );
                              },
                              childCount: state.data.lessons!.length,
                            ),
                          ),

                        // Add bottom padding for SafeArea
                        SliverPadding(
                          padding: EdgeInsets.only(bottom: 20.h),
                        ),
                      ],
                    ),
                  );
                }
                else if(state is DataLoading){
                  return const Center(child: Loader());
                }
                else if(state is DataLoadFailed){
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.r),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48.sp, color: Colors.redAccent),
                          SizedBox(height: 16.h),
                          Text(
                            state.error.message.isNotEmpty
                                ? state.error.message
                                : 'Failed to load module lessons',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15.sp, color: AppColor.text),
                          ),
                          SizedBox(height: 20.h),
                          ElevatedButton(
                            onPressed: () => context.read<ModuleCubit>().loadData(widget.moduleId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColor.primary,
                              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                            ),
                            child: Text(
                              'Retry',
                              style: TextStyle(fontSize: 14.sp, color: AppColor.background),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
        )
    );
  }

  // Helper method to calculate total lessons from all syllabus
  int _getTotalLessons(Module module) {
    if (module.syllabus != null && module.syllabus!.isNotEmpty) {
      return module.syllabus!.fold(0, (total, syllabus) {
        return total + (syllabus.lessonCount ?? syllabus.lessons?.length ?? 0);
      });
    }
    return module.lessonCount ?? module.lessons?.length ?? 0;
  }
}
