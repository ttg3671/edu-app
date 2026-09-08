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

    final res = await Api.instance.login(email: email, password: password);

    res.fold(
      (failure){
        emit(AuthFailed(failure.msg ?? ''));
      },
      (data){
        emit(AuthSuccess(
          authModel: data,
          emailVerified: data.emailVerified,
          email: email,
        ));
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

    final res = await Api.instance.register(
      email: email, 
      password: password, 
      confirmPassword: confirmPassword
    );

    res.fold(
      (failure){
        emit(AuthFailed(failure.msg ?? ''));
      },
      (data){
        emit(AuthSuccess(
          authModel: data,
          emailVerified: data.emailVerified,
          email: email,
        ));
      }
    );
  }

  Future<void> updateProfile({
    required String fullName,
    required String bio,
    String? avatarUrl,
  }) async {
    if(fullName.trim().isEmpty){
      emit(AuthFailed('Name cannot be empty'));
      return;
    }

    emit(AuthLoading());

    final res = await Api.instance.updateUserDetails(
      fullName: fullName,
      profileImage: avatarUrl,
      bio: bio,
    );

    res.fold(
      (failure){
        emit(AuthFailed(failure.message ?? failure.msg ?? ''));
      },
      (data) async {
        // Surgically update local storage name/bio/avatarUrl
        await TokenApi().updateLocalProfile(name: fullName, bio: bio, avatarUrl: avatarUrl);
        emit(AuthSuccess());
      }
    );
  }

  Future<void> isLoggedIn() async {
    final token = await TokenApi.getCookie();
    if(token != null && token.isNotEmpty){
      emit(AuthLoggedIn());
    }
    else{
      emit(AuthNotLoggedIn());
    }
  }

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
    else if(pass.length<8){
      return "Password length should be at least 8";
    }
    return '';
  }

}

abstract class AuthState{}

class AuthInitial extends AuthState{}

class AuthLoading extends AuthState{}

class AuthSuccess extends AuthState{
  final AuthModel? authModel;
  final bool emailVerified;
  final String email;

  AuthSuccess({
    this.authModel,
    this.emailVerified = true,
    this.email = '',
  });
}

class AuthFailed extends AuthState{
  final String errorMsg;

  AuthFailed(this.errorMsg);
}

class AuthLoggedIn extends AuthState{}
class AuthNotLoggedIn extends AuthState{}