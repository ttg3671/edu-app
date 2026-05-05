import 'package:edu_gym/api/api.dart';
import 'package:edu_gym/core/cubit_states/data_state.dart';
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
    
    final res = await Api.instance.getModuleLessons(
      moduleId: moduleId,
      limit: _defaultLimit,
    );
    
    res.fold((error){
      emit(DataLoadFailed(error));
    }, (jsonData){
      final module = Module.fromJson(jsonData['data']);
      emit(DataLoaded<Module>(module));
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

    final res = await Api.instance.getModuleLessons(
      moduleId: _moduleId,
      limit: 2, // Request 2 lessons at a time as per user hint
      cursor: syllabus.lessonsNextCursor,
      syllabusId: syllabusId,
    );

    res.fold((error){
      _loadingSyllabusId = null;
      emit(DataLoaded(currentModule));
    }, (jsonData){
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
    });
  }

  bool isLoadingLessons(int syllabusId) {
    return _loadingSyllabusId == syllabusId;
  }
}
