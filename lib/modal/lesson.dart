import '../api/api.dart';

class VideoFile {
  final String quality;
  final String link;

  VideoFile({required this.quality, required this.link});

  factory VideoFile.fromJson(Map<String, dynamic> json) {
    return VideoFile(
      quality: json['quality']?.toString() ?? '',
      link: json['link'] ?? '',
    );
  }
}

class Lesson {
  final int lessonId;
  final int? mid;
  final String? lessonImage;
  final String? lessonTitle;
  final String? lessonDes;
  final String? lessonVideo;
  final int? lessonVideoLength;
  final String? lessonCreatedAt;
  final bool? isReleased;
  final List<Lesson>? upNext;
  final String? videoProviderId;
  final String? videoId;
  final String? uiStyle;
  final bool isFree;
  final int? lastPositionMs;
  final bool? isCompleted;

  // NEW: Multiple quality video files
  final List<VideoFile>? videoFiles;
  final String? workoutInstructions;

  Lesson({
    required this.lessonId,
    this.mid,
    this.lessonImage,
    this.lessonTitle,
    this.lessonDes,
    this.lessonVideo,
    this.lessonVideoLength,
    this.lessonCreatedAt,
    this.isReleased,
    this.upNext,
    this.videoProviderId,
    this.videoId,
    this.uiStyle,
    this.isFree = true,
    this.lastPositionMs,
    this.isCompleted,
    this.videoFiles,
    this.workoutInstructions,
  });

  /// Checks if lesson has a valid video_id or last_position_ms.
  bool get hasVideoIdOrLastPosition {
    final bool hasVideoId = videoId != null &&
        videoId!.toString().trim().isNotEmpty &&
        videoId!.toString().trim().toLowerCase() != 'null' &&
        videoId!.toString().trim().toLowerCase() != 'undefined';

    final bool hasLastPosition = lastPositionMs != null && lastPositionMs! > 0;

    return hasVideoId || hasLastPosition;
  }

  /// Checks if the lesson has a valid video provider ID.
  bool get hasValidVideoProviderId {
    final vProvider = videoProviderId?.trim();
    if (vProvider == null ||
        vProvider.isEmpty ||
        vProvider.toLowerCase() == 'null' ||
        vProvider.toLowerCase() == 'undefined') {
      return false;
    }
    final parsed = int.tryParse(vProvider);
    if (parsed != null && parsed <= 0) {
      return false;
    }
    return true;
  }

  /// Determines whether the lesson is missing a valid video provider ID.
  bool get hasNullVideoIds {
    if (isReleased == false) return true;
    return !hasValidVideoProviderId;
  }

  /// Determines whether this lesson is "Coming Soon" / "Stay tuned".
  /// Rule:
  /// - If module/lesson is PAID (is_free == 0 / false), do NOT show stay tuned / coming soon.
  /// - If module/lesson is FREE (is_free == 1 / true) and video_provider_id is missing/null/<= 0, show stay tuned / coming soon.
  bool get isComingSoon {
    if (!isFree) return false;
    return hasNullVideoIds;
  }

  /// Checks coming soon taking the parent module's isFree status into account.
  bool isComingSoonWithModule(bool moduleIsFree) {
    if (!moduleIsFree && !isFree) return false;
    return hasNullVideoIds;
  }

  /// Returns the effective video provider ID if available and valid.
  String? get effectiveVideoProviderId {
    if (hasValidVideoProviderId) {
      return videoProviderId!.trim();
    }
    final vId = videoId?.trim();
    if (vId != null &&
        vId.isNotEmpty &&
        vId.toLowerCase() != 'null' &&
        vId.toLowerCase() != 'undefined') {
      final parsed = int.tryParse(vId);
      if (parsed == null || parsed > 0) {
        return vId;
      }
    }
    return null;
  }

  bool get hasWorkoutInstructions {
    if (workoutInstructions == null) return false;
    final clean = workoutInstructions!.trim().toLowerCase();
    if (clean.isEmpty ||
        clean == 'null' ||
        clean == 'undefined' ||
        clean == '<p></p>' ||
        clean == '<p><br></p>' ||
        clean == '<p><br/></p>') {
      return false;
    }
    return true;
  }

