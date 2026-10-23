import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class QuizScoreScreen extends StatelessWidget {
  const QuizScoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      children: [
        const Text(
          'Your Score',
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
              HugeIcon(
                icon: HugeIcons.strokeRoundedStar,
                size: 48,
                color: Color(0xffD4AF37),
                strokeWidth: 1.5,
              ),
              SizedBox(height: 16),
              Text(
                '0',
                style: TextStyle(
                  color: Color(0xffD4AF37),
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Total Points',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Recent Quizzes',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xff1A1A1A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Text(
              'No quiz history yet',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }
}
