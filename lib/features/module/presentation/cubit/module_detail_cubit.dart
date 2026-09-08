import 'package:edu_gym/api/api.dart';
import 'package:edu_gym/core/cubit_states/data_state.dart';
import 'package:edu_gym/modal/module_detail_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ModuleDetailCubit extends Cubit<DataState> {
  ModuleDetailCubit() : super(DataInitial());

  Future<void> loadData(int moduleId) async {
    emit(DataLoading());

    final res = await Api.instance.getModuleDetails(moduleId: moduleId);

    res.fold(
      (error) {
        debugPrint('❌ Failed to load module detail data: ${error.message}');
        emit(DataLoadFailed(error));
      },
      (moduleDetail) {
        debugPrint('✅ Loaded module details for id: ${moduleDetail.id}, title: ${moduleDetail.title}');
        emit(DataLoaded<ModuleDetailModel>(moduleDetail));
      },
    );
  }
}
