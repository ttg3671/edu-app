import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:video_player/video_player.dart';

class CustomVideoPlayer extends StatefulWidget {
  final VideoPlayerController controller;

  const CustomVideoPlayer({
    super.key,
    required this.controller,
  });

  @override
  State<CustomVideoPlayer> createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends State<CustomVideoPlayer> {
  bool _showControls = true;
  bool _isPlaying = false;
  bool _isFullscreen = false;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_videoListener);
    _isPlaying = widget.controller.value.isPlaying;

    // Auto-play when video loads
    if (widget.controller.value.isInitialized && !widget.controller.value.isPlaying) {
      widget.controller.play();
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    widget.controller.removeListener(_videoListener);

    // Always reset orientation to portrait when leaving the video player
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: SystemUiOverlay.values,
    );
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    super.dispose();
  }

  void _videoListener() {
    if (mounted) {
      final isPlaying = widget.controller.value.isPlaying;
      if (_isPlaying != isPlaying) {
        setState(() {
          _isPlaying = isPlaying;
        });

        // Auto-hide controls after 3 seconds when playing
        if (isPlaying) {
          _startHideControlsTimer();
        }
      }
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });

    // If showing controls and video is playing, start timer to hide them
    if (_showControls && _isPlaying) {
      _startHideControlsTimer();
    }
  }

  void _togglePlayPause() {
    setState(() {
      if (widget.controller.value.isPlaying) {
        widget.controller.pause();
        _hideControlsTimer?.cancel();
      } else {
        widget.controller.play();
        _startHideControlsTimer();
      }
    });
  }

  void _toggleFullscreen() {
    final wasPlaying = widget.controller.value.isPlaying;

    setState(() {
      _isFullscreen = !_isFullscreen;
    });

    if (_isFullscreen) {
      // Enter fullscreen - FORCE landscape and lock it
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]).then((_) {
        // After orientation change, hide system UI
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      });
    } else {
      // Exit fullscreen - return to portrait and allow all orientations
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }

    // Keep playing state
    if (wasPlaying) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !widget.controller.value.isPlaying) {
          widget.controller.play();
        }
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return GestureDetector(
      onTap: _toggleControls,
      child: Container(
        width: double.infinity,
        height: _isFullscreen ? screenHeight : 250.h,
        color: Colors.black,
        child: Stack(
          children: [
            // Video Player
            Positioned.fill(
              child: Center(
                child: widget.controller.value.isInitialized
                    ? AspectRatio(
                        aspectRatio: widget.controller.value.aspectRatio,
                        child: VideoPlayer(widget.controller),
                      )
                    : const SizedBox(),
              ),
            ),

            // Controls Overlay
            if (_showControls)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),

            // Play/Pause Button (Center)
            if (_showControls)
              Center(
                child: IconButton(
                  onPressed: _togglePlayPause,
                  icon: Icon(
                    _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                    color: Colors.white,
                    size: !_isFullscreen ? 60.sp : 50,
                  ),
                ),
              ),

            // Bottom Controls
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: !_isFullscreen ? 15.w : 20,
                    vertical: !_isFullscreen ? 10.h : 10,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Progress Bar
                      VideoProgressIndicator(
                        widget.controller,
                        allowScrubbing: true,
                        colors: VideoProgressColors(
                          playedColor: Colors.greenAccent,
                          bufferedColor: Colors.white.withOpacity(0.5),
                          backgroundColor: Colors.white.withOpacity(0.2),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: !_isFullscreen ? 5.h : 5,
                        ),
                      ),

                      SizedBox(height: !_isFullscreen ? 8.h : 8),

                      // Bottom Row with Time and Fullscreen
                      Row(
                        children: [
                          // Play/Pause Button
                          IconButton(
                            onPressed: _togglePlayPause,
                            icon: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: !_isFullscreen ? 24.sp : 24,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),

                          SizedBox(width: !_isFullscreen ? 10.w : 10),

                          // Current Time / Total Duration
                          ValueListenableBuilder(
                            valueListenable: widget.controller,
                            builder: (context, VideoPlayerValue value, child) {
                              return Text(
                                '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: !_isFullscreen ? 12.sp : 12,
                                ),
                              );
                            },
                          ),

                          const Spacer(),

                          // Fullscreen Button
                          IconButton(
                            onPressed: _toggleFullscreen,
                            icon: Icon(
                              !_isFullscreen ? Icons.fullscreen : Icons.fullscreen_exit,
                              color: Colors.white,
                              size: !_isFullscreen ? 24.sp : 24,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // Loading Indicator
            if (!widget.controller.value.isInitialized)
              const Center(
                child: CircularProgressIndicator(
                  color: Colors.greenAccent,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
