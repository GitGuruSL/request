/// Shim AuthService wrapping the new RestAuthService for legacy screens.
import 'rest_auth_service.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  RestAuthService get _rest => RestAuthService.instance;

  get currentUser => _rest.currentUser; // Exposes REST user (has id, email)

  Future<bool> isAuthenticated() => _rest.isAuthenticated();
  Future<void> signOut() => _rest.logout();

  /// Change password
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) =>
      _rest.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

  /// Reset password with OTP
  Future<AuthResult> resetPassword({
    required String emailOrPhone,
    required String otp,
    required String newPassword,
    required bool isEmail,
  }) =>
      _rest.resetPassword(
        emailOrPhone: emailOrPhone,
        otp: otp,
        newPassword: newPassword,
        isEmail: isEmail,
      );
}
