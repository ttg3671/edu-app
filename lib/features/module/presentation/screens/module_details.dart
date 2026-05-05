import 'package:edu_gym/api/api.dart';
import 'package:edu_gym/core/common/widgets/loader.dart';
import 'package:edu_gym/core/cubit_states/data_state.dart';
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
import '../../../../l10n/app_localizations.dart';

class ModuleDetails extends StatefulWidget {
  final int moduleId;
  final String moduleTitle;
  const ModuleDetails({super.key, required this.moduleId, required this.moduleTitle});

  @override
  State<ModuleDetails> createState() => _ModuleDetailsState();
}

class _ModuleDetailsState extends State<ModuleDetails> {

  Future<void> _onPlayLesson(Lesson lesson) async {
    final videoProviderId = lesson.videoProviderId;
    final uiStyle = lesson.uiStyle ?? 'horizontal';

    if (videoProviderId == null || videoProviderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video ID not found')),
      );
      return;
    }

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
        final apiThumbnail = data['thumbnail']?.toString();
        final effectiveThumbnail = (apiThumbnail != null && apiThumbnail.isNotEmpty) 
            ? apiThumbnail 
            : lesson.lessonImage;

        if (responseUiStyle == 'vertical') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerticalVideoPlayerScreen(
                videoUrl: videoUrl,
                lessonTitle: lesson.lessonTitle ?? 'Video',
                videoFiles: videoFiles,
                thumbnailUrl: effectiveThumbnail,
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
            title: Text(widget.moduleTitle,
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
                              Text(state.data.moduleTitle,
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
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.green.shade100,
                                    ),
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.green.shade700,
                                      size: 24.sp,
                                    ),
                                  ),
                                  10.horizontalSpace,
                                  Opacity(
                                    opacity: 0.5,
                                    child: Text('Edu Garcia',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontSize: 16.sp,
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
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(color: Colors.green.shade200),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.local_offer,
                                        color: Colors.green.shade700,
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
                                                    color: Colors.green.shade700,
                                                  ),
                                                ),
                                                SizedBox(width: 8.w),
                                                if (state.data.originalPrice != null)
                                                  Text(
                                                    '\$${state.data.originalPrice}',
                                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                      fontSize: 16.sp,
                                                      decoration: TextDecoration.lineThrough,
                                                      color: Colors.grey,
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
                                                color: Colors.green.shade700,
                                              ),
                                            ),
                                          ],
                                          SizedBox(height: 4.h),
                                          Text(
                                            localizations?.translate('lifetime_access') ?? 'Lifetime access',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              fontSize: 12.sp,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      ElevatedButton(
                                        onPressed: () {
                                          // TODO: Handle purchase
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green.shade700,
                                          foregroundColor: Colors.white,
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
                                    Icon(Icons.list_alt,size: 30.sp,),
                                    SizedBox(width: 10.w,),
                                    Text(localizations?.courseContent ?? "Course Content",
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontSize: 16.sp,
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.bold
                                      ),
                                    ),
                                    const Spacer(),
                                    Opacity(
                                      opacity: 0.5,
                                      child: Text(localizations?.translate('videos_count', params: {'count': '${_getTotalLessons(state.data)}'}) ?? "${_getTotalLessons(state.data)} videos",
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontSize: 16.sp,
                                        ),
                                      ),
                                    ),

                                  ],
                                ),
                                SizedBox(height: 10.h,)
                              ] else if (state.data.lessons != null && state.data.lessons!.isNotEmpty) ...[
                                Row(
                                  children: [
                                    Icon(Icons.list_alt,size: 30.sp,),
                                    SizedBox(width: 10.w,),
                                    Text(localizations?.courseContent ?? "Course Content",
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontSize: 16.sp,
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.bold
                                      ),
                                    ),
                                    const Spacer(),
                                    Opacity(
                                      opacity: 0.5,
                                      child: Text(localizations?.translate('videos_count', params: {'count': '${state.data.lessonCount ?? state.data.lessons!.length}'}) ?? "${state.data.lessonCount ?? state.data.lessons!.length} videos",
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                          fontSize: 16.sp,
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
                                return SyllabusSection(
                                  syllabus: state.data.syllabus![index],
                                  index: index,
                                  isLoadingMore: isLoading,
                                  onPlayLesson: (lesson) => _onPlayLesson(lesson),
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
                              return ModuleLesson(
                                  index: index,
                                  onTap: () => _onPlayLesson(lesson),
                                lesson: lesson,
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

