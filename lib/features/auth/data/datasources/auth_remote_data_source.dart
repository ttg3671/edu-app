import 'package:dio/dio.dart';
import 'package:edu_gym/api/api.dart';
import 'package:edu_gym/core/error/server_exception.dart';

abstract interface class AuthRemoteDataSource{
  Future<String> signUpWithEmailPassword({
    required String name,
    required String email,
    required String password,});

  Future<String> loginWithEmailPassword({
    required String email,
    required String password,});
}

class AuthRemoteSourceImpl implements AuthRemoteDataSource{
  final Api api;
  AuthRemoteSourceImpl(this.api);

  @override
  Future<String> loginWithEmailPassword({required String email, required String password}) {
    //Todo do login
    throw UnimplementedError();
  }

  @override
  Future<String> signUpWithEmailPassword({required String name, required String email, required String password}) async{
    // try{
    //   final response= await api.register(email: email, password: password);
    //   response.fold((failure){
    //     throw failure;
    //   }, (data){
    //     return data.token;
    //   });
    // }
    // on DioException catch(e){
    //   throw ServerException(msg: e.message);
    // }

    return '';
  }

}