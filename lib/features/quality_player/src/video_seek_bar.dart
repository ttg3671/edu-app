import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

import '../cubit/player_cubit.dart';
import '../utils/utils.dart';

/// A drag-friendly seek bar. Unlike the bare [VideoProgressIndicator], this
/// gives the thumb a large enough hit target to grab reliably, and only
/// commits the seek once the user lifts their finger - so dragging feels
/// smooth instead of stuttering on every pixel of movement.
class VideoSeekBar extends StatefulWidget {
  final VideoPlayerController controller;
  final Color activeColor;
  final Color inactiveColor;

  const VideoSeekBar({
    super.key,
    required this.controller,
    this.activeColor = Colors.white,
    this.inactiveColor = Colors.white30,
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

        return Row(
          children: [
            SizedBox(
              width: 42,
              child: Text(
                Utils.formatDuration(
                    Duration(milliseconds: positionMs.round())),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6, elevation: 1),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 16),
                  activeTrackColor: widget.activeColor,
                  inactiveTrackColor: widget.inactiveColor,
                  thumbColor: widget.activeColor,
                  overlayColor: widget.activeColor.withValues(alpha: 0.2),
                ),
                child: Slider(
                  min: 0,
                  max: sliderMax,
                  value: positionMs,
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
                ),
              ),
            ),
            SizedBox(
              width: 42,
              child: Text(
                Utils.formatDuration(value.duration),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ],
        );
      },
    );
  }
}
