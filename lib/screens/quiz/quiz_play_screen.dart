import 'dart:async';
import 'package:flutter/material.dart';
import 'quiz_service.dart';

const _gold = Color(0xffD4AF37);
const _bg = Color(0xff0F0F0F);
const _card = Color(0xff1A1A1A);

/// Quiz khelne ki screen (abhi sirf topic id=1 ke liye use ho rahi hai).
class QuizPlayScreen extends StatefulWidget {
  final int topicId;
  final String topicName;
  final int level;
  final int durationSeconds;

  const QuizPlayScreen({
    super.key,
    required this.topicId,
    required this.topicName,
    required this.level,
    required this.durationSeconds,
  });

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  // "Quiz starting in 5..1"
  int _startCount = 5;
  bool _started = false;

  late int _timeLeft;
  Timer? _timer;

  QuizQuestion? _question;
  bool _loadingQ = false;
  String? _error;

  int? _selected; // 1..4
  AnswerResult? _result;

  final List<int> _answeredIds = [];
  int _attempted = 0;
  int _correct = 0;

  bool _finished = false;
  bool _noMore = false; // saare questions khatam

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.durationSeconds;
    _runStartCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ---------- flow ----------
  void _runStartCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_startCount <= 1) {
        t.cancel();
        setState(() {
          _started = true;
          _startCount = 0;
        });
        _startMainTimer();
        _loadNext();
      } else {
        setState(() => _startCount--);
      }
    });
  }

  void _startMainTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_timeLeft <= 1) {
        setState(() => _timeLeft = 0);
        _finish();
      } else {
        setState(() => _timeLeft--);
      }
    });
  }

  void _finish() {
    _timer?.cancel();
    if (!mounted) return;
    setState(() => _finished = true);
  }

  Future<void> _loadNext() async {
    if (_finished) return;
    setState(() {
      _loadingQ = true;
      _error = null;
      _selected = null;
      _result = null;
    });
    try {
      final q = await QuizService.fetchQuestion(
        generatorId: widget.topicId,
        level: widget.level,
        exclude: _answeredIds,
      );
      if (!mounted || _finished) return;
      if (q == null) {
        _noMore = true;
        _finish();
        return;
      }
      setState(() {
        _question = q;
        _loadingQ = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Question load nahi hua. Internet check karo.';
        _loadingQ = false;
      });
    }
  }

  Future<void> _onOption(int option) async {
    final q = _question;
    if (q == null || _selected != null || _finished || _loadingQ) return;
    setState(() => _selected = option);
    try {
      final res = await QuizService.checkAnswer(
        topicId: widget.topicId,
        questionId: q.id,
        answer: option,
      );
      if (!mounted || _finished) return;
      setState(() {
        _result = res;
        _attempted++;
        if (res.correct) _correct++;
        _answeredIds.add(q.id);
      });
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted && !_finished) _loadNext();
    } catch (_) {
      if (!mounted) return;
      setState(() => _selected = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Answer check nahi hua, dobara try karo.')),
      );
    }
  }

  // ---------- helpers ----------
  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  Color _hex(String? hex, Color fallback) {
    if (hex == null || hex.length != 7) return fallback;
    final v = int.tryParse(hex.substring(1), radix: 16);
    return v == null ? fallback : Color(0xFF000000 | v);
  }

  // Web rule: sahi = (minutes x level), galat = -1/4 of that
  double get _score {
    final per = (widget.durationSeconds / 60) * widget.level;
    final wrong = _attempted - _correct;
    return _correct * per - wrong * per / 4;
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Stack(
          children: [
            _finished ? _buildResult() : _buildQuiz(),
            if (!_started) _buildStartOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildStartOverlay() {
    return Positioned.fill(
      child: Container(
        color: const Color(0xEB000000),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'QUIZ STARTING IN',
              style: TextStyle(
                color: _gold,
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$_startCount',
              style: const TextStyle(
                color: Color(0xff39FF14),
                fontSize: 96,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final low = _timeLeft <= 10;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white70),
            tooltip: 'Exit',
          ),
          Expanded(
            child: Text(
              widget.topicName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Icon(Icons.timer_outlined, size: 20, color: Color(0xff39FF14)),
          const SizedBox(width: 6),
          Text(
            _fmt(_timeLeft),
            style: TextStyle(
              color: low ? Colors.redAccent : const Color(0xff39FF14),
              fontSize: 20,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuiz() {
    return Column(
      children: [
        _buildTopBar(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              _buildStatusRow(),
              const SizedBox(height: 14),
              _buildQuestionBody(),
              const SizedBox(height: 18),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _finish,
                  icon: const Icon(Icons.flag, color: Colors.redAccent),
                  label: const Text(
                    'End Quiz',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow() {
    return Row(
      children: [
        _chip(Icons.check_circle_outline, 'Attempt: $_attempted', Colors.white70),
        const SizedBox(width: 10),
        _chip(Icons.edit_note, 'Correct: $_correct', const Color(0xff00FCFF)),
        const Spacer(),
        Text(
          'Level ${widget.level}',
          style: const TextStyle(color: _gold, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _chip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: color, fontSize: 13)),
      ],
    );
  }

  Widget _buildQuestionBody() {
    if (_error != null) {
      return _messageCard(
        _error!,
        action: ElevatedButton(
          onPressed: _loadNext,
          style: ElevatedButton.styleFrom(
            backgroundColor: _gold,
            foregroundColor: const Color(0xff111111),
          ),
          child: const Text('Retry'),
        ),
      );
    }
    final q = _question;
    if (q == null || _loadingQ && _selected == null && _question == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator(color: _gold)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x33D4AF37)),
          ),
          child: Text.rich(
            TextSpan(
              children: q.segments
                  .map(
                    (s) => TextSpan(
                      text: s.text,
                      style: TextStyle(
                        color: _hex(s.colorHex, Colors.white),
                        fontWeight: s.bold ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  )
                  .toList(),
            ),
            style: const TextStyle(fontSize: 17, height: 1.45),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.9,
          children: List.generate(4, (i) => _buildOption(q, i + 1)),
        ),
      ],
    );
  }

  Widget _buildOption(QuizQuestion q, int number) {
    Color bg = _gold;
    Color fg = const Color(0xff111111);

    if (_selected != null && _result != null) {
      if (number == _result!.correctOption) {
        bg = const Color(0xff2E7D32);
        fg = Colors.white;
      } else if (number == _selected) {
        bg = const Color(0xffC62828);
        fg = Colors.white;
      } else {
        bg = const Color(0x55D4AF37);
      }
    } else if (_selected == number) {
      bg = const Color(0xffB8962E); // check ho raha hai
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _onOption(number),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Center(
            child: Text(
              q.options[number - 1],
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _messageCard(String text, {Widget? action}) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33D4AF37)),
      ),
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
          if (action != null) ...[const SizedBox(height: 14), action],
        ],
      ),
    );
  }

  // ---------- result ----------
  Widget _buildResult() {
    final wrong = _attempted - _correct;
    final scoreText = _score == _score.roundToDouble()
        ? _score.toInt().toString()
        : _score.toStringAsFixed(2);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
      children: [
        const Icon(Icons.emoji_events, size: 64, color: _gold),
        const SizedBox(height: 10),
        Center(
          child: Text(
            _noMore && _timeLeft > 0 ? 'All Questions Done!' : 'Quiz Over',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            '${widget.topicName} · Level ${widget.level}',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x33D4AF37)),
          ),
          child: Column(
            children: [
              Text(
                scoreText,
                style: const TextStyle(
                  color: _gold,
                  fontSize: 46,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text('Score',
                  style: TextStyle(color: Colors.white54, fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _statBox('Attempted', '$_attempted', Colors.white)),
            const SizedBox(width: 10),
            Expanded(
                child: _statBox('Correct', '$_correct', const Color(0xff4CAF50))),
            const SizedBox(width: 10),
            Expanded(child: _statBox('Wrong', '$wrong', Colors.redAccent)),
          ],
        ),
        const SizedBox(height: 28),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: const Color(0xff111111),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Back to Quiz Home',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}