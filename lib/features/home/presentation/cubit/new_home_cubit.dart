import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:edu_gym/core/cubit_states/data_state.dart';
import 'package:edu_gym/modal/new_home_response.dart';
import 'package:edu_gym/api/api.dart';
import 'package:edu_gym/core/error/failure.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NewHomeCubit extends Cubit<DataState> {
  NewHomeCubit() : super(DataInitial());

  int? _selectedPillId;
  int? _selectedCategoryId;
  static const int _defaultLimit = 3;
  static const String _pillPersistenceKey = 'last_selected_pill_id';

  // Prevent multiple simultaneous loads for the same section
  final Set<int> _loadingSections = {};

  Future<void> loadHome({
    int limit = _defaultLimit,
    String? cursor,
  }) async {
    emit(DataLoading());

    try {
      final result = await Api.instance.getDramaBoxHome(
        limit: limit,
        cursor: cursor ?? '',
      );

      await result.fold(
        (failure) async {
          emit(DataLoadFailed(failure));
        },
        (jsonData) async {
          // print('🏠 Home API Sections: ${jsonData['data']?['initial_data']?['sections']}');
          final response = NewHomeResponse.fromJson(jsonData);
          
          // If we are refreshing and already had a pill selected (other than home/1)
          if (_selectedPillId != null && _selectedPillId != 1 && _selectedPillId != response.data.initialData.navPillId) {
             final pillResult = await Api.instance.getNavPillData(
              navPillId: _selectedPillId!,
              limit: _defaultLimit,
              categoryId: _selectedCategoryId,
            );

            pillResult.fold(
              (failure) {
                // Fallback if pill load fails
                _selectedPillId = response.data.initialData.navPillId;
                emit(DataLoaded<NewHomeResponse>(response));
              },
              (pillJson) {
                final dataPart = pillJson['data'];
                InitialData initialData;
                if (dataPart != null && dataPart['initial_data'] != null) {
                  initialData = InitialData.fromJson(dataPart['initial_data']);
                } else {
                  initialData = InitialData.fromJson(dataPart ?? {});
                }

                final updatedResponse = NewHomeResponse(
                  isSuccess: response.isSuccess,
                  data: NewHomeData(
                    navigationPills: response.data.navigationPills,
                    filterArray: response.data.filterArray,
                    initialData: initialData,
                  ),
                );
                emit(DataLoaded<NewHomeResponse>(updatedResponse));
              },
            );
          } else {
            // First load or home pill selected
            _selectedPillId = response.data.initialData.navPillId;
            emit(DataLoaded<NewHomeResponse>(response));
          }
        },
      );
    } catch (e) {
      emit(DataLoadFailed(Failure(e.toString())));
    }
  }

  Future<void> selectPill(int pillId) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (pillId == 1) {
      _selectedPillId = 1;
      _selectedCategoryId = null; // Clear category filter
      await prefs.setInt(_pillPersistenceKey, 1);
      loadHome();
      return;
    }

    if (_selectedPillId == pillId && _selectedCategoryId == null) return;
    
    _selectedPillId = pillId;
    _selectedCategoryId = null; // Clear category filter when switching pills
    
    await prefs.setInt(_pillPersistenceKey, pillId);
    
    final currentState = state;
    if (currentState is! DataLoaded<NewHomeResponse>) return;
    
    final currentFullData = currentState.data;
    emit(DataLoading());

    try {
      final result = await Api.instance.getNavPillData(
        navPillId: pillId,
        limit: _defaultLimit,
      );

      result.fold(
        (failure) {
          emit(DataLoadFailed(failure));
        },
        (jsonData) {
          final dataPart = jsonData['data'];
          InitialData initialData;
          
          if (dataPart != null && dataPart['initial_data'] != null) {
            initialData = InitialData.fromJson(dataPart['initial_data']);
          } else {
            initialData = InitialData.fromJson(dataPart ?? {});
          }
          
          final updatedResponse = NewHomeResponse(
            isSuccess: currentFullData.isSuccess,
            data: NewHomeData(
              navigationPills: currentFullData.data.navigationPills,
              filterArray: currentFullData.data.filterArray,
              initialData: initialData,
            ),
          );

          emit(DataLoaded<NewHomeResponse>(updatedResponse));
        },
      );
    } catch (e) {
      emit(DataLoadFailed(Failure(e.toString())));
    }
  }

  Future<void> filterByCategory(int? categoryId) async {
    _selectedCategoryId = categoryId;
    
    // If resetting all, we revert to pill ID 1 as requested
    if (categoryId == null) {
      _selectedPillId = 1;
      loadHome();
      return;
    }

    final currentState = state;
    if (currentState is! DataLoaded<NewHomeResponse>) return;
    
    final currentFullData = currentState.data;
    emit(DataLoading());

    try {
      // Use the section API for filtering as requested: api/v1/users/section/:section_id
      // "if no section_id then send 1"
      final result = await Api.instance.getSectionModules(
        sectionId: 1, 
        limit: _defaultLimit, 
        categoryId: _selectedCategoryId
      );

      result.fold(
        (failure) {
          emit(DataLoadFailed(failure));
        },
        (jsonData) {
          final dataPart = jsonData['data'];
          InitialData initialData;
          
          if (dataPart != null && dataPart['initial_data'] != null) {
            initialData = InitialData.fromJson(dataPart['initial_data']);
          } else {
            initialData = InitialData.fromJson(dataPart ?? {});
          }
          
          final updatedResponse = NewHomeResponse(
            isSuccess: currentFullData.isSuccess,
            data: NewHomeData(
              navigationPills: currentFullData.data.navigationPills,
              filterArray: currentFullData.data.filterArray,
              initialData: initialData,
            ),
          );

          emit(DataLoaded<NewHomeResponse>(updatedResponse));
        },
      );
    } catch (e) {
      emit(DataLoadFailed(Failure(e.toString())));
    }
  }

  // Prevent multiple simultaneous loads for sections
  bool _isLoadingSections = false;

  Future<void> loadMoreSections() async {
    final currentState = state;
    if (currentState is! DataLoaded<NewHomeResponse>) return;

    if (_isLoadingSections) return;

    final currentData = currentState.data;
    if (!currentData.data.initialData.hasMore) return;

    _isLoadingSections = true;
    final cursor = currentData.data.initialData.nextCursor?.toString() ?? '';

    try {
      final result = _selectedCategoryId != null
          ? await Api.instance.getSectionModules(sectionId: 1, limit: _defaultLimit, cursor: cursor, categoryId: _selectedCategoryId)
          : (_selectedPillId == null || _selectedPillId == 1
              ? await Api.instance.getDramaBoxHome(limit: _defaultLimit, cursor: cursor)
              : await Api.instance.getNavPillData(navPillId: _selectedPillId!, limit: _defaultLimit, cursor: cursor));

      result.fold(
        (failure) {
          _isLoadingSections = false;
        },
        (jsonData) {
          _isLoadingSections = false;
          final dataPart = jsonData['data'];
          InitialData nextInitialData;
          
          if (_selectedCategoryId != null) {
            if (dataPart != null && dataPart['initial_data'] != null) {
              nextInitialData = InitialData.fromJson(dataPart['initial_data']);
            } else {
              nextInitialData = InitialData.fromJson(dataPart ?? {});
            }
          } else if (_selectedPillId == null || _selectedPillId == 1) {
            if (dataPart != null && dataPart['initial_data'] != null) {
              nextInitialData = InitialData.fromJson(dataPart['initial_data']);
            } else {
              nextInitialData = InitialData.fromJson(dataPart ?? {});
            }
          } else {
            if (dataPart != null && dataPart['initial_data'] != null) {
              nextInitialData = InitialData.fromJson(dataPart['initial_data']);
            } else {
              nextInitialData = InitialData.fromJson(dataPart ?? {});
            }
          }
          
          final existingSectionIds = currentData.data.initialData.sections.map((s) => s.id).toSet();
          final uniqueNewSections = nextInitialData.sections.where((s) => !existingSectionIds.contains(s.id)).toList();
          
          final updatedSections = [
            ...currentData.data.initialData.sections,
            ...uniqueNewSections
          ];

          final updatedInitialData = InitialData(
            navPillId: nextInitialData.navPillId,
            sections: updatedSections,
            nextCursor: nextInitialData.nextCursor,
            hasMore: nextInitialData.hasMore,
          );

          final updatedResponse = NewHomeResponse(
            isSuccess: currentData.isSuccess,
            data: NewHomeData(
              navigationPills: currentData.data.navigationPills,
              filterArray: currentData.data.filterArray,
              initialData: updatedInitialData,
            ),
          );

          emit(DataLoaded<NewHomeResponse>(updatedResponse));
        },
      );
    } catch (e) {
      _isLoadingSections = false;
    }
  }

  Future<void> loadMoreModulesForSection(int sectionId) async {
    final currentState = state;
    if (currentState is! DataLoaded<NewHomeResponse>) return;

    if (_loadingSections.contains(sectionId)) return;

    final currentData = currentState.data;
    
    // Find the section and check if it has more
    final sections = currentData.data.initialData.sections;
    final sectionIndex = sections.indexWhere((s) => s.id == sectionId);
    
    if (sectionIndex == -1) return;
    
    final section = sections[sectionIndex];
    if (!section.hasMore || section.nextCursor == null) return;

    _loadingSections.add(sectionId);

    try {
      final result = await Api.instance.getSectionModules(
        sectionId: sectionId,
        limit: 1, // Request 1 module at a time as per user hint
        cursor: section.nextCursor!.toString(),
        categoryId: _selectedCategoryId,
      );

      result.fold(
        (failure) {
          _loadingSections.remove(sectionId);
        },
        (jsonData) {
          _loadingSections.remove(sectionId);
          // The API returns { "isSuccess": true, "data": { "modules": [], "nextCursor": ..., "hasMore": ... } }
          final dataPart = jsonData['data'] ?? {};
          final newModules = (dataPart['modules'] as List<dynamic>?)
                  ?.map((e) => NewHomeModule.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [];
          
          final nextCursor = dataPart['nextCursor'];
          final hasMore = dataPart['hasMore'] ?? false;

          // De-duplicate modules
          final existingModuleIds = section.modules.map((m) => m.id).toSet();
          final uniqueNewModules = newModules.where((m) => !existingModuleIds.contains(m.id)).toList();

          final updatedSection = NewHomeSection(
            id: section.id,
            name: section.name,
            layoutType: section.layoutType,
            aspectRatio: section.aspectRatio,
            position: section.position,
            modules: [...section.modules, ...uniqueNewModules],
            nextCursor: nextCursor,
            hasMore: hasMore,
          );

          final updatedSections = List<NewHomeSection>.from(sections);
          updatedSections[sectionIndex] = updatedSection;

          final updatedInitialData = InitialData(
            navPillId: currentData.data.initialData.navPillId,
            sections: updatedSections,
            nextCursor: currentData.data.initialData.nextCursor,
            hasMore: currentData.data.initialData.hasMore,
          );

          final updatedResponse = NewHomeResponse(
            isSuccess: currentData.isSuccess,
            data: NewHomeData(
              navigationPills: currentData.data.navigationPills,
              filterArray: currentData.data.filterArray,
              initialData: updatedInitialData,
            ),
          );

          emit(DataLoaded<NewHomeResponse>(updatedResponse));
        },
      );
    } catch (e) {
      _loadingSections.remove(sectionId);
    }
  }
}
