import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

import '../../../responsive.dart';
import '../cubit/player_cubit.dart';
import 'cast_bridge.dart';
import '../utils/utils.dart';

/// A drag-friendly seek bar. Unlike the bare [VideoProgressIndicator], this
/// gives the thumb a large enough hit target to grab reliably, and only
/// commits the seek once the user lifts their finger - so dragging feels
/// smooth instead of stuttering on every pixel of movement.
///
/// The "position / duration" text sits on a row above the bar (with optional
/// [label] and [trailing] widgets) so the bar itself spans the full width.
class VideoSeekBar extends StatefulWidget {
  final VideoPlayerController controller;
  final Color activeColor;
  final Color inactiveColor;
  final Widget? label;
  final Widget? trailing;

  const VideoSeekBar({
    super.key,
    required this.controller,
    this.activeColor = Colors.white,
    this.inactiveColor = Colors.white30,
    this.label,
    this.trailing,
  });

  @override
  State<VideoSeekBar> createState() => _VideoSeekBarState();
}

class _VideoSeekBarState extends State<VideoSeekBar> {
  double? _dragValueMs;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: widget.controller,
      builder: (context, value, child) {
        final durationMs = value.duration.inMilliseconds.toDouble();
        final hasDuration = durationMs > 0;
        final sliderMax = hasDuration ? durationMs : 1.0;
        final double positionMs =
            (_dragValueMs ?? value.position.inMilliseconds.toDouble())
                .clamp(0.0, sliderMax);

        return _SeekBarLayout(
          position: Duration(milliseconds: positionMs.round()),
          duration: value.duration,
          sliderMax: sliderMax,
          sliderValue: positionMs,
          activeColor: widget.activeColor,
          inactiveColor: widget.inactiveColor,
          label: widget.label,
          trailing: widget.trailing,
          onChanged: hasDuration
              ? (v) {
                  setState(() {
                    _dragValueMs = v;
                  });
                }
              : null,
          onChangeEnd: hasDuration
              ? (v) {
                  context
                      .read<PlayerCubit>()
                      .seekTo(Duration(milliseconds: v.round()));
                  setState(() {
                    _dragValueMs = null;
                  });
                }
              : null,
        );
      },
    );
  }
}

/// Same drag-friendly seek bar as [VideoSeekBar], but for when playback is
/// happening on a cast receiver instead of the local player: position,
/// duration and the seek itself all go through [CastBridge]
/// so dragging this bar actually moves the video on the TV.
class CastSeekBar extends StatefulWidget {
  final Color activeColor;
  final Color inactiveColor;
  final Widget? label;
  final Widget? trailing;

  const CastSeekBar({
    super.key,
    this.activeColor = Colors.white,
    this.inactiveColor = Colors.white30,
    this.label,
    this.trailing,
  });

  @override
  State<CastSeekBar> createState() => _CastSeekBarState();
}

class _CastSeekBarState extends State<CastSeekBar> {
  double? _dragValueMs;

  @override
  Widget build(BuildContext context) {
    final cast = CastBridge.instance;
    return ValueListenableBuilder<CastState>(
      valueListenable: cast.state,
      builder: (context, state, _) {
        return ValueListenableBuilder<Duration>(
          valueListenable: cast.position,
          builder: (context, position, _) {
            final duration = state.duration;
            final durationMs = duration.inMilliseconds.toDouble();
            final hasDuration = durationMs > 0;
            final sliderMax = hasDuration ? durationMs : 1.0;
            final double positionMs =
                (_dragValueMs ?? position.inMilliseconds.toDouble())
                    .clamp(0.0, sliderMax);

            return _SeekBarLayout(
              position: Duration(milliseconds: positionMs.round()),
              duration: duration,
              sliderMax: sliderMax,
              sliderValue: positionMs,
              activeColor: widget.activeColor,
              inactiveColor: widget.inactiveColor,
              label: widget.label,
              trailing: widget.trailing,
              onChanged: hasDuration
                  ? (v) {
                      setState(() {
                        _dragValueMs = v;
                      });
                    }
                  : null,
              onChangeEnd: hasDuration
                  ? (v) {
                      cast.seekTo(Duration(milliseconds: v.round()));
                      setState(() {
                        _dragValueMs = null;
                      });
                    }
                  : null,
            );
          },
        );
      },
    );
  }
}

class _SeekBarLayout extends StatelessWidget {
  final Duration position;
  final Duration duration;
  final double sliderMax;
  final double sliderValue;
  final Color activeColor;
  final Color inactiveColor;
  final Widget? label;
  final Widget? trailing;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;

  const _SeekBarLayout({
    required this.position,
    required this.duration,
    required this.sliderMax,
    required this.sliderValue,
    required this.activeColor,
    required this.inactiveColor,
    required this.onChanged,
    required this.onChangeEnd,
    this.label,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final bool tablet = Responsive.isTablet;
    final double sidePadding = tablet ? 16 : 12;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(left: sidePadding, right: sidePadding - 8),
          child: Row(
            children: [
              Text(
                '${Utils.formatDuration(position)} / '
                '${Utils.formatDuration(duration)}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: tablet ? 15 : 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (label != null) ...[
                const SizedBox(width: 10),
                Expanded(child: label!),
              ] else
                const Spacer(),
              if (trailing != null) trailing!,
            ],
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: tablet ? 6 : 5,
            thumbShape:
                RoundSliderThumbShape(enabledThumbRadius: tablet ? 10 : 8),
            overlayShape:
                RoundSliderOverlayShape(overlayRadius: tablet ? 22 : 18),
            activeTrackColor: activeColor,
            inactiveTrackColor: inactiveColor,
            thumbColor: activeColor,
            overlayColor: activeColor.withValues(alpha: 0.2),
            trackShape: const RoundedRectSliderTrackShape(),
          ),
          child: Slider(
            min: 0,
            max: sliderMax,
            value: sliderValue,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
      ],
    );
  }
}
