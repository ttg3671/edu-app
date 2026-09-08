import 'package:edu_gym/features/module/presentation/screens/module_lessons_screen.dart';
import 'package:edu_gym/features/quality_player/src/quality_player.dart';
import 'package:edu_gym/features/quality_player/cubit/player_cubit.dart';
import 'package:edu_gym/modal/lesson.dart';
import 'package:flutter/material.dart';

class VerticalVideoPlayerScreen extends StatelessWidget {
  final String videoUrl;
  final String lessonTitle;
  final List<VideoFile>? videoFiles;
  final String? thumbnailUrl;
  final dynamic videoProviderId; // Track continue watching progress
  final int? totalDuration; // Total duration in seconds from video API
  final int? moduleId; // Module ID for back navigation
  final Duration? initialPosition; // Resume position

  const VerticalVideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.lessonTitle,
    this.videoFiles,
    this.thumbnailUrl,
    this.videoProviderId,
    this.totalDuration,
    this.moduleId,
    this.initialPosition,
  });

  void _handleExit(BuildContext context) {
    if (moduleId != null && moduleId! > 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ModuleLessonsScreen(
            moduleId: moduleId!,
            moduleTitle: lessonTitle,
          ),
        ),
      );
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Convert VideoFile list to VideoQuality list
    List<VideoQuality>? qualities;
    if (videoFiles != null && videoFiles!.isNotEmpty) {
      qualities = videoFiles!.map((videoFile) {
        int qualityValue;
        if (videoFile.quality.toLowerCase() == 'hls') {
          qualityValue = VideoQuality.auto;
        } else {
          qualityValue = int.tryParse(videoFile.quality) ?? 720;
        }

        return VideoQuality(
          quality: qualityValue,
          link: videoFile.link,
        );
      }).toList();

      qualities.sort((a, b) => b.quality.compareTo(a.quality));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: QualityPlayer(
          link: videoUrl,
          videoQualities: qualities,
          thumbnailUrl: thumbnailUrl,
          alwaysLandscape: false, // For vertical videos
          height: double.infinity, // Full screen height
          videoProviderId: videoProviderId,
          totalDuration: totalDuration,
          initialPosition: initialPosition,
          onExitIconTap: () => _handleExit(context),
        ),
      ),
    );
  }
}
