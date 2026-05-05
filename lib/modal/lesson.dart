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
  final String? uiStyle;

  // NEW: Multiple quality video files
  final List<VideoFile>? videoFiles;

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
    this.uiStyle,
    this.videoFiles,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    List? upNextJson = json['upNext'];
    List? videoFilesJson = json['video_files'];

    List<VideoFile>? videoFilesList;
    if (videoFilesJson != null && videoFilesJson.isNotEmpty) {
      videoFilesList = videoFilesJson
          .map((e) => VideoFile.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return Lesson(
      lessonId: json['lesson_id'] ?? json['id'] ?? 0,
      mid: json['module_id'] ?? json['mid'],
      lessonImage: json['lesson_image'] != null
          ? '${Api.imgBaseUrl}/${json['lesson_image']}'
          : json['thumbnail'],
      lessonTitle: json['lesson_title'] ?? json['title'],
      lessonDes: json['lesson_description'] ?? json['description'],
      lessonVideo: json['lesson_video'] != null
          ? '${Api.imgBaseUrl}/${json['lesson_video']}'
          : json['vimeo_link'],
      lessonVideoLength: json['lesson_video_length'] ?? json['duration'],
      lessonCreatedAt: json['lesson_created_at'] ?? json['release_timing'],
      isReleased: json['is_released'] ?? true,
      videoProviderId: json['video_provider_id']?.toString(),
      uiStyle: json['ui_style']?.toString(),
      videoFiles: videoFilesList,
      upNext: upNextJson?.map((e) => Lesson.fromJson(e)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lesson_id': lessonId,
      'mid': mid,
      'lesson_image': lessonImage,
    };
  }
}