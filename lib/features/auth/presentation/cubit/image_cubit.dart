import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class ImageCubit extends Cubit<ImageState>{
  ImageCubit():super(ImageInitial());

  void showImage(String path, bool isImgOnline){
    if(!isImgOnline){
      emit(ImageLoaded(isImgOnline, path));
      return;
    }
    emit(ImageLoading());
  }

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if(image!=null && image.path.isNotEmpty) {
      showImage(image.path,false);
    }
  }
}

abstract class ImageState{}

class ImageInitial extends ImageState{}
class ImageLoading extends ImageState{}

class ImageLoaded extends ImageState{
  final bool isOnline;
  final String path;

  ImageLoaded(this.isOnline, this.path);
}