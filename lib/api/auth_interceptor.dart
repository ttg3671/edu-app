import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:edu_gym/api/token_api.dart';
import 'package:edu_gym/core/error/friendly_error.dart';
import 'package:edu_gym/core/utils/device_util.dart';
import 'package:edu_gym/features/auth/presentation/pages/verify_email.dart';
import 'package:edu_gym/main.dart';
import 'package:flutter/material.dart';

class AuthInterceptor extends Interceptor {
  final Dio _dio;
  bool _isRefreshing = false;
  static bool _isNavigatingToVerifyEmail = false;

  AuthInterceptor(this._dio);

  static void checkAndHandleEmailVerification(int? statusCode, dynamic resData, [String? errorMsg]) {
    String message = '';
    bool isSuccess = true;

    if (resData is Map) {
      isSuccess = resData['isSuccess'] ?? (statusCode != null && statusCode >= 200 && statusCode < 300);
      message = resData['message']?.toString() ?? '';
    } else if (resData is String) {
      try {
        final decoded = jsonDecode(resData);
        if (decoded is Map) {
          isSuccess = decoded['isSuccess'] ?? true;
          message = decoded['message']?.toString() ?? '';
        }
      } catch (_) {
        message = resData;
      }
    } else if (errorMsg != null) {
      message = errorMsg;
    }

    final lowerMsg = message.toLowerCase();
    final bool isEmailVerificationRequired =
        (statusCode == 403 || !isSuccess) &&
        (lowerMsg.contains('email verification') || lowerMsg.contains('verify your email'));

    if (isEmailVerificationRequired) {
      if (_isNavigatingToVerifyEmail) return;
      _isNavigatingToVerifyEmail = true;

      Future.delayed(const Duration(seconds: 2), () {
        _isNavigatingToVerifyEmail = false;
      });

      String email = '';
      if (resData is Map) {
        email = resData['email']?.toString() ??
            resData['data']?['email']?.toString() ??
            resData['data']?['user']?['email']?.toString() ??
            '';
      }
      if (email.isEmpty) {
        email = TokenApi.user?.email ?? '';
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigatorKey.currentState != null) {
          navigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (context) => VerifyEmail(email: email),
            ),
          );
        }
      });
    }
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    options.headers['x-device-type'] = DeviceUtil.getDeviceType();

    // Skip adding auth header for auth endpoints
    final path = options.path;
    if (path.contains('/auth/sign-in') || 
        path.contains('/auth/sign-up') ||
        path.contains('/auth/forgot-password') ||
        path.contains('/auth/reset-password') ||
        path.contains('/refresh')) {
      return handler.next(options);
    }

    // For logout: send both Cookie and Authorization (if available) so backend can clear session.
    // getAccessToken() is called first because, if the access token is expired, it silently
    // refreshes via /refresh - and the backend rotates the XXAFIT cookie on every refresh. Reading
    // the cookie before that call could attach an already-rotated-out value to the logout request,
    // which the backend would then fail to find in its session store.
    if (path.contains('/logout')) {
      final accessToken = await TokenApi().getAccessToken();
      if (accessToken != null && accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';
        // print('🔑 [AuthInterceptor] Added Authorization header for logout');
      }

      final rawCookie = await TokenApi.getCookie();
      final cookieHeader = TokenApi.formatCookieHeader(rawCookie);
      if (cookieHeader.isNotEmpty) {
        options.headers['Cookie'] = cookieHeader;
        // print('🍪 [AuthInterceptor] Added Cookie header to logout: $cookieHeader');
      } else {
        // print('⚠️ [AuthInterceptor] Warning: No cookie found for logout request');
      }
      return handler.next(options);
    }

    final accessToken = await TokenApi().getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    final cookie = await TokenApi.getCookie();
    final cookieHeader = TokenApi.formatCookieHeader(cookie);
    if (cookieHeader.isNotEmpty) {
      options.headers['Cookie'] = cookieHeader;
    }

    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    checkAndHandleEmailVerification(response.statusCode, response.data);
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    checkAndHandleEmailVerification(err.response?.statusCode, err.response?.data, err.message);

    // If we get a 401 error and we're not already refreshing
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      // Don't try to refresh if the error was on the refresh endpoint, other auth endpoints, or logout
      final path = err.requestOptions.path;
      if (path.contains('/refresh') ||
          path.contains('/auth/sign-in') ||
          path.contains('/auth/sign-up') ||
          path.contains('/logout')) {
        return handler.next(_friendly(err));
      }

      _isRefreshing = true;
      try {
        // print('🔐 401 Detected. Attempting to refresh token...');
        final newToken = await TokenApi().getAccessToken();
        
        if (newToken != null) {
          _isRefreshing = false;
          // Retry the original request with the new token and cookie
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $newToken';
          options.headers['x-device-type'] = DeviceUtil.getDeviceType();
          
          final cookie = await TokenApi.getCookie();
          if (cookie != null && cookie.isNotEmpty) {
            options.headers['Cookie'] = cookie;
          }
          
          final response = await _dio.fetch(options);
          return handler.resolve(response);
        }
      } catch (e) {
        // print('❌ Failed to refresh token during interceptor: $e');
      } finally {
        _isRefreshing = false;
      }
    }
    return handler.next(_friendly(err));
  }

  // Callers show `response.data['message'] ?? e.message`. For server errors
  // (5xx), dropped connections and non-JSON error pages that would be Dio's
  // own technical text (or a crash on a non-map body), so hand them the
  // friendly network-error message in the shape they expect instead.
  static DioException _friendly(DioException err) {
    final response = err.response;
    final status = response?.statusCode;
    final isServerError = status != null && status >= 500;
    if (response == null) {
      return err.copyWith(message: FriendlyError.networkError);
    }
    if (isServerError || response.data is! Map) {
      response.data = <String, dynamic>{
        'isSuccess': false,
        'message': FriendlyError.networkError,
      };
      return err.copyWith(message: FriendlyError.networkError);
    }
    return err;
  }
}
