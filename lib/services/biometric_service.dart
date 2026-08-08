import 'package:local_auth/local_auth.dart';

import '../config/app_strings.dart';

/// Why biometric unlock can or cannot be offered on this device.
enum BiometricAvailability {
  /// Hardware present and at least one biometric enrolled.
  ready,

  /// Hardware present, nothing enrolled yet.
  notEnrolled,

  /// No fingerprint/face hardware, or the platform doesn't support it.
  noHardware,

  /// Hardware exists but the device has no screen lock, so the keystore
  /// cannot bind a key to user authentication.
  noDeviceLock;

  bool get isReady => this == BiometricAvailability.ready;

  String? get message => switch (this) {
    BiometricAvailability.ready => null,
    BiometricAvailability.notEnrolled => AppStrings.biometricNotEnrolled,
    BiometricAvailability.noHardware => AppStrings.biometricUnavailable,
    BiometricAvailability.noDeviceLock => AppStrings.biometricNoDeviceLock,
  };
}

/// Outcome of a prompt: success, a plain refusal, or a failure worth showing.
class BiometricResult {
  final bool succeeded;

  /// Persian text to show the user, or `null` when there is nothing to say —
  /// success, or a cancellation the user performed deliberately.
  final String? message;

  const BiometricResult._(this.succeeded, this.message);

  static const success = BiometricResult._(true, null);
  static const cancelled = BiometricResult._(false, null);

  const BiometricResult.failed(String this.message) : succeeded = false;
}

/// Thin wrapper over `local_auth`.
///
/// Note what this class is **not** used for: releasing the vault key. The
/// biometric copy of the DEK is gated by the OS keystore itself (see
/// `SecureStorageService.readBiometricDek`), which raises its own prompt. Doing
/// a `local_auth` prompt first and then reading would show the user two prompts
/// back to back, and the first one would be decorative — it proves nothing about
/// whether the keystore will release the key.
///
/// So this is used for capability checks (may we offer the toggle?) and for
/// standalone confirmations, such as re-authenticating before revealing a
/// password on an already-unlocked screen.
class BiometricService {
  final LocalAuthentication _auth;

  BiometricService({LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication();

  /// Whether biometric unlock can be offered, and if not, why.
  Future<BiometricAvailability> availability() async {
    try {
      // `isDeviceSupported` is true when biometrics *or* a device credential
      // can be used; without it there is no screen lock at all.
      if (!await _auth.isDeviceSupported()) {
        return BiometricAvailability.noDeviceLock;
      }
      if (!await _auth.canCheckBiometrics) {
        return BiometricAvailability.noHardware;
      }
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isEmpty
          ? BiometricAvailability.notEnrolled
          : BiometricAvailability.ready;
    } catch (_) {
      return BiometricAvailability.noHardware;
    }
  }

  Future<bool> get isReady async => (await availability()).isReady;

  /// The enrolled kinds, used only to word the prompt ("چهره" vs "اثر انگشت").
  Future<List<BiometricType>> enrolledTypes() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return const [];
    }
  }

  /// Shows the system prompt.
  ///
  /// [biometricOnly] is false by default so a user whose finger is wet can fall
  /// back to their PIN — the same standard the OS applies to unlocking the
  /// device itself.
  Future<BiometricResult> authenticate({
    String reason = AppStrings.biometricReason,
    bool biometricOnly = false,
  }) async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: biometricOnly,
        // Retry after the app returns to the foreground instead of failing:
        // the biometric sheet itself backgrounds the app on some devices.
        persistAcrossBackgrounding: true,
      );
      return ok
          ? BiometricResult.success
          : const BiometricResult.failed(AppStrings.biometricFailed);
    } on LocalAuthException catch (e) {
      return _fromCode(e.code);
    } catch (_) {
      return const BiometricResult.failed(AppStrings.biometricFailed);
    }
  }

  /// The enum is explicitly documented as open for extension, so the default
  /// arm is required rather than exhaustive matching.
  BiometricResult _fromCode(LocalAuthExceptionCode code) => switch (code) {
    LocalAuthExceptionCode.userCanceled ||
    LocalAuthExceptionCode.systemCanceled ||
    LocalAuthExceptionCode.timeout ||
    LocalAuthExceptionCode.userRequestedFallback => BiometricResult.cancelled,

    LocalAuthExceptionCode.noBiometricsEnrolled => const BiometricResult.failed(
      AppStrings.biometricNotEnrolled,
    ),

    LocalAuthExceptionCode.noBiometricHardware ||
    LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable =>
      const BiometricResult.failed(AppStrings.biometricUnavailable),

    LocalAuthExceptionCode.noCredentialsSet => const BiometricResult.failed(
      AppStrings.biometricNoDeviceLock,
    ),

    LocalAuthExceptionCode.temporaryLockout ||
    LocalAuthExceptionCode.biometricLockout => const BiometricResult.failed(
      AppStrings.biometricLockedOut,
    ),

    _ => const BiometricResult.failed(AppStrings.biometricFailed),
  };
}
