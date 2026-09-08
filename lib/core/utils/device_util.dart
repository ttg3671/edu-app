import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceUtil {
  static const String deviceIdKey = 'Device_Id';
  static const String _legacyDeviceIdKey = 'device_id';

  /// Regex pattern strictly matching /^[A-Za-z0-9-]+$/
  static final RegExp deviceIdRegex = RegExp(r'^[A-Za-z0-9-]+$');

  /// Validates if a device ID matches the required regex ^[A-Za-z0-9-]+$ and length (9-12 chars)
  static bool isValidDeviceId(String? id) {
    if (id == null || id.isEmpty || id.length < 9 || id.length > 12) {
      return false;
    }
    return deviceIdRegex.hasMatch(id);
  }

  /// Retrieves or creates a valid device ID matching /^[A-Za-z0-9-]+$/
  static Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(deviceIdKey) ?? prefs.getString(_legacyDeviceIdKey);

    if (deviceId == null || !isValidDeviceId(deviceId)) {
      deviceId = generateDeviceId();
      await prefs.setString(deviceIdKey, deviceId);
    } else {
      // Ensure it is stored in the standard key
      await prefs.setString(deviceIdKey, deviceId);
    }

    return deviceId;
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
