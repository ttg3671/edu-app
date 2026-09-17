import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceUtil {
  static const String deviceIdKey = 'Device_Id';
  static const String _legacyDeviceIdKey = 'device_id';

  /// Dedicated secure-storage entry for the persistent device id, isolated
  /// (via a distinct iOS Keychain service/accountName) from TokenApi's
  /// `storage`, so logout/delete-account/fresh-install wipes of that store
  /// never touch this value. On iOS, Keychain items survive app uninstall,
  /// which is what lets the id survive a reinstall.
  static const String _persistentDeviceIdKey = 'persistent_device_id';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    iOptions: IOSOptions(accountName: 'com.edugarciamovimiento.deviceidentity'),
  );

  /// Android has no storage that survives uninstall, so the id is instead
  /// derived deterministically from Settings.Secure.ANDROID_ID (stable across
  /// install/uninstall/reinstall as long as the device isn't factory-reset
  /// and the app's signing key doesn't change).
  static const MethodChannel _platformChannel = MethodChannel('com.edugarciamovimiento/device_id');

  /// Known bad/placeholder ANDROID_ID values returned by some buggy/rooted devices.
  static const Set<String> _badAndroidIds = {'9774d56d682e549c', '0000000000000000'};

  /// Regex pattern strictly matching /^[A-Za-z0-9-]+$/
  static final RegExp deviceIdRegex = RegExp(r'^[A-Za-z0-9-]+$');

  /// Validates if a device ID matches the required regex ^[A-Za-z0-9-]+$ and length (9-12 chars)
  static bool isValidDeviceId(String? id) {
    if (id == null || id.isEmpty || id.length < 9 || id.length > 12) {
      return false;
    }
    return deviceIdRegex.hasMatch(id);
  }

  /// Retrieves or creates a valid device ID matching /^[A-Za-z0-9-]+$/.
  ///
  /// The id is generated once on first install and is then kept stable for
  /// the lifetime of the device: it survives logout/delete-account (callers
  /// preserve it explicitly, see TokenApi.clearPreferencesExceptDeviceId)
  /// and, where the platform allows it, survives app uninstall/reinstall too.
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Keep whatever is already stored locally. This matters for users who
    //    already had a (randomly generated) id before platform-persistent
    //    recovery existed — an app update must not silently rotate their id.
    String? deviceId = prefs.getString(deviceIdKey) ?? prefs.getString(_legacyDeviceIdKey);
    if (deviceId != null && !isValidDeviceId(deviceId)) deviceId = null;

    // 2. Nothing stored locally (fresh install, or local storage was wiped
    //    by an uninstall/reinstall) — try to recover a platform-persistent id.
    deviceId ??= await _getPlatformPersistentDeviceId();

    // 3. Last resort: generate a new random one.
    deviceId ??= generateDeviceId();

    await _persist(deviceId);
    return deviceId;
  }

  static Future<void> _persist(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(deviceIdKey, deviceId);
    await prefs.setString(_legacyDeviceIdKey, deviceId);
    if (!kIsWeb && Platform.isIOS) {
      try {
        await _secureStorage.write(key: _persistentDeviceIdKey, value: deviceId);
      } catch (_) {}
    }
  }

  static Future<String?> _getPlatformPersistentDeviceId() async {
    if (kIsWeb) return null;
    try {
      if (Platform.isIOS) {
        final existing = await _secureStorage.read(key: _persistentDeviceIdKey);
        return isValidDeviceId(existing) ? existing : null;
      } else if (Platform.isAndroid) {
        final androidId = await _platformChannel.invokeMethod<String>('getAndroidId');
        return _deriveFromAndroidId(androidId);
      }
    } catch (_) {}
    return null;
  }

  static String? _deriveFromAndroidId(String? androidId) {
    if (androidId == null || androidId.isEmpty) return null;
    if (_badAndroidIds.contains(androidId.toLowerCase())) return null;

    final cleaned = androidId.replaceAll(RegExp(r'[^A-Za-z0-9]'), '');
    if (cleaned.isEmpty) return null;

    final truncated = cleaned.length > 12 ? cleaned.substring(0, 12) : cleaned;
    return isValidDeviceId(truncated) ? truncated : null;
  }

  /// Reads the currently persisted device id (Keychain on iOS, else prefs)
  /// without generating a new one. Used to snapshot the id around
  /// TokenApi's `storage.deleteAll()` calls, since that wipes the whole
  /// secure-storage keychain entry set — including ours — regardless of
  /// which key/service wrote it.
  static Future<String?> peekPersistedDeviceId() async {
    if (!kIsWeb && Platform.isIOS) {
      try {
        final existing = await _secureStorage.read(key: _persistentDeviceIdKey);
        if (isValidDeviceId(existing)) return existing;
      } catch (_) {}
    }
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(deviceIdKey) ?? prefs.getString(_legacyDeviceIdKey);
    return isValidDeviceId(id) ? id : null;
  }

  /// Re-writes the device id into secure storage after a `storage.deleteAll()`
  /// wipe. Pair with [peekPersistedDeviceId] taken before the wipe.
  static Future<void> restoreSecureDeviceId(String? deviceId) async {
    if (deviceId == null || !isValidDeviceId(deviceId)) return;
    if (!kIsWeb && Platform.isIOS) {
      try {
        await _secureStorage.write(key: _persistentDeviceIdKey, value: deviceId);
      } catch (_) {}
    }
  }

  /// Generates a valid random device ID containing only [A-Za-z0-9-] with length between 9 and 12
  static String generateDeviceId() {
    final random = Random.secure();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-';
    // Generate length between 9 and 12
    final length = 9 + random.nextInt(4); // 9, 10, 11, or 12

    // Ensure it starts and ends with alphanumeric characters
    const alphaNumChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final List<String> buffer = [];

    buffer.add(alphaNumChars[random.nextInt(alphaNumChars.length)]);
    for (int i = 1; i < length - 1; i++) {
      buffer.add(chars[random.nextInt(chars.length)]);
    }
    buffer.add(alphaNumChars[random.nextInt(alphaNumChars.length)]);

    return buffer.join();
  }

  static String getDeviceType() {
    if (kIsWeb) {
      return 'web';
    } else if (Platform.isAndroid) {
      return 'android';
    } else if (Platform.isIOS) {
      return 'ios';
    } else {
      return 'web';
    }
  }
}
