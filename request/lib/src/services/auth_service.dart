/// Shim AuthService wrapping the new RestAuthService for legacy screens.
import 'rest_auth_service.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  RestAuthService get _rest => RestAuthService.instance;

  get currentUser => _rest.currentUser; // Exposes REST user (has id, email)

  Future<bool> isAuthenticated() => _rest.isAuthenticated();
  Future<void> signOut() => _rest.logout();
}
