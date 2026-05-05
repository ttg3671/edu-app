import 'package:edu_gym/api/api.dart';
import 'package:edu_gym/features/auth/presentation/cubit/login_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_cubit.dart';

// class RegisterCubit extends Cubit<AuthState>{
//
//   RegisterCubit(): super(AuthInitial());
//
//   Future<void> register(String email,String password,String name,String image,String ip) async {
//     // if(validateEmail(email).isNotEmpty){
//     //   emit(RegisterFailed(validateEmail(email)));
//     //   return;
//     // }
//     // if(validatePass(password).isNotEmpty){
//     //   emit(RegisterFailed(validatePass(password)));
//     //   return;
//     // }
//     emit(AuthLoading());
//     bool isSuccess=await Api.instance.register(email: email, password: password,name: name,image: image,ip: ip);
//
//     if(isSuccess){
//       final prefs= await SharedPreferences.getInstance();
//       prefs.setBool('isLoggedIn',true);
//       // prefs.setBool('isEmailVerified',false);
//       prefs.setString('email',email);
//       emit(AuthSuccess());
//     }
//     else{
//       emit(AuthFailed('Wrong email or password'));
//     }
//   }
//
//   Future<void> uploadProfileImg(String email,String password,String name,String path)async {
//     // print('path $path');
//     // if(path.isEmpty){
//     //   emit(AuthFailed('Image is required'));
//     //   return;
//     // }
//     if(name.isEmpty){
//       emit(AuthFailed('Name is required'));
//       return;
//     }
//     emit(AuthLoading());
//     String? img;
//     if(path.isNotEmpty){
//       img= await Api.instance.uploadImage(path);
//       if(img.isEmpty){
//         emit(AuthFailed('Image not uploaded'));
//         return;
//       }
//     }
//     String ip= await Api.instance.getIp();
//     print("$email, $password, $name, $img, $ip");
//     register(email, password, name, img??'', ip);
//   }
//
//   Future<void> validate(String email,String password) async {
//     if(validateEmail(email).isNotEmpty){
//       emit(AuthFailed(validateEmail(email)));
//       return;
//     }
//     if(validatePass(password).isNotEmpty){
//       emit(AuthFailed(validatePass(password)));
//       return;
//     }
//     emit(AuthSuccess());
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