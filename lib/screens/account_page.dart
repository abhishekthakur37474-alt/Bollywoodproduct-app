import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  static const gold = Color(0xffD4AF37);
  static const bg = Color(0xff0F0F0F);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Your Account"),
      ),
      body: user == null
          ? _guestView(context)
          : FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: gold),
            );
          }

          // 🔴 Logged in but profile not completed
          if (!snapshot.data!.exists) {
            return _incompleteProfileView(context);
          }

          final data =
          snapshot.data!.data() as Map<String, dynamic>;

          return _profileView(context, data);
        },
      ),
    );
  }

  // =======================
  // 🔴 NOT LOGGED IN VIEW
  // =======================
  Widget _guestView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.account_circle_outlined,
            size: 90,
            color: Colors.white24,
          ),
          const SizedBox(height: 24),

          const Text(
            "Welcome to Bollywood Product",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            "Login to manage your profile,\ntrack preferences and get updates.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white60,
              fontSize: 14,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text(
                "Continue with Google",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xff121212),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Logout",
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            "Are you sure you want to logout?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white60),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () async {
                Navigator.pop(ctx);

                print("🟡 [ACCOUNT] User confirmed logout");

                await AuthService.signOut();

                if (!context.mounted) return;

                Navigator.popUntil(
                  context,
                      (route) => route.isFirst,
                );

                print("🟢 [ACCOUNT] Logout complete");
              },
              child: const Text("Logout",style: TextStyle(color: Colors.white),),
            ),
          ],
        );
      },
    );
  }

  // =======================
  // 🔴 PROFILE NOT COMPLETED
  // =======================
  Widget _incompleteProfileView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.person_outline,
            size: 90,
            color: Colors.white24,
          ),

          const SizedBox(height: 24),

          const Text(
            "Complete Your Profile",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            "Add your details to personalize\nyour experience.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white60,
              fontSize: 14,
              height: 1.4,
            ),
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
              child: const Text(
                "Complete Profile",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // =======================
  // ✅ PROFILE COMPLETED
  // =======================
  Widget _profileView(
      BuildContext context, Map<String, dynamic> data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 10),

          CircleAvatar(
            radius: 60,
            backgroundImage:
            data["imageUrl"] != null && data["imageUrl"].isNotEmpty
                ? NetworkImage(data["imageUrl"])
                : null,
            child: data["imageUrl"] == null ||
                data["imageUrl"].isEmpty
                ? const Icon(Icons.person,
                size: 60, color: Colors.white70)
                : null,
          ),

          const SizedBox(height: 16),

          Text(
            data["name"] ?? "",
            style: const TextStyle(
              color: gold,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            data["email"] ?? "",
            style:
            const TextStyle(color: Colors.white70, fontSize: 14),
          ),

          const SizedBox(height: 30),

          _info("Phone", data["phone"]),
          _info("City", data["city"]),
          _info("State", data["state"]),
          _info("Pincode", data["pincode"]),

          const SizedBox(height: 30),

          ElevatedButton.icon(
            icon: const Icon(Icons.edit, color: Colors.black),
            style: ElevatedButton.styleFrom(
              backgroundColor: gold,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ProfilePage()),
              );
            },
            label: const Text("Edit Profile"),
          ),

          const SizedBox(height: 16),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () {
              _showLogoutDialog(context);
            },
            child: const Text(
              "Logout",
              style: TextStyle(color: Colors.white),
            ),
          ),

        ],
      ),
    );
  }

  // =======================
  // ℹ️ INFO TILE
  // =======================
  Widget _info(String label, String? value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding:
      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style:
              const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value ?? "",
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
