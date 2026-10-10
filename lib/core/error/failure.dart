import 'friendly_error.dart';

class Failure {
  final String? message;

  String? get msg => message;

  // Every error shown to the user passes through here, so this is where raw
  // exception text is replaced with the friendly network-error message.
  Failure([String? message = 'An error occurred'])
      : message = FriendlyError.clean(message);

  @override
  String toString() => message ?? 'An error occurred';
}
