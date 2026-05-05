import 'package:edu_gym/core/cubit_states/data_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../api/api.dart';

class LessonCubit extends Cubit<DataState>{
  LessonCubit():super(DataInitial());

  Future<void> loadData(int lessonId) async {
    emit(DataLoading());
    final res= await Api.instance.lessonById(id: lessonId, page: '1',);
    res.fold((error){
      emit(DataLoadFailed(error));
    }, (data){
      emit(DataLoaded(data));
    });
  }

}