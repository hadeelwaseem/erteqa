/// TEMPORARY — remove when backend auth is available.
///
/// See [README.md](README.md) and `scripts/remove_auth_mock.ps1`.
class AuthMockConfig {
  AuthMockConfig._();

  /// Set to `false` to use real [AuthRepoImpl] without deleting mock files.
  static const bool enabled = true;

  /// Simulated network latency (matches “real” feel while offline).
  static const Duration requestDelay = Duration(milliseconds: 400);

  /// Any 6-digit OTP is accepted when [acceptAnySixDigitOtp] is true.
  static const bool acceptAnySixDigitOtp = true;

  /// Fixed OTP for docs / QA (also accepted when [acceptAnySixDigitOtp] is false).
  static const String fixedOtp = '123456';

  /// Message returned from mock `requestOtp` (same copy as typical API).
  static const String otpSentMessage = 'OTP sent via WhatsApp';
}
