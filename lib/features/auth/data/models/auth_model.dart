import '../../../../modal/user_details.dart';

class AuthModel {
  final bool isSuccess;
  final String message;
  final String? token;
  final int? reasonCode;
  final bool emailVerified;
  final UserDetails? user;

  AuthModel({
    required this.isSuccess,
    required this.message,
    this.token,
    this.reasonCode,
    this.emailVerified = true,
    this.user,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    // Handle new structure where token, reasonCode and user are inside 'data'
    final data = json['data'];
    final userJson = data != null ? data['user'] : json['user'];
    final user = userJson != null && userJson is Map<String, dynamic>
        ? UserDetails.fromJson(userJson)
        : null;

    bool isEmailVerified = true;
    if (user != null) {
      isEmailVerified = user.emailVerified;
    } else if (userJson != null && userJson is Map && userJson['email_verified'] != null) {
      isEmailVerified = userJson['email_verified'] == true || userJson['email_verified'] == 1;
    } else if (json['email_verified'] != null) {
      isEmailVerified = json['email_verified'] == true || json['email_verified'] == 1;
    }

    return AuthModel(
      isSuccess: json['isSuccess'] ?? false,
      message: json['message'] ?? '',
      token: data != null ? data['accessToken'] : json['token'],
      reasonCode: data != null ? data['reasonCode'] : json['reasonCode'],
      emailVerified: isEmailVerified,
      user: user,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isSuccess': isSuccess,
      'message': message,
      'token': token,
      'reasonCode': reasonCode,
      'email_verified': emailVerified,
    };
  }
}
