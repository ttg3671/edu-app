/// Keeps raw technical errors (Dio / Dart exception text, server 5xx pages)
/// away from the user by swapping them for one friendly message.
class FriendlyError {
  FriendlyError._();

  /// Current app language; kept in sync by LanguageCubit so the message can
  /// be built where there is no BuildContext (API layer, cubits).
  static String languageCode = 'es';

  static String get networkError => languageCode == 'en'
      ? "Oops! There's been a network error"
      : '¡Ups! Ha habido un error de red';

  // Fragments that only show up in framework / transport errors, never in a
  // message the backend wrote for the user.
  static const _technicalMarkers = [
    'exception',
    'dioerror',
    'status code',
    'validatestatus',
    'socket',
    'failed host lookup',
    'connection',
    'timeout',
    'timed out',
    'handshake',
    'xmlhttprequest',
    'errno',
    'is not a subtype',
    'null check operator',
    'nosuchmethod',
    'unexpected error',
    'unexpected character',
    'internal server error',
    'bad gateway',
    'service unavailable',
    'gateway time',
    'stack trace',
    '<html',
    '<!doctype',
  ];

  static bool isTechnical(String message) {
    final lower = message.toLowerCase();
    return _technicalMarkers.any(lower.contains);
  }

  /// Returns [message] unchanged unless it is a raw technical error, in
  /// which case the friendly network-error text is returned instead.
  static String? clean(String? message) {
    if (message == null || message.isEmpty) return message;
    return isTechnical(message) ? networkError : message;
  }
}
