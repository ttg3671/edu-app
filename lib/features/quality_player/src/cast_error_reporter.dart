import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Logs a Chromecast failure (init, discovery, connect, load media) to
/// Crashlytics as a non-fatal issue. Never throws, so it is safe to call from
/// inside catch blocks.
void reportCastError(Object error, StackTrace? stack, String reason) {
  debugPrint('Cast error [$reason]: $error');
  try {
    FirebaseCrashlytics.instance.recordError(
      error,
      stack ?? StackTrace.current,
      reason: 'Cast: $reason',
      fatal: false,
    );
  } catch (_) {
    // Firebase not initialized - nothing more we can do.
  }
}
