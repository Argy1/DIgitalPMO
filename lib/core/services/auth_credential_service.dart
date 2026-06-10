import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

const _keyPhone = 'saved_phone';
const _keyPassword = 'saved_password';
const _keyBiometricEnabled = 'biometric_login_enabled';

/// Stores and retrieves login credentials + manages biometric login state.
/// Credentials are kept in FlutterSecureStorage (hardware-backed on Android).
class AuthCredentialService {
  AuthCredentialService._();
  static final AuthCredentialService instance = AuthCredentialService._();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final _localAuth = LocalAuthentication();

  // ── Credential persistence ─────────────────────────────────────────────────

  Future<void> saveCredentials(String phone, String password) async {
    await Future.wait([
      _storage.write(key: _keyPhone, value: phone),
      _storage.write(key: _keyPassword, value: password),
    ]);
  }

  Future<({String phone, String password})?> loadCredentials() async {
    final phone = await _storage.read(key: _keyPhone);
    final password = await _storage.read(key: _keyPassword);
    if (phone == null || password == null) return null;
    return (phone: phone, password: password);
  }

  Future<String?> loadSavedPhone() async =>
      _storage.read(key: _keyPhone);

  Future<void> clearCredentials() async {
    await Future.wait([
      _storage.delete(key: _keyPhone),
      _storage.delete(key: _keyPassword),
      _storage.delete(key: _keyBiometricEnabled),
    ]);
  }

  // ── Biometric login flag ───────────────────────────────────────────────────

  Future<bool> isBiometricLoginEnabled() async {
    final val = await _storage.read(key: _keyBiometricEnabled);
    return val == 'true';
  }

  Future<void> setBiometricLoginEnabled(bool enabled) async {
    await _storage.write(key: _keyBiometricEnabled, value: enabled.toString());
  }

  // ── Device capability checks ───────────────────────────────────────────────

  Future<bool> canUseBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  // ── Authenticate ──────────────────────────────────────────────────────────

  /// Prompt biometric/PIN dialog. Returns true if authenticated.
  Future<bool> authenticate({String reason = 'Masuk ke DigitalPMO'}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // allow PIN/pattern fallback
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
