import 'package:edu_gym/core/error/failure.dart';
import 'package:edu_gym/core/usecase/usecase.dart';
import 'package:edu_gym/features/auth/domain/repository/auth_repository.dart';
import 'package:fpdart/fpdart.dart';

class UserSignUp implements UseCase<String,UserSignUpParams>{
  final AuthRepository authRepository;

  UserSignUp(this.authRepository);

  @override
  Future<Either<Failure, String>> call(UserSignUpParams params) async{
    return await authRepository.signUpWithEmailPassword(name: params.name,
        email: params.email, password: params.password);
  }
}

class UserSignUpParams{
  final String name;
  final String email;
  final String password;

  UserSignUpParams({required this.name,required this.email, required this.password, });


}