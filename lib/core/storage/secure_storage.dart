import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper sobre flutter_secure_storage para tokens JWT y biometría con tolerancia a fallos en Android.
class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      resetOnError: true,
    ),
  );

  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kUserRole = 'user_role';
  static const _kUserId = 'user_id';
  static const _kBiometricsEnabled = 'biometrics_enabled';
  static const _kSavedEmail = 'saved_email';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      await _storage.write(key: _kAccessToken, value: accessToken);
      await _storage.write(key: _kRefreshToken, value: refreshToken);
    } catch (_) {}
  }

  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _kAccessToken);
    } catch (_) {
      try {
        await _storage.deleteAll();
      } catch (_) {}
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _kRefreshToken);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUserMeta({required String role, required String userId}) async {
    try {
      await _storage.write(key: _kUserRole, value: role);
      await _storage.write(key: _kUserId, value: userId);
    } catch (_) {}
  }

  Future<String?> getUserRole() async {
    try {
      return await _storage.read(key: _kUserRole);
    } catch (_) {
      return null;
    }
  }

  Future<String?> getUserId() async {
    try {
      return await _storage.read(key: _kUserId);
    } catch (_) {
      return null;
    }
  }

  Future<void> setBiometricsEnabled(bool enabled) async {
    try {
      await _storage.write(key: _kBiometricsEnabled, value: enabled ? '1' : '0');
    } catch (_) {}
  }

  Future<bool> isBiometricsEnabled() async {
    try {
      final val = await _storage.read(key: _kBiometricsEnabled);
      return val == '1';
    } catch (_) {
      return false;
    }
  }

  Future<void> saveEmail(String email) async {
    try {
      await _storage.write(key: _kSavedEmail, value: email);
    } catch (_) {}
  }

  Future<String?> getSavedEmail() async {
    try {
      return await _storage.read(key: _kSavedEmail);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteAccessToken() async {
    try {
      await _storage.delete(key: _kAccessToken);
    } catch (_) {}
  }

  Future<void> clear({bool keepBiometrics = false}) async {
    try {
      await _storage.delete(key: _kAccessToken);
      if (!keepBiometrics) {
        await _storage.delete(key: _kRefreshToken);
        await _storage.delete(key: _kBiometricsEnabled);
        await _storage.delete(key: _kSavedEmail);
        await _storage.delete(key: _kUserRole);
        await _storage.delete(key: _kUserId);
      }
    } catch (_) {
      try {
        await _storage.deleteAll();
      } catch (_) {}
    }
  }
}
