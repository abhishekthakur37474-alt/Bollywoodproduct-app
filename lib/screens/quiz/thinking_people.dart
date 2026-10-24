import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ThinkingPeople extends StatelessWidget {
  const ThinkingPeople({super.key});

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/animations/two-people-thinking.json',
      fit: BoxFit.contain,
      repeat: true,
    );
  }
}
