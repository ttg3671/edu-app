import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chrome_cast/flutter_chrome_cast.dart';

import 'cast_error_reporter.dart';

/// Where the cast session is at.
enum CastPhase {
  /// No TV connected.
  none,

  /// Connected to a TV.
  connected,

  /// The connection dropped and the Cast SDK is trying to get it back.
  suspended,
}

/// What the TV's player is doing.
enum CastPlayback { none, idle, playing, paused, buffering }

@immutable
class CastState {
  final CastPhase phase;
  final String? deviceName;
  final CastPlayback playback;

  /// The TV reached the end of the video.
  final bool finished;

  /// The TV could not play the video.
  final bool failed;
  final Duration duration;

  /// TV volume, 0..1.
  final double volume;
  final bool muted;

  const CastState({
    this.phase = CastPhase.none,
    this.deviceName,
    this.playback = CastPlayback.none,
    this.finished = false,
    this.failed = false,
    this.duration = Duration.zero,
    this.volume = 1.0,
    this.muted = false,
  });

  bool get isPlaying =>
      playback == CastPlayback.playing || playback == CastPlayback.buffering;

  /// Whether the TV currently has a video loaded that play/pause can act on.
  bool get hasMedia =>
      playback != CastPlayback.none && playback != CastPlayback.idle;

  CastState copyWith({
    CastPhase? phase,
    String? deviceName,
    CastPlayback? playback,
    bool? finished,
    bool? failed,
    Duration? duration,
    double? volume,
    bool? muted,
  }) {
    return CastState(
      phase: phase ?? this.phase,
      deviceName: deviceName ?? this.deviceName,
      playback: playback ?? this.playback,
      finished: finished ?? this.finished,
      failed: failed ?? this.failed,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      muted: muted ?? this.muted,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CastState &&
      other.phase == phase &&
      other.deviceName == deviceName &&
      other.playback == playback &&
      other.finished == finished &&
      other.failed == failed &&
      other.duration == duration &&
      other.volume == volume &&
      other.muted == muted;

  @override
  int get hashCode => Object.hash(
      phase, deviceName, playback, finished, failed, duration, volume, muted);
}

/// Single source of truth for what the TV is doing while casting.
///
/// On Android the values come straight from the Cast SDK through
/// `CastBridge.kt`: the flutter_chrome_cast status stream silently drops every
/// media status it cannot parse (HLS streams) and never reports TV volume
/// changes, which left play/pause, the seek bar and the volume icon stuck.
/// Elsewhere it falls back to the plugin's own streams.
///
/// Commands (load, play, pause) still go through the plugin; seeking and
/// volume go through here so the UI can update immediately.
class CastBridge {
  CastBridge._();

  static final CastBridge instance = CastBridge._();

  static const _channel = MethodChannel('com.edugarciamovimiento/cast');

  final ValueNotifier<CastState> state = ValueNotifier(const CastState());

  /// TV playback position. Kept apart from [state] because it ticks twice a
  /// second.
  final ValueNotifier<Duration> position = ValueNotifier(Duration.zero);

  bool _native = false;
  bool _initialized = false;

  // After a seek the TV keeps reporting the old position for a moment; ignore
  // those so the seek bar doesn't jump back.
  DateTime? _seekHoldUntil;

  // Volume to restore on un-mute where there is no real mute (plugin fallback).
  double _lastAudibleVolume = 0.5;

  /// Call once at start-up, after the Cast context has been initialised.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    if (Platform.isAndroid) {
      _channel.setMethodCallHandler(_onNativeCall);
      try {
        _applySnapshot(await _channel.invokeMethod('init'));
        _native = true;
        return;
      } catch (e, s) {
        reportCastError(e, s, 'cast bridge init failed');
        _channel.setMethodCallHandler(null);
      }
    }
    _listenToPlugin();
  }

  /// Re-reads the state from the Cast SDK.
  Future<void> refresh() async {
    if (!_native) return;
    try {
      _applySnapshot(await _channel.invokeMethod('getState'));
    } catch (e, s) {
      reportCastError(e, s, 'cast bridge refresh failed');
    }
  }

  /// Call when a video is (re)loaded on the TV at [start]. Until the TV has
  /// switched over it keeps reporting the previous video's position, which
  /// must not be mistaken for progress in the new one.
  void expectPosition(Duration start) {
    _seekHoldUntil = DateTime.now().add(const Duration(seconds: 3));
    position.value = start;
  }

  Future<void> seekTo(Duration target) async {
    final duration = state.value.duration;
    if (target < Duration.zero) target = Duration.zero;
    if (duration > Duration.zero && target > duration) target = duration;
    _seekHoldUntil = DateTime.now().add(const Duration(milliseconds: 1500));
    position.value = target;
    try {
      await GoogleCastRemoteMediaClient.instance.seek(GoogleCastMediaSeekOption(
        position: target,
        // Keep the TV's play/pause state; the default (`play`) resumed a
        // paused video.
        resumeState: GoogleCastMediaResumeState.unchanged,
      ));
    } catch (e, s) {
      reportCastError(e, s, 'cast seek failed');
    }
  }

  /// Seeks relative to the current position. The plugin's own `relative`
  /// flag is ignored on Android, so the absolute target is computed here.
  Future<void> seekBy(Duration delta) => seekTo(position.value + delta);

