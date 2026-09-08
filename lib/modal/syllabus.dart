import 'lesson.dart';

class Syllabus {
  final int syllabusId;
  final String syllabusTitle;
  final String? syllabusDescription;
  final int syllabusOrder;
  final List<Lesson>? lessons;
  final int? lessonCount;
  final int? currentPage;
  final int? totalPages;
  final bool? hasMore;

  // NEW: Cursor-based pagination for lessons
  final String? lessonsNextCursor;
  final bool? lessonsHasMore;

  // NEW: Release information
  final String? releaseTiming;
  final bool? isReleased;
  final String? workoutInstructions;

  Syllabus({
    required this.syllabusId,
    required this.syllabusTitle,
    required this.syllabusOrder,
    this.syllabusDescription,
    this.lessons,
    this.lessonCount,
    this.currentPage,
    this.totalPages,
    this.hasMore,
    this.lessonsNextCursor,
    this.lessonsHasMore,
    this.releaseTiming,
    this.isReleased,
    this.workoutInstructions,
  });

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

  factory Syllabus.fromJson(Map<String, dynamic> json, {bool isModuleFree = false}) {
    List? lessonsFromJson = json['lessons'];
    List<Lesson>? lessonList = lessonsFromJson?.map((lessonJson) {
      if (lessonJson is Map<String, dynamic>) {
        if (!lessonJson.containsKey('is_free') && !lessonJson.containsKey('isFree') && isModuleFree) {
          lessonJson['is_free'] = 1;
        }
      }
      return Lesson.fromJson(lessonJson);
    }).toList();

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

    return Syllabus(
      syllabusId: int.tryParse(json['id']?.toString() ?? json['syllabus_id']?.toString() ?? '0') ?? 0,
      syllabusTitle: json['title']?.toString() ?? json['name']?.toString() ?? json['syllabus_title']?.toString() ?? '',
      syllabusDescription: json['description']?.toString() ?? json['syllabus_description']?.toString(),
      syllabusOrder: int.tryParse(json['order']?.toString() ?? json['syllabus_order']?.toString() ?? '0') ?? 0,
      lessons: lessonList,
      lessonCount: json['lessons_count'] != null
          ? int.tryParse(json['lessons_count'].toString())
          : (json['lesson_count'] != null ? int.tryParse(json['lesson_count'].toString()) : null),
      currentPage: json['current_page'] != null ? int.tryParse(json['current_page'].toString()) : null,
      totalPages: json['total_pages'] != null ? int.tryParse(json['total_pages'].toString()) : null,
      hasMore: json['hasMore'] == true ||
          json['hasMore'] == 1 ||
          json['hasMore'] == '1' ||
          json['has_more'] == true ||
          json['has_more'] == 1 ||
          json['has_more'] == '1',
      lessonsNextCursor: json['nextCursor']?.toString() ?? json['lessons_next_cursor']?.toString(),
      lessonsHasMore: json['hasMore'] == true ||
          json['hasMore'] == 1 ||
          json['hasMore'] == '1' ||
          json['lessons_has_more'] == true ||
          json['lessons_has_more'] == 1 ||
          json['lessons_has_more'] == '1',
      releaseTiming: json['release_timing']?.toString(),
      isReleased: json['is_released'] == null
          ? true
          : (json['is_released'] == true || json['is_released'] == 1 || json['is_released'] == '1'),
      workoutInstructions: cleanWorkoutInstructions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'syllabus_id': syllabusId,
      'syllabus_title': syllabusTitle,
      'syllabus_description': syllabusDescription,
      'syllabus_order': syllabusOrder,
      'lessons': lessons?.map((lesson) => lesson.toJson()).toList(),
      'lesson_count': lessonCount,
      'current_page': currentPage,
      'total_pages': totalPages,
      'has_more': hasMore,
      'workout_instructions': workoutInstructions,
    };
  }
}
