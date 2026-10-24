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

      print("🟡 [AUTH] tokens: idToken=${googleAuth.idToken != null} accessToken=${googleAuth.accessToken != null}");
      if (googleAuth.idToken == null) {
        print("🔴 [AUTH] idToken is null, accessToken=${googleAuth.accessToken}");
      } else {
        print("🟡 [AUTH] idToken length=${googleAuth.idToken!.length}");
      }

      if (googleAuth.idToken == null) {
        print("🔴 [AUTH] Missing idToken, retrying sign-in");
        await _googleSignIn.signOut();
        googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          print("🔴 [AUTH] Retry cancelled by user");
          return null;
        }
        print("🟡 [AUTH] Retry account: ${googleUser.email}");
        final retryAuth = await googleUser.authentication;
        print("🟡 [AUTH] retry tokens: idToken=${retryAuth.idToken != null} accessToken=${retryAuth.accessToken != null}");
        if (retryAuth.idToken == null) {
          throw FirebaseAuthException(
            code: 'missing-id-token',
            message: 'Google sign-in failed. Missing idToken after retry.',
          );
        }
        return _signInToFirebase(retryAuth);
      }

      return _signInToFirebase(googleAuth);
    } catch (e, stack) {
      print("🔴 [AUTH ERROR] type=${e.runtimeType} error=$e");
      print("🔴 [AUTH STACK] $stack");
      rethrow;
    }
  }

  static Future<User?> _signInToFirebase(
    GoogleSignInAuthentication googleAuth,
  ) async {
    try {
      print("🟡 [AUTH] Signing into Firebase with Google credential");
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      print("🟢 [AUTH] Firebase login success: uid=${userCredential.user?.uid} email=${userCredential.user?.email}");
      return userCredential.user;
    } on FirebaseAuthException catch (e, stack) {
      print("🔴 [FIREBASE AUTH] code=${e.code} message=${e.message} email=${e.email} credential=${e.credential}");
      print("🔴 [FIREBASE AUTH STACK] $stack");
      rethrow;
    } catch (e, stack) {
      print("🔴 [FIREBASE SIGNIN ERROR] type=${e.runtimeType} error=$e");
      print("🔴 [FIREBASE SIGNIN STACK] $stack");
      rethrow;
    }
  }

  static Future<void> signOut() async {
    print("🟡 [AUTH] Logging out");

    await FirebaseAuth.instance.signOut();
    await _googleSignIn.signOut();

    print("🟢 [AUTH] Logged out successfully");
  }
}
