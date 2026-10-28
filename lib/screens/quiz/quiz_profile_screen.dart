import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/auth_service.dart';
import '../login_screen.dart';
import 'quiz_lang.dart';

class QuizProfileScreen extends StatelessWidget {
  const QuizProfileScreen({super.key});

  static const _gold = Color(0xffD4AF37);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: QuizLang.code,
      builder: (context, _, __) => _buildAuth(),
    );
  }

  Widget _buildAuth() {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        final user = authSnap.data;
        if (user == null) {
          return _guestView(context);
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _gold),
              );
            }

            Map<String, dynamic> data = {};
            if (snap.hasData && snap.data!.exists) {
              data = snap.data!.data() as Map<String, dynamic>? ?? {};
            }

            final name = (data['name'] as String?)?.trim().isNotEmpty == true
                ? data['name'] as String
                : (user.displayName?.trim().isNotEmpty == true
                    ? user.displayName!
                    : QuizLang.t('quiz_player'));
            final email = (data['email'] as String?)?.trim().isNotEmpty == true
                ? data['email'] as String
                : (user.email ?? '');
            final imageUrl =
                (data['imageUrl'] as String?)?.trim().isNotEmpty == true
                    ? data['imageUrl'] as String
                    : (user.photoURL ?? '');
            final phone = (data['phone'] as String?) ?? '';
            final city = (data['city'] as String?) ?? '';
            final state = (data['state'] as String?) ?? '';
            final pincode = (data['pincode'] as String?) ?? '';

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xff1A1A1A),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x33D4AF37)),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: const Color(0x22D4AF37),
                        backgroundImage:
                            imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                        child: imageUrl.isEmpty
                            ? const HugeIcon(
                                icon: HugeIcons.strokeRoundedUser,
                                size: 36,
                                color: _gold,
                                strokeWidth: 1.5,
                              )
                            : null,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          email,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (phone.isNotEmpty) _infoTile(QuizLang.t('phone'), phone),
                if (city.isNotEmpty) _infoTile(QuizLang.t('city'), city),
                if (state.isNotEmpty) _infoTile(QuizLang.t('state'), state),
                if (pincode.isNotEmpty)
                  _infoTile(QuizLang.t('pincode'), pincode),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => _logout(context),
                      child: Text(
                        QuizLang.t('logout'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _guestView(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xff1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x33D4AF37)),
          ),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 36,
                backgroundColor: Color(0x22D4AF37),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedUser,
                  size: 36,
                  color: _gold,
                  strokeWidth: 1.5,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                QuizLang.t('guest'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                QuizLang.t('login_to_see_profile'),
                style: const TextStyle(color: Colors.white38, fontSize: 13),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.black,
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
                  child: Text(
                    QuizLang.t('continue_google'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xff1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
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

  Future<void> _logout(BuildContext context) async {
    await AuthService.signOut();
  }
}
