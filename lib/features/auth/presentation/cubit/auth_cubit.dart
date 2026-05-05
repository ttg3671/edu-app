import 'package:edu_gym/api/token_api.dart';
import 'package:edu_gym/features/auth/data/models/auth_model.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../api/api.dart';

class AuthCubit extends Cubit<AuthState>{
  AuthCubit():super(AuthInitial());

  Future<void> login(String email,String password) async {

    final validResponseMsg =validate(email, password);
    if(validResponseMsg.isNotEmpty){
      emit(AuthFailed(validResponseMsg));
      return;
    }
    emit(AuthLoading());
    final res=await Api.instance.login(email: email, password: password);

    res.fold(
            (failure){
              // Show actual error message from API
              String errorMsg = 'Login failed';
              if(failure.response != null && failure.response['message'] != null){
                errorMsg = failure.response['message'];
              } else if(failure.msg != null){
                errorMsg = failure.msg!;
              }
              emit(AuthFailed(errorMsg));
            },
            (data){
              if(data.isSuccess){
                // print('✅ User signed in successfully: ${email}');
                // print('🔑 Access Token: ${data.token}');
                emit(AuthSuccess(authModel: data));
              }
              else{
                // print('❌ Sign-in failed for ${email}: ${data.message}');
                String errorMsg = data.message ?? 'Login Failed';
                emit(AuthFailed(errorMsg));
              }
            }
    );
  }

  Future<void> register(String email,String password,String confirmPassword) async {
    final validResponseMsg = validate(email, password);
    if(validResponseMsg.isNotEmpty){
      emit(AuthFailed(validResponseMsg));
      return;
    }

    if(password != confirmPassword){
      emit(AuthFailed('Passwords do not match'));
      return;
    }

    emit(AuthLoading());
    final res=await Api.instance.register(email: email, password: password, confirmPassword: confirmPassword);

    res.fold(
            (failure){
          // Show actual error message from API
          String errorMsg = 'Registration failed';
          if(failure.response != null && failure.response['message'] != null){
            errorMsg = failure.response['message'];
          } else if(failure.msg != null){
            errorMsg = failure.msg!;
          }
          // print('❌ Registration failed for ${email}: ${errorMsg}');
          emit(AuthFailed(errorMsg));
        },
            (data){
          if(data.isSuccess){
            // print('✅ User registered successfully: ${email}');
            // print('🔑 Access Token: ${data.token}');
            emit(AuthSuccess(authModel: data));
          }
          else{
            // print('❌ Registration failed for ${email}: ${data.message}');
            String errorMsg = data.message ?? 'Register Failed';
            emit(AuthFailed(errorMsg));
          }
        }
    );
  }

  Future<void> updateProfile({
    required String fullName,
    String? profileImage,
    required String bio,
  }) async {
    if(fullName.trim().isEmpty){
      emit(AuthFailed('Name cannot be empty'));
      return;
    }

    emit(AuthLoading());

    String? imageFilename;

    // If profileImage is a local file path (not a URL), upload it first
    if (profileImage != null &&
        profileImage.isNotEmpty &&
        !profileImage.startsWith('http') &&
        !profileImage.contains('person.png')) {
      // print('=== Uploading Image ===');
      // print('Local file path: $profileImage');

      final uploadedImageUrl = await Api.instance.uploadImage(profileImage);

      if (uploadedImageUrl.isEmpty) {
        emit(AuthFailed('Failed to upload image. Please try again.'));
        return;
      }

      // print('Uploaded image URL: $uploadedImageUrl');

      // Extract just the filename from the URL
      // URL format: https://api.edugarciamovimiento.com/fitness/uploads/7accIrSxpbFg0ii.jpg
      // Extract: 7accIrSxpbFg0ii.jpg
      imageFilename = uploadedImageUrl.split('/').last;
      print('Extracted filename: $imageFilename');
    } else if (profileImage != null && profileImage.startsWith('http')) {
      // If it's already a URL (existing image), extract filename
      imageFilename = profileImage.split('/').last;
    }

    final res = await Api.instance.updateUserDetails(
      fullName: fullName,
      profileImage: imageFilename,
      bio: bio,
    );

    res.fold(
      (failure){
        String errorMsg = failure.message ?? 'Failed to update profile';
        emit(AuthFailed(errorMsg));
      },
      (data){
        emit(AuthSuccess());
      }
    );
  }

  Future<void> isLoggedIn() async {
    if(TokenApi.isUserLoggedIn()){
      emit(AuthLoggedIn());
    }
    else{
      emit(AuthNotLoggedIn());
    }
  }

  // Removed uploadProfileImg function - not needed for login/register flow
  // This function was interfering with the authentication process
  // If profile image upload is needed, create a separate ProfileCubit

  String validate(String email,String password){
    if(!EmailValidator.validate(email)){
      return 'Invalid email';
    }
    if(validatePass(password).isNotEmpty){
      return validatePass(password);
    }
    return '';
  }

  String validatePass(String pass){
    if(pass.trim().isEmpty){
      return "Password can't be empty";
    }
    else if(pass.length<=8){
      return "Password length should be more than 8";
    }
    return '';
  }

}

abstract class AuthState{}

class AuthInitial extends AuthState{}

class AuthLoading extends AuthState{}

class AuthSuccess extends AuthState{
  final AuthModel? authModel;

  AuthSuccess({this.authModel});
}

class AuthFailed extends AuthState{
  final String errorMsg;

  AuthFailed(this.errorMsg);
}

class AuthLoggedIn extends AuthState{}
class AuthNotLoggedIn extends AuthState{}