import 'package:edu_gym/features/quality_player/src/quality_player.dart';
import 'package:edu_gym/features/quality_player/cubit/player_cubit.dart';
import 'package:edu_gym/modal/lesson.dart';
import 'package:flutter/material.dart';

class LandscapeVideoPlayerScreen extends StatelessWidget {
  final String videoUrl;
  final String lessonTitle;
  final List<VideoFile>? videoFiles;
  final String? thumbnailUrl; // NEW: Thumbnail for loading state

  const LandscapeVideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.lessonTitle,
    this.videoFiles,
    this.thumbnailUrl,
  });

  @override
  Widget build(BuildContext context) {
    print('🎬 LandscapeVideoPlayerScreen build');
    print('📹 Video URL: $videoUrl');
    print('📦 Video Files count: ${videoFiles?.length ?? 0}');

    // Convert VideoFile list to VideoQuality list
    List<VideoQuality>? qualities;
    if (videoFiles != null && videoFiles!.isNotEmpty) {
      print('🎥 Converting ${videoFiles!.length} video files to qualities...');
      qualities = videoFiles!.map((videoFile) {
        // Parse quality string to int (e.g., "1080" -> 1080, "hls" -> 0 for auto)
        int qualityValue;
        if (videoFile.quality.toLowerCase() == 'hls') {
          qualityValue = VideoQuality.auto; // Use auto for HLS
        } else {
          qualityValue = int.tryParse(videoFile.quality) ?? 720;
        }

        print('  📊 Quality: ${videoFile.quality} ($qualityValue) - Link: ${videoFile.link.substring(0, 50)}...');

        return VideoQuality(
          quality: qualityValue,
          link: videoFile.link,
        );
      }).toList();

      // Sort by quality (highest first)
      qualities.sort((a, b) => b.quality.compareTo(a.quality));
      print('✅ Converted to ${qualities.length} VideoQuality objects');
    } else {
      print('⚠️ No video files provided, using default video URL');
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: QualityPlayer(
          link: videoUrl,
          videoQualities: qualities, // Pass video qualities
          thumbnailUrl: thumbnailUrl, // Pass thumbnail for loading state
          alwaysLandscape: true,
          onExitIconTap: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
      ),
    );
  }
}
