import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:edu_gym/api/api.dart';
import 'package:edu_gym/core/utils/device_util.dart';
import 'package:edu_gym/modal/subscription_details.dart';
import 'package:edu_gym/modal/user_details.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenApi{

  static const storage = FlutterSecureStorage();
  static const authCookie = 'auth_cookie';
  static const accessTokenKey = 'access_token';
  static const userKey = 'user_data';
  static const userEmailKey = 'user_email';
  static const subDetailsKey = 'sub_details';
  static const maxDevicesKey = 'max_devices';
  static const reasonCodeKey = 'reason_code';
  static const otpTokenKey = 'otp_token';
  static const passwordResetTokenKey = 'password_reset_token';
  static const _firstLaunchKey = 'has_launched_before';
  static String? _cookie;
  static String? _accessToken;
  static int? _reasonCode;
  static int? _maxDevices;
  static UserDetails? _user;

  final dio = Dio(
      BaseOptions(
          baseUrl: Api.baseUrl,
          headers: {
            'x-device-type': DeviceUtil.getDeviceType(),
          },
      )
  );

  static Future<void> loadStoredData() async {
    _cookie = await storage.read(key: authCookie);
    _accessToken = await storage.read(key: accessTokenKey);
    final code = await storage.read(key: reasonCodeKey);
    if (code != null) {
      _reasonCode = int.tryParse(code);
    }
    final maxDevStr = await storage.read(key: maxDevicesKey);
    if (maxDevStr != null) {
      _maxDevices = int.tryParse(maxDevStr);
    }
    
    final userData = await storage.read(key: userKey);
    if (userData != null) {
      try {
        _user = UserDetails.fromJson(jsonDecode(userData));
      } catch (e) {
        // print('Error parsing stored user data: $e');
      }
    }

    // Fallback to SharedPreferences if secure storage was empty
    try {
      final prefs = await SharedPreferences.getInstance();
      _cookie ??= prefs.getString(authCookie);
      _accessToken ??= prefs.getString(accessTokenKey) ?? prefs.getString(Api.accessTokenKey);
      if (_reasonCode == null) {
        final code = prefs.getString(reasonCodeKey);
        if (code != null) _reasonCode = int.tryParse(code);
      }
      _maxDevices ??= prefs.getInt(maxDevicesKey) ??
          (prefs.getString(maxDevicesKey) != null ? int.tryParse(prefs.getString(maxDevicesKey)!) : null);
      if (_user == null) {
        final userDataFromPrefs = prefs.getString(userKey);
        if (userDataFromPrefs != null) {
          try {
            _user = UserDetails.fromJson(jsonDecode(userDataFromPrefs));
          } catch (_) {}
        }
      }
    } catch (_) {}

    // Ensure cached subscription details are restored if not embedded in user object
    if (_user != null && _user!.subscriptionDetails == null) {
      final subData = await storage.read(key: subDetailsKey);
      if (subData != null) {
        try {
          final sub = SubscriptionDetails.fromJson(jsonDecode(subData));
          final status = sub.status?.toLowerCase();
          final isActive = status == 'active' || status == 'trialing' || status == 'praemium' || status == 'processing';
          _user = _user!.copyWith(
            subscriptionDetails: sub,
            isSubscribed: isActive ? 1 : _user!.isSubscribed,
          );
        } catch (_) {}
      } else {
        try {
          final prefs = await SharedPreferences.getInstance();
          final prefSubData = prefs.getString(subDetailsKey);
          if (prefSubData != null) {
            final sub = SubscriptionDetails.fromJson(jsonDecode(prefSubData));
            final status = sub.status?.toLowerCase();
            final isActive = status == 'active' || status == 'trialing' || status == 'praemium' || status == 'processing';
            _user = _user!.copyWith(
              subscriptionDetails: sub,
              isSubscribed: isActive ? 1 : _user!.isSubscribed,
            );
          }
        } catch (_) {}
      }
    }

    // Restore maxDevices into user's subscriptionDetails if missing
    if (_user != null && _user!.subscriptionDetails != null) {
      if (_maxDevices != null && _maxDevices! > 0) {
        if (_user!.subscriptionDetails!.maxDevices == null || _user!.subscriptionDetails!.maxDevices! < _maxDevices!) {
          _user = _user!.copyWith(
            subscriptionDetails: _user!.subscriptionDetails!.copyWith(maxDevices: _maxDevices),
          );
        }
      } else if (_user!.subscriptionDetails!.maxDevices != null && _user!.subscriptionDetails!.maxDevices! > 0) {
        _maxDevices = _user!.subscriptionDetails!.maxDevices;
      }
    }
  }

  static UserDetails? get user => _user;
  static int? get maxDevices => _maxDevices ?? _user?.subscriptionDetails?.maxDevices;

  static Future<String?> getCookie() async {
    if (_cookie != null && _cookie!.trim().isNotEmpty) {
      return _cookie;
    }
    try {
      _cookie = await storage.read(key: authCookie);
    } catch (_) {}
    if (_cookie == null || _cookie!.trim().isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        _cookie = prefs.getString(authCookie);
      } catch (_) {}
    }
    return _cookie;
  }

  /// Helper to extract cookie by name (default 'XXAFIT') from a List<String> of Set-Cookie headers
  static String extractCookieValue(List<String>? cookies, [String name = 'XXAFIT']) {
    if (cookies == null || cookies.isEmpty) return '';
    for (final cookie in cookies) {
      final parts = cookie.split(';');
      for (final part in parts) {
        final trimmed = part.trim();
        if (trimmed.startsWith('$name=')) {
          return trimmed;
        }
      }
    }
    // Fallback: first part of first cookie
    final firstPart = cookies.first.split(';').first.trim();
    if (firstPart.isNotEmpty) {
      return firstPart.contains('=') ? firstPart : '$name=$firstPart';
    }
    return '';
  }

  /// Helper to format a cookie string for the 'Cookie' header (ensures XXAFIT=<val>)
  static String formatCookieHeader(String? cookie, [String name = 'XXAFIT']) {
    if (cookie == null) return '';
    final trimmed = cookie.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.contains('$name=')) {
      return trimmed;
    }
    if (!trimmed.contains('=')) {
      return '$name=$trimmed';
    }
    return trimmed;
  }

  Future<void> saveAuthData({
    required String accessToken,
    required String cookie,
    required int reasonCode,
    required Map<String, dynamic> userJson,
  }) async {
    final formattedCookie = formatCookieHeader(cookie);
    TokenApi._accessToken = accessToken;
    TokenApi._cookie = formattedCookie;
    TokenApi._reasonCode = reasonCode;
    
    // print('💾 [TokenApi] Saving auth data - Cookie: $formattedCookie');
    
    await storage.write(key: authCookie, value: formattedCookie);
    await storage.write(key: accessTokenKey, value: accessToken);
    await storage.write(key: reasonCodeKey, value: reasonCode.toString());
    
    final user = UserDetails.fromJson(userJson);
    TokenApi._user = user;
    
    final fullUserJsonString = jsonEncode(user.toJson());
    await storage.write(key: userKey, value: fullUserJsonString);
    
    // print('💾 FULL USER OBJECT SAVED TO STORAGE: $fullUserJsonString');
    
    if (user.subscriptionDetails != null) {
      await storage.write(key: subDetailsKey, value: jsonEncode(user.subscriptionDetails!.toJson()));
    }

    if (user.subscriptionDetails?.maxDevices != null && user.subscriptionDetails!.maxDevices! > 0) {
      _maxDevices = user.subscriptionDetails!.maxDevices;
      await storage.write(key: maxDevicesKey, value: _maxDevices.toString());
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(authCookie, formattedCookie);
      await prefs.setString(accessTokenKey, accessToken);
      await prefs.setString(Api.accessTokenKey, accessToken);
      await prefs.setString(reasonCodeKey, reasonCode.toString());
      await prefs.setString(userKey, fullUserJsonString);
      if (user.subscriptionDetails != null) {
        await prefs.setString(subDetailsKey, jsonEncode(user.subscriptionDetails!.toJson()));
      }
      if (_maxDevices != null && _maxDevices! > 0) {
        await prefs.setInt(maxDevicesKey, _maxDevices!);
        await prefs.setString(maxDevicesKey, _maxDevices.toString());
      }
    } catch (_) {}
  }

  Future<void> updateMaxDevices(int count) async {
    _maxDevices = count;
    await storage.write(key: maxDevicesKey, value: count.toString());
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(maxDevicesKey, count);
      await prefs.setString(maxDevicesKey, count.toString());
    } catch (_) {}

    final currentUser = _user;
    if (currentUser != null && currentUser.subscriptionDetails != null) {
      final updatedSub = currentUser.subscriptionDetails!.copyWith(maxDevices: count);
      final updatedUser = currentUser.copyWith(subscriptionDetails: updatedSub);
      TokenApi._user = updatedUser;
      final userJson = jsonEncode(updatedUser.toJson());
      final subJson = jsonEncode(updatedSub.toJson());
      await storage.write(key: userKey, value: userJson);
      await storage.write(key: subDetailsKey, value: subJson);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(userKey, userJson);
        await prefs.setString(subDetailsKey, subJson);
      } catch (_) {}
    }
  }

  Future<void> updateSubscriptionDetails(SubscriptionDetails? subDetails) async {
    final currentUser = _user;
    if (currentUser == null) return;

    if (subDetails?.maxDevices != null && subDetails!.maxDevices! > 0) {
      _maxDevices = subDetails.maxDevices;
      await storage.write(key: maxDevicesKey, value: subDetails.maxDevices.toString());
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(maxDevicesKey, subDetails.maxDevices!);
        await prefs.setString(maxDevicesKey, subDetails.maxDevices.toString());
      } catch (_) {}
    } else if (_maxDevices != null && _maxDevices! > 0 && subDetails != null && (subDetails.maxDevices == null || subDetails.maxDevices! <= 1)) {
      subDetails = subDetails.copyWith(maxDevices: _maxDevices);
    }

    final String? status = subDetails?.status?.toLowerCase();
    final bool active = status == "active" || status == "praemium" || status == "trialing" || status == "processing";

    final updatedUser = UserDetails(
      email: currentUser.email,
      name: currentUser.name,
      bio: currentUser.bio,
      avatarUrl: currentUser.avatarUrl,
      isSubscribed: active ? 1 : 0,
      isReviewer: currentUser.isReviewer,
      subscriptionDetails: subDetails,
    );

    TokenApi._user = updatedUser;
    final userJson = jsonEncode(updatedUser.toJson());
    await storage.write(key: userKey, value: userJson);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(userKey, userJson);
    } catch (_) {}
    
    if (subDetails != null) {
      final subJson = jsonEncode(subDetails.toJson());
      await storage.write(key: subDetailsKey, value: subJson);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(subDetailsKey, subJson);
      } catch (_) {}
    } else {
      await storage.delete(key: subDetailsKey);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(subDetailsKey);
      } catch (_) {}
    }
  }

  /// Updates subscription details from the get_subscription_status API response
  /// Sets subscription_details object key values and is_subscribed to 1
  Future<void> updateSubscriptionFromStatusResponse({
    required SubscriptionDetails subDetails,
    int isSubscribed = 1,
  }) async {
    final currentUser = _user;
    if (currentUser == null) return;

    if (subDetails.maxDevices != null && subDetails.maxDevices! > 0) {
      _maxDevices = subDetails.maxDevices;
      await storage.write(key: maxDevicesKey, value: subDetails.maxDevices.toString());
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(maxDevicesKey, subDetails.maxDevices!);
        await prefs.setString(maxDevicesKey, subDetails.maxDevices.toString());
      } catch (_) {}
    } else if (_maxDevices != null && _maxDevices! > 0 && (subDetails.maxDevices == null || subDetails.maxDevices! <= 1)) {
      subDetails = subDetails.copyWith(maxDevices: _maxDevices);
    }

    final updatedUser = currentUser.copyWith(
      isSubscribed: isSubscribed,
      subscriptionDetails: subDetails,
    );

    TokenApi._user = updatedUser;
    final userJson = jsonEncode(updatedUser.toJson());
    final subJson = jsonEncode(subDetails.toJson());

    await storage.write(key: userKey, value: userJson);
    await storage.write(key: subDetailsKey, value: subJson);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(userKey, userJson);
      await prefs.setString(subDetailsKey, subJson);
    } catch (_) {}
  }

  /// Sets user.is_subscribed to 0, subscription_details.max_devices = 1, and status = "expired"
  /// in memory, FlutterSecureStorage, and SharedPreferences
  Future<void> updateAfterSubscriptionCancelled() async {
    final currentUser = _user;
    if (currentUser == null) return;

    _maxDevices = 1;
    await storage.write(key: maxDevicesKey, value: '1');
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(maxDevicesKey, 1);
      await prefs.setString(maxDevicesKey, '1');
    } catch (_) {}

    final existingSub = currentUser.subscriptionDetails;
    final updatedSub = SubscriptionDetails(
      subId: existingSub?.subId,
      plan: existingSub?.plan,
      maxDevices: 1,
      expiry: existingSub?.expiry,
      status: 'expired',
      amount: existingSub?.amount,
      planDurationValue: existingSub?.planDurationValue,
      planDurationType: existingSub?.planDurationType,
    );

    final updatedUser = currentUser.copyWith(
      isSubscribed: 0,
      subscriptionDetails: updatedSub,
    );

    TokenApi._user = updatedUser;
    final userJson = jsonEncode(updatedUser.toJson());
    final subJson = jsonEncode(updatedSub.toJson());

    await storage.write(key: userKey, value: userJson);
    await storage.write(key: subDetailsKey, value: subJson);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(userKey, userJson);
      await prefs.setString(subDetailsKey, subJson);
    } catch (_) {}
  }

  Future<void> clearSubscriptionData() async {
    final currentUser = _user;
    if (currentUser == null) return;

    final updatedUser = UserDetails(
      email: currentUser.email,
      name: currentUser.name,
      bio: currentUser.bio,
      avatarUrl: currentUser.avatarUrl,
      isSubscribed: 0,
      isReviewer: currentUser.isReviewer,
      subscriptionDetails: null,
    );

    TokenApi._user = updatedUser;
    final userJson = jsonEncode(updatedUser.toJson());
    await storage.write(key: userKey, value: userJson);
    await storage.delete(key: subDetailsKey);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(userKey, userJson);
      await prefs.remove(subDetailsKey);
    } catch (_) {}
  }

  Future<void> updateIsSubscribed(int isSubscribed) async {
    final currentUser = _user;
    if (currentUser == null) return;

    final updatedUser = UserDetails(
      email: currentUser.email,
      name: currentUser.name,
      bio: currentUser.bio,
      avatarUrl: currentUser.avatarUrl,
      isSubscribed: isSubscribed,
      isReviewer: currentUser.isReviewer,
      subscriptionDetails: currentUser.subscriptionDetails,
    );

    TokenApi._user = updatedUser;
    final userJson = jsonEncode(updatedUser.toJson());
    await storage.write(key: userKey, value: userJson);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(userKey, userJson);
    } catch (_) {}
  }

  Future<void> updateLocalProfile({required String name, required String bio, String? avatarUrl}) async {
    final currentUser = _user;
    if (currentUser == null) return;

    final updatedUser = UserDetails(
      email: currentUser.email,
      name: name,
      bio: bio,
      avatarUrl: avatarUrl ?? currentUser.avatarUrl,
      isSubscribed: currentUser.isSubscribed,
      isReviewer: currentUser.isReviewer,
      subscriptionDetails: currentUser.subscriptionDetails,
    );

    TokenApi._user = updatedUser;
    final userJson = jsonEncode(updatedUser.toJson());
    await storage.write(key: userKey, value: userJson);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(userKey, userJson);
    } catch (_) {}
  }

  Future<void> saveUserData(UserDetails newUser) async {
    // Merge logic: keep existing values if new ones are empty/null
    final currentUser = _user;

    // Retain active subscription details if newUser doesn't have them
    final existingSub = newUser.subscriptionDetails ?? currentUser?.subscriptionDetails;
    final int? resolvedMaxDevices = newUser.subscriptionDetails?.maxDevices ??
        currentUser?.subscriptionDetails?.maxDevices ??
        _maxDevices;

    final resolvedSub = existingSub != null && resolvedMaxDevices != null && resolvedMaxDevices > 0
        ? existingSub.copyWith(maxDevices: resolvedMaxDevices)
        : existingSub;

    if (resolvedMaxDevices != null && resolvedMaxDevices > 0) {
      _maxDevices = resolvedMaxDevices;
      await storage.write(key: maxDevicesKey, value: resolvedMaxDevices.toString());
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(maxDevicesKey, resolvedMaxDevices);
        await prefs.setString(maxDevicesKey, resolvedMaxDevices.toString());
      } catch (_) {}
    }

    final subStatus = resolvedSub?.status?.toLowerCase();
    final bool hasActiveSub = subStatus == 'active' || 
                              subStatus == 'trialing' || 
                              subStatus == 'praemium' || 
                              subStatus == 'processing';

    // Prioritize active subscription state: if active, isSubscribed is always 1
    final int mergedIsSubscribed = hasActiveSub
        ? 1
        : (subStatus == 'expired' || subStatus == 'canceled'
            ? 0
            : (newUser.isSubscribed != 0 ? newUser.isSubscribed : (currentUser?.isSubscribed ?? 0)));

    final mergedUser = UserDetails(
      email: newUser.email.isNotEmpty ? newUser.email : (currentUser?.email ?? ''),
      name: newUser.name ?? currentUser?.name,
      bio: newUser.bio ?? currentUser?.bio,
      avatarUrl: (newUser.avatarUrl != null && newUser.avatarUrl!.isNotEmpty)
          ? newUser.avatarUrl
          : currentUser?.avatarUrl,
      isSubscribed: mergedIsSubscribed,
      isReviewer: newUser.isReviewer != 0 ? newUser.isReviewer : (currentUser?.isReviewer ?? 0),
      emailVerified: newUser.emailVerified,
      subscriptionDetails: resolvedSub,
    );

    TokenApi._user = mergedUser;
    final userJson = jsonEncode(mergedUser.toJson());
    await storage.write(key: userKey, value: userJson);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(userKey, userJson);
    } catch (_) {}

    if (mergedUser.subscriptionDetails != null) {
      final subJson = jsonEncode(mergedUser.subscriptionDetails!.toJson());
      await storage.write(key: subDetailsKey, value: subJson);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(subDetailsKey, subJson);
      } catch (_) {}
    }
  }

  static Future<UserDetails?> getUserDetails({bool forceRefresh = false}) async {
    if (_user != null && !forceRefresh) return _user;
    final userData = await storage.read(key: userKey);
    if (userData != null) {
      _user = UserDetails.fromJson(jsonDecode(userData));
      return _user;
    }
    return null;
  }

  static Future<SubscriptionDetails?> getSubscriptionDetails() async {
    final subData = await storage.read(key: subDetailsKey);
    if (subData != null) {
      return SubscriptionDetails.fromJson(jsonDecode(subData));
    }
    return null;
  }

  static Future<int?> getReasonCode() async {
    if (_reasonCode != null) return _reasonCode;
    final code = await storage.read(key: reasonCodeKey);
    if (code != null) {
      _reasonCode = int.tryParse(code);
    }
    return _reasonCode;
  }

  Future<void> saveTokens({required String accessToken, required String cookie, String? email}) async {
    TokenApi._cookie = cookie;
    TokenApi._accessToken = accessToken;
    await storage.write(key: authCookie, value: cookie);
    await storage.write(key: accessTokenKey, value: accessToken);

    // Save user email if provided
    if(email != null && email.isNotEmpty) {
      await storage.write(key: userEmailKey, value: email);
    }
  }

  Future<void> deleteCookie() async {
    TokenApi._cookie = null;
    TokenApi._accessToken = null;
    TokenApi._user = null;
    TokenApi._reasonCode = null;
    TokenApi._maxDevices = null;
    TokenApi._resetToken = null;
    await storage.deleteAll();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(authCookie);
      await prefs.remove(accessTokenKey);
      await prefs.remove(userKey);
      await prefs.remove(subDetailsKey);
      await prefs.remove(reasonCodeKey);
    } catch (_) {}
  }

  static const resetTokenKey = 'reset_token';
  static String? _resetToken;

  static Future<void> saveResetToken(String token) async {
    _resetToken = token;
    await storage.write(key: resetTokenKey, value: token);
  }

  static Future<String?> getResetToken() async {
    if (_resetToken != null) {
      return _resetToken;
    }
    _resetToken = await storage.read(key: resetTokenKey);
    return _resetToken;
  }

  static Future<void> deleteResetToken() async {
    _resetToken = null;
    await storage.delete(key: resetTokenKey);
    await storage.delete(key: otpTokenKey);
    await storage.delete(key: passwordResetTokenKey);
  }

  static Future<void> saveOtpToken(String token) => saveResetToken(token);
  static Future<String?> getOtpToken() => getResetToken();
  static Future<void> deleteOtpToken() => deleteResetToken();

  static Future<void> savePasswordResetToken(String token) => saveResetToken(token);
  static Future<String?> getPasswordResetToken() => getResetToken();
  static Future<void> deletePasswordResetToken() => deleteResetToken();

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

  static String maskEmail(String? email) {
    if (email == null) return '';
    final trimmed = email.trim();
    if (trimmed.isEmpty) return '';
    if (trimmed.length <= 2) return '$trimmed***';
    return '${trimmed[0]}***${trimmed[trimmed.length - 1]}';
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

    final formattedCookie = formatCookieHeader(_cookie);
    var headers = {
      if (formattedCookie.isNotEmpty) 'Cookie': formattedCookie,
      'x-device-type': DeviceUtil.getDeviceType(),
    };

    try{
      // print('🔄 Refreshing access token using cookie...');
      final response = await dio.get('/refresh',
        options: Options(
          headers: headers,
        ),
      );

      if (response.statusCode == 200) {
        if(response.data['isSuccess'] == true){
          _accessToken = response.data['token'];
          // print('✅ Access token refreshed successfully');
          
          final setCookie = response.headers['set-cookie'];
          if (setCookie != null && setCookie.isNotEmpty) {
            final newCookie = extractCookieValue(setCookie, 'XXAFIT');
            if (newCookie.isNotEmpty) {
              _cookie = newCookie;
              await storage.write(key: authCookie, value: newCookie);
              try {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString(authCookie, newCookie);
              } catch (_) {}
              // print('🍪 [TokenApi] Refreshed cookie updated: $newCookie');
            }
          }

          // Save the new access token
          await storage.write(key: accessTokenKey, value: _accessToken!);
          
          return _accessToken;
        }
      }
      
      // Only delete cookie if the server explicitly rejects the refresh token
      if (response.statusCode == 401 || response.statusCode == 403 || response.data?['isSuccess'] == false) {
        await deleteCookie();
      }
      return null;
    }
    catch (e){
      // print('❌ Error refreshing token: $e.');
      // Only delete cookie on actual 401/403 Dio responses, not transient network errors
      if (e is DioException && (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
        await deleteCookie();
      }
      return null;
    }
  }

  static Future<void> clearOnFreshInstall() async {
    final prefs = await SharedPreferences.getInstance();
    final hasLaunched = prefs.getBool(_firstLaunchKey);

    if (hasLaunched == null) {
      await storage.deleteAll();
      await prefs.setBool(_firstLaunchKey, true);
    }
  }

  static Future<void> clearPreferencesExceptDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(DeviceUtil.deviceIdKey) ?? prefs.getString('device_id');
    if (deviceId == null || !DeviceUtil.isValidDeviceId(deviceId)) {
      deviceId = await DeviceUtil.getDeviceId();
    }

    await prefs.clear();

    await prefs.setString(DeviceUtil.deviceIdKey, deviceId);
    await prefs.setString('device_id', deviceId);
  }

  static bool isUserLoggedIn() {
    // print('🧐 Checking isUserLoggedIn: _cookie is "${_cookie}"');
    return _cookie != null && _cookie!.isNotEmpty;
  }
}