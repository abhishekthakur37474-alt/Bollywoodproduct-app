import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';

class UserService {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  /// 🔥 UPLOAD PROFILE IMAGE
  Future<String> uploadProfileImage(String uid, File file) async {
    try {
      print("🟡 [STORAGE] Uploading image for $uid");

      final ref =
      _storage.ref().child("users/$uid/profile.jpg");

      final uploadTask = await ref.putFile(file);

      final url = await uploadTask.ref.getDownloadURL();

      print("🟢 [STORAGE] Image uploaded: $url");
      return url;
    } catch (e) {
      print("🔴 [STORAGE ERROR] $e");
      rethrow;
    }
  }

  /// 🔥 SAVE USER TO FIRESTORE
  Future<void> saveUser(UserModel model) async {
    try {
      print("🟡 [FIRESTORE] Saving user ${model.uid}");

      await _db
          .collection("users")
          .doc(model.uid)
          .set(model.toMap(), SetOptions(merge: true));

      print("🟢 [FIRESTORE] User saved successfully");
    } catch (e) {
      print("🔴 [FIRESTORE ERROR] $e");
      rethrow;
    }
  }
}
