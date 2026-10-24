import 'package:flutter/material.dart';
import 'quiz_service.dart';

const _gold = Color(0xffD4AF37);
const _bg = Color(0xff0F0F0F);
const _card = Color(0xff1A1A1A);
const _green = Color(0xff4CAF50);

Color _hex(String? hex, Color fallback) {
  if (hex == null || hex.length != 7) return fallback;
  final v = int.tryParse(hex.substring(1), radix: 16);
  return v == null ? fallback : Color(0xFF000000 | v);
}

/// History me quiz pe tap karne par khulti hai.
/// Header (topic, level, duration, date) + questions & attempts server se (quiz_user_answers).
class QuizResultScreen extends StatefulWidget {
  final RecentQuiz quiz;
  const QuizResultScreen({super.key, required this.quiz});

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> {
  late Future<List<AttemptedQuestion>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<AttemptedQuestion>> _load() {
    final n = widget.quiz.quizNumber;
    if (n == null) {
      return Future.error('quiz_number nahi aaya - server pe quiz-score-api.php purani hai');
    }
    return QuizService.fetchQuizDetail(n);
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.quiz;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Quiz Result'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        children: [
          Center(
            child: Text(
              q.topic,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'Level ${q.level} · ${q.duration ~/ 60} min · ${q.playedAt}',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your Quiz Responses',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          FutureBuilder<List<AttemptedQuestion>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator(color: _gold)),
                );
              }
              if (snap.hasError) {
                return Column(
                  children: [
                    _note('Questions load nahi hue.\n${snap.error}'),
                    TextButton(
                      onPressed: () => setState(() => _future = _load()),
                      child: const Text('Retry',
                          style: TextStyle(color: _gold)),
                    ),
                  ],
                );
              }
              final qs = snap.data ?? const <AttemptedQuestion>[];
              if (qs.isEmpty) {
                return _note(
                  'Is quiz ke questions & answers available nahi hain.\n'
                  'Ye quiz website par ya app update se pehle khela gaya tha.',
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < qs.length; i++)
                    _questionTile(i + 1, qs[i]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _note(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
      ),
    );
  }

  Widget _questionTile(int index, AttemptedQuestion a) {
    final ok = a.isCorrect;
    final accent = ok ? _green : Colors.redAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          iconColor: _gold,
          collapsedIconColor: Colors.white54,
          title: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Q$index. ',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800),
                ),
                ...a.segments.map(
                  (s) => TextSpan(
                    text: s.text,
                    style: TextStyle(
                      color: _hex(s.colorHex, Colors.white),
                      fontWeight: s.bold ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 14, height: 1.4),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              ok ? '✅ Correct' : '❌ Wrong',
              style: TextStyle(
                  color: accent, fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
          children: [
            for (var i = 1; i <= a.options.length; i++) _option(a, i),
          ],
        ),
      ),
    );
  }

  Widget _option(AttemptedQuestion a, int n) {
    final isCorrect = n == a.correctOption;
    final isMine = n == a.selected;

    Color bg = const Color(0xff222222);
    if (isCorrect) bg = const Color(0xff1B5E20);
    if (isMine && !isCorrect) bg = const Color(0xff7F1D1D);

    final tags = <String>[
      if (isMine) '✅ Your Answer',
      if (isCorrect) '🎯 Correct',
    ];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(
        'Option $n: ${a.options[n - 1]}${tags.isEmpty ? '' : '  ${tags.join('  ')}'}',
        style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.35),
      ),
    );
  }
}