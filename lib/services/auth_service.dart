import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
  );

  /// 🔐 GOOGLE LOGIN
  static Future<User?> signInWithGoogle() async {
    try {
      print("🟡 [AUTH] Google sign-in started");

      // 🔥 FORCE ACCOUNT PICKER EVERY TIME
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser =
      await _googleSignIn.signIn();

      if (googleUser == null) {
        print("🔴 [AUTH] User cancelled login");
        return null;
      }

      print("🟡 [AUTH] Selected account: ${googleUser.email}");

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      print("🟢 [AUTH] Firebase login success: ${userCredential.user?.uid}");

      return userCredential.user;
    } catch (e) {
      print("🔴 [AUTH ERROR] $e");
      return null;
    }
  }

  /// 🚪 LOGOUT
  static Future<void> signOut() async {
    print("🟡 [AUTH] Logging out");

    await FirebaseAuth.instance.signOut();
    await _googleSignIn.signOut();

    print("🟢 [AUTH] Logged out successfully");
  }
}
