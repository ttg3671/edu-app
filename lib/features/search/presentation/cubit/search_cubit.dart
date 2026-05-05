import 'package:edu_gym/api/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../modal/search_modal.dart';


class SearchCubit extends Cubit<SearchState>{
  final String _key="SEARCHES";
  String searchText='';
  List<String> searchList=[];

  SearchCubit():super(SearchInitial());

  Future<void> search(String s)async {
    searchText=s;
    if(s.trim().isEmpty){
      emit(RecentLoaded(searchList));
      return;
    }

    emit(SearchLoading());
    final res= await Api.instance.searchModules(term: s);
    res.fold((error){
      emit(SearchInitial()); // or error state
    }, (jsonData){
      if(searchText.isEmpty){
        emit(RecentLoaded(searchList));
        return;
      }
      final searchModal = SearchModal.fromJson(jsonData);
      if(state is SearchLoading || searchText==s) {
        emit(SearchLoaded(searchModal));
      }
    });
  }

  Future<void> loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    searchList= prefs.getStringList(_key) ?? [];
    emit(RecentLoaded(searchList));
  }

  Future<void> saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    searchList= prefs.getStringList(_key) ?? [];
    for(String a in searchList){
      if(a.toLowerCase()==searchText.toLowerCase()){
        return;
      }
    }
    searchList.add(searchText);
    await prefs.setStringList(_key, searchList);
    // emit(RecentLoaded(searchList));
  }

  Future<void> clearPrefs() async {
    searchList.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    emit(RecentLoaded([]));
  }


}

abstract class SearchState{}

class SearchInitial extends SearchState{}
class SearchLoading extends SearchState{}
class SearchLoaded extends SearchState{
  final SearchModal searchModal;

  SearchLoaded(this.searchModal);
}

class RecentLoaded extends SearchState{
  final List<String> list;

  RecentLoaded(this.list);
}