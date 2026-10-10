import 'dart:async';
import 'package:edu_gym/api/api.dart';
import 'package:edu_gym/api/token_api.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:edu_gym/features/quality_player/cubit/player_state.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class PlayerCubit extends Cubit<PlayerState> {
  final dynamic videoProviderId;
  final int? totalDuration;
  // Freemium videos can be watched without logging in.
  final bool allowGuest;
  PlayerCubit(
      {this.videoProviderId, this.totalDuration, this.allowGuest = false})
      : super(VideoInitial());

  VideoPlayerController? _controller;
  bool _showControls = false;
  bool _isControlChecking = false;
  int? _currentQuality;
  Timer? _progressSyncTimer;
  int _lastKnownPositionSec = 0;
  int _lastKnownDurationSec = 0;
  // True while a Cast receiver is playing the video. The local controller
  // stays paused/muted and must not auto-play on (re)initialization.
  bool _castingActive = false;
  String? _currentLink;
  List<VideoQuality>? _videoQualities;
  // User-chosen volume for the in-app player (0..1). Re-applied after a
  // quality switch recreates the controller and when casting ends.
  double _volume = 1.0;

  Future<void> loadVideo({
    String? link,
    String? trailerId,
    required bool? isTrailer,
  }) async {
    WakelockPlus.enable();
    emit(VideoLoading());

    initVideoPlayer(link: link!, isTrailer: isTrailer ?? false);
  }

  Future<void> initVideoPlayer(
      {required String link,
      int? quality,
      List<VideoQuality>? videoQualities,
      Duration? seekPosition,
      bool isTrailer = false}) async {
    // print('🎬 PlayerCubit: initVideoPlayer called');

    // 1. Check if user is logged in
    if (!allowGuest && !TokenApi.isUserLoggedIn()) {
      emit(AuthRequired());
      return;
    }

    _currentLink = link;
    _videoQualities = videoQualities ?? _videoQualities;
    if (!_castingActive) enableWakeLock();
    emit(VideoLoading());
    try {
      _progressSyncTimer?.cancel();
      if (_controller != null) {
        _controller!.dispose();
        _controller = null;
      }
    } catch (e) {
      // print('❌ Error disposing old controller: $e');
    }

    if (totalDuration != null && totalDuration! > 0) {
      _lastKnownDurationSec = totalDuration!;
    }

    // print('🔄 Creating VideoPlayerController with URL: ${link.substring(0, 50)}...');
    _controller = VideoPlayerController.networkUrl(Uri.parse(link))
      ..initialize().then((_) {
        // print('✅ Video initialized successfully');
        if (!isClosed) {
          if (seekPosition != null) {
            _controller!.seekTo(seekPosition);
            _lastKnownPositionSec = seekPosition.inSeconds;
          }
          if (_castingActive) {
            _controller!.setVolume(0);
          } else {
            _controller!.setVolume(_volume);
            _controller!.play();
          }
          _showControls = false;

          if (_lastKnownDurationSec <= 0 &&
              _controller!.value.duration.inSeconds > 0) {
            _lastKnownDurationSec = _controller!.value.duration.inSeconds;
          }

          // Start periodic continue-watching sync while active
          _startProgressSync();

          // print('📺 Emitting VideoInitialized state with ${videoQualities?.length ?? 0} qualities');
          _emitInitialized();
        }
      }, onError: (error) {
        // print('❌ Video initialization error: $error');
        if (!isClosed) {
          emit(VideoError(link));
        }
      });
    _controller!.addListener(() async {
      if (_controller != null &&
          _controller!.value.isInitialized &&
          !_castingActive) {
        _lastKnownPositionSec = _controller!.value.position.inSeconds;
        if (_lastKnownDurationSec <= 0 &&
            _controller!.value.duration.inSeconds > 0) {
          _lastKnownDurationSec =
              totalDuration ?? _controller!.value.duration.inSeconds;
        }
      }

      if (_controller != null &&
          _controller!.value.isPlaying &&
          _showControls &&
          !_isControlChecking) {
        _isControlChecking = true;
        await Future.delayed(const Duration(seconds: 3));
        _isControlChecking = false;
        if (_controller != null &&
            _controller!.value.isPlaying &&
            _showControls &&
            !isClosed) {
          _showControls = !_showControls;
          _emitInitialized();
        }
      }
    });
  }

  void _emitInitialized() {
    if (isClosed || !_isReady) return;
    emit(VideoInitialized(
        videoPlayerController: _controller!,
        showControls: _showControls,
        videoQualities: _videoQualities,
        currentQuality: _currentQuality));
  }

  bool get _isReady => _controller != null && _controller!.value.isInitialized;

  void _startProgressSync() {
    _progressSyncTimer?.cancel();
    if (videoProviderId != null) {
      // print('⏱️ [CW TABLE] Starting sync timer for videoProviderId: $videoProviderId, duration: ${totalDuration ?? _lastKnownDurationSec}s');
      // Sync early progress after 2 seconds of playback
      Future.delayed(const Duration(seconds: 2), () {
        if (!isClosed && _controller != null && _controller!.value.isPlaying) {
          syncProgress();
        }
      });

      // While casting the local controller is paused, so keep syncing using
      // the receiver position reported via [updateCastPosition].
      _progressSyncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!isClosed &&
            (_castingActive ||
                (_controller != null && _controller!.value.isPlaying))) {
          syncProgress();
        }
      });
    }
  }

  void syncProgress() {
    if (videoProviderId == null) return;

    int posSec = _lastKnownPositionSec;
    int durSec = totalDuration ?? _lastKnownDurationSec;

    if (_controller != null && _controller!.value.isInitialized) {
      if (!_castingActive) {
        posSec = _controller!.value.position.inSeconds;
        _lastKnownPositionSec = posSec;
      }
      if (durSec <= 0 && _controller!.value.duration.inSeconds > 0) {
        durSec = _controller!.value.duration.inSeconds;
        _lastKnownDurationSec = durSec;
      }
    }

    if (durSec <= 0 || posSec < 0) return;

    final parsedProviderId =
        int.tryParse(videoProviderId.toString()) ?? videoProviderId;
    // print('⏱️ [CW TABLE - SYNC PROGRESS] video_provider_id: $parsedProviderId, last_position_ms: $posSec, total_duration_ms: $durSec');

    Api.instance.updateContinueWatching(
      videoProviderId: parsedProviderId,
      lastPositionMs: posSec,
      totalDurationMs: durSec,
    );
  }

  void toggleControls() {
    if (_controller == null) return;
    _showControls = !_showControls;
    _emitInitialized();
  }

  void toggleVideoPlay() {
    if (!_isReady || _castingActive) return;
    if (_controller!.value.isPlaying) {
      _controller!.pause();
      disableWakeLock();
      syncProgress();
    } else {
      _controller!.play();
      enableWakeLock();
    }

    _emitInitialized();
  }

  void forwardVideo() {
    if (!_isReady || _castingActive) return;
    seekTo(_controller!.value.position + const Duration(seconds: 10));
  }

  void disposePlayer() {
    _progressSyncTimer?.cancel();
    syncProgress();
    if (_controller != null) {
      _controller!.dispose();
      _controller = null;
    }
  }

  void backwardVideo() {
    if (!_isReady || _castingActive) return;
    seekTo(_controller!.value.position - const Duration(seconds: 10));
  }

  void seekTo(Duration position) {
    if (!_isReady) return;
    final duration = _controller!.value.duration;
    var target = position;
    if (target < Duration.zero) target = Duration.zero;
    if (duration > Duration.zero && target > duration) target = duration;
    _controller!.seekTo(target);
    _lastKnownPositionSec = target.inSeconds;
    syncProgress();
  }

  void changeSpeed(double speed) {
    if (!_isReady || speed == _controller!.value.playbackSpeed) return;
    _controller!.setPlaybackSpeed(speed);
    _emitInitialized();
  }

  Future<void> changeQuality(VideoQuality videoQuality) async {
    if (!_isReady || videoQuality.quality == _currentQuality) return;
    _currentQuality = videoQuality.quality;
    final currentPosition = _controller!.value.position;
    initVideoPlayer(
        link: videoQuality.link,
        quality: videoQuality.quality,
        seekPosition: currentPosition);
  }

  int? get currentQuality => _currentQuality;

  double get volume => _volume;

  /// Sets the in-app player volume (0 = muted, 1 = full). While casting the
  /// local player stays muted; the value is applied once casting ends.
  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    if (_isReady && !_castingActive) {
      _controller!.setVolume(_volume);
    }
  }

  /// Link currently loaded in the local player (reflects quality changes).
  String? get currentLink => _currentLink;

  /// Where local playback currently is; used as the start point when a cast
  /// session begins so the TV continues from the same spot.
  Duration get currentPosition => _isReady
      ? _controller!.value.position
      : Duration(seconds: _lastKnownPositionSec);

  bool get isCastingActive => _castingActive;

  /// Receiver position while casting, so continue-watching keeps syncing.
  void updateCastPosition(Duration position) {
    if (_castingActive && position > Duration.zero) {
      _lastKnownPositionSec = position.inSeconds;
    }
  }

  /// Called when a Cast session connects/disconnects. While casting, the TV
  /// plays the video, so the local player is paused and muted. Playback on
  /// the TV is driven by [GoogleCastRemoteMediaClient] from the UI layer.
  ///
  /// On disconnect, the local player jumps to [resumePosition] (where the TV
  /// left off) and resumes if [resumePlayback] is true, so it behaves exactly
  /// like it did before casting.
  void setCastingActive(bool active,
      {Duration? resumePosition, bool resumePlayback = true}) {
    if (_castingActive == active) return;
    _castingActive = active;
    if (active) {
      if (_controller != null) {
        _lastKnownPositionSec = currentPosition.inSeconds;
        _controller!.pause();
        _controller!.setVolume(0);
      }
      disableWakeLock();
      _showControls = true;
      _emitInitialized();
      return;
    }

    // Still loading: initVideoPlayer starts playback itself once it's ready.
    if (!_isReady) return;
    _showControls = true;
    _emitInitialized();
    _resumeLocalPlayback(resumePosition, resumePlayback);
  }

  // The local player has been sitting paused for the whole cast session, so
  // wait for the seek to land before playing, and rebuild the player if it
  // didn't survive - otherwise the app could be left on a frozen frame.
  Future<void> _resumeLocalPlayback(Duration? position, bool play) async {
    final controller = _controller!;
    final target =
        position != null && position > Duration.zero ? position : null;
    try {
      await controller.setVolume(_volume);
      if (target != null) {
        final duration = controller.value.duration;
        final clamped =
            duration > Duration.zero && target > duration ? duration : target;
        await controller.seekTo(clamped);
        _lastKnownPositionSec = clamped.inSeconds;
      }
      // Casting started again, or the player was replaced, while seeking.
      if (isClosed || _castingActive || controller != _controller) return;
      if (controller.value.hasError) {
        throw StateError(controller.value.errorDescription ?? 'player error');
      }
      if (play) {
        await controller.play();
        enableWakeLock();
      }
      syncProgress();
      _emitInitialized();
    } catch (_) {
      if (isClosed || _castingActive || controller != _controller) return;
      final link = _currentLink;
      if (link != null) initVideoPlayer(link: link, seekPosition: target);
    }
  }

  Future<void> enableWakeLock() async {
    if (!await WakelockPlus.enabled) {
      await WakelockPlus.enable();
    }
  }

  Future<void> disableWakeLock() async {
    if (await WakelockPlus.enabled) {
      await WakelockPlus.disable();
    }
  }

  @override
  Future<void> close() {
    _progressSyncTimer?.cancel();
    syncProgress();
    disableWakeLock();
    disposePlayer();
    return super.close();
  }
}

class VideoOrientationCubit extends Cubit<Orientation> {
  VideoOrientationCubit() : super(Orientation.portrait);

  void landscape() {
    if (!isClosed) {
      emit(Orientation.landscape);
    }
  }

  void portrait() {
    if (!isClosed) {
      emit(Orientation.portrait);
    }
  }

  void changeOrientation({bool toLandscape = false}) {
    if (toLandscape) {
      emit(Orientation.landscape);
    }
  }
}

class VideoQuality {
  final int quality;
  final String link;
  static const int auto = 0;

  VideoQuality({
    required this.quality,
    required this.link,
  });
}
