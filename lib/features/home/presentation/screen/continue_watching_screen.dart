import 'package:cached_network_image/cached_network_image.dart';
import 'package:edu_gym/api/api.dart';
import 'package:edu_gym/api/token_api.dart';
import 'package:edu_gym/core/common/widgets/custom_shimmer.dart';
import 'package:edu_gym/core/common/widgets/loader.dart';
import 'package:edu_gym/core/theme/app_color.dart';
import 'package:edu_gym/core/utils/convert.dart';
import 'package:edu_gym/core/utils/custom_snackbar.dart';
import 'package:edu_gym/cubits/navigation_cubit.dart';
import 'package:edu_gym/features/account/presentation/screens/subscription_screen.dart';
import 'package:edu_gym/features/auth/presentation/pages/login.dart';
import 'package:edu_gym/features/module/presentation/screens/landscape_video_player_screen.dart';
import 'package:edu_gym/features/module/presentation/screens/vertical_video_player_screen.dart';
import 'package:edu_gym/l10n/app_localizations.dart';
import 'package:edu_gym/main.dart';
import 'package:edu_gym/modal/continue_watching_model.dart';
import 'package:edu_gym/modal/lesson.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ContinueWatchingScreen extends StatefulWidget {
  final bool isFromBottomNav;
  const ContinueWatchingScreen({super.key, this.isFromBottomNav = false});

  @override
  State<ContinueWatchingScreen> createState() => _ContinueWatchingScreenState();
}

