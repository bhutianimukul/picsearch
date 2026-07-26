import 'package:local_auth/local_auth.dart';

/// Gates reveal of sensitive values behind device biometrics / credential.
class Biometric {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Whether the user may see the value now. If the device has no biometric or
  /// screen-lock set up, we allow it (there's nothing to authenticate against);
  /// an explicit cancelled/failed prompt returns false. Plugin errors fail-open
  /// so the app never becomes unusable.
  Future<bool> confirm(String reason) async {
    try {
      if (!await _auth.isDeviceSupported()) return true;
      return await _auth.authenticate(localizedReason: reason);
    } catch (_) {
      return true;
    }
  }
}
