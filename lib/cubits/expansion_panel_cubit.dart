import 'package:flutter_bloc/flutter_bloc.dart';


class ExpansionPanelCubit extends Cubit<bool>{
  ExpansionPanelCubit():super(false);

  void expansion(){
    // print(isExpanded);
    emit(!state);
  }

}