import 'package:edu_gym/api/api.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_cubit.dart';

class PasswordCubit extends Cubit<PasswordState>{
  bool _isVisible=false;

  PasswordCubit():super(PasswordInvisible());

  void toggle(){
    if(_isVisible){
      emit(PasswordInvisible());
      _isVisible=false;
    }
    else{
      emit(PasswordVisible());
      _isVisible=true;
    }
  }

}

// class LoginCubit extends Cubit<AuthState>{
//
//   LoginCubit():super(AuthInitial());
//
//   Future<void> login(String email,String password) async {
//     if(validateEmail(email).isNotEmpty){
//       emit(AuthFailed(validateEmail(email)));
//       return;
//     }
//     if(validatePass(password).isNotEmpty){
//       emit(AuthFailed(validatePass(password)));
//       return;
//     }
//     emit(AuthLoading());
//     bool isSuccess=await Api.instance.login(email: email, password: password);
//
//     if(isSuccess){
//       final prefs= await SharedPreferences.getInstance();
//       prefs.setBool('isLoggedIn',true);
//       prefs.setString('email',email);
//       emit(AuthSuccess());
//     }
//     else{
//       emit(AuthFailed('Wrong email or password'));
//     }
//   }
//
//   String validateEmail(String email){
//     if(email.trim().isEmpty){
//       return "Email can't be empty";
//     }
//     else if(!email.contains('@') || !email.contains('.')){
//       return "Invalid email";
//     }
//     return '';
//   }
//
//   String validatePass(String pass){
//     if(pass.trim().isEmpty){
//       return "Password can't be empty";
//     }
//     else if(pass.length<=4){
//       return "Password length should be more than 4";
//     }
//     return '';
//   }
// }


abstract class PasswordState{}

class PasswordVisible extends PasswordState{}
class PasswordInvisible extends PasswordState{}

