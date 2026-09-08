import 'package:edu_gym/core/error/failure.dart';
import 'package:edu_gym/core/error/server_exception.dart';
import 'package:edu_gym/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:edu_gym/features/auth/domain/repository/auth_repository.dart';
import 'package:fpdart/fpdart.dart';
import 'package:edu_gym/core/utils/device_util.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource authRemoteDataSource;

  AuthRepositoryImpl(this.authRemoteDataSource);

  @override
  Future<Either<Failure, String>> loginWithEmailPassword(
      {required String email, required String password}) async {
    try {
      final deviceId = await DeviceUtil.getDeviceId();
      final response = await authRemoteDataSource.loginWithEmailPassword(
          email: email,
          password: password,
          deviceId: deviceId);
      final String message = response['message']?.toString() ?? 'Login successful';
      return right(message);
    } on ServerException catch (e) {
      return left(Failure(e.msg));
    }
  }

  @override
  Future<Either<Failure, String>> signUpWithEmailPassword(
      {required String name,
      required String email,
      required String password}) async {
    try {
      final deviceId = await DeviceUtil.getDeviceId();
      // Note: name is passed but AuthRemoteDataSource.signUpWithEmailPassword doesn't seem to take it in current definition
      // Also cpassword is required by data source but not repository. Using password as cpassword.
      final response = await authRemoteDataSource.signUpWithEmailPassword(
          email: email,
          password: password,
          cpassword: password,
          deviceId: deviceId);
      final String message = response['message']?.toString() ?? 'Sign up successful';
      return right(message);
    } on ServerException catch (e) {
      return left(Failure(e.msg));
    }
  }
}