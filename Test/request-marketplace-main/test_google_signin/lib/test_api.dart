import 'package:google_sign_in/google_sign_in.dart';

void testAPI() {
  // Test different GoogleSignIn constructors
  try {
    final googleSignIn1 = GoogleSignIn();
    print('Default constructor works: $googleSignIn1');
  } catch (e) {
    print('Default constructor failed: $e');
  }
  
  try {
    final googleSignIn2 = GoogleSignIn.withConfig(scopes: <String>['email']);
    print('withConfig constructor works: $googleSignIn2');
  } catch (e) {
    print('withConfig constructor failed: $e');
  }
}
