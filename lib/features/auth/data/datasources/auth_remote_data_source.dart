import 'package:dio/dio.dart';
import 'package:edu_gym/api/api.dart';
import 'package:edu_gym/core/error/server_exception.dart';
import 'package:edu_gym/core/utils/device_util.dart';

abstract interface class AuthRemoteDataSource{
  Future<Map<String, dynamic>> signUpWithEmailPassword({
    required String email,
    required String password,
    required String cpassword,
    required String deviceId,
  });

  Future<Map<String, dynamic>> loginWithEmailPassword({
    required String email,
    required String password,
    required String deviceId,
  });
}

class AuthRemoteSourceImpl implements AuthRemoteDataSource{
  final Dio _dio = Dio(BaseOptions(
    baseUrl: Api.baseUrl,
    headers: {
      'x-device-type': DeviceUtil.getDeviceType(),
    },
  ));

  @override
  Future<Map<String, dynamic>> loginWithEmailPassword({
    required String email,
    required String password,
    required String deviceId,
  }) async {
    try {
      final response = await _dio.post('/auth/sign-in', data: {
        'email': email,
        'password': password,
        'device_id': deviceId,
      });

      if (response.data['isSuccess']) {
        return response.data;
      } else {
        throw ServerException(msg: response.data['message'] ?? 'Login failed');
      }
    } on DioException catch (e) {
      throw ServerException(msg: e.response?.data['message'] ?? e.message);
    } catch (e) {
      throw ServerException(msg: e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> signUpWithEmailPassword({
    required String email,
    required String password,
    required String cpassword,
    required String deviceId,
  }) async {
    try {
      final response = await _dio.post('/auth/sign-up', data: {
        'email': email,
        'password': password,
        'cpassword': cpassword,
        'device_id': deviceId,
      });

      if (response.data['isSuccess']) {
        return response.data;
      } else {
        throw ServerException(msg: response.data['message'] ?? 'Sign up failed');
      }
    } on DioException catch (e) {
      throw ServerException(msg: e.response?.data['message'] ?? e.message);
    } catch (e) {
      throw ServerException(msg: e.toString());
    }
  }
}