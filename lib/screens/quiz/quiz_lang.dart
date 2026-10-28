import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class QuizLang {
  static const en = 'en';
  static const hi = 'hi';

  static final ValueNotifier<String> code = ValueNotifier(en);
  static final ValueNotifier<int> liveTick = ValueNotifier(0);
  static Listenable get changes => Listenable.merge([code, liveTick]);

  static bool get isHi => code.value == hi;

  static void set(String lang) {
    if (lang != en && lang != hi) return;
    if (lang == code.value) return;
    code.value = lang;
  }

  static String t(String key) {
    final map = isHi ? _hi : _en;
    return map[key] ?? _en[key] ?? key;
  }

  static String topic(int id, [String? fallback]) {
    if (!isHi) return fallback ?? _topicEn[id] ?? '';
    return _topicHi[id] ?? fallback ?? _topicEn[id] ?? '';
  }

  static String topicName(String name) {
    if (!isHi) return name;
    for (final e in _topicEn.entries) {
      if (e.value == name) return _topicHi[e.key] ?? name;
    }
    return _topicNameHi[name] ?? live(name);
  }

  static String minutes(int seconds) =>
      t('n_min').replaceAll('{n}', '${seconds ~/ 60}');

  static String level(int n) => t('level_n').replaceAll('{n}', '$n');

  static String phrase(String text) {
    if (!isHi) return text;
    final key = text.trim();
    if (key.isEmpty) return text;
    final direct = _phraseHi[key] ?? _phraseHi[key.toLowerCase()];
    if (direct != null) return direct;
    if (key.contains(',')) {
      return key
          .split(',')
          .map((p) {
            final part = p.trim();
            return _phraseHi[part] ?? _phraseHi[part.toLowerCase()] ?? part;
          })
          .join(', ');
    }
    return text;
  }

  static String option(String text) => live(text);

  static String live(String text) {
    if (!isHi) return text;
    final local = phrase(text);
    if (!_needsLive(local)) return local;
    final key = local.trim();
    final cached = _liveCache[key];
    if (cached != null) return cached;
    _enqueue(key);
    return local;
  }

  static void prefetch(Iterable<String> texts) {
    if (!isHi) return;
    for (final t in texts) {
      live(t);
    }
  }

  static bool _needsLive(String s) => _latin.hasMatch(s);

  static final _latin = RegExp(r'[A-Za-z]');
  static final Map<String, String> _liveCache = {};
  static final Set<String> _queued = {};
  static final List<String> _queue = [];
  static int _inflight = 0;
  static Timer? _tickTimer;

  static void _enqueue(String text) {
    if (text.isEmpty || _liveCache.containsKey(text) || _queued.contains(text)) {
      return;
    }
    _queued.add(text);
    _queue.add(text);
    _pump();
  }

  static void _pump() {
    while (_inflight < 3 && _queue.isNotEmpty) {
      final text = _queue.removeAt(0);
      _inflight++;
      _translateOne(text).whenComplete(() {
        _inflight--;
        _queued.remove(text);
        _pump();
      });
    }
  }

  static Future<void> _translateOne(String text) async {
    try {
      final uri = Uri.https(
        'translate.googleapis.com',
        '/translate_a/single',
        {
          'client': 'gtx',
          'sl': 'en',
          'tl': 'hi',
          'dt': 't',
          'q': text,
        },
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return;
      final data = jsonDecode(res.body);
      final buf = StringBuffer();
      if (data is List && data.isNotEmpty && data.first is List) {
        for (final part in data.first) {
          if (part is List && part.isNotEmpty) buf.write(part.first);
        }
      }
      final out = buf.toString();
      if (out.isEmpty) return;
      _liveCache[text] = out;
      _scheduleTick();
    } catch (_) {}
  }

  static void _scheduleTick() {
    _tickTimer?.cancel();
    _tickTimer = Timer(const Duration(milliseconds: 80), () {
      liveTick.value++;
    });
  }
}

const _phraseHi = {
  'Who is the': 'कौन है',
  'Who is the ': 'कौन है ',
  'singer': 'गायक',
  'music director (composer)': 'संगीत निर्देशक',
  'lyricist': 'गीतकार',
  ' of the song ': ' गाने ',
  '  of the song ': ' गाने ',
  'of the song': 'गाने',
  ' from the ': ' की ',
  'from the': 'की',
  ' film ': ' फिल्म ',
  'film': 'फिल्म',
  'Film': 'फिल्म',
  'Who among these played one of the lead roles in the ':
      'इनमें से किसने मुख्य भूमिका निभाई ',
  'Who among these played one of the lead roles in the':
      'इनमें से किसने मुख्य भूमिका निभाई',
  'Hindi': 'हिन्दी',
  'English': 'अंग्रेज़ी',
  'Telugu': 'तेलुगु',
  'Tamil': 'तमिल',
  'Kannada': 'कन्नड़',
  'Malayalam': 'मलयालम',
  'Punjabi': 'पंजाबी',
  'Marathi': 'मराठी',
  'Bengali': 'बंगाली',
  'Gujarati': 'गुजराती',
  'Urdu': 'उर्दू',
  'Bhojpuri': 'भोजपुरी',
};

const _topicEn = {
  1: 'Guess the Singer',
  2: 'Song (Music Director) Quiz',
  3: 'Song (Lyricist) Quiz',
  11: 'Film Cast Quiz',
};

const _topicHi = {
  1: 'गायक पहचानो',
  2: 'गाना (संगीत निर्देशक)',
  3: 'गाना (गीतकार)',
  11: 'फिल्म कास्ट क्विज',
};

const _topicNameHi = {
  'Guess the Singer': 'गायक पहचानो',
  'Song (Music Director) Quiz': 'गाना (संगीत निर्देशक)',
  'Song (Lyricist) Quiz': 'गाना (गीतकार)',
  'Film Cast Quiz': 'फिल्म कास्ट क्विज',
};

const _en = {
  'retry': 'Retry',
  'something_wrong': 'Something went wrong',
  'login': 'Login',
  'level_n': 'Level {n}',
  'n_min': '{n} Min',
  'pts': 'pts',
  'english': 'English',
  'hindi': 'Hindi',
  'bollywood_quiz': 'Bollywood Quiz',
  'home': 'Home',
  'score': 'Score',
  'leaderboard': 'Leaderboard',
  'profile': 'Profile',
  'exit': 'Exit',
  'select_language': 'Select Language',
  'select_duration': 'Select Duration',
  'select_difficulty': 'Select Difficulty Level',
  'select_topic': 'Select Topic',
  'play_quiz': 'Play Quiz',
  'select_all_first': 'Please select duration, level and topic first.',
  'topic_coming_soon':
      'This topic is coming soon. Please choose another topic.',
  'load_options_fail':
      'Could not load quiz options. Please check your internet.',
  'exit_quiz': 'Exit Quiz?',
  'exit_quiz_msg':
      'Your current score will be saved and this attempt will end.',
  'stay': 'Stay',
  'quiz_starting': 'QUIZ STARTING IN',
  'close': 'Close',
  'time': 'Time',
  'load_question_fail':
      'Could not load question. Please check your internet.',
  'attempt': 'Attempt',
  'correct': 'Correct',
  'all_done': 'All Questions Done!',
  'quiz_over': 'Quiz Over',
  'score_label': 'Score',
  'attempted': 'Attempted',
  'wrong': 'Wrong',
  'back_home': 'Back to Quiz Home',
  'saving_score': 'Saving score...',
  'score_saved': 'Score saved  ·  Total points: {n}',
  'login_to_save': 'Login to save your score.',
  'save_fail': 'Could not save score. Please check your internet.',
  'retry_save': 'Retry save',
  'check_answer_fail': 'Could not check answer, please try again.',
  'your_score': 'Your Score',
  'total_points': 'Total Points',
  'quizzes': 'Quizzes',
  'recent_quizzes': 'Recent Quizzes',
  'login_to_view_score': 'Login to view your score',
  'load_score_fail': 'Could not load score. Please check your internet.',
  'loading': 'Loading...',
  'no_history': 'No quiz history yet',
  'today': 'Today',
  'week': 'Week',
  'month': 'Month',
  'year': 'Year',
  'load_board_fail':
      'Could not load leaderboard. Please check your internet.',
  'pull_retry': 'Pull down to try again',
  'no_scores': 'No scores yet for this period',
  'be_first': 'Be the first to climb the board!',
  'your_rank': 'Your Rank',
  'play_to_rank': 'Play a quiz to get ranked',
  'you_suffix': '(You)',
  'quiz_player': 'Quiz Player',
  'phone': 'Phone',
  'city': 'City',
  'state': 'State',
  'pincode': 'Pincode',
  'logout': 'Logout',
  'guest': 'Guest',
  'login_to_see_profile': 'Login to see your profile',
  'continue_google': 'Continue with Google',
  'quiz_result': 'Quiz Result',
  'your_responses': 'Your Quiz Responses',
  'load_questions_fail': 'Could not load questions.',
  'data_na': 'Data Not Available',
  'tag_correct': 'Correct',
  'tag_wrong': 'Wrong',
  'your_answer': 'Your Answer',
  'option_n': 'Option {n}',
  'correct_of': '{c}/{a} correct',
};

const _hi = {
  'retry': 'पुनः प्रयास',
  'something_wrong': 'कुछ गलत हो गया',
  'login': 'लॉगिन',
  'level_n': 'स्तर {n}',
  'n_min': '{n} मिनट',
  'pts': 'अंक',
  'english': 'English',
  'hindi': 'हिन्दी',
  'bollywood_quiz': 'बॉलीवुड क्विज',
  'home': 'होम',
  'score': 'स्कोर',
  'leaderboard': 'लीडरबोर्ड',
  'profile': 'प्रोफ़ाइल',
  'exit': 'बाहर निकलें',
  'select_language': 'भाषा चुनें',
  'select_duration': 'अवधि चुनें',
  'select_difficulty': 'कठिनाई स्तर चुनें',
  'select_topic': 'विषय चुनें',
  'play_quiz': 'क्विज खेलें',
  'select_all_first': 'कृपया पहले अवधि, स्तर और विषय चुनें।',
  'topic_coming_soon': 'यह विषय जल्द आ रहा है। कृपया कोई और विषय चुनें।',
  'load_options_fail':
      'क्विज विकल्प लोड नहीं हो सके। कृपया अपना इंटरनेट जांचें।',
  'exit_quiz': 'क्विज छोड़ें?',
  'exit_quiz_msg':
      'आपका मौजूदा स्कोर सेव हो जाएगा और यह प्रयास खत्म हो जाएगा।',
  'stay': 'रहें',
  'quiz_starting': 'क्विज शुरू हो रही है',
  'close': 'बंद करें',
  'time': 'समय',
  'load_question_fail':
      'प्रश्न लोड नहीं हो सका। कृपया अपना इंटरनेट जांचें।',
  'attempt': 'प्रयास',
  'correct': 'सही',
  'all_done': 'सभी प्रश्न पूरे!',
  'quiz_over': 'क्विज समाप्त',
  'score_label': 'स्कोर',
  'attempted': 'प्रयास',
  'wrong': 'गलत',
  'back_home': 'क्विज होम पर वापस',
  'saving_score': 'स्कोर सेव हो रहा है...',
  'score_saved': 'स्कोर सेव हो गया  ·  कुल अंक: {n}',
  'login_to_save': 'स्कोर सेव करने के लिए लॉगिन करें।',
  'save_fail': 'स्कोर सेव नहीं हो सका। कृपया अपना इंटरनेट जांचें।',
  'retry_save': 'फिर से सेव करें',
  'check_answer_fail': 'उत्तर जांच नहीं सका, कृपया फिर कोशिश करें।',
  'your_score': 'आपका स्कोर',
  'total_points': 'कुल अंक',
  'quizzes': 'क्विज',
  'recent_quizzes': 'हाल की क्विज',
  'login_to_view_score': 'स्कोर देखने के लिए लॉगिन करें',
  'load_score_fail': 'स्कोर लोड नहीं हो सका। कृपया अपना इंटरनेट जांचें।',
  'loading': 'लोड हो रहा है...',
  'no_history': 'अभी कोई क्विज इतिहास नहीं',
  'today': 'आज',
  'week': 'सप्ताह',
  'month': 'महीना',
  'year': 'वर्ष',
  'load_board_fail':
      'लीडरबोर्ड लोड नहीं हो सका। कृपया अपना इंटरनेट जांचें।',
  'pull_retry': 'फिर कोशिश करने के लिए नीचे खींचें',
  'no_scores': 'इस अवधि के लिए अभी कोई स्कोर नहीं',
  'be_first': 'बोर्ड पर सबसे पहले पहुंचें!',
  'your_rank': 'आपकी रैंक',
  'play_to_rank': 'रैंक पाने के लिए क्विज खेलें',
  'you_suffix': '(आप)',
  'quiz_player': 'क्विज प्लेयर',
  'phone': 'फ़ोन',
  'city': 'शहर',
  'state': 'राज्य',
  'pincode': 'पिनकोड',
  'logout': 'लॉगआउट',
  'guest': 'अतिथि',
  'login_to_see_profile': 'प्रोफ़ाइल देखने के लिए लॉगिन करें',
  'continue_google': 'Google से जारी रखें',
  'quiz_result': 'क्विज परिणाम',
  'your_responses': 'आपके क्विज उत्तर',
  'load_questions_fail': 'प्रश्न लोड नहीं हो सके।',
  'data_na': 'डेटा उपलब्ध नहीं',
  'tag_correct': 'सही',
  'tag_wrong': 'गलत',
  'your_answer': 'आपका उत्तर',
  'option_n': 'विकल्प {n}',
  'correct_of': '{c}/{a} सही',
};
