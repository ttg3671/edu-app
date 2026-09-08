import 'package:edu_gym/api/api.dart';

class ModuleDetailModel {
  final int id;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final int isFree;
  final int videosCount;

  ModuleDetailModel({
    required this.id,
    required this.title,
    this.description,
    this.thumbnailUrl,
    required this.isFree,
    required this.videosCount,
  });

  factory ModuleDetailModel.fromJson(Map<String, dynamic> json) {
    final rawThumbnail = json['thumbnail_url'] ?? json['thumbnail'] ?? json['module_image'] ?? '';

    return ModuleDetailModel(
      id: json['id'] is int
          ? json['id']
          : (int.tryParse(json['id']?.toString() ?? '0') ?? 0),
      title: json['title']?.toString() ?? json['module_title']?.toString() ?? '',
      description: json['description']?.toString() ?? json['module_description']?.toString(),
      thumbnailUrl: rawThumbnail.toString(),
      isFree: json['is_free'] is int
          ? json['is_free']
          : (json['is_free'] == true || json['is_free'] == '1' || json['is_free'] == null ? (json['is_free'] == null ? 1 : 1) : 0),
      videosCount: json['videos_count'] is int
          ? json['videos_count']
          : (int.tryParse(json['videos_count']?.toString() ?? json['video_count']?.toString() ?? json['lesson_count']?.toString() ?? '0') ?? 0),
    );
  }

  String get fullThumbnailUrl {
    if (thumbnailUrl == null || thumbnailUrl!.isEmpty) return '';
    if (thumbnailUrl!.startsWith('http://') || thumbnailUrl!.startsWith('https://')) {
      return thumbnailUrl!;
    }
    final cleanPath = thumbnailUrl!.startsWith('/') ? thumbnailUrl!.substring(1) : thumbnailUrl!;
    final base = Api.imgBaseUrl.endsWith('/')
        ? Api.imgBaseUrl.substring(0, Api.imgBaseUrl.length - 1)
        : Api.imgBaseUrl;
    return '$base/$cleanPath';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnail_url': thumbnailUrl,
      'is_free': isFree,
      'videos_count': videosCount,
    };
  }
}
