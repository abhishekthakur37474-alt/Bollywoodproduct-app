import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'quiz_header.dart';
import 'quiz_home_screen.dart';
import 'quiz_score_screen.dart';
import 'quiz_leaderboard_screen.dart';
import 'quiz_profile_screen.dart';

class BollywoodQuizScreen extends StatefulWidget {
  const BollywoodQuizScreen({super.key});

  @override
  State<BollywoodQuizScreen> createState() => _BollywoodQuizScreenState();
}

class _BollywoodQuizScreenState extends State<BollywoodQuizScreen> {
  int _selectedIndex = 0;

  static const _pages = [
    QuizHomeScreen(),
    QuizScoreScreen(),
    QuizLeaderboardScreen(),
    QuizProfileScreen(),
  ];

  static const _titles = [
    'Bollywood Quiz',
    'Score',
    'Leaderboard',
    'Profile',
  ];

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F0F0F),
      extendBody: true,
      body: Column(
        children: [
          QuizHeader(
            title: _titles[_selectedIndex],
            showExit: _selectedIndex == 0,
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: _pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xf2141414),
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: const Color(0x40D4AF37),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: const Color(0xffD4AF37).withValues(alpha: 0.08),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                _buildNavItem(
                  index: 0,
                  icon: HugeIcons.strokeRoundedHome07,
                  label: "Home",
                ),
                _buildNavItem(
                  index: 1,
                  icon: HugeIcons.strokeRoundedStar,
                  label: "Score",
                ),
                _buildNavItem(
                  index: 2,
                  icon: HugeIcons.strokeRoundedChampion,
                  label: "Leaderboard",
                ),
                _buildNavItem(
                  index: 3,
                  icon: HugeIcons.strokeRoundedUser,
                  label: "Profile",
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required dynamic icon,
    required String label,
  }) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTabTapped(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: icon,
              size: 20.0,
              color: isSelected
                  ? const Color(0xffD4AF37)
                  : Colors.white54,
              strokeWidth: isSelected ? 2.0 : 1.5,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? const Color(0xffD4AF37)
                    : Colors.white54,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
