import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'cast_bridge.dart';

/// Volume control for the in-app (local) video player: tap the icon for a
/// popup slider; the speaker icon inside the popup toggles mute.
class LocalVolumeButton extends StatelessWidget {
  final VideoPlayerController controller;
  final double iconSize;

  /// Reads the volume the user chose (kept in the cubit so it survives
  /// controller re-creation on quality change).
  final double Function() getVolume;
  final ValueChanged<double> onVolumeChanged;

  const LocalVolumeButton({
    super.key,
    required this.controller,
    required this.getVolume,
    required this.onVolumeChanged,
    this.iconSize = 24,
  });

  static IconData _iconFor(double volume) {
    if (volume <= 0) return Icons.volume_off;
    if (volume < 0.5) return Icons.volume_down;
    return Icons.volume_up;
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<void>(
      padding: const EdgeInsets.all(8),
      tooltip: 'Volume',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: const Color(0xFF1C1C1E),
      icon: ValueListenableBuilder<VideoPlayerValue>(
        valueListenable: controller,
        builder: (context, value, _) => Icon(
          _iconFor(getVolume()),
          color: Colors.white,
          size: iconSize,
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem<void>(
          enabled: false,
          child: _VolumeSlider(
            initialVolume: getVolume(),
            onChanged: onVolumeChanged,
          ),
        ),
      ],
    );
  }
}

/// Same control as [LocalVolumeButton], but for the TV while casting. The
/// icon follows the TV's real volume / mute state, including changes made
/// with the TV remote.
class CastVolumeButton extends StatelessWidget {
  final double iconSize;

  const CastVolumeButton({super.key, this.iconSize = 24});

  @override
  Widget build(BuildContext context) {
    final cast = CastBridge.instance;
    return PopupMenuButton<void>(
      padding: const EdgeInsets.all(8),
      tooltip: 'Volume',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: const Color(0xFF1C1C1E),
      icon: ValueListenableBuilder<CastState>(
        valueListenable: cast.state,
        builder: (context, state, _) => Icon(
          LocalVolumeButton._iconFor(state.muted ? 0 : state.volume),
          color: Colors.white,
          size: iconSize,
        ),
      ),
      itemBuilder: (context) {
        final state = cast.state.value;
        return [
          PopupMenuItem<void>(
            enabled: false,
            child: _VolumeSlider(
              initialVolume: state.muted ? 0 : state.volume,
              initialAudible: state.volume > 0 ? state.volume : 0.5,
              // Sending every drag step floods the TV; update it when the
              // finger lifts (and on mute toggles).
              onChanged: (_) {},
              onChangeEnd: cast.setVolume,
              onMuteChanged: (muted, restoreTo) async {
                await cast.setMuted(muted);
                if (!muted && cast.state.value.volume <= 0) {
                  await cast.setVolume(restoreTo);
                }
              },
            ),
          ),
        ];
      },
    );
  }
}

class _VolumeSlider extends StatefulWidget {
  final double initialVolume;

  /// Level to restore when un-muting; defaults to [initialVolume].
  final double? initialAudible;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;

  /// Called instead of [onChanged] when the speaker icon is tapped, for
  /// targets that have a real mute separate from the volume level.
  final void Function(bool muted, double restoreTo)? onMuteChanged;

  const _VolumeSlider({
    required this.initialVolume,
    required this.onChanged,
    this.initialAudible,
    this.onChangeEnd,
    this.onMuteChanged,
  });

  @override
  State<_VolumeSlider> createState() => _VolumeSliderState();
}

class _VolumeSliderState extends State<_VolumeSlider> {
  late double _volume = widget.initialVolume;
  // Level to restore when un-muting from the speaker icon.
  late double _lastAudible = widget.initialAudible ??
      (widget.initialVolume > 0 ? widget.initialVolume : 1.0);

  void _set(double v) {
    setState(() {
      _volume = v;
      if (v > 0) _lastAudible = v;
    });
    widget.onChanged(v);
  }

  void _toggleMute() {
    final mute = _volume > 0;
    final onMuteChanged = widget.onMuteChanged;
    if (onMuteChanged == null) {
      _set(mute ? 0 : _lastAudible);
      return;
    }
    setState(() => _volume = mute ? 0 : _lastAudible);
    onMuteChanged(mute, _lastAudible);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _toggleMute,
          icon: Icon(
            LocalVolumeButton._iconFor(_volume),
            color: Colors.white,
          ),
        ),
        SizedBox(
          width: 160,
          child: Slider(
            value: _volume,
            onChanged: _set,
            onChangeEnd: widget.onChangeEnd,
            activeColor: Colors.lightBlueAccent,
            inactiveColor: Colors.white24,
          ),
        ),
      ],
    );
  }
}
