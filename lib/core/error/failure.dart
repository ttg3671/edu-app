class Failure {
  final String? message;

  String? get msg => message;

  Failure([this.message = 'An error occurred']);

  @override
  String toString() => message ?? 'An error occurred';
}