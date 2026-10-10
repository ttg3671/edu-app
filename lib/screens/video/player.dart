import 'dart:async';

import 'package:edu_gym/features/auth/presentation/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

import '../../cubits/video_cubit.dart';
import '../../features/quality_player/src/cast_error_reporter.dart';
import '../../features/quality_player/src/video_seek_bar.dart' show CastSeekBar;

class Player extends StatefulWidget {
  final bool isTrailer;
  final bool? isLandscape;
  final String? videoUrl; // Added to pass to Chromecast
  const Player({super.key, this.isLandscape, required this.isTrailer, this.videoUrl});

  @override
  State<Player> createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  StreamSubscription? _sessionSubscription;

  // Whether a Cast session is currently connected. While true, the local
  // video_player is paused/muted (see VideoCubit.setCastingActive) and the
  // playback controls below are re-routed to GoogleCastRemoteMediaClient so
  // they act on the TV instead of the hidden local player.
  bool _isCasting = false;

  @override
  void initState() {
    super.initState();
    _sessionSubscription = GoogleCastSessionManager.instance.currentSessionStream.listen((session) {
      if (!mounted) return;
      final isConnected = session != null;
      setState(() => _isCasting = isConnected);
      try {
        context.read<VideoCubit>().setCastingActive(isConnected);
      } catch (_) {
        // Cubit not ready yet (shouldn't happen once the tree is built).
      }
      if (isConnected) {
        _loadMedia();
      }
    });
  }

  void _loadMedia() {
    if (widget.videoUrl == null) return;

    final mediaInfo = GoogleCastMediaInformation(
      contentId: widget.videoUrl!,
      streamType: CastMediaStreamType.buffered,
      contentType: 'video/mp4',
      metadata: GoogleCastMovieMediaMetadata(
        title: 'Edu Gym Video',
      ),
    );

    GoogleCastRemoteMediaClient.instance.loadMedia(mediaInfo).catchError(
        (Object e, StackTrace s) => reportCastError(e, s, 'load media failed'));
  }

  void _toggleCastPlayback(CastMediaPlayerState? playerState) {
    final isPlaying = playerState == CastMediaPlayerState.playing || playerState == CastMediaPlayerState.buffering;
    final action = isPlaying ? GoogleCastRemoteMediaClient.instance.pause() : GoogleCastRemoteMediaClient.instance.play();
    action.catchError((Object e, StackTrace s) => reportCastError(e, s, 'cast play/pause failed'));
  }

  void _castSeekRelative(Duration delta) {
    GoogleCastRemoteMediaClient.instance
        .seek(GoogleCastMediaSeekOption(position: delta, relative: true))
        .catchError((Object e, StackTrace s) => reportCastError(e, s, 'cast seek failed'));
  }

  @override
  void dispose() {
    _sessionSubscription?.cancel();
    super.dispose();
  }

