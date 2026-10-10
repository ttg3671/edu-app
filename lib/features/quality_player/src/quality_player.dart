import 'dart:async';

import 'package:edu_gym/features/auth/presentation/pages/login.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:edu_gym/features/quality_player/src/potrait_video.dart';
import 'package:video_player/video_player.dart';

import '../../../responsive.dart';
import '../cubit/player_cubit.dart';
import '../cubit/player_state.dart';
import 'cast_bridge.dart';
import 'cast_button.dart';
import 'cast_error_reporter.dart';
import 'video_seek_bar.dart';
import 'volume_button.dart';
import 'landscape_video.dart';
import '../../../l10n/app_localizations.dart';

class QualityPlayer extends StatefulWidget {
  ///Default video link
  final String link;
  final bool alwaysLandscape;
  final double? height;
  final VoidCallback? onExitIconTap;
  final List<VideoQuality>? videoQualities;
  final bool showMinimalControls;
  final String? thumbnailUrl; // Thumbnail to show while loading
  final bool isTrailer; // Added to handle trailer logic
  final dynamic videoProviderId; // Track continue watching progress
  final int? totalDuration; // Total duration in seconds from video API
  final Duration? initialPosition; // Start playback at position
  final String? videoTitle; // Shown as the media title when cast to a TV
  final bool allowGuest; // Freemium: playable without login

  const QualityPlayer({
    super.key,
    required this.link,
    this.height,
    this.onExitIconTap,
    this.videoQualities,
    this.alwaysLandscape = false,
    this.showMinimalControls = false,
    this.thumbnailUrl,
    this.isTrailer = false,
    this.videoProviderId,
    this.totalDuration,
    this.initialPosition,
    this.videoTitle,
    this.allowGuest = false,
  });

  @override
  State<QualityPlayer> createState() => _QualityPlayerState();
}

class _QualityPlayerState extends State<QualityPlayer> {
  // Owned here (not created inside build) so the cast session listener in
  // initState can reach it - `context.read` from this State's context can't
  // see a provider that is created further down the tree.
  late final PlayerCubit _playerCubit;

  final CastBridge _cast = CastBridge.instance;

  // Whether playback is currently happening on a TV. While true, the local
  // video_player is paused/muted (see PlayerCubit.setCastingActive) and all
  // playback controls below act on the TV instead of the hidden local
  // player.
  bool _isCasting = false;
  int? _castQuality;
  double _castSpeed = 1.0;

  // Last known receiver state, used to hand playback back to the local
  // player at the same spot (and play/pause state) when casting ends.
  Duration _lastCastPosition = Duration.zero;
  bool _castWasPlaying = true;

  // What the play/pause button was just asked to do. Shown until the TV
  // confirms it, so the button reacts instantly instead of waiting for the
  // round trip.
  bool? _castPendingPlaying;
  Timer? _castPendingTimer;

  // A dropped connection usually comes back by itself within a few seconds.
  // Stay in casting mode meanwhile and only fall back to the in-app player
  // if it doesn't.
  Timer? _castReconnectTimer;
  static const _castReconnectTimeout = Duration(seconds: 20);

  @override
  void initState() {
    super.initState();
    _playerCubit = PlayerCubit(
      videoProviderId: widget.videoProviderId,
      totalDuration: widget.totalDuration,
      allowGuest: widget.allowGuest,
    )..initVideoPlayer(
        link: widget.link,
        videoQualities: widget.videoQualities,
        isTrailer: widget.isTrailer,
        seekPosition: widget.initialPosition,
      );

    _cast.state.addListener(_onCastStateChanged);
    _cast.position.addListener(_onCastPositionChanged);
    // A TV may already be connected from a previous video. Deferred because
    // starting to cast updates notifiers other widgets are listening to,
    // which isn't allowed while the tree is still being built.
    WidgetsBinding.instance.addPostFrameCallback((_) => _onCastStateChanged());
  }

  void _onCastStateChanged() {
    if (!mounted) return;
    final wasCasting = _isCasting;
    final hadPending = _castPendingPlaying != null;
    _syncCastState();
    if (wasCasting != _isCasting ||
        hadPending != (_castPendingPlaying != null)) {
      setState(() {});
    }
  }

