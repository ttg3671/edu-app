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
  });

  factory Syllabus.fromJson(Map<String, dynamic> json) {
    List? lessonsFromJson = json['lessons'];
    List<Lesson>? lessonList = lessonsFromJson?.map((lessonJson) => Lesson.fromJson(lessonJson)).toList();

    return Syllabus(
      syllabusId: json['id'] ?? json['syllabus_id'] ?? 0,
      syllabusTitle: json['title'] ?? json['name'] ?? json['syllabus_title'] ?? '',
      syllabusDescription: json['description'] ?? json['syllabus_description'],
      syllabusOrder: json['order'] ?? json['syllabus_order'] ?? 0,
      lessons: lessonList,
      lessonCount: json['lessons_count'] ?? json['lesson_count'],
      currentPage: json['current_page'],
      totalPages: json['total_pages'],
      hasMore: json['hasMore'] ?? json['has_more'],
      lessonsNextCursor: json['nextCursor']?.toString() ?? json['lessons_next_cursor']?.toString(),
      lessonsHasMore: json['hasMore'] ?? json['lessons_has_more'],
      releaseTiming: json['release_timing'],
      isReleased: json['is_released'],
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
    };
  }
}