  // Custom device list modal mapping discovery channels safely
  void _showCastDeviceSelector(BuildContext context) {
    GoogleCastDiscoveryManager.instance.startDiscovery();

    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StreamBuilder<List<GoogleCastDevice>>(
          stream: GoogleCastDiscoveryManager.instance.devicesStream,
          builder: (context, snapshot) {
            final devices = snapshot.data ?? [];
            if (devices.isEmpty) {
              return const SizedBox(
                height: 150,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text("Scanning for nearby Cast receivers..."),
                    ],
                  ),
                ),
              );
            }
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final device = devices[index];
                  return ListTile(
                    leading: const Icon(Icons.cast),
                    title: Text(device.friendlyName),
                    subtitle: Text(device.modelName ?? 'Chromecast Device'),
                    onTap: () async {
                      Navigator.pop(context);
                      try {
                        final started = await GoogleCastSessionManager.instance.startSessionWithDevice(device);
                        if (!started) {
                          reportCastError(
                              StateError('startSessionWithDevice returned false (${device.modelName ?? 'unknown model'})'),
                              null,
                              'connect failed');
                        }
                      } catch (e, s) {
                        reportCastError(e, s, 'connect failed');
                      }
                    },
                  );
                },
              ),
            );
          },
        );
      },
    ).then((_) => GoogleCastDiscoveryManager.instance.stopDiscovery());
  }

  @override
  Widget build(BuildContext context) {
    double iconSize = widget.isLandscape == true ? 20.sp : 30.sp;

    return BlocBuilder<VideoCubit, VideoState>(builder: (context, VideoState state) {
      if (state is VideoInitialized) {
        return GestureDetector(
          onTap: () {
            context.read<VideoCubit>().toggleControls();
          },
          child: widget.isLandscape == true
              ? Center(
            child: _player(context: context, state: state, iconSize: iconSize),
          )
              : _player(context: context, state: state, iconSize: iconSize),
        );
      } else if (state is VideoLoading || state is VideoInitial) {
        return Stack(
          children: [
            Positioned.fill(
                top: 5.h,
                left: 5.w,
                child: Align(
                  alignment: Alignment.topLeft,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close_sharp,
                      size: iconSize,
                      color: Colors.white,
                    ),
                  ),
                )),
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          ],
        );
      } else if (state is VideoError) {
        return Stack(
          children: [
            Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Playback error",
                      style: TextStyle(color: Colors.white, fontSize: 12.sp),
                    ),
                    SizedBox(height: 5.h),
                    InkWell(
                      onTap: () {
                        context.read<VideoCubit>().initVideoPlayer(link: state.videoLink);
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 10.w),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10.r)),
                        child: Text(
                          "Retry",
                          style: TextStyle(color: Colors.black, fontSize: 10.sp),
                        ),
                      ),
                    )
                  ],
                )),
            Positioned.fill(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      child: Icon(
                        Icons.arrow_back_ios,
                        size: 30.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ))
          ],
        );
      } else if (state is SubNotActive) {
        return _errorOverlay(context, iconSize, "Subscription Required", "Please subscribe to watch this video.",
            onRetry: () => Navigator.pop(context), buttonText: "Go Back");
      } else if (state is AuthRequired) {
        return _errorOverlay(context, iconSize, "Authentication Required", "Please login to watch this video.", onRetry: () {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => const Login()));
        }, buttonText: "Login Now");
      }
      return Container();
    });
  }

  Widget _errorOverlay(BuildContext context, double iconSize, String title, String message,
      {required VoidCallback onRetry, required String buttonText}) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, color: Colors.white, size: 50.sp),
                SizedBox(height: 20.h),
                Text(title, style: TextStyle(color: Colors.white, fontSize: 18.sp, fontWeight: FontWeight.bold)),
                SizedBox(height: 10.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40.w),
                  child: Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontSize: 14.sp)),
                ),
                SizedBox(height: 30.h),
                ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                  child: Text(buttonText),
                ),
              ],
            ),
          ),
          Positioned(
            top: 40.h,
            left: 20.w,
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.white, size: iconSize),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _player({required BuildContext context, required VideoInitialized state, required double iconSize}) {
    return AspectRatio(
      aspectRatio: state.videoPlayerController.value.aspectRatio,
      child: Stack(
        children: [
          VideoPlayer(state.videoPlayerController),
          ValueListenableBuilder(
            valueListenable: state.videoPlayerController,
            builder: (BuildContext context, VideoPlayerValue value, Widget? child) {
              if (value.isBuffering) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                );
              }
              return Container();
            },
          ),
          Container(
            color: state.showControls ? Colors.black45 : Colors.transparent,
          ),
          Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: AnimatedOpacity(
                  opacity: state.showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: _isCasting
                      ? StreamBuilder<GoggleCastMediaStatus?>(
                          stream: GoogleCastRemoteMediaClient.instance.mediaStatusStream,
                          initialData: GoogleCastRemoteMediaClient.instance.mediaStatus,
                          builder: (context, snapshot) {
                            final playerState = snapshot.data?.playerState;
                            final isPlaying = playerState == CastMediaPlayerState.playing || playerState == CastMediaPlayerState.buffering;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                InkWell(
                                  onTap: () => state.showControls
                                      ? _castSeekRelative(const Duration(seconds: -10))
                                      : context.read<VideoCubit>().toggleControls(),
                                  child: Container(
                                      padding: EdgeInsets.all(10.r),
                                      decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                                      child: Icon(Icons.replay_10, size: iconSize, color: Colors.white)),
                                ),
                                InkWell(
                                  onTap: () => state.showControls
                                      ? _toggleCastPlayback(playerState)
                                      : context.read<VideoCubit>().toggleControls(),
                                  child: Container(
                                    padding: EdgeInsets.all(10.r),
                                    decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                                    child: Icon(
                                      isPlaying ? Icons.pause : Icons.play_arrow,
                                      size: iconSize,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => state.showControls
                                      ? _castSeekRelative(const Duration(seconds: 10))
                                      : context.read<VideoCubit>().toggleControls(),
                                  child: Container(
                                    padding: EdgeInsets.all(10.r),
                                    decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                                    child: Icon(Icons.forward_10, size: iconSize, color: Colors.white),
                                  ),
                                ),
                              ],
                            );
                          },
                        )
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      InkWell(
                        onTap: () => state.showControls ? context.read<VideoCubit>().backwardVideo() : context.read<VideoCubit>().toggleControls(),
                        child: Container(
                            padding: EdgeInsets.all(10.r),
                            decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                            child: Icon(
                              Icons.replay_10,
                              size: iconSize,
                              color: Colors.white,
                            )),
                      ),
                      InkWell(
                        onTap: () => state.showControls ? context.read<VideoCubit>().toggleVideoPlay() : context.read<VideoCubit>().toggleControls(),
                        child: Container(
                          padding: EdgeInsets.all(10.r),
                          decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                          child: Icon(
                            state.videoPlayerController.value.isPlaying ? Icons.pause : Icons.play_arrow,
                            size: iconSize,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => state.showControls ? context.read<VideoCubit>().forwardVideo() : context.read<VideoCubit>().toggleControls(),
                        child: Container(
                          padding: EdgeInsets.all(10.r),
                          decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                          child: Icon(
                            Icons.forward_10,
                            size: iconSize,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
          Positioned.fill(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: ValueListenableBuilder(
                  valueListenable: state.videoPlayerController,
                  builder: (BuildContext context, value, Widget? child) {
                    final currentPosition = _formatDuration(value.position);
                    final totalDuration = _formatDuration(value.duration);
                    return AnimatedOpacity(
                      opacity: state.showControls ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 5.h, horizontal: 10.w),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '$currentPosition : $totalDuration',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium!
                                      .copyWith(color: Colors.white, fontSize: widget.isLandscape == true ? 10.sp : 18.sp),
                                ),
                                Row(
                                  children: [
                                    // Swapped invalid layout widget for standard reactive interface
                                    StreamBuilder<GoogleCastSession?>(
                                      stream: GoogleCastSessionManager.instance.currentSessionStream,
                                      builder: (context, snapshot) {
                                        final bool isConnected = GoogleCastSessionManager.instance.connectionState == GoogleCastConnectState.connected;
                                        return IconButton(
                                          onPressed: () {
                                            if (isConnected) {
                                              GoogleCastSessionManager.instance.endSessionAndStopCasting();
                                            } else {
                                              _showCastDeviceSelector(context);
                                            }
                                          },
                                          icon: Icon(
                                            isConnected ? Icons.cast_connected : Icons.cast,
                                            color: Colors.white,
                                            size: iconSize * 0.9,
                                          ),
                                        );
                                      },
                                    ),
                                    SizedBox(width: 10.w),
                                    InkWell(
                                      onTap: () {
                                        if (state.showControls) {
                                          widget.isLandscape == true
                                              ? context.read<VideoCubit>().toggleControls()
                                              : context.read<VideoCubit>().toggleControls();
                                        }
                                      },
                                      child: Icon(
                                        widget.isLandscape == true ? Icons.fullscreen_exit : Icons.fullscreen,
                                        color: Colors.white,
                                        size: iconSize,
                                      ),
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
                          _isCasting
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  child: CastSeekBar(),
                                )
                              : VideoProgressIndicator(state.videoPlayerController, allowScrubbing: true),
                          if (widget.isLandscape == true) SizedBox(height: 40.h,)
                        ],
                      ),
                    );
                  },
                ),
              )),
          Positioned.fill(
              top: 5.h,
              right: 5.w,
              child: AnimatedOpacity(
                opacity: state.showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Visibility(
                    visible: state.showControls,
                    child: InkWell(
                        onTap: () {
                          _showBottomDialog(
                              context: context,
                              controller: state.videoPlayerController,
                              videoQualities: state.videoQualities ?? [],
                              currentQuality: state.currentQuality ?? 'adaptive');
                        },
                        child: Icon(
                          Icons.settings,
                          size: iconSize,
                          color: Colors.white,
                        )),
                  ),
                ),
              )),
          Positioned.fill(
              top: 5.h,
              left: 5.w,
              child: Align(
                alignment: Alignment.topLeft,
                child: AnimatedOpacity(
                  opacity: state.showControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: InkWell(
                    onTap: () {
                      if (widget.isLandscape == true) {
                        if (state.showControls) {
                          if (widget.isTrailer) {
                            context.read<VideoCubit>().disposePlayer();
                          }
                          Navigator.pop(context);
                        } else {
                          context.read<VideoCubit>().toggleControls();
                        }
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: Icon(
                      Icons.close_sharp,
                      size: iconSize,
                      color: Colors.white,
                    ),
                  ),
                ),
              ))
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  void _showBottomDialog({required BuildContext context, required VideoPlayerController controller, required List<String> videoQualities, required String currentQuality}) {
    String? currentQualityStr = context.read<VideoCubit>().currentQuality;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (c) {
          return Container(
            padding: EdgeInsets.symmetric(vertical: 30.h, horizontal: 20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _bottomSettingsIcon(
                    context: context,
                    settingsName: 'Quality',
                    settingsIcon: Icons.high_quality_outlined,
                    value: currentQualityStr == 'adaptive' || currentQualityStr == null ? 'Auto' : '${currentQualityStr}p',
                    onTap: () {
                      _videoQualityDialog(context: context, controller: controller, videoQualities: videoQualities, currentQuality: currentQualityStr ?? 'adaptive');
                    }),
                _bottomSettingsIcon(
                    context: context,
                    settingsName: 'Playback speed',
                    settingsIcon: Icons.speed,
                    value: '${controller.value.playbackSpeed}',
                    onTap: () {
                      _playBackDialog(context: context, controller: controller);
                    }),
              ],
            ),
          );
        });
  }

  Widget _bottomSettingsIcon({required BuildContext context, required String settingsName, required IconData settingsIcon, required String value, required VoidCallback onTap}) {
    double iconSize = widget.isLandscape == true ? 15.sp : 25.sp;
    double fontSize = widget.isLandscape == true ? 10.sp : 18.sp;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: widget.isLandscape == true ? 12.h : 8.h,
        ),
        child: Row(
          children: [
            Icon(
              settingsIcon,
              size: iconSize,
            ),
            SizedBox(
              width: 20.w,
            ),
            Text(settingsName, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: fontSize, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: fontSize),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 12.sp,
            ),
          ],
        ),
      ),
    );
  }

  void _videoQualityDialog({required BuildContext context, required VideoPlayerController controller, required List<String> videoQualities, required String currentQuality}) {
    double fontSize = widget.isLandscape == true ? 10.sp : 18.sp;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (c) {
          return Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 30.h, horizontal: 20.w),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: videoQualities
                    .map((quality) => InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    child: Row(
                      children: [
                        Opacity(opacity: quality == currentQuality ? 1 : 0, child: Icon(Icons.check, size: 18.sp)),
                        SizedBox(
                          width: 10.w,
                        ),
                        Text(quality.toLowerCase() == 'adaptive' ? 'Auto' : '${quality}p',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: fontSize, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ))
                    .toList(),
              ),
            ),
          );
        });
  }

  void _playBackDialog({required BuildContext context, required VideoPlayerController controller}) {
    double fontSize = widget.isLandscape == true ? 10.sp : 18.sp;

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (c) {
          return Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 30.h, horizontal: 20.w),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [0.25, 0.5, 1.0, 1.25, 1.5, 2.0]
                    .map((e) => InkWell(
                  onTap: () {
                    context.read<VideoCubit>().changeSpeed(e);
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    child: Row(
                      children: [
                        Opacity(opacity: e == controller.value.playbackSpeed ? 1 : 0, child: Icon(Icons.check, size: 18.sp)),
                        SizedBox(
                          width: 10.w,
                        ),
                        Text('$e', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: fontSize, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ))
                    .toList(),
              ),
            ),
          );
        });
  }
}