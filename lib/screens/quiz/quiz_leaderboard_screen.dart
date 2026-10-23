import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class QuizLeaderboardScreen extends StatelessWidget {
  const QuizLeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
          decoration: BoxDecoration(
            color: const Color(0xff1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x33D4AF37)),
          ),
          child: const Column(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedChampion,
                size: 48,
                color: Color(0xffD4AF37),
                strokeWidth: 1.5,
              ),
              SizedBox(height: 16),
              Text(
                'No rankings yet',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Play a quiz to appear on the board',
                style: TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
