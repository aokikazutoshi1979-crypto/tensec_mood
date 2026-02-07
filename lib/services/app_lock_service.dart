import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class AppLockService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isSupported() async {
    try {
      final supported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      return supported || canCheck;
    } catch (error) {
      debugPrint('Lock support check failed: $error');
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'アプリを開くために認証します',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (error) {
      debugPrint('Authentication failed: $error');
      return false;
    }
  }
}