  void _syncCastState() {
    final state = _cast.state.value;
    switch (state.phase) {
      case CastPhase.connected:
        _castReconnectTimer?.cancel();
        _castReconnectTimer = null;
        if (!_isCasting) _startCasting();
        break;
      case CastPhase.suspended:
        if (_isCasting) {
          _castReconnectTimer ??= Timer(_castReconnectTimeout, () {
            _castReconnectTimer = null;
            if (!mounted || !_isCasting) return;
            setState(_stopCasting);
          });
        }
        break;
      case CastPhase.none:
        _castReconnectTimer?.cancel();
        _castReconnectTimer = null;
        if (_isCasting) _stopCasting();
        break;
    }

    if (!_isCasting || state.phase != CastPhase.connected) return;
    if (state.isPlaying) {
      _castWasPlaying = true;
    } else if (state.playback == CastPlayback.paused) {
      _castWasPlaying = false;
    }
    if (_castPendingPlaying != null &&
        state.hasMedia &&
        state.isPlaying == _castPendingPlaying) {
      _clearCastPending();
    }
  }

  void _onCastPositionChanged() {
    final position = _cast.position.value;
    if (!_isCasting || position <= Duration.zero) return;
    _lastCastPosition = position;
    _playerCubit.updateCastPosition(position);
  }

