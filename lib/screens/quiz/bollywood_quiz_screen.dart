import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'quiz_header.dart';
import 'quiz_home_screen.dart';
import 'quiz_lang.dart';
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
    RepaintBoundary(child: QuizHomeScreen()),
    RepaintBoundary(child: QuizScoreScreen()),
    RepaintBoundary(child: QuizLeaderboardScreen()),
    RepaintBoundary(child: QuizProfileScreen()),
  ];

  List<String> get _titles => [
        QuizLang.t('bollywood_quiz'),
        QuizLang.t('score'),
        QuizLang.t('leaderboard'),
        QuizLang.t('profile'),
      ];

  void _onTabTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: QuizLang.code,
      builder: (context, _, __) => _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
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
                _QuizNavItem(
                  selected: _selectedIndex == 0,
                  icon: HugeIcons.strokeRoundedHome07,
                  label: QuizLang.t('home'),
                  onTap: () => _onTabTapped(0),
                ),
                _QuizNavItem(
                  selected: _selectedIndex == 1,
                  icon: HugeIcons.strokeRoundedStar,
                  label: QuizLang.t('score'),
                  onTap: () => _onTabTapped(1),
                ),
                _QuizNavItem(
                  selected: _selectedIndex == 2,
                  icon: HugeIcons.strokeRoundedChampion,
                  label: QuizLang.t('leaderboard'),
                  onTap: () => _onTabTapped(2),
                ),
                _QuizNavItem(
                  selected: _selectedIndex == 3,
                  icon: HugeIcons.strokeRoundedUser,
                  label: QuizLang.t('profile'),
                  onTap: () => _onTabTapped(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuizNavItem extends StatelessWidget {
  final bool selected;
  final dynamic icon;
  final String label;
  final VoidCallback onTap;

  const _QuizNavItem({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xffD4AF37) : Colors.white54;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: icon,
              size: 20.0,
              color: color,
              strokeWidth: selected ? 2.0 : 1.5,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
