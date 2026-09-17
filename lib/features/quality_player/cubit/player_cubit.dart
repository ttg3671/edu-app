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
  PlayerCubit({this.videoProviderId, this.totalDuration})
      : super(VideoInitial());

  VideoPlayerController? _controller;
  bool _showControls = false;
  bool _isControlChecking = false;
  int? _currentQuality;
  Timer? _progressSyncTimer;
  int _lastKnownPositionSec = 0;
  int _lastKnownDurationSec = 0;

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
    if (!TokenApi.isUserLoggedIn()) {
      emit(AuthRequired());
      return;
    }

    enableWakeLock();
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
          _controller!.play();
          _showControls = false;

          if (_lastKnownDurationSec <= 0 &&
              _controller!.value.duration.inSeconds > 0) {
            _lastKnownDurationSec = _controller!.value.duration.inSeconds;
          }

          // Start periodic continue-watching sync while active
          _startProgressSync();

          // print('📺 Emitting VideoInitialized state with ${videoQualities?.length ?? 0} qualities');
          emit(VideoInitialized(
              videoPlayerController: _controller!,
              showControls: _showControls,
              videoQualities: videoQualities,
              currentQuality: quality));
        }
      }, onError: (error) {
        // print('❌ Video initialization error: $error');
        if (!isClosed) {
          emit(VideoError(link));
        }
      });
    _controller!.addListener(() async {
      if (_controller != null && _controller!.value.isInitialized) {
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
          emit(VideoInitialized(
              videoPlayerController: _controller!,
              showControls: _showControls,
              videoQualities: videoQualities,
              currentQuality: quality));
        }
      }
    });
  }

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

      _progressSyncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (!isClosed && _controller != null && _controller!.value.isPlaying) {
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
      posSec = _controller!.value.position.inSeconds;
      _lastKnownPositionSec = posSec;
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
    _showControls = !_showControls;
    emit(VideoInitialized(
        videoPlayerController: _controller!,
        showControls: _showControls,
        currentQuality: _currentQuality));
  }

  void toggleVideoPlay() {
    if (_controller!.value.isPlaying) {
      _controller!.pause();
      disableWakeLock();
      syncProgress();
    } else {
      _controller!.play();
      enableWakeLock();
    }

    emit(VideoInitialized(
        videoPlayerController: _controller!,
        showControls: _showControls,
        currentQuality: _currentQuality));
  }

  void forwardVideo() {
    final currentPosition = _controller!.value.position;
    final newPosition = currentPosition + const Duration(seconds: 10);
    _controller!.seekTo(newPosition);
    syncProgress();
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
    final currentPosition = _controller!.value.position;
    final newPosition = currentPosition - const Duration(seconds: 10);
    _controller!.seekTo(newPosition);
    syncProgress();
  }

  void seekTo(Duration position) {
    if (_controller == null) return;
    final duration = _controller!.value.duration;
    var target = position;
    if (target < Duration.zero) target = Duration.zero;
    if (duration > Duration.zero && target > duration) target = duration;
    _controller!.seekTo(target);
    syncProgress();
  }

  void changeSpeed(double speed) {
    if (speed == _controller!.value.playbackSpeed) return;
    _controller!.setPlaybackSpeed(speed);
    emit(VideoInitialized(
        videoPlayerController: _controller!,
        showControls: _showControls,
        currentQuality: _currentQuality));
  }

  Future<void> changeQuality(VideoQuality videoQuality) async {
    if (videoQuality.quality == _currentQuality) return;
    _currentQuality = videoQuality.quality;
    final currentPosition = _controller!.value.position;
    initVideoPlayer(
        link: videoQuality.link,
        quality: videoQuality.quality,
        seekPosition: currentPosition);
  }

  get currentQuality => _currentQuality;

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
