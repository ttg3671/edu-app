import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class AppBarState{}
class ExpandedBar extends AppBarState{}
class CollapsedBar extends AppBarState{}

class AppbarCubit extends Cubit<AppBarState>{
  AppbarCubit():super(ExpandedBar());

  void onScroll(ScrollController scrollController){
    scrollController.addListener((){
      if(scrollController.offset>50){
        emit(CollapsedBar());
      }
      else{
        emit(ExpandedBar());
      }
    });
  }

}