import 'package:edu_gym/api/api.dart';

import 'lesson.dart';
import 'syllabus.dart';

class Badge {
  final int id;
  final String name;

  Badge({required this.id, required this.name});

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'],
      name: json['name'],
    );
  }
}

class Module {
  final int moduleId;
  final String moduleTitle;
  final String moduleImage;
  final String? moduleDes;
  final String? moduleVideo;
  final int? moduleVideoDuration;
  final String? moduleCategory;
  final List<Lesson>? lessons;
  final int? lessonCount;
  final List<Syllabus>? syllabus;
  final int? syllabusCount;
  final int? currentSyllabusPage;
  final int? totalSyllabusPages;
  final bool? hasSyllabusMore;
  final String? syllabusNextCursor;  // NEW: Cursor-based pagination
  final bool? isReleased;
  final List<String>? categories;
  final List<String>? sections;
  final List<Badge>? badges;

  // NEW: Pricing and ownership
  final bool alreadyOwned;
  final String? originalPrice;
  final String? discountedPrice;

  Module({
    required this.moduleId,
    required this.moduleTitle,
    required this.moduleImage,
    required this.lessons,
    required this.lessonCount,
    this.moduleDes,
    this.moduleVideo,
    this.moduleVideoDuration,
    this.moduleCategory,
    this.syllabus,
    this.syllabusCount,
    this.currentSyllabusPage,
    this.totalSyllabusPages,
    this.hasSyllabusMore,
    this.syllabusNextCursor,
    this.isReleased,
    this.categories,
    this.sections,
    this.badges,
    this.alreadyOwned = false,
    this.originalPrice,
    this.discountedPrice,
  });

  factory Module.fromJson(Map<String, dynamic> json) {
    // Handle nested structure where module data is inside 'module' key
    final moduleData = json['module'] ?? json;

    List? lessonsFromJson = json['lessons'];
    List<Lesson>? lessonList = lessonsFromJson?.map((lessonJson) => Lesson.fromJson(lessonJson)).toList();

    List? syllabusFromJson = json['syllabus'];
    List<Syllabus>? syllabusList = syllabusFromJson?.map((syllabusJson) => Syllabus.fromJson(syllabusJson)).toList();

    // Parse categories as List<String>
    List<String>? categoriesList;
    if (moduleData['categories'] != null) {
      if (moduleData['categories'] is String) {
        // If it's a string (like in search API), split by comma
        categoriesList = (moduleData['categories'] as String)
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      } else if (moduleData['categories'] is List) {
        categoriesList = (moduleData['categories'] as List).map((e) => e.toString()).toList();
      }
    }

    // Parse sections as List<String>
    List<String>? sectionsList;
    if (moduleData['sections'] != null) {
      sectionsList = (moduleData['sections'] as List).map((e) => e.toString()).toList();
    }

    // Parse badges
    List<Badge>? badgesList;
    if (moduleData['badges'] != null) {
      badgesList = (moduleData['badges'] as List).map((badgeJson) => Badge.fromJson(badgeJson)).toList();
    }

    return Module(
      moduleId: moduleData['module_id'] ?? moduleData['id'] ?? 0,
      moduleTitle: moduleData['module_title'] ?? moduleData['title'] ?? '',
      moduleImage: moduleData['module_image'] != null
          ? '${Api.imgBaseUrl}/${moduleData['module_image']}'
          : (moduleData['image'] != null ? '${Api.imgBaseUrl}/${moduleData['image']}' : (moduleData['thumbnail_url'] != null ? '${Api.imgBaseUrl}/${moduleData['thumbnail_url']}' : '')),
      lessons: lessonList,
      lessonCount: json['lesson_count'] ?? moduleData['lesson_count'] ?? 0,
      moduleDes: moduleData['module_description'] ?? moduleData['description'],
      moduleVideo: moduleData['module_video'] != null
          ? '${Api.imgBaseUrl}/${moduleData['module_video']}'
          : moduleData['vimeo_link'],
      moduleVideoDuration: moduleData['module_duration'] ?? moduleData['duration'],
      moduleCategory: moduleData['category'],
      syllabus: syllabusList,
      syllabusCount: json['total_syllabus'] ?? json['syllabus_count'] ?? 0,
      currentSyllabusPage: json['syllabus_current_page'] ?? json['current_syllabus_page'],
      totalSyllabusPages: json['total_syllabus_pages'],
      hasSyllabusMore: json['syllabus_has_more'] ?? json['has_syllabus_more'],
      syllabusNextCursor: json['syllabus_next_cursor']?.toString(),
      isReleased: moduleData['is_released'],
      categories: categoriesList,
      sections: sectionsList,
      badges: badgesList,
      alreadyOwned: json['already_owned'] ?? (moduleData['is_free'] == 1),
      originalPrice: moduleData['original_price']?.toString(),
      discountedPrice: moduleData['discounted_price']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'module_id': moduleId,
      'module_title': moduleTitle,
      'module_image': moduleImage,
      'lessons': lessons?.map((lesson) => lesson.toJson()).toList(),
    };
  }
}
