import 'package:edu_gym/core/error/friendly_error.dart';
import 'package:edu_gym/api/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

class ImageCubit extends Cubit<ImageState> {
  ImageCubit() : super(ImageInitial());

  String? _currentImageUrl;
  String? get currentImageUrl => _currentImageUrl;

  void setInitialImage(String? imageUrl) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      _currentImageUrl = imageUrl;
      emit(ImageLoaded(true, imageUrl));
    }
  }

  void showImage(String path, bool isImgOnline) {
    if (!isImgOnline) {
      emit(ImageLoaded(isImgOnline, path));
      return;
    }
    emit(ImageLoading());
  }

  Future<String?> pickAndUploadImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null || image.path.isEmpty) {
        return null;
      }

      // Show local image preview while uploading
      emit(ImageUploading(image.path));

      final uploadResult = await Api.instance.uploadImageToCloudinary(image.path);

      return uploadResult.fold(
        (failure) {
          emit(ImageUploadFailed(failure.message ?? 'Upload failed', localPath: image.path));
          return null;
        },
        (uploadedUrl) {
          _currentImageUrl = uploadedUrl;
          emit(ImageLoaded(true, uploadedUrl, localPath: image.path));
          return uploadedUrl;
        },
      );
    } catch (e) {
      emit(ImageUploadFailed(
          FriendlyError.clean(e.toString()) ?? FriendlyError.networkError));
      return null;
    }
  }
}

abstract class ImageState {}

class ImageInitial extends ImageState {}

class ImageLoading extends ImageState {}

class ImageUploading extends ImageState {
  final String localPath;
  ImageUploading(this.localPath);
}

class ImageLoaded extends ImageState {
  final bool isOnline;
  final String path;
  final String? localPath;

  ImageLoaded(this.isOnline, this.path, {this.localPath});
}

class ImageUploadFailed extends ImageState {
  final String errorMsg;
  final String? localPath;

  ImageUploadFailed(this.errorMsg, {this.localPath});
}