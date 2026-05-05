import 'package:edu_gym/core/error/failure.dart';
import 'package:edu_gym/core/error/server_exception.dart';
import 'package:edu_gym/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:edu_gym/features/auth/domain/repository/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

class AuthRepositoryImpl implements AuthRepository{
  final AuthRemoteDataSource authRemoteDataSource;

  AuthRepositoryImpl(this.authRemoteDataSource);

  @override
  Future<Either<Failure, String>> loginWithEmailPassword({required String email, required String password}) {
    // TODO: implement loginWithEmailPassword
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, String>> signUpWithEmailPassword({required String name, required String email, required String password}) async{
    try{
      final response= await authRemoteDataSource.signUpWithEmailPassword(name: name, email: email, password: password);
      return right(response);
    }
    on ServerException catch(e){
      return left(Failure(e.msg));
    }
  }
  
}