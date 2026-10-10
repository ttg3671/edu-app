import 'package:edu_gym/api/api.dart';
import 'package:edu_gym/core/common/widgets/loader.dart';
import 'package:edu_gym/core/utils/custom_snackbar.dart';
import 'package:edu_gym/modal/lesson.dart';
import 'package:flutter/material.dart';

import 'screens/landscape_video_player_screen.dart';
import 'screens/vertical_video_player_screen.dart';

bool _opening = false;

/// Fetches `/users/free-modules/:module_id/video` and opens the matching
/// player (vertical or landscape, from `ui_style`).
///
/// [allowGuest] lets a logged-out user play it (freemium). When logged in,
/// the video id is passed on so continue-watching progress is tracked, and
/// playback resumes from [initialPosition].
Future<void> openFreeModuleVideo(
  BuildContext context, {
  required int moduleId,
  required String title,
  String? fallbackThumbnail,
  Duration? initialPosition,
  bool allowGuest = false,
  bool trackProgress = false,
}) async {
  if (_opening) return;
  _opening = true;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: Loader()),
  );
  final result = await Api.instance.getFreeModuleVideo(moduleId: moduleId);
  _opening = false;
  if (!context.mounted) return;
  Navigator.pop(context); // loader

  Map<String, dynamic>? data;
  String? error;
  result.fold((f) => error = f.message, (d) => data = d);

  final List<VideoFile> files = (data?['files'] as List? ?? const [])
      .whereType<Map>()
      .map((f) => VideoFile.fromJson(Map<String, dynamic>.from(f)))
      .where((f) => f.link.isNotEmpty)
      .toList();

  if (data == null || files.isEmpty) {
    CustomSnackBar.show(
      context: context,
      message: error ?? 'Video currently unavailable',
    );
    return;
  }

  // Prefer HLS (adaptive quality); fall back to the first file.
  final videoUrl = files
      .firstWhere((f) => f.quality.toLowerCase() == 'hls',
          orElse: () => files.first)
      .link;
  final String? apiThumbnail = data!['thumbnail']?.toString();
  final thumbnail = apiThumbnail != null && apiThumbnail.isNotEmpty
      ? apiThumbnail
      : fallbackThumbnail;
  final int? duration = data!['duration'] is int
      ? data!['duration']
      : int.tryParse(data!['duration']?.toString() ?? '');
  final String? videoProviderId =
      trackProgress ? data!['id']?.toString() : null;
  final isVertical = data!['ui_style']?.toString() == 'vertical';

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => isVertical
          ? VerticalVideoPlayerScreen(
              videoUrl: videoUrl,
              lessonTitle: title,
              videoFiles: files,
              thumbnailUrl: thumbnail,
              totalDuration: duration,
              videoProviderId: videoProviderId,
              initialPosition: initialPosition,
              allowGuest: allowGuest,
            )
          : LandscapeVideoPlayerScreen(
              videoUrl: videoUrl,
              lessonTitle: title,
              videoFiles: files,
              thumbnailUrl: thumbnail,
              totalDuration: duration,
              videoProviderId: videoProviderId,
              initialPosition: initialPosition,
              allowGuest: allowGuest,
            ),
    ),
  );
}