class _ContinueWatchingScreenState extends State<ContinueWatchingScreen> with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();
  static const int _pageSize = 5;

  List<ContinueWatchingItem> _items = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  dynamic _nextCursor;
  bool _hasMore = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchInitial();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _fetchInitial();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore &&
        _nextCursor != null) {
      _fetchMore();
    }
  }

  Future<void> _fetchInitial() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // In first run, do NOT add cursor to the URL.
    final result = await Api.instance.getContinueWatching(
      limit: _pageSize,
      cursor: null,
    );

    if (mounted) {
      result.fold(
        (failure) {
          setState(() {
            _isLoading = false;
            _errorMessage = failure.message;
          });
        },
        (jsonData) {
          final response = ContinueWatchingResponse.fromJson(jsonData);
          setState(() {
            _isLoading = false;
            _items = response.data;
            _nextCursor = response.nextCursor;
            _hasMore = response.hasMore;
          });
        },
      );
    }
  }

  Future<void> _fetchMore() async {
    if (_isLoadingMore || !_hasMore || _nextCursor == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Add cursor during page scroll infinite loading when nextCursor != null
    final result = await Api.instance.getContinueWatching(
      limit: _pageSize,
      cursor: _nextCursor,
    );

    if (mounted) {
      result.fold(
        (failure) {
          setState(() {
            _isLoadingMore = false;
          });
        },
        (jsonData) {
          final response = ContinueWatchingResponse.fromJson(jsonData);
          setState(() {
            _isLoadingMore = false;
            _items.addAll(response.data);
            _nextCursor = response.nextCursor;
            _hasMore = response.hasMore;
          });
        },
      );
    }
  }

  Future<void> _onPlayItem(ContinueWatchingItem item) async {
    final localizations = AppLocalizations.of(context);
    final comingSoonText = localizations?.comingSoonStayTuned ?? 'Coming Soon! Stay tuned.';

    if (!TokenApi.isUserLoggedIn()) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const Login()));
      return;
    }

    // Check if free and coming soon (video_provider_id or video_id is null / "null")
    if (item.isComingSoon) {
      if (item.isFree == 1) {
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

    final user = TokenApi.user;
    final bool isReviewer = user?.isReviewer == 1;
    final bool isSubscribed = user?.isSubscribed == 1;

    bool hasAccess = false;
    if (isReviewer || item.isFree == 1 || isSubscribed) {
      hasAccess = true;
    }

    if (!hasAccess) {
      final userDetails = await TokenApi.getUserDetails();
      if (mounted && userDetails != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubscriptionScreen(userDetails: userDetails),
          ),
        );
      }
      return;
    }

    // Show loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: Loader()),
    );

    // 1. Try to fetch video streams using Continue Watching Video endpoint
    Map<String, dynamic>? data;
    if (item.videoId != null && item.videoId! > 0) {
      final cwResult = await Api.instance.getContinueWatchingVideo(videoId: item.videoId!);
      cwResult.fold(
        (_) => null,
        (jsonData) {
          data = jsonData['data'];
        },
      );
    }

    // 2. Fallback to Lesson Video endpoint if needed
    final rawProviderId = item.effectiveVideoProviderId ?? item.videoProviderId;
    if (data == null || data?['files'] == null || (data?['files'] as List).isEmpty) {
      if (rawProviderId != null && rawProviderId.isNotEmpty && rawProviderId != 'null') {
        final result = await Api.instance.getLessonVideo(
          videoProviderId: rawProviderId,
          uiStyle: item.uiStyle ?? 'horizontal',
        );
        result.fold(
          (failure) => null,
          (jsonData) {
            data = jsonData['data'];
          },
        );
      }
    }

    if (mounted) Navigator.pop(context);
    if (!mounted) return;

    if (data == null) {
      if (item.isFree == 1) {
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

    final List<dynamic> filesJson = data!['files'] ?? [];
    final List<VideoFile> videoFiles = filesJson.map((f) => VideoFile.fromJson(f)).toList();

    if (videoFiles.isEmpty) {
      CustomSnackBar.show(
        context: context,
        message: 'No video files found',
      );
      return;
    }

    final hlsVideo = videoFiles.firstWhere(
      (vf) => vf.quality.toLowerCase() == 'hls',
      orElse: () => videoFiles.first,
    );

    final videoUrl = hlsVideo.link;
    final responseUiStyle = data!['ui_style'] ?? item.uiStyle ?? 'horizontal';
    final rawApiThumbnail = (data!['thumbnail'] ?? data!['thumbnail_url'])?.toString();
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
        : item.effectiveThumbnail;

    final effectiveVideoProviderId = data!['id']?.toString() ?? data!['video_provider_id']?.toString() ?? rawProviderId;
    final int? effectiveDuration = data!['duration'] is int
        ? data!['duration']
        : int.tryParse(data!['duration']?.toString() ?? '') ?? item.totalDurationMs;
    final int? effectiveModuleId = data!['module_id'] is int
        ? data!['module_id']
        : int.tryParse(data!['module_id']?.toString() ?? '') ?? item.moduleId;

    // Calculate initial playback position
    Duration? initialPos;
    final posVal = data!['watch_time'] ?? data!['last_position_ms'] ?? item.lastPositionMs;
    if (posVal != null) {
      final int? p = int.tryParse(posVal.toString());
      if (p != null && p > 0) {
        initialPos = p > 1000 ? Duration(milliseconds: p) : Duration(seconds: p);
      }
    }

    if (responseUiStyle == 'vertical') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VerticalVideoPlayerScreen(
            videoUrl: videoUrl,
            lessonTitle: item.lessonTitle ?? 'Video',
            videoFiles: videoFiles,
            thumbnailUrl: effectiveThumbnail,
            videoProviderId: effectiveVideoProviderId,
            totalDuration: effectiveDuration,
            moduleId: effectiveModuleId,
            initialPosition: initialPos,
          ),
        ),
      );
    } else {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => LandscapeVideoPlayerScreen(
            videoUrl: videoUrl,
            lessonTitle: item.lessonTitle ?? 'Video',
            videoFiles: videoFiles,
            thumbnailUrl: effectiveThumbnail,
            videoProviderId: effectiveVideoProviderId,
            totalDuration: effectiveDuration,
            moduleId: effectiveModuleId,
            initialPosition: initialPos,
          ),
        ),
      );
    }
    if (mounted) {
      _fetchInitial();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);

    final content = Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: Text(
          localizations?.watchHistory ?? localizations?.continueWatching ?? 'History',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: AppColor.text,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: !widget.isFromBottomNav,
        leading: widget.isFromBottomNav
            ? null
            : IconButton(
                icon: Icon(Icons.arrow_back_ios_new, size: 20.sp, color: AppColor.text),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: _buildBody(localizations),
    );

    if (widget.isFromBottomNav) {
      return BlocListener<NavigationCubit, int>(
        listener: (context, navIndex) {
          if (navIndex == 2 && mounted) {
            _fetchInitial();
          }
        },
        child: content,
      );
    }

    return content;
  }

  Widget _buildBody(AppLocalizations? localizations) {
    if (_isLoading) {
      return _buildShimmerList();
    }

    if (_errorMessage != null && _items.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48.sp, color: Colors.grey),
              SizedBox(height: 12.h),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15.sp, color: Colors.grey.shade700),
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: _fetchInitial,
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

    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 30.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90.r,
                height: 90.r,
                decoration: BoxDecoration(
                  color: AppColor.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.history_toggle_off_rounded,
                  size: 48.sp,
                  color: AppColor.primary,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                localizations?.noContinueWatchingVideos ?? 'No videos in progress',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColor.text,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                localizations?.noContinueWatchingSubtitle ??
                    'Watch something to see your history and resume videos here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: () {
                  if (widget.isFromBottomNav) {
                    context.read<NavigationCubit>().changeIndex(0);
                  } else {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const MyHomePage()),
                      (route) => false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: AppColor.background,
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: Text(
                  localizations?.startWatching ?? 'Start Watching',
                  style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColor.primary,
      onRefresh: _fetchInitial,
      child: ListView.separated(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        itemCount: _items.length + (_isLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) => SizedBox(height: 14.h),
        itemBuilder: (context, index) {
          if (index == _items.length) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16.h),
                child: const CircularProgressIndicator(color: AppColor.primary),
              ),
            );
          }

          final item = _items[index];
          return _buildItemCard(item, localizations);
        },
      ),
    );
  }

  Widget _buildItemCard(ContinueWatchingItem item, AppLocalizations? localizations) {
    final int durationSec = item.totalDurationMs > 1000
        ? (item.totalDurationMs / 1000).round()
        : item.totalDurationMs;
    final int lastPosSec = item.lastPositionMs > 1000
        ? (item.lastPositionMs / 1000).round()
        : item.lastPositionMs;
    final isCompleted = item.isCompleted == 1;

    return InkWell(
      onTap: () => _onPlayItem(item),
      borderRadius: BorderRadius.circular(14.r),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail with Progress bar overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: item.effectiveThumbnail.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: item.effectiveThumbnail,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => const CustomShimmer(),
                            errorWidget: (context, url, error) => Container(
                              color: Colors.grey.shade200,
                              child: Icon(Icons.video_library, size: 40.sp, color: Colors.grey.shade400),
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: Icon(Icons.video_library, size: 40.sp, color: Colors.grey.shade400),
                          ),
                  ),
                ),

                // Play Icon Overlay
                Positioned.fill(
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.all(12.r),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.play_arrow_rounded,
                        size: 32.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Free / Completed Badge
                Positioned(
                  top: 10.h,
                  right: 10.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.green.shade700
                          : (item.isFree == 1 ? AppColor.primary : Colors.black87),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      isCompleted
                          ? (localizations?.completed ?? 'Completed')
                          : (item.isFree == 1 ? 'FREE' : 'PREMIUM'),
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                // Progress Bar at Bottom of Thumbnail
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    value: item.progress,
                    backgroundColor: Colors.black38,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColor.primary),
                    minHeight: 4.h,
                  ),
                ),
              ],
            ),

            // Card Body
            Padding(
              padding: EdgeInsets.all(14.r),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Convert.toTitleCase(item.lessonTitle),
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColor.text,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 6.h),
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded, size: 14.sp, color: Colors.grey.shade600),
                            SizedBox(width: 4.w),
                            Text(
                              '${Convert.formatSeconds(lastPosSec)} / ${Convert.formatSeconds(durationSec)}',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Text(
                              '•',
                              style: TextStyle(color: Colors.grey.shade400),
                            ),
                            SizedBox(width: 10.w),
                            Text(
                              '${item.progressPercent}% watched',
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: AppColor.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: AppColor.primary,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow, size: 16.sp, color: AppColor.background),
                        SizedBox(width: 4.w),
                        Text(
                          localizations?.resume ?? 'Resume',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColor.background,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      itemCount: 4,
      separatorBuilder: (context, index) => SizedBox(height: 14.h),
      itemBuilder: (context, index) => Container(
        height: 220.h,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: const CustomShimmer(),
      ),
    );
  }


}
