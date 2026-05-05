import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:edu_gym/api/token_api.dart';
import 'package:edu_gym/core/error/failure.dart';
import 'package:edu_gym/modal/module.dart';
import 'package:edu_gym/modal/search_modal.dart';
import 'package:edu_gym/modal/user_details.dart';
import 'package:fpdart/fpdart.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../core/error/server_exception.dart';
import '../features/auth/data/models/auth_model.dart';
import '../features/auth/domain/entities/user.dart';
import '../modal/lesson.dart';

class Api{

  static final _api= Api();
  final _dio= Dio(
    BaseOptions(
      baseUrl: baseUrl
    )
  );
  static const accessTokenKey="Access_Token";
  static const refreshTokenKey="Refresh_Token";
  static const deviceIdKey="Device_Id";
  static const baseUrl='https://api.edugarciamovimiento.com/api/v1';
  static const imgBaseUrl='https://admin.edugarciamovimiento.com/fitness/uploads';

  static Api get instance =>_api;

  bool _isAccessTokenExpired(String? token){
    if (token==null || token.isEmpty) {
      return true;
    }
    return JwtDecoder.isExpired(token);
  }

  Future<void> _saveToken({String? accessToken, String? refreshToken}) async {
    final prefs= await SharedPreferences.getInstance();
    prefs.setString(Api.accessTokenKey, accessToken??'');
    prefs.setString(Api.refreshTokenKey, refreshToken??'');
  }

  Future<void> logout() async {
    try {
      final deviceId = await _getOrCreateDeviceId();
      final accessToken = await TokenApi().getAccessToken();

      // Only call logout API if we have a valid token
      if (accessToken != null && accessToken.isNotEmpty) {
        final data = jsonEncode({
          'device_id': deviceId,
        });

        var headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        };

        var response = await _dio.request(
          '$baseUrl/logout',
          options: Options(
            method: 'POST',
            headers: headers,
            validateStatus: (_) => true, // Accept all status codes, handle errors gracefully
          ),
          data: data,
        );

        // Check if logout was successful (optional - we proceed with local cleanup regardless)
        if (response.statusCode == 200) {
          // Logout successful
        }
        // If 401 or other error, we'll still clear local data below
      }
    } catch (e) {
      // Silently handle any network errors - we'll clear local data regardless
    }