  String? get thumbnail => lessonImage;
  String? get thumbnailUrl => lessonImage;
  String? get fullThumbnailUrl => lessonImage;

  factory Lesson.fromJson(Map<String, dynamic> json) {
    List? upNextJson = json['upNext'];
    List? videoFilesJson = json['video_files'] ?? json['files'];

    List<VideoFile>? videoFilesList;
    if (videoFilesJson != null && videoFilesJson.isNotEmpty) {
      videoFilesList = videoFilesJson
          .map((e) => VideoFile.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final rawLessonImage = json['thumbnail'] ?? '';

    String? resolvedLessonImage;
    if (rawLessonImage != null && rawLessonImage.toString().isNotEmpty) {
      final imgStr = rawLessonImage.toString();
      if (imgStr.startsWith('http://') || imgStr.startsWith('https://')) {
        resolvedLessonImage = imgStr;
      } else {
        final cleanPath = imgStr.startsWith('/') ? imgStr.substring(1) : imgStr;
        final base = Api.imgBaseUrl.endsWith('/')
            ? Api.imgBaseUrl.substring(0, Api.imgBaseUrl.length - 1)
            : Api.imgBaseUrl;
        resolvedLessonImage = '$base/$cleanPath';
      }
    }

    final rawWorkoutInstructions = json['workout_instructions']?.toString();
    final cleanWorkoutInstructions = (rawWorkoutInstructions != null &&
            rawWorkoutInstructions.trim().isNotEmpty &&
            rawWorkoutInstructions.trim().toLowerCase() != 'null' &&
            rawWorkoutInstructions.trim().toLowerCase() != 'undefined' &&
            rawWorkoutInstructions.trim() != '<p></p>' &&
            rawWorkoutInstructions.trim() != '<p><br></p>' &&
            rawWorkoutInstructions.trim() != '<p><br/></p>')
        ? rawWorkoutInstructions
        : null;

    return Lesson(
      lessonId: int.tryParse(json['id']?.toString() ?? json['lesson_id']?.toString() ?? '0') ?? 0,
      mid: json['module_id'] != null
          ? int.tryParse(json['module_id'].toString())
          : (json['mid'] != null ? int.tryParse(json['mid'].toString()) : null),
      lessonImage: resolvedLessonImage,
      lessonTitle: json['title']?.toString() ?? json['lesson_title']?.toString(),
      lessonDes: json['description']?.toString() ?? json['lesson_description']?.toString(),
      lessonVideo: json['lesson_video'] != null
          ? '${Api.imgBaseUrl}/${json['lesson_video']}'
          : json['vimeo_link']?.toString(),
      lessonVideoLength: json['duration'] != null
          ? int.tryParse(json['duration'].toString())
          : (json['lesson_video_length'] != null ? int.tryParse(json['lesson_video_length'].toString()) : null),
      lessonCreatedAt: json['release_timing']?.toString() ?? json['lesson_created_at']?.toString(),
      isReleased: json['is_released'] == null
          ? true
          : (json['is_released'] == true || json['is_released'] == 1 || json['is_released'] == '1'),
      videoProviderId: json['video_provider_id']?.toString(),
      videoId: json['video_id']?.toString(),
      uiStyle: json['ui_style']?.toString(),
      isFree: json['is_free'] == 1 ||
          json['is_free'] == '1' ||
          json['is_free'] == true ||
          json['isFree'] == 1 ||
          json['isFree'] == true,
      lastPositionMs: json['last_position_ms'] is int
          ? json['last_position_ms']
          : (int.tryParse(json['last_position_ms']?.toString() ?? '')),
      isCompleted: json['is_completed'] == true ||
          json['is_completed'] == 1 ||
          json['is_completed'] == '1',
      videoFiles: videoFilesList,
      workoutInstructions: cleanWorkoutInstructions,
      upNext: upNextJson?.map((e) => Lesson.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lesson_id': lessonId,
      'mid': mid,
      'lesson_image': lessonImage,
      'thumbnail': lessonImage,
      'thumbnail_url': lessonImage,
      'video_provider_id': videoProviderId,
      'video_id': videoId,
      'last_position_ms': lastPositionMs,
      'is_completed': isCompleted,
      'workout_instructions': workoutInstructions,
    };
  }
}