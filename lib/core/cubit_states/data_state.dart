abstract class DataState{}

class DataInitial extends DataState{}
class DataLoading extends DataState{}
class DataLoaded<T> extends DataState{
  final T data;

  DataLoaded(this.data);
}
class DataLoadFailed<T> extends DataState{
  final T error;

  DataLoadFailed(this.error);
}
