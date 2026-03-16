import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportService {
  static final _db = FirebaseFirestore.instance;

  static Future<void> submitReport({
    required String movieId,
    required String movieName,
    required String issueType,
    required String message,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    await _db.collection("reports").add({
      "movieId": movieId,
      "movieName": movieName,
      "issueType": issueType,
      "message": message,
      "userId": user?.uid,
      "userEmail": user?.email,
      "createdAt": FieldValue.serverTimestamp(),
      "status": "pending", // future admin use
    });
  }
}
