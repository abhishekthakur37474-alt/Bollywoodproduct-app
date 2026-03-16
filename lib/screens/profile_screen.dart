import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../controllers/profile_controller.dart';
import '../widgets/bottom_nav.dart';
import '../utils/home_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final controller = ProfileController();

  final name = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final city = TextEditingController();
  final state = TextEditingController();
  final pincode = TextEditingController();

  bool saving = false;
  bool skipping = false; // 🔥 loader for skip

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      email.text = user.email ?? '';
      name.text = user.displayName ?? '';
    }
  }

  /// 🔥 SKIP PROFILE WITH LOADER
  Future<void> _skipProfile() async {
    if (skipping) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => skipping = true);
    print("🟡 [PROFILE] Skipped by user");

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .set({
        "uid": user.uid,
        "email": user.email ?? "",
        "profileCompleted": false,
        "createdAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // await HomeService.loadHomeData();
      await HomeService.loadAllHomeData();



      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const BottomNav()),
            (_) => false,
      );
    } catch (e) {
      print("🔴 [PROFILE SKIP ERROR] $e");
      if (mounted) setState(() => skipping = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Complete Profile'),
        backgroundColor: Colors.black,
        actions: [
          TextButton(
            onPressed: (saving || skipping) ? null : _skipProfile,
            child: skipping
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xffD4AF37),
              ),
            )
                : const Text(
              "Skip",
              style: TextStyle(
                color: Color(0xffD4AF37),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: saving
                  ? null
                  : () async {
                await controller.pickImage();
                setState(() {});
              },
              child: CircleAvatar(
                radius: 55,
                backgroundColor: Colors.amber,
                backgroundImage: controller.selectedImage != null
                    ? FileImage(controller.selectedImage!)
                    : null,
                child: controller.selectedImage == null
                    ? const Icon(Icons.camera_alt,
                    size: 30, color: Colors.black)
                    : null,
              ),
            ),
            const SizedBox(height: 30),

            _field("Name", name),
            _field("Email", email),

            /// 🔢 PHONE (NUMBER KEYBOARD)
            _field(
              "Phone",
              phone,
              keyboard: TextInputType.number,
            ),

            _field("City", city),
            _field("State", state),

            /// 🔢 PINCODE (NUMBER KEYBOARD)
            _field(
              "Pincode",
              pincode,
              keyboard: TextInputType.number,
            ),

            const SizedBox(height: 30),

            /// 🔥 SAVE BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: saving
                    ? null
                    : () async {
                  setState(() => saving = true);

                  await controller.saveProfile(
                    name: name.text,
                    email: email.text,
                    phone: phone.text,
                    city: city.text,
                    state: state.text,
                    pincode: pincode.text,
                  );

                  final user =
                      FirebaseAuth.instance.currentUser;

                  if (user != null) {
                    await FirebaseFirestore.instance
                        .collection("users")
                        .doc(user.uid)
                        .set({
                      "profileCompleted": true,
                    }, SetOptions(merge: true));
                  }

                  // await HomeService.loadHomeData();
                  await HomeService.loadAllHomeData();

                  if (!mounted) return;

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const BottomNav()),
                        (_) => false,
                  );
                },
                child: saving
                    ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: Colors.black,
                  ),
                )
                    : const Text(
                  "Save & Continue",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔥 COMMON FIELD
  Widget _field(
      String hint,
      TextEditingController c, {
        TextInputType keyboard = TextInputType.text,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        keyboardType: keyboard,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.amber),
          ),
        ),
      ),
    );
  }
}
