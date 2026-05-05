class AuthModel {
  final bool isSuccess;
  final String message;
  final String? token;
  final int? reasonCode;

  AuthModel({
    required this.isSuccess,
    required this.message,
    this.token,
    this.reasonCode,
  });

  factory AuthModel.fromJson(Map<String, dynamic> json) {
    return AuthModel(
      isSuccess: json['isSuccess'],
      message: json['message'],
      token: json['token'],
      reasonCode: json['reasonCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isSuccess': isSuccess,
      'message': message,
      'token': token,
      'reasonCode': reasonCode,
    };
  }
}
