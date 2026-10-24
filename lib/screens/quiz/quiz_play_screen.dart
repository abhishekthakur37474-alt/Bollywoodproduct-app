import 'dart:async';
import 'package:flutter/material.dart';
import 'quiz_service.dart';
import 'thinking_people.dart';

const _gold = Color(0xffD4AF37);
const _bg = Color(0xff0F0F0F);
const _card = Color(0xff1A1A1A);

/// Screen for playing the quiz.
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
  final List<MapEntry<int, int>> _answers = []; // (questionId, option) to send to server
  int _attempted = 0;
  int _correct = 0;

  bool _finished = false;
  bool _noMore = false; // all questions finished

  // score save
  bool _saving = false;
  SavedScore? _saved;
  String? _saveError;

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
    if (_finished) return;
    _timer?.cancel();
    if (!mounted) return;
    setState(() => _finished = true);
    _saveScore();
  }

  Future<void> _confirmExit() async {
    if (_finished) return;
    final leave = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: _card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Do you really want to exit?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'No',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Yes',
              style: TextStyle(color: _gold, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
    if (leave == true && mounted) _finish();
  }

  Future<void> _saveScore() async {
    if (_saving || _saved != null || _attempted == 0) return;
    if (QuizService.userId == null) return; // not logged in, result screen will show a message
    setState(() {
      _saving = true;
      _saveError = null;
    });
    try {
      final r = await QuizService.saveScore(
        topicId: widget.topicId,
        level: widget.level,
        durationSeconds: widget.durationSeconds,
        answers: _answers,
      );
      if (!mounted) return;
      setState(() {
        _saved = r;
        _saving = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = 'Could not save score. Please check your internet.';
      });
    }
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
        _error = 'Could not load question. Please check your internet.';
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
        _answers.add(MapEntry(q.id, option));
      });
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted && !_finished) _loadNext();
    } catch (_) {
      if (!mounted) return;
      setState(() => _selected = null);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not check answer, please try again.')),
      );
    }
  }

  // ---------- helpers ----------
  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

  // Web rule: correct = (minutes x level), wrong = -1/4 of that
  double get _score {
    final per = (widget.durationSeconds / 60) * widget.level;
    final wrong = _attempted - _correct;
    return _correct * per - wrong * per / 4;
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _finished,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_finished) _confirmExit();
      },
      child: Scaffold(
        backgroundColor: _bg,
        body: SafeArea(
          child: Stack(
            children: [
              _finished ? _buildResult() : _buildQuiz(),
              if (!_started) _buildStartOverlay(),
            ],
          ),
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

  Widget _buildQuiz() {
    final low = _timeLeft <= 10;
    final progress = widget.durationSeconds == 0
        ? 0.0
        : (_timeLeft / widget.durationSeconds).clamp(0.0, 1.0);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Column(
            children: [
              SizedBox(
                height: 40,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: _confirmExit,
                        tooltip: 'Close',
                        icon: const Icon(Icons.close, color: Colors.white70, size: 22),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.topicName,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: Center(
                        child: Text(
                          '$_attempted',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'Time',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: const Color(0xff2A2A2A),
                        color: low ? Colors.redAccent : _gold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _fmt(_timeLeft),
                    style: TextStyle(
                      color: low ? Colors.redAccent : Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: _buildQuestionBody(),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionBody() {
    if (_error != null) {
      return Center(
        child: _messageCard(
          _error!,
          action: ElevatedButton(
            onPressed: _loadNext,
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: const Color(0xff111111),
            ),
            child: const Text('Retry'),
          ),
        ),
      );
    }
    final q = _question;
    if (q == null) {
      return const Center(child: CircularProgressIndicator(color: _gold));
    }

    return Column(
      children: [
        const SizedBox(
          height: 150,
          width: double.infinity,
          child: ThinkingPeople(),
        ),
        Text(
          'Level ${widget.level}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: _gold,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 96),
          child: SingleChildScrollView(
            child: Text.rich(
              TextSpan(
                children: q.segments
                    .map(
                      (s) => TextSpan(
                        text: s.text,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight:
                              s.bold ? FontWeight.w800 : FontWeight.w600,
                        ),
                      ),
                    )
                    .toList(),
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, height: 1.4),
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (var i = 1; i <= 4; i++) ...[
          if (i > 1) const SizedBox(height: 10),
          _buildOption(q, i),
        ],
        const Spacer(),
      ],
    );
  }

  Widget _buildOption(QuizQuestion q, int number) {
    Color bg = _card;
    Color fg = Colors.white;
    Color border = const Color(0x22FFFFFF);

    if (_selected != null && _result != null) {
      if (number == _result!.correctOption) {
        bg = const Color(0xff2E7D32);
        fg = Colors.white;
        border = const Color(0xff2E7D32);
      } else if (number == _selected) {
        bg = const Color(0xffC62828);
        fg = Colors.white;
        border = const Color(0xffC62828);
      }
    } else if (_selected == number) {
      bg = _gold;
      fg = const Color(0xff111111);
      border = _gold;
    }

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => _onOption(number),
        child: Container(
          width: double.infinity,
          height: 52,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: border),
          ),
          child: Text(
            q.options[number - 1],
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              height: 1.25,
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
    final sc = _saved?.points ?? _score; // use server score once saved
    final scoreText =
        sc == sc.roundToDouble() ? sc.toInt().toString() : sc.toStringAsFixed(2);

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
        const SizedBox(height: 16),
        _buildSaveStatus(),
        const SizedBox(height: 20),
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

  Widget _buildSaveStatus() {
    if (_attempted == 0) return const SizedBox.shrink();

    Widget line(String text, Color color, {Widget? lead, Widget? action}) {
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (lead != null) ...[lead, const SizedBox(width: 8)],
              Flexible(
                child: Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: color, fontSize: 13),
                ),
              ),
            ],
          ),
          if (action != null) ...[const SizedBox(height: 8), action],
        ],
      );
    }

    if (_saving) {
      return line(
        'Saving score...',
        Colors.white70,
        lead: const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2, color: _gold),
        ),
      );
    }
    final saved = _saved;
    if (saved != null) {
      final t = saved.totalPoints;
      final tt = t == t.roundToDouble() ? t.toInt().toString() : t.toStringAsFixed(2);
      return line(
        'Score saved  ·  Total points: $tt',
        const Color(0xff4CAF50),
        lead: const Icon(Icons.check_circle, size: 18, color: Color(0xff4CAF50)),
      );
    }
    if (QuizService.userId == null) {
      return line('Login to save your score.', Colors.white54);
    }
    return line(
      _saveError ?? 'Could not save score.',
      Colors.redAccent,
      action: OutlinedButton(
        onPressed: _saveScore,
        style: OutlinedButton.styleFrom(
          foregroundColor: _gold,
          side: const BorderSide(color: _gold),
        ),
        child: const Text('Retry save'),
      ),
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