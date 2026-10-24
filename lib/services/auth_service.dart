import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Result of website DB sync (subscription DB + bollywoodprodu DB).
class WebsiteUser {
  final int subId; // u171564966_subscription.users.id
  final int? bollyId; // u171564966_bollywoodprodu.users.id
  final String name;
  final String email;
  final String? picture;
  final bool isNew;
  final String? trialEndDate;

  WebsiteUser({
    required this.subId,
    required this.bollyId,
    required this.name,
    required this.email,
    required this.picture,
    required this.isNew,
    required this.trialEndDate,
  });

  factory WebsiteUser.fromJson(Map<String, dynamic> j) => WebsiteUser(
        subId: int.parse(j['sub_id'].toString()),
        bollyId:
            j['bolly_id'] == null ? null : int.tryParse(j['bolly_id'].toString()),
        name: (j['name'] ?? '').toString(),
        email: (j['email'] ?? '').toString(),
        picture: j['picture']?.toString(),
        isNew: j['is_new'] == true,
        trialEndDate: j['trial_end_date']?.toString(),
      );
}

class AuthService {
  // Firebase "Web client" ID (same as before) -> idToken audience.
  static const _webClientId =
      '1031037529929-ob7gmjugokl2q32mv45f5fh2b3va0lpo.apps.googleusercontent.com';

  // NEW endpoint on website (see app-google-login.php)
  static const _syncUrl =
      'https://www.bollywoodproduct.com/sub/user/app-google-login.php';

  static const _kSubId = 'web_sub_id';
  static const _kBollyId = 'web_bolly_id';

  /// Logged-in user ka bollywoodprodu `users.id`. Quiz score isi se save hota hai.
  /// null = login nahi. Quiz/Score screens isko sunti hain.
  static final ValueNotifier<int?> bollyUserId = ValueNotifier<int?>(null);

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: _webClientId,
  );

  // ---------------------------------------------------------------------------
  // PUBLIC: login
  // ---------------------------------------------------------------------------
  static Future<User?> signInWithGoogle() async {
    try {
      debugPrint('[AUTH] Google sign-in started');

      GoogleSignInAccount? googleUser = _googleSignIn.currentUser;
      googleUser ??= await _googleSignIn.signInSilently();
      googleUser ??= await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('[AUTH] User cancelled login');
        return null;
      }

      var googleAuth = await googleUser.authentication;

      // idToken missing -> one retry
      if (googleAuth.idToken == null) {
        debugPrint('[AUTH] Missing idToken, retrying sign-in');
        await _googleSignIn.signOut();
        googleUser = await _googleSignIn.signIn();
        if (googleUser == null) return null;
        googleAuth = await googleUser.authentication;
        if (googleAuth.idToken == null) {
          throw FirebaseAuthException(
            code: 'missing-id-token',
            message: 'Google sign-in failed. Missing idToken after retry.',
          );
        }
      }

      // 1) Firebase login
      final user = await _signInToFirebase(googleAuth);
      if (user == null) return null;

      // 2) Website DB sync (same user as website). Fail => full rollback.
      try {
        final web = await _syncWithWebsite(googleAuth.idToken!);
        await _saveWebIds(web);
        debugPrint('[AUTH] Website sync ok sub_id=${web.subId} '
            'bolly_id=${web.bollyId} new=${web.isNew}');
      } catch (e) {
        debugPrint('[AUTH] Website sync FAILED: $e');
        await signOut(); // no half-logged-in user
        rethrow;
      }

      return user;
    } catch (e, stack) {
      debugPrint('[AUTH ERROR] type=${e.runtimeType} error=$e');
      debugPrint('[AUTH STACK] $stack');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Firebase
  // ---------------------------------------------------------------------------
  static Future<User?> _signInToFirebase(
    GoogleSignInAuthentication googleAuth,
  ) async {
    try {
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      debugPrint('[AUTH] Firebase ok uid=${userCredential.user?.uid}');
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('[FIREBASE AUTH] code=${e.code} message=${e.message}');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Website sync
  // ---------------------------------------------------------------------------
  static Future<WebsiteUser> _syncWithWebsite(String googleIdToken) async {
    final res = await http
        .post(
          Uri.parse(_syncUrl),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({'id_token': googleIdToken}),
        )
        .timeout(const Duration(seconds: 25));

    Map<String, dynamic> body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw Exception('Server error (${res.statusCode}). Try again.');
    }

    if (res.statusCode != 200 || body['success'] != true) {
      throw Exception(body['message'] ?? 'Website sync failed.');
    }
    return WebsiteUser.fromJson(body['user'] as Map<String, dynamic>);
  }

  static Future<void> _saveWebIds(WebsiteUser u) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kSubId, u.subId);
    if (u.bollyId != null) {
      await p.setInt(_kBollyId, u.bollyId!);
      bollyUserId.value = u.bollyId; // quiz + score screen ko turant pata chale
    }
  }

  /// App start pe ek baar call kar (main.dart me Firebase.initializeApp ke baad).
  /// Saved id load karta hai. Purana login hai aur id nahi, to chup-chap re-sync.
  static Future<void> restoreSession() async {
    final p = await SharedPreferences.getInstance();

    if (FirebaseAuth.instance.currentUser == null) {
      await p.remove(_kSubId);
      await p.remove(_kBollyId);
      bollyUserId.value = null;
      return;
    }

    final saved = p.getInt(_kBollyId);
    if (saved != null) {
      bollyUserId.value = saved;
      return;
    }

    try {
      final acc = _googleSignIn.currentUser ?? await _googleSignIn.signInSilently();
      final auth = await acc?.authentication;
      if (auth?.idToken == null) return;
      final web = await _syncWithWebsite(auth!.idToken!);
      await _saveWebIds(web);
    } catch (e) {
      debugPrint('[AUTH] restoreSession re-sync failed: $e');
    }
  }

  /// Website subscription-DB user id (null if not logged in).
  static Future<int?> getWebsiteSubId() async =>
      (await SharedPreferences.getInstance()).getInt(_kSubId);

  /// Website bollywoodprodu-DB user id.
  static Future<int?> getWebsiteBollyId() async =>
      (await SharedPreferences.getInstance()).getInt(_kBollyId);

  // ---------------------------------------------------------------------------
  // Logout
  // ---------------------------------------------------------------------------
  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await _googleSignIn.signOut();
    final p = await SharedPreferences.getInstance();
    await p.remove(_kSubId);
    await p.remove(_kBollyId);
    bollyUserId.value = null;
    debugPrint('[AUTH] Logged out');
  }
}