  Future<void> setVolume(double volume) async {
    final v = volume.clamp(0.0, 1.0).toDouble();
    final wasMuted = state.value.muted;
    if (v > 0) _lastAudibleVolume = v;
    state.value = state.value.copyWith(volume: v, muted: v > 0 ? false : null);
    try {
      if (_native) {
        if (wasMuted && v > 0) await _channel.invokeMethod('setMuted', false);
        await _channel.invokeMethod('setVolume', v);
      } else {
        GoogleCastSessionManager.instance.setDeviceVolume(v);
      }
    } catch (e, s) {
      reportCastError(e, s, 'cast volume failed');
    }
  }

  Future<void> setMuted(bool muted) async {
    final current = state.value;
    try {
      if (_native) {
        state.value = current.copyWith(muted: muted);
        await _channel.invokeMethod('setMuted', muted);
      } else {
        if (muted && current.volume > 0) _lastAudibleVolume = current.volume;
        final v = muted ? 0.0 : _lastAudibleVolume;
        state.value = current.copyWith(volume: v, muted: false);
        GoogleCastSessionManager.instance.setDeviceVolume(v);
      }
    } catch (e, s) {
      reportCastError(e, s, 'cast mute failed');
    }
  }

  // -- Android: state pushed by CastBridge.kt ---------------------------

  Future<void> _onNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'onState':
        _applySnapshot(call.arguments);
        break;
      case 'onProgress':
        final map = Map<String, dynamic>.from(call.arguments as Map);
        _applyProgress(
          positionMs: (map['positionMs'] as num?)?.toInt() ?? 0,
          durationMs: (map['durationMs'] as num?)?.toInt() ?? 0,
        );
        break;
    }
  }

  void _applySnapshot(dynamic raw) {
    if (raw is! Map) return;
    final map = Map<String, dynamic>.from(raw);
    final phase = switch (map['phase']) {
      'connected' => CastPhase.connected,
      'suspended' => CastPhase.suspended,
      _ => CastPhase.none,
    };
    // MediaStatus.PLAYER_STATE_* / IDLE_REASON_* from the Cast SDK.
    final playback = switch ((map['playerState'] as num?)?.toInt() ?? 0) {
      1 => CastPlayback.idle,
      2 => CastPlayback.playing,
      3 => CastPlayback.paused,
      4 || 5 => CastPlayback.buffering,
      _ => CastPlayback.none,
    };
    final idleReason = (map['idleReason'] as num?)?.toInt() ?? 0;
    final idle = playback == CastPlayback.idle;
    final durationMs = (map['durationMs'] as num?)?.toInt() ?? 0;
    final previous = state.value;
    final hasVolume = map['hasVolume'] == true;

    state.value = CastState(
      phase: phase,
      deviceName: map['deviceName'] as String?,
      playback: playback,
      finished: idle && idleReason == 1,
      failed: idle && idleReason == 4,
      // The duration is briefly unknown between videos; keep the last one
      // while still connected so the seek bar doesn't collapse.
      duration: durationMs > 0
          ? Duration(milliseconds: durationMs)
          : (phase == CastPhase.none || idle ? Duration.zero : previous.duration),
      volume: hasVolume
          ? ((map['volume'] as num?)?.toDouble() ?? previous.volume)
              .clamp(0.0, 1.0)
              .toDouble()
          : previous.volume,
      muted: hasVolume ? map['muted'] == true : previous.muted,
    );
    _applyProgress(
      positionMs: (map['positionMs'] as num?)?.toInt() ?? 0,
      durationMs: 0,
    );
  }

  void _applyProgress({required int positionMs, required int durationMs}) {
    if (durationMs > 0 &&
        state.value.duration.inMilliseconds != durationMs &&
        state.value.phase != CastPhase.none) {
      state.value =
          state.value.copyWith(duration: Duration(milliseconds: durationMs));
    }
    final hold = _seekHoldUntil;
    if (hold != null) {
      if (DateTime.now().isBefore(hold)) return;
      _seekHoldUntil = null;
    }
    if (positionMs > 0) position.value = Duration(milliseconds: positionMs);
  }

  // -- Fallback: the plugin's own streams --------------------------------

  void _listenToPlugin() {
    GoogleCastSessionManager.instance.currentSessionStream.listen((session) {
      final connected =
          session?.connectionState == GoogleCastConnectState.connected;
      if (!connected) {
        state.value = const CastState();
        return;
      }
      state.value = state.value.copyWith(
        phase: CastPhase.connected,
        deviceName: session?.device?.friendlyName,
        volume: session?.currentDeviceVolume.clamp(0.0, 1.0).toDouble(),
        muted: session?.currentDeviceMuted,
      );
    }, onError: (Object e, StackTrace s) {
      reportCastError(e, s, 'session stream error');
    });

    final remote = GoogleCastRemoteMediaClient.instance;
    remote.mediaStatusStream.listen((status) {
      if (status == null) return;
      final playback = switch (status.playerState) {
        CastMediaPlayerState.idle => CastPlayback.idle,
        CastMediaPlayerState.playing => CastPlayback.playing,
        CastMediaPlayerState.paused => CastPlayback.paused,
        CastMediaPlayerState.buffering ||
        CastMediaPlayerState.loading =>
          CastPlayback.buffering,
        CastMediaPlayerState.unknown => CastPlayback.none,
      };
      final idle = playback == CastPlayback.idle;
      state.value = state.value.copyWith(
        playback: playback,
        finished: idle && status.idleReason == GoogleCastMediaIdleReason.finished,
        failed: idle && status.idleReason == GoogleCastMediaIdleReason.error,
        duration: status.mediaInformation?.duration,
      );
    }, onError: (Object e, StackTrace s) {
      reportCastError(e, s, 'media status stream error');
    });
    remote.playerPositionStream.listen((p) {
      _applyProgress(positionMs: p.inMilliseconds, durationMs: 0);
    });
  }
}