  void _startCasting() {
    var startAt = _playerCubit.currentPosition;
    // Nothing played locally yet: start where the screen was asked to.
    if (startAt <= Duration.zero && widget.initialPosition != null) {
      startAt = widget.initialPosition!;
    }
    _lastCastPosition = startAt;
    _castWasPlaying = true;
    _castQuality = _playerCubit.currentQuality;
    _castSpeed = 1.0;
    _isCasting = true;
    // Show "playing" while the TV is still loading the video.
    _castPendingTimer?.cancel();
    _castPendingTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => _castPendingPlaying = null);
    });
    _castPendingPlaying = true;
    _playerCubit.setCastingActive(true);
    // A TV that was left muted would otherwise play the video silently.
    if (_cast.state.value.muted) _cast.setMuted(false);
    _loadMedia(link: _playerCubit.currentLink, startPosition: startAt);
  }

  void _stopCasting() {
    _isCasting = false;
    _clearCastPending();
    _playerCubit.setCastingActive(
      false,
      resumePosition: _lastCastPosition,
      resumePlayback: _castWasPlaying,
    );
  }

  void _setCastPending(bool playing) {
    _castPendingTimer?.cancel();
    _castPendingTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => _castPendingPlaying = null);
    });
    setState(() => _castPendingPlaying = playing);
  }

  void _clearCastPending() {
    _castPendingTimer?.cancel();
    _castPendingTimer = null;
    _castPendingPlaying = null;
  }

  void _loadMedia({String? link, Duration? startPosition}) {
    final mediaLink = link ?? widget.link;
    final isHls = mediaLink.toLowerCase().contains('.m3u8');
    final mediaInfo = GoogleCastMediaInformation(
      contentId: mediaLink,
      streamType: CastMediaStreamType.buffered,
      contentType: isHls ? 'application/x-mpegurl' : 'video/mp4',
      metadata: GoogleCastMovieMediaMetadata(
        title: widget.videoTitle ?? 'Edu Gym Video',
        images: widget.thumbnailUrl != null
            ? [GoogleCastImage(url: Uri.parse(widget.thumbnailUrl!))]
            : [],
      ),
    );

    _cast.expectPosition(startPosition ?? Duration.zero);
    GoogleCastRemoteMediaClient.instance
        .loadMedia(mediaInfo, playPosition: startPosition ?? Duration.zero)
        .catchError(
            (Object e, StackTrace s) => reportCastError(e, s, 'load media failed'));
  }

  // -- Cast playback controls -----------------------------------------
  // These mirror the local PlayerCubit controls below but act on the video
  // actually playing on the TV, instead of the paused/muted local player.

  void _toggleCastPlayback() {
    final remote = GoogleCastRemoteMediaClient.instance;
    final state = _cast.state.value;
    // Nothing loaded on the receiver (or playback finished): play() is a
    // no-op there, so load the media again - from the start if it had
    // reached the end, otherwise from the last known position.
    if (!state.hasMedia) {
      _castWasPlaying = true;
      _setCastPending(true);
      _loadMedia(
        link: _castLinkForQuality(),
        startPosition: state.finished ? Duration.zero : _lastCastPosition,
      );
      return;
    }
    final isPlaying = _castPendingPlaying ?? state.isPlaying;
    _castWasPlaying = !isPlaying;
    _setCastPending(!isPlaying);
    final action = isPlaying ? remote.pause() : remote.play();
    action.catchError((Object e, StackTrace s) =>
        reportCastError(e, s, 'cast play/pause failed'));
  }

  String? _castLinkForQuality() {
    final qualities = widget.videoQualities ?? const <VideoQuality>[];
    for (final q in qualities) {
      if (q.quality == _castQuality) return q.link;
    }
    return _playerCubit.currentLink;
  }

  void _castChangeQuality(VideoQuality videoQuality) {
    if (videoQuality.quality == _castQuality) return;
    final currentPosition = _cast.position.value;
    setState(() => _castQuality = videoQuality.quality);
    _loadMedia(link: videoQuality.link, startPosition: currentPosition);
  }

  void _castChangeSpeed(double speed) {
    if (speed == _castSpeed) return;
    setState(() => _castSpeed = speed);
    GoogleCastRemoteMediaClient.instance.setPlaybackRate(speed).catchError(
        (Object e, StackTrace s) => reportCastError(e, s, 'cast speed failed'));
  }

  Widget _castControlsRow() {
    return ValueListenableBuilder<CastState>(
      valueListenable: _cast.state,
      builder: (context, state, _) {
        return _centerControls(
          isPlaying: _castPendingPlaying ?? state.isPlaying,
          onRewind: () => _cast.seekBy(const Duration(seconds: -10)),
          onPlayPause: _toggleCastPlayback,
          onForward: () => _cast.seekBy(const Duration(seconds: 10)),
        );
      },
    );
  }

  /// Big rewind / play-pause / forward buttons in the middle of the video.
  Widget _centerControls({
    required bool isPlaying,
    required VoidCallback onRewind,
    required VoidCallback onPlayPause,
    required VoidCallback onForward,
  }) {
    final bool tablet = Responsive.isTablet;
    final double skipSize = tablet ? 48 : 36;
    final double playSize = tablet ? 68 : 52;
    final double gap = tablet ? 64 : 40;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _roundButton(
            icon: Icons.replay_10, size: skipSize, padding: 10, onTap: onRewind),
        SizedBox(width: gap),
        _roundButton(
          icon: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          size: playSize,
          padding: 14,
          onTap: onPlayPause,
          emphasized: true,
        ),
        SizedBox(width: gap),
        _roundButton(
            icon: Icons.forward_10, size: skipSize, padding: 10, onTap: onForward),
      ],
    );
  }

  Widget _roundButton({
    required IconData icon,
    required double size,
    required double padding,
    required VoidCallback onTap,
    bool emphasized = false,
  }) {
    return Material(
      color: emphasized ? Colors.black54 : Colors.black38,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Icon(icon, size: size, color: Colors.white),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cast.state.removeListener(_onCastStateChanged);
    _cast.position.removeListener(_onCastPositionChanged);
    _castPendingTimer?.cancel();
    _castReconnectTimer?.cancel();
    _playerCubit.close();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PlayerCubit>.value(value: _playerCubit),
        BlocProvider(
            create: (create) => VideoOrientationCubit()
              ..changeOrientation(toLandscape: widget.alwaysLandscape)),
      ],
      child: BlocBuilder<VideoOrientationCubit, Orientation>(
        builder: (context, orientation) {
          return orientation == Orientation.landscape
              ? LandscapeVideo(
                  key: const ValueKey('landscape'),
                  player: _vPlayer(
                      iconSize: !Responsive.isTablet ? 25 : 35,
                      isLandscape: true),
                  alwaysLandscape: widget.alwaysLandscape,
                )
              : PortraitVideo(
                  key: const ValueKey('portrait'),
                  player: _vPlayer(iconSize: !Responsive.isTablet ? 25 : 35),
                  height: widget.height,
                );
        },
      ),
    );
  }

  Widget _vPlayer({required double iconSize, bool isLandscape = false}) =>
      BlocBuilder<PlayerCubit, PlayerState>(
        builder: (context, PlayerState state) {
          if (state is VideoInitialized) {
            final Widget player = GestureDetector(
              onTap: () {
                context.read<PlayerCubit>().toggleControls();
              },
              child: _player(
                context: context,
                state: state,
                iconSize: iconSize,
                isLandscape: isLandscape,
                fontSize: !Responsive.isTablet ? 14 : 18,
              ),
            );
            if (!_isBoxed(isLandscape, state)) return player;
            // Upright phone, wide video: size the whole player (video and
            // every control on top of it) to the video itself, so the
            // buttons sit on the picture instead of on the black page
            // around it. The box is away from the screen edges, so the
            // system-bar padding no longer applies to it.
            return Center(
              child: AspectRatio(
                aspectRatio: state.videoPlayerController.value.aspectRatio,
                child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  removeBottom: true,
                  removeLeft: true,
                  removeRight: true,
                  child: player,
                ),
              ),
            );
          } else if (state is VideoLoading) {
            return SizedBox(
              height: isLandscape
                  ? double.infinity
                  : widget.height ??
                      (MediaQuery.sizeOf(context).height *
                          (!Responsive.isTablet ? 0.25 : 0.55)),
              child: SafeArea(
                left: isLandscape,
                child: Stack(
                  children: [
                    if (widget.thumbnailUrl != null &&
                        widget.thumbnailUrl!.isNotEmpty)
                      Positioned.fill(
                        child: Image.network(
                          widget.thumbnailUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: Colors.black),
                        ),
                      ),
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withOpacity(0.3),
                      ),
                    ),
                    Positioned.fill(
                      top: _topInset(isLandscape),
                      left: _sideInset(isLandscape, 5, 10),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: InkWell(
                          onTap: widget.onExitIconTap ?? () => onPressBack(),
                          child: Icon(
                            Icons.close_sharp,
                            size: iconSize,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(height: 16),
                          Text(
                            'Loading video...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          } else if (state is VideoError) {
            final localizations = AppLocalizations.of(context);
            return Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        localizations?.playbackError ?? "Playback error",
                        style:
                            const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      const SizedBox(height: 5),
                      InkWell(
                        onTap: () {
                          context
                              .read<PlayerCubit>()
                              .initVideoPlayer(link: state.videoLink);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 5, horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            localizations?.retry ?? "Retry",
                            style: const TextStyle(
                                color: Colors.black, fontSize: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: InkWell(
                      onTap: widget.onExitIconTap ?? () => onPressBack(),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(
                          Icons.arrow_back_ios,
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          } else if (state is SubNotActive) {
            return _errorOverlay(
              context,
              iconSize,
              "Subscription Required",
              "Please subscribe to watch this video.",
              onRetry: () => onPressBack(),
              buttonText: "Go Back",
            );
          } else if (state is AuthRequired) {
            return _errorOverlay(
              context,
              iconSize,
              "Authentication Required",
              "Please login to watch this video.",
              onRetry: () {
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (c) => const Login()));
              },
              buttonText: "Login Now",
            );
          }
          return const SizedBox.shrink();
        },
      );

  Widget _errorOverlay(
      BuildContext context, double iconSize, String title, String message,
      {required VoidCallback onRetry, required String buttonText}) {
    return Container(
      color: Colors.black,
      height: widget.height ??
          (MediaQuery.sizeOf(context).height *
              (!Responsive.isTablet ? 0.25 : 0.55)),
      child: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline, color: Colors.white, size: 40.sp),
                  SizedBox(height: 10.h),
                  Text(title,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 5.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40.w),
                    child: Text(message,
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(color: Colors.white70, fontSize: 12.sp)),
                  ),
                  SizedBox(height: 20.h),
                  ElevatedButton(
                    onPressed: onRetry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding:
                          EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                    ),
                    child: Text(buttonText),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 10.h,
            left: 10.w,
            child: IconButton(
              icon: Icon(Icons.close, color: Colors.white, size: 24.sp),
              onPressed: () => onPressBack(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _player(
      {required BuildContext context,
      required VideoInitialized state,
      required double iconSize,
      required double fontSize,
      bool isLandscape = false}) {
    // Plain Stack (not wrapped in a GestureDetector with onScaleStart): an
    // ancestor scale-gesture recognizer competes with the seek bar's own
    // drag recognizer and was winning the gesture arena, which made the
    // progress bar impossible to scrub reliably.
    //
    // While casting the controls stay visible: the phone is the remote.
    final bool showControls = state.showControls || _isCasting;
    final Widget fullscreenButton = InkWell(
      borderRadius: BorderRadius.circular(iconSize),
      onTap: () {
        isLandscape
            ? context.read<VideoOrientationCubit>().portrait()
            : context.read<VideoOrientationCubit>().landscape();
      },
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          isLandscape ? Icons.fullscreen_exit : Icons.fullscreen,
          color: Colors.white,
          size: iconSize,
        ),
      ),
    );
    final bool isWideVideo =
        state.videoPlayerController.value.aspectRatio >= 1;
    // Corner buttons use the small insets whenever the player isn't the
    // full-height upright layout.
    final bool compact = isLandscape || _isBoxed(isLandscape, state);
    // Fill the whole screen when the video's shape matches the way the
    // phone is held (wide video in landscape, upright video in portrait);
    // the little that doesn't fit is cropped. Otherwise show all of it.
    final bool fillScreen = isLandscape
        ? isWideVideo
        : widget.height == double.infinity && !isWideVideo;
    return Stack(
      children: [
        SizedBox.expand(
          child: FittedBox(
            fit: fillScreen ? BoxFit.cover : BoxFit.contain,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: state.videoPlayerController.value.size.width,
              height: state.videoPlayerController.value.size.height,
              child: VideoPlayer(state.videoPlayerController),
            ),
          ),
        ),
        // While casting the local player is paused behind this, so cover it
        // with a plain "casting" backdrop instead of a frozen frame.
        if (_isCasting)
          Positioned.fill(
            child: Container(
              color: Colors.black,
              alignment: Alignment.center,
              child: Icon(
                Icons.cast_connected,
                size: Responsive.isTablet ? 120 : 80,
                color: Colors.white10,
              ),
            ),
          ),
        if (!_isCasting)
          ValueListenableBuilder(
            valueListenable: state.videoPlayerController,
            builder:
                (BuildContext context, VideoPlayerValue value, Widget? child) {
              if (value.isBuffering) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.white));
              }
              return const SizedBox.shrink();
            },
          ),
        IgnorePointer(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            color: showControls ? Colors.black45 : Colors.transparent,
          ),
        ),
        // Hidden controls must not swallow taps: with only opacity 0 they
        // were still hit-testable, so taps on the "empty" video landed on
        // invisible buttons / the seek bar instead of showing the controls.
        Positioned.fill(
          child: Align(
            // Dead centre of the video when upright; nudged up in the
            // full-screen layouts to stay clear of the seek bar.
            alignment:
                isLandscape ? const Alignment(0, -0.15) : Alignment.center,
            child: _fade(
              visible: showControls,
              child: _isCasting
                  ? _castControlsRow()
                  : ValueListenableBuilder<VideoPlayerValue>(
                      valueListenable: state.videoPlayerController,
                      builder: (context, value, _) => _centerControls(
                        isPlaying: value.isPlaying,
                        onRewind: () =>
                            context.read<PlayerCubit>().backwardVideo(),
                        onPlayPause: () =>
                            context.read<PlayerCubit>().toggleVideoPlay(),
                        onForward: () =>
                            context.read<PlayerCubit>().forwardVideo(),
                      ),
                    ),
            ),
          ),
        ),
        Positioned.fill(
          bottom: isLandscape ? (!Responsive.isTablet ? 24 : 36) : 0,
          left: isLandscape ? (!Responsive.isTablet ? 5 : 10) : 0,
          right: isLandscape ? (!Responsive.isTablet ? 5 : 10) : 0,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: _fade(
              visible: showControls,
              child: SafeArea(
                left: isLandscape,
                right: isLandscape,
                top: false,
                child: _isCasting
                    ? CastSeekBar(
                        label: _castingLabel(),
                        trailing: fullscreenButton,
                      )
                    : VideoSeekBar(
                        controller: state.videoPlayerController,
                        trailing: fullscreenButton,
                      ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          top: _topInset(compact),
          right: _sideInset(compact, 8, 12),
          child: Align(
            alignment: Alignment.topRight,
            child: SafeArea(
              right: isLandscape,
              left: false,
              child: _fade(
                visible: showControls,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Casting: controls the TV volume. Otherwise: the
                    // in-app player's own volume.
                    if (_isCasting)
                      CastVolumeButton(iconSize: iconSize)
                    else
                      LocalVolumeButton(
                        controller: state.videoPlayerController,
                        iconSize: iconSize,
                        getVolume: () => _playerCubit.volume,
                        onVolumeChanged: _playerCubit.setVolume,
                      ),
                    CastButton(iconSize: iconSize),
                    InkWell(
                      borderRadius: BorderRadius.circular(iconSize),
                      onTap: () {
                        _showBottomDialog(
                          context: context,
                          controller: state.videoPlayerController,
                          videoQualities: widget.videoQualities ?? [],
                          isLandscape: isLandscape,
                          isCasting: _isCasting,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.settings,
                          size: iconSize,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          top: _topInset(compact),
          left: _sideInset(compact, 5, 10),
          child: Align(
            alignment: Alignment.topLeft,
            child: SafeArea(
              left: isLandscape,
              child: _fade(
                visible: showControls,
                child: InkWell(
                  // Full screen: X goes back to the upright player.
                  // Upright: X leaves the player.
                  onTap: () {
                    context.read<PlayerCubit>().syncProgress();
                    if (isLandscape) {
                      context.read<VideoOrientationCubit>().portrait();
                    } else if (widget.onExitIconTap != null) {
                      widget.onExitIconTap!();
                    } else {
                      onPressBack();
                    }
                  },
                  child: Icon(
                    Icons.close_sharp,
                    size: iconSize,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Fades [child] in/out and makes it ignore touches while hidden.
  Widget _fade({required bool visible, required Widget child}) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: child,
      ),
    );
  }

  /// Whether the player is drawn as a video-shaped box in the middle of an
  /// upright full-height page (a wide video while the phone is upright).
  bool _isBoxed(bool isLandscape, VideoInitialized state) =>
      !isLandscape &&
      widget.height == double.infinity &&
      state.videoPlayerController.value.aspectRatio >= 1;

  // The full-height portrait layout sits under the status bar area, so its
  // corner buttons are pushed further in. Landscape relies on SafeArea.
  double _topInset(bool isLandscape) =>
      widget.height == double.infinity && !isLandscape
          ? 40.h
          : (!Responsive.isTablet ? 5 : 10);

  double _sideInset(bool isLandscape, double phone, double tablet) =>
      widget.height == double.infinity && !isLandscape
          ? 20.w
          : (!Responsive.isTablet ? phone : tablet);

  Widget _castingLabel() {
    return ValueListenableBuilder<CastState>(
      valueListenable: _cast.state,
      builder: (context, state, _) {
        final name = state.deviceName;
        final String text;
        if (state.phase == CastPhase.suspended) {
          text = 'Reconnecting to TV...';
        } else if (state.failed) {
          text = 'This video could not be played on the TV';
        } else {
          text = name == null || name.isEmpty ? 'Casting' : 'Casting to $name';
        }
        return _castingLabelText(text, warning: state.failed);
      },
    );
  }

  Widget _castingLabelText(String text, {bool warning = false}) {
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: warning ? Colors.orangeAccent : Colors.lightBlueAccent,
        fontSize: Responsive.isTablet ? 14 : 11,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  void _showBottomDialog(
      {required BuildContext context,
      required VideoPlayerController controller,
      required List<VideoQuality> videoQualities,
      bool? isLandscape,
      bool isCasting = false}) {
    // While casting, quality/speed reflect the TV playback (driven by
    // GoogleCastRemoteMediaClient), not the paused/muted local player.
    final int? effectiveQuality =
        isCasting ? _castQuality : context.read<PlayerCubit>().currentQuality;
    final double effectiveSpeed =
        isCasting ? _castSpeed : controller.value.playbackSpeed;
    final localizations = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (c) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _bottomSettingsIcon(
                  context: context,
                  settingsName: localizations?.quality ?? 'Quality',
                  settingsIcon: Icons.high_quality_outlined,
                  value: effectiveQuality == VideoQuality.auto ||
                          effectiveQuality == null
                      ? localizations?.auto ?? 'Auto'
                      : '${effectiveQuality}p',
                  onTap: () {
                    _videoQualityDialog(
                      context: context,
                      controller: controller,
                      videoQualities: videoQualities,
                      currentQuality: effectiveQuality ?? VideoQuality.auto,
                      isLandscape: isLandscape,
                      isCasting: isCasting,
                    );
                  },
                  isLandscape: isLandscape,
                ),
                _bottomSettingsIcon(
                  context: context,
                  settingsName:
                      localizations?.playbackSpeed ?? 'Playback speed',
                  settingsIcon: Icons.speed,
                  value: '$effectiveSpeed',
                  onTap: () {
                    _playBackDialog(
                        context: context,
                        controller: controller,
                        isLandscape: isLandscape,
                        isCasting: isCasting);
                  },
                  isLandscape: isLandscape,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _bottomSettingsIcon(
      {required BuildContext context,
      required String settingsName,
      required IconData settingsIcon,
      required String value,
      required VoidCallback onTap,
      bool? isLandscape}) {
    final double iconSize = !Responsive.isTablet ? 25 : 35;
    final double fontSize = !Responsive.isTablet ? 15 : 20;
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: isLandscape == true ? 12 : 8),
        child: Row(
          children: [
            Icon(settingsIcon, size: iconSize),
            const SizedBox(width: 20),
            Text(
              settingsName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: fontSize,
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: fontSize,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: iconSize / 2),
          ],
        ),
      ),
    );
  }

  void _videoQualityDialog(
      {required BuildContext context,
      required VideoPlayerController controller,
      required List<VideoQuality> videoQualities,
      required int currentQuality,
      bool? isLandscape,
      bool isCasting = false}) {
    final double fontSize = !Responsive.isTablet ? 15 : 20;
    final double iconSize = fontSize;
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (c) {
        return SafeArea(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: videoQualities
                    .map((videoQuality) => InkWell(
                          onTap: () {
                            isCasting
                                ? _castChangeQuality(videoQuality)
                                : context
                                    .read<PlayerCubit>()
                                    .changeQuality(videoQuality);
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                Opacity(
                                  opacity:
                                      videoQuality.quality == currentQuality
                                          ? 1
                                          : 0,
                                  child: Icon(Icons.check, size: iconSize),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                    videoQuality.quality == 0
                                        ? localizations?.auto ?? 'Auto'
                                        : '${videoQuality.quality}p',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    )),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  void _playBackDialog(
      {required BuildContext context,
      required VideoPlayerController controller,
      bool? isLandscape,
      bool isCasting = false}) {
    final double fontSize = !Responsive.isTablet ? 15 : 20;
    final double iconSize = fontSize;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (c) {
        return SafeArea(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [0.25, 0.5, 1.0, 1.25, 1.5, 2.0]
                    .map((e) => InkWell(
                          onTap: () {
                            isCasting
                                ? _castChangeSpeed(e)
                                : context.read<PlayerCubit>().changeSpeed(e);
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              children: [
                                Opacity(
                                  opacity: e ==
                                          (isCasting
                                              ? _castSpeed
                                              : controller.value.playbackSpeed)
                                      ? 1
                                      : 0,
                                  child: Icon(Icons.check, size: iconSize),
                                ),
                                const SizedBox(width: 10),
                                Text('$e',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurface,
                                    )),
                              ],
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  void onPressBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
}
