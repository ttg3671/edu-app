class ServerException{
  final String? msg;
  final int? statusCode;
  final dynamic response;

  ServerException({
    this.msg,
    this.statusCode,
    this.response
  });
}