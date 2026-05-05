import 'package:flutter_bloc/flutter_bloc.dart';

class ShowHideVideoCubit extends Cubit<bool> {
  ShowHideVideoCubit():super(false);

  void changeState(){
    emit(!state);
  }
}

class ShowHideWidgetCubit extends Cubit<bool> {
  ShowHideWidgetCubit():super(true);

  void changeState(){
    emit(!state);
  }
}