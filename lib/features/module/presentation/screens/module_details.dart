import 'package:cached_network_image/cached_network_image.dart';
import 'package:edu_gym/api/token_api.dart';
import 'package:edu_gym/features/module/presentation/free_module_video.dart';
import 'package:edu_gym/core/common/widgets/custom_shimmer.dart';
import 'package:edu_gym/core/common/widgets/loader.dart';
import 'package:edu_gym/core/cubit_states/data_state.dart';
import 'package:edu_gym/core/theme/app_color.dart';
import 'package:edu_gym/core/utils/convert.dart';
import 'package:edu_gym/features/auth/presentation/pages/training_auth_prompt_screen.dart';
import 'package:edu_gym/features/auth/presentation/widgets/auth_btn.dart';
import 'package:edu_gym/features/module/presentation/cubit/module_detail_cubit.dart';
import 'package:edu_gym/features/module/presentation/screens/module_lessons_screen.dart';
import 'package:edu_gym/l10n/app_localizations.dart';
import 'package:edu_gym/modal/module_detail_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ModuleDetails extends StatefulWidget {
  final int moduleId;
  final String? moduleTitle;
  const ModuleDetails({super.key, required this.moduleId, this.moduleTitle});

  @override
  State<ModuleDetails> createState() => _ModuleDetailsState();
}

class _ModuleDetailsState extends State<ModuleDetails> {
  @override
  void initState() {
    super.initState();
    if (TokenApi.isUserLoggedIn()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ModuleLessonsScreen(
                moduleId: widget.moduleId,
                moduleTitle: widget.moduleTitle ?? '',
              ),
            ),
          );
        }
      });
    }
  }

  /// Freemium modules: open the free video directly, without login.
  void _playFreemiumVideo(int moduleId, String title, String moduleThumbnail) {
    openFreeModuleVideo(
      context,
      moduleId: moduleId,
      title: title,
      fallbackThumbnail: moduleThumbnail,
      allowGuest: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (TokenApi.isUserLoggedIn()) {
      return const Scaffold(
        backgroundColor: AppColor.background,
        body: Center(child: Loader()),
      );
    }
    final localizations = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;

    return BlocProvider(
      create: (context) => ModuleDetailCubit()..loadData(widget.moduleId),
      child: Scaffold(
        backgroundColor: AppColor.background,
        appBar: AppBar(
          backgroundColor: AppColor.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColor.text),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.moduleTitle != null && widget.moduleTitle!.isNotEmpty
                ? Convert.toTitleCase(widget.moduleTitle!)
                : (localizations?.translate('modules') ?? 'Module Details'),
            style: textTheme.titleSmall?.copyWith(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          centerTitle: false,
        ),
        body: BlocBuilder<ModuleDetailCubit, DataState>(
          builder: (context, state) {
            if (state is DataLoading) {
              return const Center(child: Loader());
            } else if (state is DataLoaded<ModuleDetailModel>) {
              final module = state.data;
              final displayTitle = module.title.isNotEmpty ? module.title : (widget.moduleTitle ?? '');
              final int count = module.videosCount;
              final String videoCountText = count == 1 ? '1 video' : '$count videos';

              return SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Thumbnail Image Container
                            Center(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15.r),
                                  child: AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: module.fullThumbnailUrl.isNotEmpty
                                        ? CachedNetworkImage(
                                            imageUrl: module.fullThumbnailUrl,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => const CustomShimmer(),
                                            errorWidget: (context, url, error) => Container(
                                              color: AppColor.secondary,
                                              child: const Icon(
                                                Icons.image,
                                                color: AppColor.text,
                                                size: 40,
                                              ),
                                            ),
                                          )
                                        : Container(
                                            color: AppColor.secondary,
                                            child: const Icon(
                                              Icons.image,
                                              color: AppColor.text,
                                              size: 40,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),

                            // Spacing Top for Video Count
                            SizedBox(height: 24.h),

                            // Video count in center (no icon)
                            Center(
                              child: Text(
                                videoCountText,
                                textAlign: TextAlign.center,
                                style: textTheme.titleSmall?.copyWith(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppColor.text.withValues(alpha: 0.65),
                                ),
                              ),
                            ),

                            // Spacing Bottom for Video Count
                            SizedBox(height: 20.h),

                            // Light grey line below video count
                            Divider(
                              color: Colors.grey.shade300,
                              thickness: 1,
                              height: 1,
                            ),

                            // Spacing Top for Description
                            SizedBox(height: 24.h),

                            // Description Section (left aligned)
                            if (module.description != null && module.description!.isNotEmpty) ...[
                              Text(
                                localizations?.translate('description') ?? 'Description',
                                style: textTheme.titleSmall?.copyWith(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppColor.text,
                                ),
                              ),

                              // Spacing between Description title and Description value
                              SizedBox(height: 14.h),

                              Text(
                                module.description!,
                                style: textTheme.bodyMedium?.copyWith(
                                  fontSize: 15.sp,
                                  color: AppColor.text.withValues(alpha: 0.8),
                                  height: 1.6,
                                ),
                              ),

                              // Spacing Bottom for Description value
                              SizedBox(height: 30.h),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Start Video Button at the bottom
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 15.h),
                      decoration: BoxDecoration(
                        color: AppColor.background,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            offset: const Offset(0, -2),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: AuthBtn(
                        text: localizations?.translate('start_video') ?? 'Start Video',
                        width: double.infinity,
                        bgColor: AppColor.primary,
                        textColor: AppColor.background,
                        onTap: () {
                          if (module.isFreemium) {
                            _playFreemiumVideo(
                              module.id > 0 ? module.id : widget.moduleId,
                              displayTitle,
                              module.fullThumbnailUrl,
                            );
                          } else if (!TokenApi.isUserLoggedIn()) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TrainingAuthPromptScreen(),
                              ),
                            );
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ModuleLessonsScreen(
                                  moduleId: module.id > 0 ? module.id : widget.moduleId,
                                  moduleTitle: displayTitle,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            } else if (state is DataLoadFailed) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48.sp, color: Colors.grey),
                      SizedBox(height: 12.h),
                      Text(
                        state.error?.toString() ?? 'Failed to load module details',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15.sp, color: Colors.grey.shade700),
                      ),
                      SizedBox(height: 16.h),
                      ElevatedButton(
                        onPressed: () => context.read<ModuleDetailCubit>().loadData(widget.moduleId),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          foregroundColor: AppColor.background,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        ),
                        child: Text(localizations?.translate('retry') ?? 'Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
