import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:edu_gym/api/auth_interceptor.dart';
import 'package:edu_gym/api/socket_service.dart';
import 'package:edu_gym/api/token_api.dart';
import 'package:edu_gym/core/error/failure.dart';
import 'package:edu_gym/modal/module.dart';
import 'package:edu_gym/modal/module_detail_model.dart';
import 'package:edu_gym/modal/search_modal.dart';
import 'package:edu_gym/modal/user_details.dart';
import 'package:fpdart/fpdart.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/error/server_exception.dart';
import '../core/utils/device_util.dart';
import '../features/auth/data/models/auth_model.dart';
import '../modal/lesson.dart';

class Api{

  static final _api= Api();
  late final Dio _dio;
  
  Api() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'x-device-type': DeviceUtil.getDeviceType(),
        },
      )
    );
    _dio.interceptors.add(AuthInterceptor(_dio));
    // LogInterceptor removed to stop global response printing
  }

  static const accessTokenKey="Access_Token";
  static const refreshTokenKey="Refresh_Token";
  static const deviceIdKey="Device_Id";
  static const baseUrl='https://api.edumovimiento.com/api/v1';
  static const imgBaseUrl='https://res.cloudinary.com/zft8bss0/image/upload';

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
      final rawCookie = await TokenApi.getCookie();
      final accessToken = await TokenApi().getAccessToken();
      final cookieHeader = TokenApi.formatCookieHeader(rawCookie);

      // print('🚪 ==================== LOGOUT ====================');
      // print('📱 [Logout] Device ID: $deviceId');
      // print('🍪 [Logout] Raw Stored Cookie: $rawCookie');
      // print('🍪 [Logout] Formatted Cookie header being sent: "$cookieHeader"');
      // print('🔑 [Logout] Access Token present: ${accessToken != null && accessToken.isNotEmpty}');

      final cleanCookieValue = (rawCookie != null && rawCookie.isNotEmpty)
          ? (rawCookie.contains('XXAFIT=')
              ? rawCookie.split('XXAFIT=').last.split(';').first
              : rawCookie)
          : null;

      final data = {
        'device_id': deviceId,
        if (cleanCookieValue != null && cleanCookieValue.isNotEmpty) ...{
          'cookie': cleanCookieValue,
          'XXAFIT': cleanCookieValue,
          'refreshToken': cleanCookieValue,
        },
      };

      var headers = {
        'Content-Type': 'application/json',
        if (cookieHeader.isNotEmpty) 'Cookie': cookieHeader,
        if (cleanCookieValue != null && cleanCookieValue.isNotEmpty) 'x-cookie': cleanCookieValue,
        if (accessToken != null && accessToken.isNotEmpty) 'Authorization': 'Bearer $accessToken',
        'x-device-type': DeviceUtil.getDeviceType(),
      };

      // print('📤 [Logout] Headers: $headers');
      // print('📤 [Logout] Body: $data');

      var response = await _dio.request(
        '$baseUrl/logout',
        options: Options(
          method: 'POST',
          headers: headers,
          validateStatus: (_) => true, // Accept all status codes, handle errors gracefully
        ),
        data: data,
      );

      // print('📥 [Logout] Response Status: ${response.statusCode}');
      // print('📥 [Logout] Response Data: ${response.data}');
      // print('🚪 ================================================');

      // Check if logout was successful (optional - we proceed with local cleanup regardless)
      if (response.statusCode == 204 || response.statusCode == 200) {
        // print('✅ [Logout] Server logout successful (${response.statusCode})');
      } else {
        // print('⚠️ [Logout] Server returned status ${response.statusCode}');
      }
    } catch (e) {
      // print('❌ [Logout] Exception during logout request: $e');
      // Silently handle any network errors - we'll clear local data regardless
    }

    // Disconnect socket
    try {
      SocketService().disconnect();
    } catch (_) {}

    // Clear local tokens, secure storage and shared preferences (preserving only device_id)
    await TokenApi().deleteCookie();
    await TokenApi.clearPreferencesExceptDeviceId();
    // print('🧹 [Logout] Local session & tokens cleared');
  }

  Future<Either<Failure, bool>> deleteAccount() async {
    try {
      final accessToken = await TokenApi().getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        // print('Access token is null or empty - user needs to login again');
        return left(Failure('Authentication failed. Please login again.'));
      }

      var headers = {
        'Authorization': 'Bearer $accessToken',
        'x-device-type': DeviceUtil.getDeviceType(),
      };

      var response = await _dio.request(
        '$baseUrl/remove-session/user',
        options: Options(
          method: 'DELETE',
          headers: headers,
        ),
      );

      if (response.statusCode == 200) {
        // Disconnect socket
        try {
          SocketService().disconnect();
        } catch (_) {}

        // Clear local tokens, secure storage and shared preferences (preserving only device_id)
        await TokenApi().deleteCookie();
        await TokenApi.clearPreferencesExceptDeviceId();
        return right(true);
      } else {
        throw ServerException(
          msg: response.data['message'] ?? '',
          statusCode: response.statusCode,
          response: response.data,
        );
      }
    } on DioException catch (e) {
      return left(Failure(e.response?.data['message'] ?? e.message ?? ''));
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
        return left(Failure(''));
      }

      var headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
        'x-device-type': DeviceUtil.getDeviceType(),
      };

      final data = jsonEncode({
        "device_id": deviceId,
        "name": name,
        "bio": bio,
        "avatar_url": avatarUrl,
      });

      // print('📡 Making Update Profile API call to: $baseUrl/profile/details');

      var response = await _dio.request(
        '$baseUrl/profile/details',
        options: Options(
          method: 'PUT',
          headers: headers,
        ),
        data: data,
      );

      if (response.statusCode == 200) {
        return right(response.data);
      } else {
        throw ServerException(
          msg: response.data['message'] ?? '',
          statusCode: response.statusCode,
          response: response.data,
        );
      }
    } on DioException catch (e) {
      return left(Failure(e.response?.data['message'] ?? e.message ?? ''));
    } on ServerException catch (e) {
      return left(Failure(e.msg));
    } catch (e) {
      return left(Failure(''));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> getConnectedDevices() async {
    try {
      final deviceId = await DeviceUtil.getDeviceId();
      final data = jsonEncode({
        "device_id": deviceId,
      });

      final response = await _hitApi(
        route: '/devices/connected-device',
        method: 'POST',
        data: data,
      );

      if (response.statusCode == 200) {
        return right(response.data);
      } else {
        throw ServerException(
          msg: response.data['message'] ?? '',
          statusCode: response.statusCode,
          response: response.data,
        );
      }
    } on DioException catch (e) {
      return left(Failure(e.response?.data['message'] ?? e.message ?? ''));
    } on ServerException catch (e) {
      return left(Failure(e.msg));
    } catch (e) {
      return left(Failure(''));
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

      // print('📡 Making Remove Device API call to: $baseUrl/devices/remove-device');

      final response = await _hitApi(
        route: '/devices/remove-device',
        method: 'POST',
        data: data,
      );

      if (response.statusCode == 200) {
        return right(response.data);
      } else {
        throw ServerException(
          msg: response.data['message'] ?? '',
          statusCode: response.statusCode,
          response: response.data,
        );
      }
    } on DioException catch (e) {
      return left(Failure(e.response?.data['message'] ?? e.message ?? ''));
    } on ServerException catch (e) {
      return left(Failure(e.msg));
    } catch (e) {
      return left(Failure(''));
    }
  }

  Future<void> deleteToken() async {
    await TokenApi.clearPreferencesExceptDeviceId();
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
    return await DeviceUtil.getDeviceId();
  }

  String _generateDeviceId() {
    return DeviceUtil.generateDeviceId();
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

      final data = jsonEncode({
        'email': email,
        'password': password,
        'device_id': deviceId,
      });

      var headers = {
        'Content-Type': 'application/json',
        'x-device-type': DeviceUtil.getDeviceType(),
      };

      var response = await _dio.request(
        '$baseUrl/auth/sign-in',
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
      );

      // print('login response => ${response.data}');

      if (response.statusCode == 200) {
        final authModel = AuthModel.fromJson(response.data);
        if(authModel.token!=null) {

          final setCookie = response.headers['set-cookie'];
          // print('🍪 [Login] Set-Cookie headers: $setCookie');
          final cookieKeyValue = TokenApi.extractCookieValue(setCookie, 'XXAFIT');
          // print('🍪 [Login] Extracted XXAFIT Cookie: $cookieKeyValue');

          final dataObj = response.data['data'];
          final reasonCode = dataObj?['reasonCode'] ?? 1;
          final userJson = dataObj?['user'];

          await TokenApi().saveAuthData(
            accessToken: authModel.token!, 
            cookie: cookieKeyValue, 
            reasonCode: reasonCode,
            userJson: userJson ?? {},
          );
          
          // Initialize Socket with deviceId
          final deviceId = await _getOrCreateDeviceId();
          SocketService().initSocket(deviceId);
        }
        return right(authModel);
      } else {
        throw ServerException(
          msg: response.statusMessage ?? '',
          statusCode: response.statusCode,
          response: response.data
        );
      }
    }
    on DioException catch (e) {
      String? msg;
      if (e.response?.data is Map) {
        msg = e.response?.data['message'];
      }
      return left(ServerException(
        msg: msg ?? e.message ?? '',
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

      final data = jsonEncode({
        'email': email,
        'password': password,
        'cpassword': confirmPassword,
        'device_id': deviceId,
      });

      var headers = {
        'Content-Type': 'application/json',
        'x-device-type': DeviceUtil.getDeviceType(),
      };

      var response = await _dio.request(
        '/auth/sign-up',
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
      );

      // print('📥 Register Response: ${response.data}');

      if (response.statusCode == 200) {
        final authModel = AuthModel.fromJson(response.data);
        if(authModel.token!=null) {
          final setCookie = response.headers['set-cookie'];
          // print('🍪 [Register] Set-Cookie headers: $setCookie');
          final cookieKeyValue = TokenApi.extractCookieValue(setCookie, 'XXAFIT');
          // print('🍪 [Register] Extracted XXAFIT Cookie: $cookieKeyValue');

          final dataObj = response.data['data'];
          final reasonCode = dataObj?['reasonCode'] ?? 1;
          final userJson = dataObj?['user'];

          await TokenApi().saveAuthData(
            accessToken: authModel.token!, 
            cookie: cookieKeyValue, 
            reasonCode: reasonCode,
            userJson: userJson ?? {},
          );
          
          // Initialize Socket with deviceId
          final deviceId = await _getOrCreateDeviceId();
          SocketService().initSocket(deviceId);
        }
        return right(authModel);
      } else {
        throw ServerException(
          msg: response.data?['message'] ?? response.statusMessage ?? '',
          statusCode: response.statusCode,
          response: response.data
        );
      }
    }
    on DioException catch (e) {
      String? msg;
      if (e.response?.data is Map) {
        msg = e.response?.data['message'];
      }
      return left(ServerException(
        msg: msg ?? e.message ?? '',
        response: e.response?.data
      ));
    }
    on ServerException catch(e){
      return left(e);
    }
  }

  Future<Either<Failure, String>> sendVerificationEmail({required String email}) async {
    try {
      final data = jsonEncode({
        'email': email,
      });

      var headers = {
        'Content-Type': 'application/json',
        'x-device-type': DeviceUtil.getDeviceType(),
      };

      var response = await _dio.request(
        '$baseUrl/auth/send-verification-email',
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
      );

      if (response.statusCode == 200 && response.data['isSuccess'] == true) {
        final message = response.data['data']?['message']?.toString() ??
            response.data['message']?.toString() ??
            'Verification email sent successfully.';
        return right(message);
      } else {
        throw ServerException(
          msg: response.data['data']?['message']?.toString() ??
              response.data['message']?.toString() ??
              'Failed to send verification email',
          statusCode: response.statusCode,
          response: response.data,
        );
      }
    } on DioException catch (e) {
      return left(Failure(
        e.response?.data?['data']?['message']?.toString() ??
            e.response?.data?['message']?.toString() ??
            e.message ??
            'Failed to send verification email',
      ));
    } on ServerException catch (e) {
      return left(Failure(e.msg));
    }
  }

  Future<Either<Failure, String>> sendOtp({required String email}) async {
    try {
      final data = jsonEncode({
        'email': email,
      });

      var headers = {
        'Content-Type': 'application/json',
        'x-device-type': DeviceUtil.getDeviceType(),
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
        final token = response.data['token']?.toString() ?? '';

        // Store token in reset token value (not access token)
        await TokenApi.saveResetToken(token);

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
      // Get stored token from sendOtp (reset token value)
      final token = await TokenApi.getResetToken();

      if (token == null || token.isEmpty) {
        return left(Failure('No OTP token found. Please request OTP again.'));
      }

      final data = jsonEncode({
        'token': token,
        'otp': otp,
      });

      var headers = {
        'Content-Type': 'application/json',
        'x-device-type': DeviceUtil.getDeviceType(),
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
        // Store returned token in reset token value (for reset password Bearer token)
        final verifyToken = response.data['token']?.toString() ?? '';
        if (verifyToken.isNotEmpty) {
          await TokenApi.saveResetToken(verifyToken);
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

  Future<Either<Failure, AuthModel>> resetPassword({
    required String newPassword,
    String? confirmPassword,
  }) async {
    try {
      // Get stored reset token from verifyOtp
      final resetToken = await TokenApi.getResetToken();

      if (resetToken == null || resetToken.isEmpty) {
        return left(Failure('No reset token found. Please restart the password reset process.'));
      }

      final deviceId = await _getOrCreateDeviceId();

      final data = jsonEncode({
        'password': newPassword,
        'cpassword': confirmPassword ?? newPassword,
        'device_id': deviceId,
      });

      var headers = {
        'Authorization': 'Bearer $resetToken',
        'Content-Type': 'application/json',
        'x-device-type': DeviceUtil.getDeviceType(),
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
        // Extract auth data from response:
        // {"isSuccess":true,"message":"Successfull!","data":{"user":{...},"accessToken":"...","reasonCode":1}}
        final authModel = AuthModel.fromJson(response.data);
        final dataObj = response.data['data'];
        final accessToken = authModel.token ?? dataObj?['accessToken']?.toString() ?? response.data['token']?.toString() ?? '';
        final reasonCode = authModel.reasonCode ?? (dataObj?['reasonCode'] != null
            ? (dataObj['reasonCode'] is int ? dataObj['reasonCode'] : int.tryParse(dataObj['reasonCode'].toString()) ?? 1)
            : 1);
        final userJson = dataObj?['user'];

        final setCookie = response.headers['set-cookie'];
        // print('🍪 [ResetPassword/Auth] Set-Cookie headers: $setCookie');
        final cookieKeyValue = TokenApi.extractCookieValue(setCookie, 'XXAFIT');
        // print('🍪 [ResetPassword/Auth] Extracted XXAFIT Cookie: $cookieKeyValue');

        if (accessToken.isNotEmpty) {
          final Map<String, dynamic> parsedUserJson = userJson is Map<String, dynamic>
              ? userJson
              : (userJson is Map ? Map<String, dynamic>.from(userJson) : <String, dynamic>{});

          await TokenApi().saveAuthData(
            accessToken: accessToken,
            cookie: cookieKeyValue,
            reasonCode: reasonCode,
            userJson: parsedUserJson,
          );

          // Save in SharedPreferences (same as auth)
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(Api.accessTokenKey, accessToken);
            await prefs.setString(TokenApi.accessTokenKey, accessToken);
            await prefs.setString('Device_Id', deviceId);
            await prefs.setString(TokenApi.reasonCodeKey, reasonCode.toString());
            if (cookieKeyValue.isNotEmpty) {
              await prefs.setString(TokenApi.authCookie, cookieKeyValue);
            }
            if (parsedUserJson.isNotEmpty) {
              await prefs.setString(TokenApi.userKey, jsonEncode(parsedUserJson));
            }
          } catch (_) {}

          // Initialize Socket with deviceId
          SocketService().initSocket(deviceId);
        }

        // Set reset token value to null after reset password is done
        await TokenApi.deleteResetToken();

        return right(authModel);
      } else {
        AuthInterceptor.checkAndHandleEmailVerification(response.statusCode, response.data, response.statusMessage);
        throw ServerException(
          msg: response.data?['message'] ?? 'Failed to reset password',
          statusCode: response.statusCode,
          response: response.data,
        );
      }
    } on DioException catch (e) {
      AuthInterceptor.checkAndHandleEmailVerification(e.response?.statusCode, e.response?.data, e.message);
      return left(Failure(e.response?.data?['message'] ?? e.message ?? 'Failed to reset password'));
    } on ServerException catch (e) {
      return left(Failure(e.msg));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> getCloudinarySignature() async {
    try {
      final response = await _hitApi(
        route: '/cloudinary/signature',
        method: 'GET',
      );

      if (response.statusCode == 200 && response.data != null) {
        if (response.data['isSuccess'] == true && response.data['data'] != null) {
          return right(Map<String, dynamic>.from(response.data['data']));
        } else {
          return left(Failure(
            response.data['message'] ?? response.data['msg'] ?? 'Failed to get Cloudinary signature',
          ));
        }
      } else {
        throw ServerException(
          msg: response.data?['message'] ?? 'Failed to get Cloudinary signature',
          statusCode: response.statusCode,
          response: response.data,
        );
      }
    } on DioException catch (e) {
      return left(Failure(e.response?.data?['message'] ?? e.message ?? 'Failed to get Cloudinary signature'));
    } on ServerException catch (e) {
      return left(Failure(e.msg));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Future<Either<Failure, String>> uploadImageToCloudinary(String filePath) async {
    try {
      final sigResult = await getCloudinarySignature();
      return await sigResult.fold(
        (failure) => left(failure),
        (sigData) async {
          final cloudName = sigData['cloud_name']?.toString() ?? '';
          final apiKey = sigData['api_key']?.toString() ?? '';
          final timestamp = sigData['timestamp']?.toString() ?? '';
          final signature = sigData['signature']?.toString() ?? '';
          final folder = sigData['folder']?.toString();

          if (cloudName.isEmpty || apiKey.isEmpty || signature.isEmpty || timestamp.isEmpty) {
            return left(Failure('Invalid Cloudinary signature data'));
          }

          final fileName = filePath.contains(Platform.pathSeparator)
              ? filePath.split(Platform.pathSeparator).last
              : (filePath.contains('/') ? filePath.split('/').last : 'upload.jpg');

          final formDataMap = <String, dynamic>{
            'file': await MultipartFile.fromFile(filePath, filename: fileName.isNotEmpty ? fileName : 'upload.jpg'),
            'api_key': apiKey,
            'timestamp': timestamp,
            'signature': signature,
          };
          if (folder != null && folder.isNotEmpty) {
            formDataMap['folder'] = folder;
          }

          final formData = FormData.fromMap(formDataMap);

          final cloudinaryDio = Dio(
            BaseOptions(
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
            ),
          );
          final uploadUrl = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

          final uploadResponse = await cloudinaryDio.post(
            uploadUrl,
            data: formData,
          );

          if (uploadResponse.statusCode == 200 && uploadResponse.data != null) {
            final data = uploadResponse.data is String ? jsonDecode(uploadResponse.data) : uploadResponse.data;
            final uploadedUrl = (data['secure_url'] ?? data['url'])?.toString() ?? '';
            if (uploadedUrl.isNotEmpty) {
              final relativePath = extractCloudinaryRelativePath(uploadedUrl);
              return right(relativePath);
            }
            return left(Failure('Failed to retrieve image URL from Cloudinary response'));
          } else {
            return left(Failure(uploadResponse.statusMessage ?? 'Cloudinary upload failed'));
          }
        },
      );
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['error']?['message'] ?? e.response?.data?['message'] ?? e.message ?? 'Image upload failed';
      return left(Failure(errorMsg.toString()));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  static String extractCloudinaryRelativePath(String url) {
    if (url.isEmpty) return '';
    final regExp = RegExp(r'upload\/?(.+)$');
    final match = regExp.firstMatch(url);
    if (match != null && match.group(1) != null) {
      String path = match.group(1)!;
      if (path.startsWith('/')) {
        path = path.substring(1);
      }
      return path;
    }
    return url;
  }

  static String getFullImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    final base = imgBaseUrl.endsWith('/')
        ? imgBaseUrl.substring(0, imgBaseUrl.length - 1)
        : imgBaseUrl;
    return '$base/$cleanPath';
  }

  Future<String> uploadImage(String filePath) async {
    final result = await uploadImageToCloudinary(filePath);
    return result.fold(
      (failure) {
        // print('Error during image upload: ${failure.message}');
        return '';
      },
      (imageUrl) => imageUrl,
    );
  }

  // New DramaBox API method
  Future<Either<Failure, Map<String, dynamic>>> getDramaBoxHome({
    int? limit,
    String? cursor,
    int? categoryId,
  }) async {
    try {
      final accessToken = await TokenApi().getAccessToken();

      Map<String, dynamic> headers = {
        'x-device-type': DeviceUtil.getDeviceType(),
      };
      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
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
        // print('🏠 [HOME PAGE API RESPONSE]: ${jsonEncode(response.data)}');
        return right(response.data);
      } else {
        // print('❌ [HOME PAGE API ERROR]: ${response.statusCode} - ${response.statusMessage}');
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
    int limit = 10,
    String? cursor,
    int? categoryId,
  }) async {
    try {
      final accessToken = await TokenApi().getAccessToken();
      Map<String, dynamic> headers = {
        'x-device-type': DeviceUtil.getDeviceType(),
      };
      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
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
      Map<String, dynamic> headers = {
        'x-device-type': DeviceUtil.getDeviceType(),
      };
      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
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
        // print('💊 [NAV PILL API RESPONSE]: ${jsonEncode(response.data)}');
        return right(response.data);
      } else {
        // print('❌ [NAV PILL API ERROR]: ${response.statusCode} - ${response.statusMessage}');
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
    String limit = '',
    String cursor = '',
  }) async {
    try {
      final accessToken = await TokenApi().getAccessToken();
      Map<String, dynamic> headers = {
        'x-device-type': DeviceUtil.getDeviceType(),
      };
      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
      }

      var queryParameters = <String, dynamic>{
        'term': term,
        'limit': limit,
        'cursor': cursor,
      };

      var response = await _dio.request(
        '$baseUrl/users/search',
        options: Options(
          method: 'GET',
          headers: headers,
        ),
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        // print('🔍 [SEARCH PAGE API RESPONSE]: ${jsonEncode(response.data)}');
        return right(response.data);
      } else {
        // print('❌ [SEARCH PAGE API ERROR]: ${response.statusCode} - ${response.statusMessage}');
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
      return left(Failure(e.toString()));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> getLessonVideo({
    required String videoProviderId,
    required String uiStyle,
  }) async {
    try {
      final accessToken = await TokenApi().getAccessToken();
      Map<String, dynamic> headers = {
        'x-device-type': DeviceUtil.getDeviceType(),
      };
      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
      }

      var response = await _dio.request(
        '$baseUrl/users/lesson/$videoProviderId/$uiStyle',
        options: Options(
          method: 'GET',
          headers: headers,
        ),
      );

      if (response.statusCode == 200) {
        // print('🎬 [LESSON VIDEO API RESPONSE]: ${jsonEncode(response.data)}');
        return right(response.data);
      } else {
        // print('❌ [LESSON VIDEO API ERROR]: ${response.statusCode} - ${response.statusMessage}');
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
      Map<String, dynamic> headers = {
        'x-device-type': DeviceUtil.getDeviceType(),
      };
      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
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
        // print('📚 [MODULE LESSONS API RESPONSE]: ${jsonEncode(response.data)}');
        return right(response.data);
      } else {
        // print('❌ [MODULE LESSONS API ERROR]: ${response.statusCode} - ${response.statusMessage} - ${response.data}');
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
      return left(Failure(e.toString()));
    }
  }

  Future<Either<Failure, ModuleDetailModel>> getModuleDetails({
    required int moduleId,
  }) async {
    try {
      final accessToken = await TokenApi().getAccessToken();
      Map<String, dynamic> headers = {
        'x-device-type': DeviceUtil.getDeviceType(),
      };
      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
      }

      var response = await _dio.request(
        '$baseUrl/users/modules/$moduleId',
        options: Options(
          method: 'GET',
          headers: headers,
        ),
      );

      if (response.statusCode == 200) {
        // print('📦 [MODULE DETAILS API RESPONSE]: ${jsonEncode(response.data)}');
        final data = response.data;
        if (data != null && (data['isSuccess'] == true || data['isSuccess'] == null)) {
          final moduleDetail = ModuleDetailModel.fromJson(data['data'] ?? data);
          return right(moduleDetail);
        } else {
          return left(Failure(data?['message'] ?? 'Failed to load module details'));
        }
      } else {
        // print('❌ [MODULE DETAILS API ERROR]: ${response.statusCode} - ${response.statusMessage}');
        throw ServerException(
          msg: response.statusMessage,
          statusCode: response.statusCode,
          response: response.data,
        );
      }
    } on DioException catch (e) {
      return left(Failure(e.response?.data?['message'] ?? e.message ?? 'Failed to load module details'));
    } on ServerException catch (e) {
      return left(Failure(e.msg));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Future<Either<Failure, String>> generateWebLink() async {
    try {
      final deviceId = await DeviceUtil.getDeviceId();

      final response = await _hitApi(
        route: '/weblink/send-access-steps/$deviceId',
        method: 'GET',
      );

      if (response.statusCode == 200 && response.data != null) {
        final bool isSuccess = response.data['isSuccess'] == true ||
            response.data['isSuccess'] == 1 ||
            response.data['isSuccess'] == 'true' ||
            response.data['status'] == true ||
            response.data['status'] == 'success';

        if (isSuccess) {
          final message = response.data['message'] ??
              response.data['msg'] ??
              'Access steps sent to your email successfully.';
          return right(message.toString());
        } else {
          return left(Failure(
            response.data['message'] ??
                response.data['msg'] ??
                'Failed to send access steps email',
          ));
        }
      } else {
        throw ServerException(
          msg: response.data?['message'] ?? 'Failed to send access steps email',
          statusCode: response.statusCode,
          response: response.data,
        );
      }
    } on DioException catch (e) {
      return left(Failure(e.response?.data?['message'] ?? e.message ?? 'Failed to send access steps email'));
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

      Map<String, dynamic> headers = {
        'x-device-type': DeviceUtil.getDeviceType(),
      };
      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
      }

      var queryParameters = <String, dynamic>{
        'cursor': cursor,
        'limit': limit.toString(),
        'category_id': filterId.toString(),
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

      if(json['isSuccess'] == true){
        // print('📦 [MODULE DETAILS API RESPONSE]: ${jsonEncode(json)}');
        final module=Module.fromJson(json['data']);
        return right(module);
      }
      else{
        // print('❌ [MODULE DETAILS API ERROR]: ${json['message'] ?? 'Failed to load module'}');
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
      if(json['isSuccess'] == true){
        // print('📖 [LESSON BY ID API RESPONSE]: ${jsonEncode(json)}');
        final lesson=Lesson.fromJson(json['data']);
        return right(lesson);
      }
      else{
        // print('❌ [LESSON BY ID API ERROR]: ${json['message'] ?? 'Failed to load lesson'}');
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
        // Handle nested structure: check for 'user' key first
        final userJson = json['data']?['user'] ?? json['data'];
        final details = UserDetails.fromJson(userJson);
        // Store and merge user details
        await TokenApi().saveUserData(details);
        
        // Return the MERGED details from TokenApi.user
        return right(TokenApi.user ?? details);
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

  /// Get user's subscriptions from /payments/subscriptions
  Future<Either<Failure, Map<String, dynamic>>> getSubscriptions() async {
    try {
      final response = await _hitApi(
        route: '/payments/subscriptions',
        method: 'GET',
      );

      if (response.statusCode == 200 && response.data != null) {
        Map<String, dynamic> responseData;
        if (response.data is Map<String, dynamic>) {
          responseData = response.data;
        } else if (response.data is Map) {
          responseData = Map<String, dynamic>.from(response.data);
        } else if (response.data is String) {
          responseData = jsonDecode(response.data);
        } else {
          responseData = {};
        }
        return right(responseData);
      } else {
        throw ServerException(
          msg: response.data?['message'] ?? 'Failed to get subscriptions',
          statusCode: response.statusCode,
          response: response.data,
        );
      }
    } on DioException catch (e) {
      return left(Failure(e.response?.data?['message'] ?? e.message ?? 'Failed to get subscriptions'));
    } on ServerException catch (e) {
      return left(Failure(e.msg));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> getLatestSubscription() async {
    try {
      // 1. Try /payments/subscriptions first
      try {
        final subResponse = await _hitApi(
          route: '/payments/subscriptions',
          method: 'GET',
        );

        if (subResponse.statusCode == 200 && subResponse.data != null) {
          final resData = subResponse.data;
          final dynamic listData = resData['data'];
          if (listData is List && listData.isNotEmpty) {
            // Find active subscription or first item
            final activeSub = listData.firstWhere(
              (item) => item is Map && (item['status'] == 'active' || item['status'] == 'trialing'),
              orElse: () => listData.first,
            );

            final Map<String, dynamic> mergedSub = activeSub is Map
                ? Map<String, dynamic>.from(activeSub)
                : <String, dynamic>{};
            final maxDev = resData['max_devices'] ??
                (resData['data'] is Map ? resData['data']['max_devices'] : null) ??
                resData['maxDevices'] ??
                mergedSub['max_devices'] ??
                mergedSub['maxDevices'];
            if (maxDev != null) {
              mergedSub['max_devices'] = maxDev;
            }

            return right({
              'isSuccess': true,
              'data': {
                'subscription': mergedSub,
              },
              'max_devices': maxDev,
              'raw': resData,
            });
          }
        }
      } catch (_) {
        // Fallback to /users/latest-subscription
      }

      // 2. Fallback to /users/latest-subscription
      final response = await _hitApi(
        route: '/users/latest-subscription',
        method: 'GET',
      );

      if (response.statusCode == 200) {
        final resData = response.data;
        if (resData is Map) {
          final maxDev = resData['max_devices'] ??
              (resData['data'] is Map ? resData['data']['max_devices'] : null) ??
              resData['maxDevices'];
          if (maxDev != null && resData['data'] is Map && resData['data']['subscription'] is Map) {
            resData['data']['subscription']['max_devices'] ??= maxDev;
          }
        }
        return right(response.data);
      } else {
        throw ServerException(
          msg: response.data['message'] ?? 'Failed to get latest subscription',
          statusCode: response.statusCode,
          response: response.data,
        );
      }
    } on DioException catch (e) {
      return left(Failure(e.response?.data['message'] ?? e.message ?? 'Failed to get latest subscription'));
    } on ServerException catch (e) {
      return left(Failure(e.msg));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  /// Check subscription status by checkout session_id
  /// Endpoint: /payments/subscription-status?session_id=...
  Future<Either<Failure, Map<String, dynamic>>> getSubscriptionStatus({required String sessionId}) async {
    try {
      Response response;
      try {
        response = await _hitApi(
          route: '/payments/subscription-status',
          method: 'GET',
          queryParameters: {'session_id': sessionId},
        );
      } catch (e) {
        if (e is ServerException && e.statusCode == 404) {
          response = await _hitApi(
            route: '/payments/subscriptions-status',
            method: 'GET',
            queryParameters: {'session_id': sessionId},
          );
        } else {
          rethrow;
        }
      }

      if (response.statusCode == 200 && response.data != null) {
        Map<String, dynamic> responseData;
        if (response.data is Map<String, dynamic>) {
          responseData = response.data;
        } else if (response.data is Map) {
          responseData = Map<String, dynamic>.from(response.data);
        } else if (response.data is String) {
          responseData = jsonDecode(response.data);
        } else {
          responseData = {};
        }
        return right(responseData);
      } else {
        throw ServerException(
          msg: response.data?['message'] ?? 'Failed to get subscription status',
          statusCode: response.statusCode,
          response: response.data,
        );
      }
    } on DioException catch (e) {
      return left(Failure(e.response?.data?['message'] ?? e.message ?? 'Failed to get subscription status'));
    } on ServerException catch (e) {
      return left(Failure(e.msg));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  /// Cancel subscription by subs_id
  /// Endpoint: /payments/subscription-cancel
  /// Body: { subs_id: "subs_value" }
  Future<Either<Failure, Map<String, dynamic>>> cancelSubscription({required String subsId}) async {
    try {
      final response = await _hitApi(
        route: '/payments/subscription-cancel',
        method: 'POST',
        data: jsonEncode({'subs_id': subsId}),
      );

      if (response.statusCode == 200 && response.data != null) {
        Map<String, dynamic> responseData;
        if (response.data is Map<String, dynamic>) {
          responseData = response.data;
        } else if (response.data is Map) {
          responseData = Map<String, dynamic>.from(response.data);
        } else if (response.data is String) {
          responseData = jsonDecode(response.data);
        } else {
          responseData = {};
        }
        return right(responseData);
      } else {
        throw ServerException(
          msg: response.data?['message'] ?? 'Failed to cancel subscription',
          statusCode: response.statusCode,
          response: response.data,
        );
      }
    } on DioException catch (e) {
      return left(Failure(e.response?.data?['message'] ?? e.message ?? 'Failed to cancel subscription'));
    } on ServerException catch (e) {
      return left(Failure(e.msg));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> getContinueWatching({
    int limit = 5,
    dynamic cursor,
  }) async {
    try {
      final accessToken = await TokenApi().getAccessToken();
      final cookie = await TokenApi.getCookie();
      Map<String, dynamic> headers = {
        'Content-Type': 'application/json',
        'x-device-type': DeviceUtil.getDeviceType(),
      };
      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
      }
      if (cookie != null && cookie.isNotEmpty) {
        headers['Cookie'] = cookie;
      }

      var queryParameters = <String, dynamic>{
        'limit': limit.toString(),
      };

      // In the first run, do NOT add cursor. Only add cursor if cursor != null during infinite scroll
      if (cursor != null &&
          cursor.toString().trim().isNotEmpty &&
          cursor.toString().trim().toLowerCase() != 'null') {
        queryParameters['cursor'] = cursor.toString().trim();
      }

      // print('📥 [CW TABLE - GET]: $baseUrl/users/continue-watching with params: $queryParameters');

      var response = await _dio.request(
        '$baseUrl/users/continue-watching',
        options: Options(
          method: 'GET',
          headers: headers,
        ),
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        // print('▶️ [CW TABLE - GET RESPONSE]: ${jsonEncode(response.data)}');
        Map<String, dynamic> responseData;
        if (response.data is Map) {
          responseData = Map<String, dynamic>.from(response.data as Map);
        } else if (response.data is String) {
          responseData = jsonDecode(response.data as String);
        } else {
          responseData = {};
        }
        return right(responseData);
      } else {
        // print('❌ [CW TABLE - GET ERROR]: ${response.statusCode} - ${response.statusMessage}');
        throw ServerException(
          msg: response.statusMessage,
          statusCode: response.statusCode,
          response: response.data,
        );
      }
    } on DioException catch (e) {
      // print('❌ [CW TABLE - GET DIO ERROR]: ${e.response?.data ?? e.message}');
      return left(Failure(e.response?.data?['message'] ?? e.message));
    } on ServerException catch (e) {
      return left(Failure(e.msg));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Future<Either<Failure, bool>> updateContinueWatching({
    required dynamic videoProviderId,
    required int lastPositionMs,
    required int totalDurationMs,
  }) async {
    try {
      final accessToken = await TokenApi().getAccessToken();
      final cookie = await TokenApi.getCookie();

      final parsedId = int.tryParse(videoProviderId.toString());
      final payload = {
        'video_provider_id': parsedId ?? videoProviderId,
        'last_position_ms': lastPositionMs,
        'total_duration_ms': totalDurationMs,
      };
      final data = jsonEncode(payload);

      Map<String, dynamic> headers = {
        'Content-Type': 'application/json',
        'x-device-type': DeviceUtil.getDeviceType(),
      };
      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
      }
      if (cookie != null && cookie.isNotEmpty) {
        headers['Cookie'] = cookie;
      }

      // print('📤 [CW TABLE - POST]: $baseUrl/users/continue-watching with body: $data');

      final response = await _dio.request(
        '$baseUrl/users/continue-watching',
        options: Options(
          method: 'POST',
          headers: headers,
        ),
        data: data,
      );

      if (response.statusCode == 200) {
        // print('⏱️ [CW TABLE - POST RESPONSE]: ${jsonEncode(response.data)}');
        return right(true);
      } else {
        // print('❌ [CW TABLE - POST ERROR]: ${response.statusCode} - ${response.statusMessage}');
        return left(Failure(response.data?['message'] ?? 'Failed to update progress'));
      }
    } on DioException catch (e) {
      // print('❌ [CW TABLE - POST DIO ERROR]: ${e.response?.data ?? e.message}');
      return left(Failure(e.response?.data?['message'] ?? e.message ?? 'Failed to update progress'));
    } on ServerException catch (e) {
      return left(Failure(e.msg));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  Future<Either<Failure, Map<String, dynamic>>> getContinueWatchingVideo({
    required dynamic videoId,
  }) async {
    try {
      final accessToken = await TokenApi().getAccessToken();
      Map<String, dynamic> headers = {
        'x-device-type': DeviceUtil.getDeviceType(),
      };
      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
      }

      // print('📥 [CW TABLE - GET VIDEO]: $baseUrl/users/continue-watching/$videoId');

      var response = await _dio.request(
        '$baseUrl/users/continue-watching/$videoId',
        options: Options(
          method: 'GET',
          headers: headers,
        ),
      );

      if (response.statusCode == 200) {
        // print('▶️ [CW TABLE - GET VIDEO RESPONSE]: ${jsonEncode(response.data)}');
        return right(response.data);
      } else {
        // print('❌ [CW TABLE - GET VIDEO ERROR]: ${response.statusCode} - ${response.statusMessage}');
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

  Future<Response> _hitApi({required String route, String? data, bool setHeaders=true,
    String method='GET', Map<String,dynamic>? queryParameters}) async {

    Map<String, String> headers = {
      'Content-Type': 'application/json',
      'x-device-type': DeviceUtil.getDeviceType(),
    };

    if(setHeaders){
      final accessToken = await TokenApi().getAccessToken();
      final cookie = await TokenApi.getCookie();
      if (accessToken != null && accessToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $accessToken';
      }
      if (cookie != null && cookie.isNotEmpty) {
        headers['Cookie'] = cookie;
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
        // Global error catching for isSuccess: false
        if (res.data is Map && res.data['isSuccess'] == false) {
          AuthInterceptor.checkAndHandleEmailVerification(res.statusCode, res.data);
          throw ServerException(
              msg: res.data['message'] ?? 'Action failed',
              statusCode: res.statusCode,
              response: res.data
          );
        }
        return res;
      }
      else{
        AuthInterceptor.checkAndHandleEmailVerification(res.statusCode, res.data, res.statusMessage);
        throw ServerException(
            msg: res.statusMessage,
            statusCode: res.statusCode,
            response: res.data
        );
      }
    }
    on DioException catch(e){
      AuthInterceptor.checkAndHandleEmailVerification(e.response?.statusCode, e.response?.data, e.message);
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
