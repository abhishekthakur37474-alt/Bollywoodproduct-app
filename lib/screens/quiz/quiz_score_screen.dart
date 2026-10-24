import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../services/auth_service.dart';
import 'quiz_result_screen.dart';
import 'quiz_service.dart';

const _gold = Color(0xffD4AF37);
const _card = Color(0xff1A1A1A);

String _pts(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);

class QuizScoreScreen extends StatefulWidget {
  const QuizScoreScreen({super.key});

  @override
  State<QuizScoreScreen> createState() => _QuizScoreScreenState();
}

class _QuizScoreScreenState extends State<QuizScoreScreen> {
  ScoreSummary? _summary;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // quiz save hote hi (ya login ke baad) yaha refresh
    QuizService.scoreVersion.addListener(_load);
    AuthService.bollyUserId.addListener(_load); // login/logout pe refresh
    _load();
  }

  @override
  void dispose() {
    QuizService.scoreVersion.removeListener(_load);
    AuthService.bollyUserId.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    if (QuizService.userId == null) {
      if (mounted) setState(() => _summary = null);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await QuizService.fetchSummary();
      if (!mounted) return;
      setState(() {
        _summary = s;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Score load nahi hua. Internet check karo.';
        _loading = false;
      });
    }
  }

  String _fmtDuration(int sec) => '${sec ~/ 60} min';

  @override
  Widget build(BuildContext context) {
    final loggedIn = QuizService.userId != null;
    final s = _summary;

    return RefreshIndicator(
      color: _gold,
      backgroundColor: _card,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
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
              color: _card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x33D4AF37)),
            ),
            child: Column(
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedStar,
                  size: 48,
                  color: _gold,
                  strokeWidth: 1.5,
                ),
                const SizedBox(height: 16),
                if (_loading && s == null)
                  const SizedBox(
                    height: 50,
                    child: Center(
                      child: CircularProgressIndicator(color: _gold),
                    ),
                  )
                else
                  Text(
                    _pts(s?.totalPoints ?? 0),
                    style: const TextStyle(
                      color: _gold,
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                const SizedBox(height: 6),
                const Text(
                  'Total Points',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                ),
                if (s != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _mini('Quizzes', '${s.quizzes}')),
                      Expanded(child: _mini('Attempted', '${s.totalAttempted}')),
                      Expanded(child: _mini('Correct', '${s.totalCorrect}')),
                    ],
                  ),
                ],
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
          if (!loggedIn)
            _msgBox('Score dekhne ke liye login karo')
          else if (_error != null)
            _msgBox(_error!)
          else if (s == null || s.recent.isEmpty)
            _msgBox(_loading ? 'Loading...' : 'No quiz history yet')
          else
            ...s.recent.map(_recentTile),
        ],
      ),
    );
  }

  Widget _mini(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ],
    );
  }

  Widget _msgBox(String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          text,
          style: const TextStyle(color: Colors.white38, fontSize: 14),
        ),
      ),
    );
  }

  Widget _recentTile(RecentQuiz q) {
    final neg = q.points < 0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(builder: (_) => QuizResultScreen(quiz: q)),
      ),
      child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x22D4AF37)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  q.topic,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Level ${q.level} · ${_fmtDuration(q.duration)} · ${q.correct}/${q.attempted} correct',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  q.playedAt,
                  style: const TextStyle(color: Colors.white30, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${neg ? '' : '+'}${_pts(q.points)}',
            style: TextStyle(
              color: neg ? Colors.redAccent : const Color(0xff4CAF50),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, color: Colors.white38),
        ],
      ),
    ),
    );
  }
}