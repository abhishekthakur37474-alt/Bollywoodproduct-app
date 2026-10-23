import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static const _webClientId =
      '1031037529929-ob7gmjugokl2q32mv45f5fh2b3va0lpo.apps.googleusercontent.com';

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: _webClientId,
  );

  static Future<User?> signInWithGoogle() async {
    try {
      print("🟡 [AUTH] Google sign-in started");

      GoogleSignInAccount? googleUser = _googleSignIn.currentUser;
      googleUser ??= await _googleSignIn.signInSilently();
      googleUser ??= await _googleSignIn.signIn();

      if (googleUser == null) {
        print("🔴 [AUTH] User cancelled login");
        return null;
      }

      print("🟡 [AUTH] Selected account: ${googleUser.email}");

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (googleAuth.idToken == null) {
        print("🔴 [AUTH] Missing idToken, retrying sign-in");
        await _googleSignIn.signOut();
        googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;
        final retryAuth = await googleUser.authentication;
        if (retryAuth.idToken == null) {
          throw FirebaseAuthException(
            code: 'missing-id-token',
            message: 'Google sign-in failed. Please try again.',
          );
        }
        return _signInToFirebase(retryAuth);
      }

      return _signInToFirebase(googleAuth);
    } catch (e) {
      print("🔴 [AUTH ERROR] $e");
      rethrow;
    }
  }

  static Future<User?> _signInToFirebase(
    GoogleSignInAuthentication googleAuth,
  ) async {
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential =
        await FirebaseAuth.instance.signInWithCredential(credential);

    print("🟢 [AUTH] Firebase login success: ${userCredential.user?.uid}");
    return userCredential.user;
  }

  static Future<void> signOut() async {
    print("🟡 [AUTH] Logging out");

    await FirebaseAuth.instance.signOut();
    await _googleSignIn.signOut();

    print("🟢 [AUTH] Logged out successfully");
  }
}
