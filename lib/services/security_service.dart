import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  static const _pinEnabledKey = 'memory_maker_pin_enabled';
  static const _pinKey = 'memory_maker_pin_code';
  static const _bioEnabledKey = 'memory_maker_biometric_enabled';
  static DateTime? _suppressLockUntil;

  final LocalAuthentication _auth = LocalAuthentication();

  void suppressLockFor([Duration duration = const Duration(seconds: 90)]) {
    _suppressLockUntil = DateTime.now().add(duration);
  }

  bool get isLockSuppressed {
    final until = _suppressLockUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  Future<bool> get pinEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pinEnabledKey) ?? false;
  }

  Future<bool> get biometricEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_bioEnabledKey) ?? false;
  }

  Future<bool> get hasAnyLock async => await pinEnabled || await biometricEnabled;

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pinKey, pin);
    await prefs.setBool(_pinEnabledKey, true);
  }

  Future<void> disablePin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pinKey);
    await prefs.setBool(_pinEnabledKey, false);
  }

  Future<bool> verifyPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString(_pinKey) ?? '') == pin;
  }

  Future<bool> canUseBiometrics() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      final available = await _auth.getAvailableBiometrics();
      return supported && canCheck && available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticateBiometric() async {
    try {
      if (!await canUseBiometrics()) return false;
      return _auth.authenticate(
        localizedReason: 'Unlock Memory Maker',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> enableBiometric() async {
    suppressLockFor(const Duration(seconds: 30));
    final ok = await authenticateBiometric();
    if (ok) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_bioEnabledKey, true);
    }
    return ok;
  }

  Future<void> disableBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bioEnabledKey, false);
  }
}
