import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../widgets/bottom_nav.dart';
// import '../widgets/app_drawer.dart';

class BollywoodQuizScreen extends StatefulWidget {
  const BollywoodQuizScreen({super.key});

  @override
  State<BollywoodQuizScreen> createState() => _BollywoodQuizScreenState();
}

class _BollywoodQuizScreenState extends State<BollywoodQuizScreen> {
  int _selectedIndex = 0;

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  void _exitToMain() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const BottomNav()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff0F0F0F),
      extendBody: true,

      // /// ─── SIDEBAR DRAWER (commented out for now) ────────────────
      // drawer: const AppDrawer(),

      /// ─── TOP APP BAR ───────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: const Color(0xff111111),
        elevation: 0,
        titleSpacing: 16,
        // leading: Builder(
        //   builder: (ctx) => IconButton(
        //     icon: const HugeIcon(
        //       icon: HugeIcons.strokeRoundedMenu02,
        //       size: 24.0,
        //       color: Colors.white,
        //     ),
        //     onPressed: () => Scaffold.of(ctx).openDrawer(),
        //   ),
        // ),
        title: const Text(
          "Bollywood Quiz",
          style: TextStyle(
            color: Color(0xffD4AF37),
            fontWeight: FontWeight.bold,
            fontSize: 20,
            letterSpacing: 0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0x33D4AF37), height: 1),
        ),
      ),

      /// ─── BODY ───────────────────────────────────────────────────
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _QuizHomeTab(),
          _ComingSoonTab(icon: Icons.scoreboard_rounded, label: "Score"),
          _ComingSoonTab(icon: Icons.emoji_events_rounded, label: "Leaderboard"),
        ],
      ),

      /// ─── FLOATING PILL BOTTOM NAV ─────────────────────────────
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
                _buildPillItem(
                  index: 0,
                  icon: HugeIcons.strokeRoundedHome07,
                  label: "Home",
                ),
                _buildPillItem(
                  index: 1,
                  icon: HugeIcons.strokeRoundedStarFace,
                  label: "Score",
                ),
                _buildPillItem(
                  index: 2,
                  icon: HugeIcons.strokeRoundedChampion,
                  label: "Leaderboard",
                ),
                _buildPillItem(
                  index: 3,
                  icon: HugeIcons.strokeRoundedLogout02,
                  label: "Exit",
                  isExit: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPillItem({
    required int index,
    required dynamic icon,
    required String label,
    bool isExit = false,
  }) {
    final isSelected = !isExit && _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (isExit) {
            _exitToMain();
          } else {
            _onTabTapped(index);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0x24D4AF37)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
            border: isSelected
                ? Border.all(color: const Color(0x66D4AF37), width: 1)
                : Border.all(color: Colors.transparent, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(
                icon: icon,
                size: 20.0,
                color: isExit
                    ? Colors.redAccent
                    : (isSelected
                        ? const Color(0xffD4AF37)
                        : Colors.white54),
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
                  color: isExit
                      ? Colors.redAccent
                      : (isSelected
                          ? const Color(0xffD4AF37)
                          : Colors.white54),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ─── HOME TAB ───────────────────────────────────────────────────────────────
class _QuizHomeTab extends StatelessWidget {
  const _QuizHomeTab();

  @override
  Widget build(BuildContext context) {
    return const SizedBox();
  }
}

/// ─── COMING SOON TAB (Score / Leaderboard) ──────────────────────────────────
class _ComingSoonTab extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ComingSoonTab({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: const Color(0x55D4AF37)),
          const SizedBox(height: 20),
          Text(
            label,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white70),
          ),
          const SizedBox(height: 10),
          const Text("Coming Soon", style: TextStyle(color: Colors.white38, fontSize: 14)),
        ],
      ),
    );
  }
}
