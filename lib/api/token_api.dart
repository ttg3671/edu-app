import 'package:dio/dio.dart';
import 'package:edu_gym/api/api.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenApi{

  static const storage = FlutterSecureStorage();
  static const authCookie= 'auth_cookie';
  static const userEmailKey = 'user_email';
  static const otpTokenKey = 'otp_token';
  static const passwordResetTokenKey = 'password_reset_token';
  static const _firstLaunchKey = 'has_launched_before';
  static String? _cookie;
  static String? _accessToken;
  static String? _otpToken;
  static String? _passwordResetToken;

  final dio= Dio(
      BaseOptions(
          baseUrl: Api.baseUrl
      )
  );

  static Future<String?> getCookie() async {
    _cookie= await storage.read(key: authCookie);
    return _cookie;
  }

  Future<void> saveTokens({required String accessToken, required String cookie, String? email}) async {
    TokenApi._cookie = cookie;
    TokenApi._accessToken = accessToken;
    await storage.write(key: authCookie, value: cookie);

    // Save user email if provided
    if(email != null && email.isNotEmpty) {
      await storage.write(key: userEmailKey, value: email);
    }
  }

  Future<void> deleteCookie() async {
    TokenApi._cookie=null;
    TokenApi._accessToken=null;
    await storage.delete(key: authCookie);
    await storage.delete(key: userEmailKey);
  }

  static Future<void> saveOtpToken(String token) async {
    _otpToken = token;
    await storage.write(key: otpTokenKey, value: token);
  }

  static Future<String?> getOtpToken() async {
    if (_otpToken != null) {
      return _otpToken;
    }
    _otpToken = await storage.read(key: otpTokenKey);
    return _otpToken;
  }

  static Future<void> deleteOtpToken() async {
    _otpToken = null;
    await storage.delete(key: otpTokenKey);
  }

  static Future<void> savePasswordResetToken(String token) async {
    _passwordResetToken = token;
    await storage.write(key: passwordResetTokenKey, value: token);
  }

  static Future<String?> getPasswordResetToken() async {
    if (_passwordResetToken != null) {
      return _passwordResetToken;
    }
    _passwordResetToken = await storage.read(key: passwordResetTokenKey);
    return _passwordResetToken;
  }

  static Future<void> deletePasswordResetToken() async {
    _passwordResetToken = null;
    await storage.delete(key: passwordResetTokenKey);
  }

  static Future<String?> getUserEmail() async {
    return await storage.read(key: userEmailKey);
  }

  static String getUsernameFromEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'User';
    }

    // Extract username from email (part before @)
    final parts = email.split('@');
    if (parts.isEmpty) {
      return 'User';
    }

    String username = parts[0];

    // Capitalize first letter and replace dots/underscores with spaces
    username = username.replaceAll('.', ' ').replaceAll('_', ' ');

    // Capitalize each word
    final words = username.split(' ');
    username = words.map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');

    return username;
  }

  Future<String?> getAccessToken() async {
    if(_accessToken!=null && !JwtDecoder.isExpired(_accessToken!)){
      return _accessToken;
    }

    if(_cookie==null){
      await getCookie();
    }

    if(_cookie==null || _cookie!.isEmpty){
      return null;
    }

    var headers = {
      'Cookie': _cookie,
    };

    try{
      print('🔄 Refreshing access token using cookie...');
      final response = await dio.get('/refresh',
        options: Options(
          headers: headers,
        ),
      );

      if (response.statusCode == 200) {
        if(response.data['isSuccess']){
          _accessToken= response.data['token'];
          print('✅ Access token refreshed successfully');
          return _accessToken;
        }
      }
    }
    catch (e){
      print('❌ Error refreshing token: $e');
      return null;
    }
    return null;
  }

  static Future<void> clearOnFreshInstall() async {
    final prefs = await SharedPreferences.getInstance();
    final hasLaunched = prefs.getBool(_firstLaunchKey);

    if (hasLaunched == null) {
      await storage.deleteAll();
      await prefs.setBool(_firstLaunchKey, true);
    }
  }

  static bool isUserLoggedIn()=>TokenApi._cookie!=null;
}