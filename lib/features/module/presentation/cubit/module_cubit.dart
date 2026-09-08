import 'package:edu_gym/api/api.dart';
import 'package:edu_gym/core/cubit_states/data_state.dart';
import 'package:edu_gym/core/error/failure.dart';
import 'package:edu_gym/modal/lesson.dart';
import 'package:edu_gym/modal/module.dart';
import 'package:edu_gym/modal/syllabus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ModuleCubit extends Cubit<DataState>{
  ModuleCubit():super(DataInitial());

  int _moduleId = 0;
  static const int _defaultLimit = 4;
  int? _loadingSyllabusId;

  Future<void> loadData(int moduleId) async {
    _moduleId = moduleId;
    emit(DataLoading());
    
    // print('📡 [MODULE CUBIT] Fetching module data for moduleId: $moduleId');
    final res = await Api.instance.getModuleLessons(
      moduleId: moduleId,
      limit: _defaultLimit,
    );
    
    res.fold((error){
      // print('❌ [MODULE CUBIT] Failed to load module data: ${error.message}');
      emit(DataLoadFailed(error));
    }, (jsonData){
      // print('=================== [MODULE LESSONS DATA] ===================');
      // print('📦 Raw Data: ${jsonEncode(jsonData)}');
      try {
        final module = Module.fromJson(jsonData['data']);
        // print('🏷️ Module ID: ${module.moduleId}');
        // print('🏷️ Module Title: ${module.moduleTitle}');
        // print('🏷️ Module isFree: ${module.isFree}');
        // print('🏷️ Module alreadyOwned: ${module.alreadyOwned}');
        // print('🏷️ Total Syllabus Count: ${module.syllabus?.length ?? 0}');

        // if (module.syllabus != null && module.syllabus!.isNotEmpty) {
        //   for (var s in module.syllabus!) {
        //     print('  📘 Syllabus [${s.syllabusId}] "${s.syllabusTitle}" (Lessons: ${s.lessons?.length ?? 0}):');
        //     if (s.lessons != null) {
        //       for (var l in s.lessons!) {
        //         print('    ▶️ Lesson [${l.lessonId}] "${l.lessonTitle}": videoProviderId=${l.videoProviderId}, videoId=${l.videoId}, isFree=${l.isFree}');
        //       }
        //     }
        //   }
        // }
        // if (module.lessons != null && module.lessons!.isNotEmpty) {
        //   print('  📘 Direct Lessons Count: ${module.lessons!.length}');
        //   for (var l in module.lessons!) {
        //     print('    ▶️ Lesson [${l.lessonId}] "${l.lessonTitle}": videoProviderId=${l.videoProviderId}, videoId=${l.videoId}, isFree=${l.isFree}');
        //   }
        // }
        // print('=============================================================');
        emit(DataLoaded<Module>(module));
      } catch (e) {
        // print('❌ [MODULE CUBIT] Error parsing module lessons data: $e');
        emit(DataLoadFailed(Failure('Failed to parse module: $e')));
      }
    });
  }

  Future<void> loadMoreLessons(int syllabusId) async {
    final currentState = state;
    if (currentState is! DataLoaded<Module>) return;

    final currentModule = currentState.data;
    final syllabusIndex = currentModule.syllabus?.indexWhere((s) => s.syllabusId == syllabusId) ?? -1;
    
    if (syllabusIndex == -1) return;
    
    final syllabus = currentModule.syllabus![syllabusIndex];
    if (syllabus.lessonsHasMore != true || syllabus.lessonsNextCursor == null) return;

    // Set loading state for this syllabus
    _loadingSyllabusId = syllabusId;
    emit(DataLoaded(currentModule));

    // print('📡 [MODULE CUBIT] Fetching more lessons for syllabusId: $syllabusId with cursor: ${syllabus.lessonsNextCursor}');
    final res = await Api.instance.getModuleLessons(
      moduleId: _moduleId,
      limit: 2, // Request 2 lessons at a time as per user hint
      cursor: syllabus.lessonsNextCursor,
      syllabusId: syllabusId,
    );

    res.fold((error){
      // print('❌ [MODULE CUBIT] Failed to load more lessons: ${error.message}');
      _loadingSyllabusId = null;
      emit(DataLoaded(currentModule));
    }, (jsonData){
      // print('📥 [LOAD MORE LESSONS API RESPONSE]: ${jsonEncode(jsonData)}');
      try {
        final newModuleData = Module.fromJson(jsonData['data']);
        
        // Find the specific syllabus in the new response
        final newSyllabus = newModuleData.syllabus?.firstWhere(
          (s) => s.syllabusId == syllabusId,
          orElse: () => syllabus,
        );

        if (newSyllabus != null) {
          final List<Lesson> updatedLessons = [
            ...(syllabus.lessons ?? []),
            ...(newSyllabus.lessons ?? []),
          ];

          final updatedSyllabus = Syllabus(
            syllabusId: syllabus.syllabusId,
            syllabusTitle: syllabus.syllabusTitle,
            syllabusOrder: syllabus.syllabusOrder,
            syllabusDescription: syllabus.syllabusDescription,
            lessons: updatedLessons,
            lessonCount: syllabus.lessonCount,
            currentPage: newSyllabus.currentPage,
            totalPages: newSyllabus.totalPages,
            hasMore: newSyllabus.hasMore,
            lessonsNextCursor: newSyllabus.lessonsNextCursor,
            lessonsHasMore: newSyllabus.lessonsHasMore,
            releaseTiming: syllabus.releaseTiming,
            isReleased: syllabus.isReleased,
          );

          final updatedSyllabusList = List<Syllabus>.from(currentModule.syllabus!);
          updatedSyllabusList[syllabusIndex] = updatedSyllabus;

          final updatedModule = Module(
            moduleId: currentModule.moduleId,
            moduleTitle: currentModule.moduleTitle,
            moduleImage: currentModule.moduleImage,
            lessons: currentModule.lessons,
            lessonCount: currentModule.lessonCount,
            moduleDes: currentModule.moduleDes,
            moduleVideo: currentModule.moduleVideo,
            moduleVideoDuration: currentModule.moduleVideoDuration,
            moduleCategory: currentModule.moduleCategory,
            syllabus: updatedSyllabusList,
            syllabusCount: currentModule.syllabusCount,
            currentSyllabusPage: currentModule.currentSyllabusPage,
            totalSyllabusPages: currentModule.totalSyllabusPages,
            hasSyllabusMore: currentModule.hasSyllabusMore,
            syllabusNextCursor: currentModule.syllabusNextCursor,
            isReleased: currentModule.isReleased,
            isFree: currentModule.isFree,
            categories: currentModule.categories,
            sections: currentModule.sections,
            badges: currentModule.badges,
            alreadyOwned: currentModule.alreadyOwned,
            originalPrice: currentModule.originalPrice,
            discountedPrice: currentModule.discountedPrice,
          );

          _loadingSyllabusId = null;
          emit(DataLoaded<Module>(updatedModule));
        } else {
          _loadingSyllabusId = null;
          emit(DataLoaded<Module>(currentModule));
        }
      } catch (e) {
        _loadingSyllabusId = null;
        emit(DataLoaded<Module>(currentModule));
      }
    });
  }

  bool isLoadingLessons(int syllabusId) {
    return _loadingSyllabusId == syllabusId;
  }
}
