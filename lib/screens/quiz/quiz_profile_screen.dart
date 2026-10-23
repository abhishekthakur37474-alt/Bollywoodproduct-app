import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class QuizProfileScreen extends StatelessWidget {
  const QuizProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      children: [
        const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xff1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x33D4AF37)),
          ),
          child: const Column(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: Color(0x22D4AF37),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedUser,
                  size: 36,
                  color: Color(0xffD4AF37),
                  strokeWidth: 1.5,
                ),
              ),
              SizedBox(height: 14),
              Text(
                'Quiz Player',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Complete quizzes to build your profile',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
