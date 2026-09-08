import 'package:edu_gym/api/api.dart';
import 'package:edu_gym/api/token_api.dart';

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
  final bool isFree;
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
    this.isFree = true,
    this.categories,
    this.sections,
    this.badges,
    this.alreadyOwned = false,
    this.originalPrice,
    this.discountedPrice,
  });

  factory Module.fromJson(Map<String, dynamic> json) {
    // Handle nested structure where module data is inside 'module' key
    final moduleData = (json['module'] != null && json['module'] is Map<String, dynamic>)
        ? json['module'] as Map<String, dynamic>
        : json;

    final bool isModuleFree = moduleData['is_free'] == 1 ||
        moduleData['is_free'] == '1' ||
        moduleData['is_free'] == true ||
        moduleData['isFree'] == 1 ||
        moduleData['isFree'] == true;

    final bool isUserReviewer = TokenApi.user?.isReviewer == 1;

    List? lessonsFromJson = (json['lessons'] is List)
        ? json['lessons']
        : (moduleData['lessons'] is List ? moduleData['lessons'] : null);

    List<Lesson>? lessonList = lessonsFromJson?.map((lessonJson) {
      if (lessonJson is Map<String, dynamic>) {
        if (!lessonJson.containsKey('is_free') && !lessonJson.containsKey('isFree') && isModuleFree) {
          lessonJson['is_free'] = 1;
        }
      }
      return Lesson.fromJson(lessonJson);
    }).toList();

    List? syllabusFromJson = (json['syllabus'] is List)
        ? json['syllabus']
        : (moduleData['syllabus'] is List ? moduleData['syllabus'] : null);

    List<Syllabus>? syllabusList = syllabusFromJson?.map((syllabusJson) {
      if (syllabusJson is Map<String, dynamic>) {
        return Syllabus.fromJson(syllabusJson, isModuleFree: isModuleFree);
      }
      return Syllabus.fromJson(syllabusJson);
    }).toList();

    // Parse categories as List<String>
    List<String>? categoriesList;
    if (moduleData['categories'] != null) {
      if (moduleData['categories'] is String) {
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
    if (moduleData['sections'] != null && moduleData['sections'] is List) {
      sectionsList = (moduleData['sections'] as List).map((e) => e.toString()).toList();
    }

    // Parse badges
    List<Badge>? badgesList;
    if (moduleData['badges'] != null && moduleData['badges'] is List) {
      badgesList = (moduleData['badges'] as List)
          .whereType<Map<String, dynamic>>()
          .map((badgeJson) => Badge.fromJson(badgeJson))
          .toList();
    }

    final rawModuleImage = moduleData['thumbnail_url'] ?? moduleData['thumbnail'] ?? moduleData['module_image'] ?? '';

    String resolvedModuleImage = '';
    if (rawModuleImage != null && rawModuleImage.toString().isNotEmpty) {
      final imgStr = rawModuleImage.toString();
      if (imgStr.startsWith('http://') || imgStr.startsWith('https://')) {
        resolvedModuleImage = imgStr;
      } else {
        final cleanPath = imgStr.startsWith('/') ? imgStr.substring(1) : imgStr;
        final base = Api.imgBaseUrl.endsWith('/')
            ? Api.imgBaseUrl.substring(0, Api.imgBaseUrl.length - 1)
            : Api.imgBaseUrl;
        resolvedModuleImage = '$base/$cleanPath';
      }
    }

    final bool hasAccess = json['hasAccess'] == true ||
        json['hasAccess'] == 1 ||
        json['hasAccess'] == '1' ||
        json['already_owned'] == true ||
        json['already_owned'] == 1 ||
        json['already_owned'] == '1' ||
        moduleData['hasAccess'] == true ||
        moduleData['hasAccess'] == 1 ||
        moduleData['hasAccess'] == '1' ||
        moduleData['already_owned'] == true ||
        moduleData['already_owned'] == 1 ||
        moduleData['already_owned'] == '1' ||
        isUserReviewer ||
        isModuleFree;

    return Module(
      moduleId: int.tryParse(moduleData['id']?.toString() ?? moduleData['module_id']?.toString() ?? '0') ?? 0,
      moduleTitle: moduleData['title']?.toString() ?? moduleData['module_title']?.toString() ?? '',
      moduleImage: resolvedModuleImage,
      lessons: lessonList,
      lessonCount: int.tryParse(json['lesson_count']?.toString() ?? moduleData['lesson_count']?.toString() ?? '0') ?? 0,
      moduleDes: moduleData['description']?.toString() ?? moduleData['module_description']?.toString(),
      moduleVideo: moduleData['module_video'] != null
          ? '${Api.imgBaseUrl}/${moduleData['module_video']}'
          : moduleData['vimeo_link']?.toString(),
      moduleVideoDuration: moduleData['duration'] != null
          ? int.tryParse(moduleData['duration'].toString())
          : (moduleData['module_duration'] != null ? int.tryParse(moduleData['module_duration'].toString()) : null),
      moduleCategory: moduleData['category']?.toString(),
      syllabus: syllabusList,
      syllabusCount: int.tryParse(json['total_syllabus']?.toString() ?? json['syllabus_count']?.toString() ?? '0') ?? 0,
      currentSyllabusPage: json['syllabus_current_page'] != null
          ? int.tryParse(json['syllabus_current_page'].toString())
          : (json['current_syllabus_page'] != null ? int.tryParse(json['current_syllabus_page'].toString()) : null),
      totalSyllabusPages: json['total_syllabus_pages'] != null ? int.tryParse(json['total_syllabus_pages'].toString()) : null,
      hasSyllabusMore: json['syllabus_has_more'] == true ||
          json['syllabus_has_more'] == 1 ||
          json['syllabus_has_more'] == '1' ||
          json['has_syllabus_more'] == true ||
          json['has_syllabus_more'] == 1 ||
          json['has_syllabus_more'] == '1',
      syllabusNextCursor: json['syllabus_next_cursor']?.toString(),
      isReleased: moduleData['is_released'] == null
          ? true
          : (moduleData['is_released'] == true || moduleData['is_released'] == 1 || moduleData['is_released'] == '1'),
      isFree: isModuleFree,
      categories: categoriesList,
      sections: sectionsList,
      badges: badgesList,
      alreadyOwned: hasAccess,
      originalPrice: moduleData['original_price']?.toString(),
      discountedPrice: moduleData['discounted_price']?.toString(),
    );
  }

  String get thumbnailUrl => moduleImage;
  String get thumbnail => moduleImage;
  String get fullThumbnailUrl => moduleImage;

  Map<String, dynamic> toJson() {
    return {
      'module_id': moduleId,
      'module_title': moduleTitle,
      'module_image': moduleImage,
      'thumbnail_url': moduleImage,
      'thumbnail': moduleImage,
      'lessons': lessons?.map((lesson) => lesson.toJson()).toList(),
    };
  }
}