    // Clear local tokens and cookies regardless of API response
    await deleteToken();
    await TokenApi().deleteCookie();
  }

  Future<Either<Failure, bool>> deleteAccount() async {
    try {
      final accessToken = await TokenApi().getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        print('Access token is null or empty - user needs to login again');
        return left(Failure('Authentication failed. Please login again.'));
      }

      var headers = {
        'Authorization': 'Bearer $accessToken',
      };

      var response = await _dio.request(
        '$baseUrl/remove-session/user',
        options: Options(
          method: 'DELETE',
          headers: headers,
        ),
      );

      if (response.statusCode == 200) {
        // Clear local tokens and cookies after successful deletion
        await deleteToken();
        await TokenApi().deleteCookie();
        return right(true);
      } else {
        throw ServerException(
          msg: response.data['message'] ?? 'Failed to delete account',
          statusCode: response.statusCode,
          response: response.data,
        );
      }
    } on DioException catch (e) {
      return left(Failure(e.response?.data['message'] ?? e.message ?? 'Failed to delete account'));
    } on ServerException catch (e) {
      return left(Failure(e.msg));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> updateProfileDetails({
    required String name,
    required String bio,
    String avatarUrl = "",
  }) async {
    try {
      final deviceId = await _getOrCreateDeviceId();
      final accessToken = await TokenApi().getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        return left(Failure('Authentication failed. Please login again.'));
      }

      var headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

      final data = jsonEncode({
        "device_id": deviceId,
        "name": name,
        "bio": bio,
        "avatar_url": avatarUrl,
      });

      print('📡 Making Update Profile API call to: $baseUrl/profile/details');

      var response = await _dio.request(
        '$baseUrl/profile/details',
        options: Options(
          method: 'PUT',
          headers: headers,
        ),
        queryParameters: {'device_id': deviceId},
        data: data,
      );

      if (response.statusCode == 200) {
        return right(response.data);
      } else {
        throw ServerException(
          msg: response.data['message'] ?? 'Failed to update profile',
          statusCode: response.statusCode,
          response: response.data,
        );
      }
    } on DioException catch (e) {
      return left(Failure(e.response?.data['message'] ?? e.message ?? 'Failed to update profile'));
    } on ServerException catch (e) {
      return left(Failure(e.msg));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> getConnectedDevices() async {
    try {
      print('📡 Making Connected Devices API call to: $baseUrl/devices/connected-device');

      final response = await _hitApi(
        route: '/devices/connected-device',
        method: 'GET',
      );

      if (response.statusCode == 200) {
        return right(response.data);
      } else {
        throw ServerException(
          msg: response.data['message'] ?? 'Failed to get connected devices',
          statusCode: response.statusCode,
          response: response.data,
        );
      }
    } on DioException catch (e) {
      return left(Failure(e.response?.data['message'] ?? e.message ?? 'Failed to get connected devices'));
    } on ServerException catch (e) {
      return left(Failure(e.msg));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> removeDevice({
    required String deviceIdToRemove,
  }) async {
    try {
      final currentDeviceId = await _getOrCreateDeviceId();

      final data = jsonEncode({
        "current_device_id": currentDeviceId,
        "device_id": deviceIdToRemove,
      });

      print('📡 Making Remove Device API call to: $baseUrl/devices/remove-device');

      final response = await _hitApi(
        route: '/devices/remove-device',
        method: 'POST',
        data: data,
      );

      if (response.statusCode == 200) {
        return right(response.data);
      } else {
        throw ServerException(
          msg: response.data['message'] ?? 'Failed to remove device',
          statusCode: response.statusCode,
          response: response.data,
        );
      }
    } on DioException catch (e) {
      return left(Failure(e.response?.data['message'] ?? e.message ?? 'Failed to remove device'));
    } on ServerException catch (e) {
      return left(Failure(e.msg));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Future<void> deleteToken() async {
    final prefs= await SharedPreferences.getInstance();
    prefs.remove(Api.accessTokenKey);
    prefs.remove(Api.refreshTokenKey);
    UserDetails.isLoggedIn=false;
  }

  Future<String?> get _refreshToken async {
    final prefs= await SharedPreferences.getInstance();
    return prefs.getString(Api.refreshTokenKey);
  }

  Future<bool> isLoggedIn() async{
    if(await _refreshToken==null) return false;
    return true;
  }

  Future<String?> get _accessToken async {
    final prefs= await SharedPreferences.getInstance();
    return prefs.getString(Api.accessTokenKey);
  }

  Future<String> _getOrCreateDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(deviceIdKey);

    // Validate existing device ID length (must be 9-12 characters)
    if (deviceId == null || deviceId.isEmpty || deviceId.length < 9 || deviceId.length > 12) {
      deviceId = _generateDeviceId();
      await prefs.setString(deviceIdKey, deviceId);
    }

    return deviceId;
  }

  String _generateDeviceId() {
    final random = Random.secure();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

    // Generate device ID with length between 9 and 12
    final length = 9 + random.nextInt(4); // Random length: 9, 10, 11, or 12

    return List.generate(length, (_) => chars[random.nextInt(chars.length)]).join();
  }

  Future<String> _getDeviceName() async {
    try {
      String baseName;

      if (Platform.isAndroid) {
        baseName = 'Android';
      } else if (Platform.isIOS) {
        baseName = 'iOS';
      } else if (Platform.isWindows) {
        baseName = 'Windows';
      } else if (Platform.isMacOS) {
        baseName = 'macOS';
      } else if (Platform.isLinux) {
        baseName = 'Linux';
      } else {
        baseName = 'Device';
      }

      // Add random suffix to make it unique and ensure length is 9-15
      final random = Random.secure();
      final suffix = List.generate(4, (_) => random.nextInt(10)).join();
      final deviceName = '$baseName-$suffix';

      // Ensure device name is between 9 and 15 characters
      return _validateDeviceName(deviceName);
    } catch (e) {
      return _validateDeviceName('Device-${Random().nextInt(10000)}');
    }
  }

  String _validateDeviceName(String name) {
    // Ensure device name length is between 9 and 15 characters
    if (name.length < 9) {
      // Pad with random characters if too short
      final random = Random.secure();
      const chars = '0123456789';
      final padding = List.generate(
        9 - name.length,
        (_) => chars[random.nextInt(chars.length)]
      ).join();
      return '$name$padding';
    } else if (name.length > 15) {
      // Truncate if too long
      return name.substring(0, 15);
    }
    return name;
  }

  Future<String> _getRefreshedAccessToken()async {
    final accessToken = await TokenApi().getAccessToken();
    return accessToken ?? '';
  }

  Future<Either<ServerException,AuthModel>> login({required String email, required String password})async {

    try{
      final deviceId = await _getOrCreateDeviceId();
      final deviceName = await _getDeviceName();

      final data = jsonEncode({
        'email': email,
        'password': password,
        'device_id': deviceId,
        'device_name': deviceName,
      });

      var headers = {
        'Content-Type': 'application/json',
      };

      var response = await _dio.request(
        '$baseUrl/auth/sign-in',
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
      );

      if (response.statusCode == 200) {
        final authModel = AuthModel.fromJson(response.data);
        if(authModel.token!=null) {

          final setCookie = response.headers['set-cookie'];
          if (setCookie != null && setCookie.isNotEmpty) {
            final fullCookie = setCookie.first;
            // The cookie might contain more than just the key=value (e.g., ; Path=/; HttpOnly)
            // But for the refresh call, we often just need the first part or the whole thing
            final cookieKeyValue = fullCookie.split(';').first;
            print('🍪 Cookie extracted: $cookieKeyValue');
            await TokenApi().saveTokens(accessToken: authModel.token!, cookie: cookieKeyValue, email: email);
          }
        }
        return right(authModel);
      } else {
        throw ServerException(
          msg: response.statusMessage,
          statusCode: response.statusCode,
          response: response.data
        );
      }
    }
    on DioException catch(e){
      return left(ServerException(
        msg: e.message,
        response: e.response?.data
      ));
    }
    on ServerException catch(e){
      return left(e);
    }
  }


  Future<Either<ServerException,AuthModel>> register({
    required String email,
    required String password,
    required String confirmPassword,
  })async {

    try{
      final deviceId = await _getOrCreateDeviceId();
      final deviceName = await _getDeviceName();

      final data = jsonEncode({
        'email': email,
        'password': password,
        'cpassword': confirmPassword,
        'device_id': deviceId,
        'device_name': deviceName,
      });

      var headers = {
        'Content-Type': 'application/json',
      };

      var response = await _dio.request(
        '$baseUrl/auth/sign-up',
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
      );

      if (response.statusCode == 200) {
        final authModel = AuthModel.fromJson(response.data);
        if(authModel.token!=null) {
          final setCookie = response.headers['set-cookie'];
          if (setCookie != null && setCookie.isNotEmpty) {
            final fullCookie = setCookie.first;
            final cookieKeyValue = fullCookie.split(';').first;
            print('🍪 Cookie extracted (register): $cookieKeyValue');
            await TokenApi().saveTokens(accessToken: authModel.token!, cookie: cookieKeyValue, email: email);
          }
        }
        return right(authModel);
      } else {
        throw ServerException(
          msg: response.statusMessage,
          statusCode: response.statusCode,
          response: response.data
        );
      }
    }
    on DioException catch(e){
      return left(ServerException(
        msg: e.message,
        response: e.response?.data
      ));
    }
    on ServerException catch(e){
      return left(e);
    }
  }

  Future<Either<Failure, String>> sendOtp({required String email}) async {
    try {
      final data = jsonEncode({
        'email': email,
      });

      var headers = {
        'Content-Type': 'application/json',
      };

      var response = await _dio.request(
        '$baseUrl/auth/send',
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
      );

      if (response.statusCode == 200 && response.data['isSuccess'] == true) {
        final token = response.data['token'];

        // Store OTP token
        await TokenApi.saveOtpToken(token);

        return right(token);
      } else {
        throw ServerException(
          msg: response.data['message'] ?? 'Failed to send OTP',
          statusCode: response.statusCode,
          response: response.data,
        );
      }
    } on DioException catch (e) {
      return left(Failure(e.response?.data['message'] ?? e.message ?? 'Failed to send OTP'));
    } on ServerException catch (e) {
      return left(Failure(e.msg));
    }
  }

  Future<Either<Failure, bool>> verifyOtp({required String otp}) async {
    try {
      // Get stored OTP token
      final otpToken = await TokenApi.getOtpToken();

      if (otpToken == null || otpToken.isEmpty) {
        return left(Failure('No OTP token found. Please request OTP again.'));
      }

      final data = jsonEncode({
        'token': otpToken,
        'otp': otp,
      });

      var headers = {
        'Content-Type': 'application/json',
      };

      var response = await _dio.request(
        '$baseUrl/mail/verify',
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
      );

      if (response.statusCode == 200 && response.data['isSuccess'] == true) {
        await TokenApi.deleteOtpToken();

        // Save password reset token for the next step
        final passwordResetToken = response.data['token'];
        if (passwordResetToken != null && passwordResetToken.isNotEmpty) {
          await TokenApi.savePasswordResetToken(passwordResetToken);
        }

        return right(true);
      } else {
        throw ServerException(
          msg: response.data['message'] ?? 'Invalid OTP',
          statusCode: response.statusCode,
          response: response.data,
        );
      }
    } on DioException catch (e) {
      return left(Failure(e.response?.data['message'] ?? e.message ?? 'Failed to verify OTP'));
    } on ServerException catch (e) {
      return left(Failure(e.msg));
    }
  }

  Future<Either<Failure, bool>> resetPassword({required String newPassword}) async {
    try {
      // Get stored password reset token (pwdtoken from verifyOtp)
      final pwdToken = await TokenApi.getPasswordResetToken();

      if (pwdToken == null || pwdToken.isEmpty) {
        return left(Failure('No reset token found. Please restart the password reset process.'));
      }

      final data = jsonEncode({
        'password': newPassword,
        'cpassword': newPassword,
      });

      var headers = {
        'Authorization': 'Bearer $pwdToken',
        'Content-Type': 'application/json',
      };

      var response = await _dio.request(
        '$baseUrl/forget/reset',
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
      );

      if (response.statusCode == 200 && response.data['isSuccess'] == true) {
        // Delete password reset token
        await TokenApi.deletePasswordResetToken();

        // Save access token and cookies (user is now logged in)
        final accessToken = response.data['token'];
        if (accessToken != null && accessToken.isNotEmpty) {

          final setCookie = response.headers['set-cookie'];
          if (setCookie != null && setCookie.isNotEmpty) {
            final fullCookie = setCookie.first;
            final cookieKeyValue = fullCookie.split(';').first;
            await TokenApi().saveTokens(
              accessToken: accessToken,
              cookie: cookieKeyValue,
            );
          }
        }

        return right(true);
      } else {
        throw ServerException(
          msg: response.data['message'] ?? 'Failed to reset password',
          statusCode: response.statusCode,
          response: response.data,
        );
      }
    } on DioException catch (e) {
      return left(Failure(e.response?.data['message'] ?? e.message ?? 'Failed to reset password'));
    } on ServerException catch (e) {
      return left(Failure(e.msg));
    }
  }

  Future<String> uploadImage(String filePath) async {
    try {
      String url = 'https://api.edugarciamovimiento.com/fitness/uploadImage.php';

      FormData formData = FormData.fromMap({
        'fileToUpload': await MultipartFile.fromFile(filePath, filename: 'upload.jpg'),
      });
      final response = await _dio.post(url, data: formData);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.data);
        return json['isSuccess'] ? json['image'] : '';
      }
    } catch (e) {
      print('Error during image upload: $e');
    }
    return '';
  }

  // New DramaBox API method
  Future<Either<Failure, Map<String, dynamic>>> getDramaBoxHome({
    int? limit,
    String? cursor,
    int? categoryId,
  }) async {
    try {
      final accessToken = await TokenApi().getAccessToken();

      Map<String, dynamic>? headers;
      if (accessToken != null && accessToken.isNotEmpty) {
        headers = {
          'Authorization': 'Bearer $accessToken',
        };
      }

      var queryParameters = <String, dynamic>{};
      if (limit != null) queryParameters['limit'] = limit.toString();
      if (cursor != null && cursor.isNotEmpty) queryParameters['cursor'] = cursor;
      if (categoryId != null) queryParameters['category_id'] = categoryId.toString();

      var response = await _dio.request(
        '$baseUrl/users/home',
        options: Options(
          method: 'GET',
          headers: headers,
        ),
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        return right(response.data);
      } else {
        throw ServerException(
          msg: response.statusMessage,
          statusCode: response.statusCode,
          response: response.data
        );
      }
    } on DioException catch (e) {
      return left(Failure(e.message));
    } on ServerException catch (e) {
      return left(Failure(e.msg));
    } catch (e) {
      return left(Failure('Unexpected error: ${e.toString()}'));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> getNavPillData({
    required int navPillId,
    int limit = 2,
    String? cursor,
    int? categoryId,
  }) async {
    try {
      final accessToken = await TokenApi().getAccessToken();
      Map<String, dynamic>? headers;
      if (accessToken != null && accessToken.isNotEmpty) {
        headers = {'Authorization': 'Bearer $accessToken'};
      }

      var queryParameters = <String, dynamic>{'limit': limit.toString()};
      if (cursor != null && cursor.isNotEmpty) queryParameters['cursor'] = cursor;
      if (categoryId != null) queryParameters['category_id'] = categoryId.toString();

      var response = await _dio.request(
        '$baseUrl/users/nav-pill/$navPillId',
        options: Options(
          method: 'GET',
          headers: headers,
        ),
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        return right(response.data);
      } else {
        throw ServerException(
          msg: response.statusMessage,
          statusCode: response.statusCode,
          response: response.data,
        );
      }
    } on DioException catch (e) {
      return left(Failure(e.message));
    } on ServerException catch (e) {
      return left(Failure(e.msg));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> getSectionModules({
    required int sectionId,
    int limit = 10,
    String? cursor,
    int? categoryId,
  }) async {
    try {
      final accessToken = await TokenApi().getAccessToken();
      Map<String, dynamic>? headers;
      if (accessToken != null && accessToken.isNotEmpty) {
        headers = {'Authorization': 'Bearer $accessToken'};
      }

      var queryParameters = <String, dynamic>{'limit': limit.toString()};
      if (cursor != null && cursor.isNotEmpty) queryParameters['cursor'] = cursor;
      if (categoryId != null) queryParameters['category_id'] = categoryId.toString();

      var response = await _dio.request(
        '$baseUrl/users/section/$sectionId',
        options: Options(
          method: 'GET',
          headers: headers,
        ),
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        return right(response.data);
      } else {
        throw ServerException(
          msg: response.statusMessage,
          statusCode: response.statusCode,
          response: response.data,
        );
      }
    } on DioException catch (e) {
      return left(Failure(e.message));
    } on ServerException catch (e) {
      return left(Failure(e.msg));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> searchModules({
    required String term,
    int limit = 10,
    String? cursor,
  }) async {
    try {
      final accessToken = await TokenApi().getAccessToken();
      Map<String, dynamic>? headers;
      if (accessToken != null && accessToken.isNotEmpty) {
        headers = {'Authorization': 'Bearer $accessToken'};
      }

      var queryParameters = <String, dynamic>{
        'term': term,
        'limit': limit.toString(),
      };
      if (cursor != null && cursor.isNotEmpty) queryParameters['cursor'] = cursor;

      var response = await _dio.request(
        '$baseUrl/users/search',
        options: Options(
          method: 'GET',
          headers: headers,
        ),
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        return right(response.data);
      } else {
        throw ServerException(
          msg: response.statusMessage,
          statusCode: response.statusCode,
          response: response.data,
        );
      }
    } on DioException catch (e) {
      return left(Failure(e.message));
    } on ServerException catch (e) {
      return left(Failure(e.msg));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> getLessonVideo({
    required String videoProviderId,
    required String uiStyle,
  }) async {
    try {
      final accessToken = await TokenApi().getAccessToken();
      Map<String, dynamic>? headers;
      if (accessToken != null && accessToken.isNotEmpty) {
        headers = {'Authorization': 'Bearer $accessToken'};
      }

      var response = await _dio.request(
        '$baseUrl/users/lesson/$videoProviderId/$uiStyle',
        options: Options(
          method: 'GET',
          headers: headers,
        ),
      );

      if (response.statusCode == 200) {
        return right(response.data);
      } else {
        throw ServerException(
          msg: response.statusMessage,
          statusCode: response.statusCode,
          response: response.data,
        );
      }
    } on DioException catch (e) {
      return left(Failure(e.message));
    } on ServerException catch (e) {
      return left(Failure(e.msg));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> getModuleLessons({
    required int moduleId,
    int limit = 4,
    String? cursor,
    int? syllabusId,
  }) async {
    try {
      final accessToken = await TokenApi().getAccessToken();
      Map<String, dynamic>? headers;
      if (accessToken != null && accessToken.isNotEmpty) {
        headers = {'Authorization': 'Bearer $accessToken'};
      }

      var queryParameters = <String, dynamic>{'limit': limit.toString()};
      if (cursor != null && cursor.isNotEmpty) queryParameters['cursor'] = cursor;
      if (syllabusId != null) queryParameters['syllabus_id'] = syllabusId.toString();

      var response = await _dio.request(
        '$baseUrl/users/modules-lessons/$moduleId',
        options: Options(
          method: 'GET',
          headers: headers,
        ),
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        return right(response.data);
      } else {
        throw ServerException(
          msg: response.statusMessage,
          statusCode: response.statusCode,
          response: response.data,
        );
      }
    } on DioException catch (e) {
      return left(Failure(e.message));
    } on ServerException catch (e) {
      return left(Failure(e.msg));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  // Load more data for a specific section filter
  Future<Either<Failure, Map<String, dynamic>>> loadMoreSectionData({
    required int sectionId,
    required int filterId,
    required String cursor,
    int limit = 10,
  }) async {
    try {
      final accessToken = await TokenApi().getAccessToken();

      Map<String, dynamic>? headers;
      if (accessToken != null && accessToken.isNotEmpty) {
        headers = {
          'Authorization': 'Bearer $accessToken',
        };
      }

      var queryParameters = <String, dynamic>{
        'cursor': cursor,
        'limit': limit.toString(),
        'filter_id': filterId.toString(),
      };

      var response = await _dio.request(
        '$baseUrl/users/section/$sectionId',
        options: Options(
          method: 'GET',
          headers: headers,
        ),
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        return right(response.data);
      } else {
        throw ServerException(
          msg: response.statusMessage,
          statusCode: response.statusCode,
          response: response.data
        );
      }
    } on DioException catch (e) {
      return left(Failure(e.message));
    } on ServerException catch (e) {
      return left(Failure(e.msg));
    } catch (e) {
      return left(Failure('Unexpected error: ${e.toString()}'));
    }
  }

  Future<Either<Failure,Module>> getModuleById({
    required int id,
    int syllabusLimit = 5,
    int lessonsLimit = 3,
    String? syllabusCursor,
    Map<int, dynamic>? lessonsCursors, // Map of syllabusId to cursor
  })async {
    try{
      // Build query parameters with cursor-based pagination
      final queryParams = <String, dynamic>{
        'syllabus_limit': syllabusLimit,
        'lessons_limit': lessonsLimit,
      };

      // Add syllabus cursor
      if (syllabusCursor != null && syllabusCursor.isNotEmpty) {
        queryParams['syllabus_cursor'] = syllabusCursor;
      } else {
        queryParams['syllabus_cursor'] = '';
      }

      // Add dynamic lessons_cursor parameters for each syllabus
      if (lessonsCursors != null && lessonsCursors.isNotEmpty) {
        lessonsCursors.forEach((syllabusId, cursor) {
          queryParams['lessons_cursor[$syllabusId]'] = cursor?.toString() ?? '';
        });
      }

      final response = await _hitApi(
        route: '/users/modules-lessons/$id',
        queryParameters: queryParams,
      );

      Map<String,dynamic> json= response.data;

      if(json['isSuccess']){
        final module=Module.fromJson(json['data']);
        return right(module);
      }
      else{
        return left(Failure('Failed to load module'));
      }

    }
    on ServerException catch(e){
      return left(Failure(e.msg));
    }
    catch(e){
      return left(Failure('Failed to load module: $e'));
    }
  }

  Future<Either<Failure,Lesson>> lessonById({
    required int id, required String page,})async {

    try{
      final response = await _hitApi(route: 'users/lesson/$id',
          queryParameters: {
            'page': page
          }
      );
      Map<String,dynamic> json= response.data;
      if(json['isSuccess']){
        final lesson=Lesson.fromJson(json['data']);
        return right(lesson);
      }
      else{
        return left(Failure());
      }
    }
    on ServerException catch(e){
      return left(Failure(e.msg));
    }
  }

  Future<Either<Failure,SearchModal>> search(
    String term, {
    int pageItems = 10,
    int pageNumber = 1,
  }) async {
    try{
      final queryParams = {
        'term': term,
        'page_items': pageItems,
        'pgNo': pageNumber,
      };

      final response = await _hitApi(
        route: '/users/search',
        queryParameters: queryParams,
      );

      Map<String,dynamic> json= response.data;
      if(json['isSuccess']){
        final searchModal= SearchModal.fromJson(json['data']);
        return right(searchModal);
      }
      else{
        return left(Failure());
      }

    }
    on ServerException catch(e){
      return left(Failure(e.msg));
    }
  }

  Future<Either<Failure,UserDetails>> userDetails() async {
    try{
      final deviceId = await _getOrCreateDeviceId();

      final response = await _hitApi(
        route: '/profile/details',
        method: 'GET',
        queryParameters: {'device_id': deviceId},
      );

      Map<String,dynamic> json = response.data;
      if (json['isSuccess']) {
        return right(UserDetails.fromJson(json['data']));
      } else {
        throw ServerException(
          msg: json['message'] ?? 'Failed to get user details',
          statusCode: response.statusCode,
          response: json
        );
      }
    }
    on DioException catch(e){
      return left(Failure(e.response?.data['message'] ?? e.message ?? 'Failed to get user details'));
    }
    on ServerException catch(e){
      return left(Failure(e.msg));
    }
  }

  Future<Either<Failure,UserDetails>> updateUserDetails({
    required String fullName,
    String? profileImage,
    required String bio,
  }) async {
    try{
      final deviceId = await _getOrCreateDeviceId();

      final data = jsonEncode({
        "device_id": deviceId,
        "name": fullName,
        "avatar_url": profileImage ?? "",
        "bio": bio ?? "",
      });

      final response = await _hitApi(
        route: '/profile/details',
        method: 'PUT',
        data: data,
      );

      if (response.statusCode == 200) {
        final userDetailsResponse = await userDetails();
        return userDetailsResponse;
      } else {
        throw ServerException(
          msg: response.data['message'] ?? 'Failed to update profile',
          statusCode: response.statusCode,
          response: response.data
        );
      }
    }
    on DioException catch(e){
      return left(Failure(e.response?.data['message'] ?? e.message ?? 'Failed to update profile'));
    }
    on ServerException catch(e){
      return left(Failure(e.msg));
    }
  }

  Future<Response> _hitApi({required String route, String? data, bool setHeaders=true,
    String method='GET', Map<String,dynamic>? queryParameters}) async {

    Map<String, String>? headers;

    if(setHeaders){
      final accessToken = await TokenApi().getAccessToken();
      final cookie = await TokenApi.getCookie();
      headers = {
        'Authorization': 'Bearer $accessToken'
      };
      if (cookie != null && cookie.isNotEmpty) {
        headers!['Cookie'] = cookie;
      }
    }
    try{
      final res= await _dio.request(route,
          data: data,
          queryParameters: queryParameters,
          options: Options(
            method: method,
            headers: headers,
          )
      );
      if(res.statusCode == 200){
        return res;
      }
      else{
        throw ServerException(
            msg: res.statusMessage,
            statusCode: res.statusCode,
            response: res.data
        );
      }
    }
    on DioException catch(e){
      throw ServerException(
          msg: e.message,
          response: e.response?.data
      );
    }
    catch(e){
      throw ServerException(
        msg: e.toString(),
      );
    }
  }
}
