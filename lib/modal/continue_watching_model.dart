import 'package:edu_gym/api/api.dart';

class ContinueWatchingItem {
  final int id;
  final int? videoId;
  final String? videoProviderId;
  final String? thumbnail;
  final String? uiStyle;
  final String? lessonTitle;
  final int isFree;
  final int lastPositionMs;
  final int totalDurationMs;
  final int isCompleted;
  final int? moduleId;

  ContinueWatchingItem({
    required this.id,
    this.videoId,
    this.videoProviderId,
    this.thumbnail,
    this.uiStyle,
    this.lessonTitle,
    this.isFree = 1,
    this.lastPositionMs = 0,
    this.totalDurationMs = 0,
    this.isCompleted = 0,
    this.moduleId,
  });

  factory ContinueWatchingItem.fromJson(Map<String, dynamic> json) {
    final rawThumbnail = json['thumbnail'] ?? json['thumbnail_url'] ?? '';

    return ContinueWatchingItem(
      id: json['id'] is int ? json['id'] : (int.tryParse(json['id']?.toString() ?? '') ?? 0),
      videoId: json['video_id'] is int ? json['video_id'] : int.tryParse(json['video_id']?.toString() ?? ''),
      videoProviderId: json['video_provider_id']?.toString(),
      thumbnail: rawThumbnail?.toString(),
      uiStyle: json['ui_style']?.toString() ?? 'horizontal',
      lessonTitle: json['lesson_title']?.toString() ?? json['title']?.toString() ?? 'Lesson',
      isFree: json['is_free'] is int
          ? json['is_free']
          : (json['is_free'] == true || json['is_free'] == '1' || json['is_free']?.toString().toLowerCase() == 'true' ? 1 : 0),
      lastPositionMs: json['last_position_ms'] is num
          ? (json['last_position_ms'] as num).toInt()
          : (int.tryParse(json['last_position_ms']?.toString() ?? '') ?? (int.tryParse(json['watch_time']?.toString() ?? '') ?? 0)),
      totalDurationMs: json['total_duration_ms'] is num
          ? (json['total_duration_ms'] as num).toInt()
          : (int.tryParse(json['total_duration_ms']?.toString() ?? '') ?? (int.tryParse(json['duration']?.toString() ?? '') ?? 0)),
      isCompleted: json['is_completed'] is int
          ? json['is_completed']
          : (json['is_completed'] == true || json['is_completed'] == '1' || json['is_completed']?.toString().toLowerCase() == 'true' ? 1 : 0),
      moduleId: json['module_id'] is int ? json['module_id'] : int.tryParse(json['module_id']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'video_id': videoId,
      'video_provider_id': videoProviderId,
      'thumbnail': thumbnail,
      'thumbnail_url': thumbnail,
      'ui_style': uiStyle,
      'lesson_title': lessonTitle,
      'is_free': isFree,
      'last_position_ms': lastPositionMs,
      'total_duration_ms': totalDurationMs,
      'is_completed': isCompleted,
      'module_id': moduleId,
    };
  }

  double get progress {
    if (totalDurationMs <= 0) return 0.0;
    final val = lastPositionMs / totalDurationMs;
    return val.clamp(0.0, 1.0);
  }

  int get progressPercent {
    return (progress * 100).round();
  }

  String get effectiveThumbnail {
    if (thumbnail == null || thumbnail!.isEmpty) return '';
    if (thumbnail!.startsWith('http://') || thumbnail!.startsWith('https://')) {
      return thumbnail!;
    }
    final cleanPath = thumbnail!.startsWith('/') ? thumbnail!.substring(1) : thumbnail!;
    final base = Api.imgBaseUrl.endsWith('/')
        ? Api.imgBaseUrl.substring(0, Api.imgBaseUrl.length - 1)
        : Api.imgBaseUrl;
    return '$base/$cleanPath';
  }

  String get fullThumbnailUrl => effectiveThumbnail;
  String? get thumbnailUrl => effectiveThumbnail;

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

  bool get isComingSoon {
    if (isFree != 1) return false;
    return !hasValidVideoProviderId;
  }

  String? get effectiveVideoProviderId {
    if (hasValidVideoProviderId) {
      return videoProviderId!.trim();
    }
    final vId = videoId?.toString().trim();
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
}

class ContinueWatchingResponse {
  final bool isSuccess;
  final List<ContinueWatchingItem> data;
  final dynamic nextCursor;
  final bool hasMore;

  ContinueWatchingResponse({
    required this.isSuccess,
    required this.data,
    this.nextCursor,
    required this.hasMore,
  });

  factory ContinueWatchingResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['data'] as List<dynamic>?)
            ?.map((e) => ContinueWatchingItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final nextCursorVal = (json['nextCursor'] == null ||
            json['nextCursor'].toString().trim().toLowerCase() == 'null' ||
            json['nextCursor'].toString().trim().isEmpty)
        ? null
        : json['nextCursor'];

    final bool hasMoreVal = json['hasMore'] == true ||
        json['hasMore'] == 1 ||
        json['hasMore']?.toString().toLowerCase() == 'true' ||
        (nextCursorVal != null);

    return ContinueWatchingResponse(
      isSuccess: json['isSuccess'] == true || json['isSuccess'] == 1 || json['isSuccess']?.toString().toLowerCase() == 'true',
      data: list,
      nextCursor: nextCursorVal,
      hasMore: hasMoreVal,
    );
  }
}
