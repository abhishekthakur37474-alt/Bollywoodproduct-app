import 'package:flutter/material.dart';
import 'quiz_play_screen.dart';
import 'quiz_service.dart';

class _Opt {
  final Object value;
  final String label;
  const _Opt(this.value, this.label);
}

class QuizHomeScreen extends StatefulWidget {
  const QuizHomeScreen({super.key});

  @override
  State<QuizHomeScreen> createState() => _QuizHomeScreenState();
}

class _QuizHomeScreenState extends State<QuizHomeScreen> {
  QuizOptions? _options;
  bool _loading = true;
  String? _error;

  // selected values (web ke defaults jaise: 120 sec, level 1)
  int? _duration;
  int? _topicId;
  int? _level;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final o = await QuizService.fetchOptions();
      if (!mounted) return;
      setState(() {
        _options = o;
        _duration = o.durations.isNotEmpty ? o.durations.first.value : null;
        if (o.topics.isNotEmpty) {
          _topicId = o.topics.first.id;
          _level = o.topics.first.levels.first;
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Quiz options load nahi hue. Internet check karo.';
        _loading = false;
      });
    }
  }

  QuizTopic? get _topic {
    final o = _options;
    if (o == null || _topicId == null) return null;
    for (final t in o.topics) {
      if (t.id == _topicId) return t;
    }
    return null;
  }

  void _onTopicChanged(int id) {
    final t = _options!.topics.firstWhere((t) => t.id == id);
    setState(() {
      _topicId = id;
      // web jaisa: purana level available ho to rakho, warna pehla level
      if (_level == null || !t.levels.contains(_level)) {
        _level = t.levels.first;
      }
    });
  }

  void _playQuiz() {
    final t = _topic;
    if (t == null || _level == null || _duration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pehle duration, level aur topic chuno.')),
      );
      return;
    }

    // Jis topic ki API bani hai wahi khulega
    if (!QuizService.hasApi(t.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xff1A1A1A),
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Ye topic jald aa raha hai. Koi aur topic chuno.',
            style: TextStyle(color: Color(0xffD4AF37)),
          ),
        ),
      );
      return;
    }

    // rootNavigator: quiz poori screen pe khule (nested navigator me bhi chale)
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (_) => QuizPlayScreen(
          topicId: t.id,
          topicName: t.name,
          level: _level!,
          durationSeconds: _duration!,
        ),
      ),
    );
  }

  String _durationLabel() {
    for (final d in _options!.durations) {
      if (d.value == _duration) return d.label;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xffD4AF37)),
      );
    }
    if (_error != null || _options == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error ?? 'Something went wrong',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffD4AF37),
                foregroundColor: const Color(0xff111111),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final o = _options!;
    final t = _topic;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
      children: [
        _buildDropdown(
          title: 'Select Duration',
          options: o.durations.map((d) => _Opt(d.value, d.label)).toList(),
          value: _duration,
          onChanged: (v) => setState(() => _duration = v as int),
        ),
        const SizedBox(height: 22),
        _buildDropdown(
          title: 'Select Difficulty Level',
          options:
              (t?.levels ?? <int>[]).map((l) => _Opt(l, 'Level $l')).toList(),
          value: _level,
          onChanged: (v) => setState(() => _level = v as int),
        ),
        const SizedBox(height: 22),
        _buildDropdown(
          title: 'Select Topic',
          options: o.topics.map((t) => _Opt(t.id, t.name)).toList(),
          value: _topicId,
          onChanged: (v) => _onTopicChanged(v as int),
        ),
        const SizedBox(height: 32),
        SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: t == null ? null : _playQuiz,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffD4AF37),
              foregroundColor: const Color(0xff111111),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Play Quiz',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openDropdown({
    required BuildContext buttonContext,
    required List<_Opt> options,
    required Object? value,
    required ValueChanged<Object> onChanged,
  }) async {
    if (options.isEmpty) return;
    final box = buttonContext.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero, ancestor: overlay);
    final menuWidth = box.size.width;
    final position = RelativeRect.fromLTRB(
      offset.dx,
      offset.dy + box.size.height + 4,
      overlay.size.width - offset.dx - menuWidth,
      overlay.size.height - offset.dy - box.size.height,
    );

    final selected = await showMenu<Object>(
      context: context,
      position: position,
      color: const Color(0xff1A1A1A),
      elevation: 8,
      constraints: BoxConstraints(
        minWidth: menuWidth,
        maxWidth: menuWidth,
        maxHeight: 320,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0x55D4AF37)),
      ),
      items: options
          .map(
            (option) => PopupMenuItem<Object>(
              value: option.value,
              child: SizedBox(
                width: menuWidth,
                child: Text(
                  option.label,
                  style: TextStyle(
                    color: option.value == value
                        ? const Color(0xffD4AF37)
                        : Colors.white,
                    fontWeight: option.value == value
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );

    if (selected != null) onChanged(selected);
  }

  Widget _buildDropdown({
    required String title,
    required List<_Opt> options,
    required Object? value,
    required ValueChanged<Object> onChanged,
  }) {
    String shown = '';
    for (final o in options) {
      if (o.value == value) shown = o.label;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Builder(
          builder: (buttonContext) {
            return GestureDetector(
              onTap: () => _openDropdown(
                buttonContext: buttonContext,
                options: options,
                value: value,
                onChanged: onChanged,
              ),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xff1A1A1A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x33D4AF37)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        shown,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down,
                      color: Color(0xffD4AF37),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}