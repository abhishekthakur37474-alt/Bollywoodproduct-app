import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// 🔐 SAFE UID GETTER
  static String? get _uid =>
      FirebaseAuth.instance.currentUser?.uid;

  // ============================================================
  // 🔥 STREAM ALL NOTIFICATIONS
  // ============================================================
  static Stream<QuerySnapshot> stream() {
    final uid = _uid;

    print("🟡 [NOTIFICATION] Listening stream");

    if (uid == null) {
      print("🔴 [NOTIFICATION] No user logged in");
      return const Stream.empty();
    }

    return _db
        .collection("users")
        .doc(uid)
        .collection("notifications")
        .orderBy("createdAt", descending: true)
        .snapshots();
  }

  // ============================================================
  // 🔥 SAVE (Used by FCM)
  // ============================================================
  static Future<void> save({
    required String uid,
    required String title,
    required String body,
    String? image,
  }) async {
    try {
      await _db
          .collection("users")
          .doc(uid)
          .collection("notifications")
          .add({
        "title": title,
        "body": body,
        "image": image,
        "seen": false,
        "createdAt": FieldValue.serverTimestamp(),
      });

      print("🟢 [NOTIFICATION] Saved");
    } catch (e) {
      print("🔴 [NOTIFICATION] Save error: $e");
    }
  }

  // ============================================================
  // 👁 MARK AS SEEN
  // ============================================================
  static Future<void> markSeen(String id) async {
    final uid = _uid;

    if (uid == null) {
      print("🔴 [NOTIFICATION] markSeen failed: No user");
      return;
    }

    try {
      print("🟡 [NOTIFICATION] Mark seen: $id");

      await _db
          .collection("users")
          .doc(uid)
          .collection("notifications")
          .doc(id)
          .update({"seen": true});
    } catch (e) {
      print("🔴 [NOTIFICATION] markSeen error: $e");
    }
  }

  // ============================================================
  // 🗑 DELETE
  // ============================================================
  static Future<void> delete(String id) async {
    final uid = _uid;

    if (uid == null) {
      print("🔴 [NOTIFICATION] delete failed: No user");
      return;
    }

    try {
      print("🔴 [NOTIFICATION] Deleted: $id");

      await _db
          .collection("users")
          .doc(uid)
          .collection("notifications")
          .doc(id)
          .delete();
    } catch (e) {
      print("🔴 [NOTIFICATION] delete error: $e");
    }
  }
}
