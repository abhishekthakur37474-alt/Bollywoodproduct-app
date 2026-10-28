import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../services/auth_service.dart';

// ---------------- dropdown options ----------------
class QuizDuration {
  final int value; // seconds (quiz_duration on web)
  final String label;
  const QuizDuration(this.value, this.label);
}

class QuizTopic {
  final int id; // quiz_question_generator_id
  final String name;
  final List<int> levels; // available difficulty levels
  const QuizTopic(this.id, this.name, this.levels);
}

class QuizOptions {
  final List<QuizDuration> durations;
  final List<QuizTopic> topics;
  const QuizOptions(this.durations, this.topics);
}

// ---------------- questions ----------------
/// One piece of question text (on web: <strong>/<span style="color:..">)
class QuestionSegment {
  final String text;
  final String? colorHex; // "#RRGGBB" or null
  final bool bold;
  const QuestionSegment(this.text, this.colorHex, this.bold);
}

class QuizQuestion {
  final int id;
  final List<QuestionSegment> segments;
  final List<String> options; // 4 options
  final String videoId; // YouTube id (can be empty, e.g. topic 11)
  const QuizQuestion(this.id, this.segments, this.options, this.videoId);
}

class AnswerResult {
  final bool correct;
  final int correctOption; // 1..4
  const AnswerResult(this.correct, this.correctOption);
}

// ---------------- score ----------------
class SavedScore {
  final double points; // points for this quiz (calculated by server)
  final int attempted;
  final int correct;
  final int wrong;
  final double totalPoints; // all-time total
  final int? quizNumber; // user's N-th quiz (history key)
  final String? playedAt;
  const SavedScore(this.points, this.attempted, this.correct, this.wrong,
      this.totalPoints,
      {this.quizNumber, this.playedAt});
}

class RecentQuiz {
  final int? quizNumber; // user_quiz_number (for history detail)
  final String topic;
  final int level;
  final int duration; // seconds
  final int attempted;
  final int correct;
  final double points;
  final String playedAt;
  const RecentQuiz(this.topic, this.level, this.duration, this.attempted,
      this.correct, this.points, this.playedAt,
      {this.quizNumber});
}

/// A question attempted in a quiz (history -> result screen).
class AttemptedQuestion {
  final int id;
  final List<QuestionSegment> segments;
  final List<String> options; // 4 options
  final int selected; // user's option 1..4
  final int correctOption; // correct option 1..4
  const AttemptedQuestion(
      this.id, this.segments, this.options, this.selected, this.correctOption);
  bool get isCorrect => selected == correctOption;
}

class LeaderboardEntry {
  final int? rank; // null = did not play in this period
  final int userId;
  final String name;
  final String picture;
  final double points;
  final int correct;
  final int attempted;
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.name,
    required this.picture,
    required this.points,
    required this.correct,
    required this.attempted,
  });
}

class LeaderboardData {
  final List<LeaderboardEntry> rows;
  final LeaderboardEntry? me;
  const LeaderboardData(this.rows, this.me);
}

class ScoreSummary {
  final double totalPoints;
  final int totalCorrect;
  final int totalAttempted;
  final int quizzes;
  final List<RecentQuiz> recent;
  const ScoreSummary(this.totalPoints, this.totalCorrect, this.totalAttempted,
      this.quizzes, this.recent);
}

class QuizService {
  /// Logged-in user id (bollywoodprodu `users.id`).
  /// Comes automatically from AuthService (set on login, null on logout).
  static int? get userId => AuthService.bollyUserId.value;

  /// Increments by 1 when a score is saved; Score tab refreshes from this.
  static final ValueNotifier<int> scoreVersion = ValueNotifier<int>(0);

  static const _scoreUrl = '$_base/quiz-score-api.php';
  static const _leaderboardUrl = '$_base/quiz-leaderboard-api.php';

  static const _base = 'https://www.bollywoodproduct.com/quiz';
  static const _optionsUrl = '$_base/quiz-options-api.php';

  /// Each topic has its own API file (topic id -> file name).
  /// Add a line here when creating a new topic.
  /// NOTE: id=4 API is not built yet, so that topic shows as "coming soon".
  static const _playApiFile = {
    1: 'guess-the-singer-api.php', // Guess the Singer
    2: 'song-music-director-api.php', // Song (Music Director)
    3: 'song-lyricist-api.php', // Song (Lyricist)
    // 5: 'director-of-upcoming-film-api.php', // Director of Upcoming Film
    // 6: 'film-director-api.php', // Film Director
    // 7: 'film-producer-api.php', // Film Producer
    // 8: 'producer-of-upcoming-film-api.php', // Upcoming Film Producers
    // 9: 'production-house-of-upcoming-film-api.php', // Upcoming Films of Production House
    // 10: 'production-house-of-film-api.php', // Film Production House
    11: 'find-actor-of-film-api.php', // Film Cast Quiz
  };

  static const _visibleTopicIds = {1, 2, 3, 11};

  /// Whether this topic has an API.
  static bool hasApi(int topicId) => _playApiFile.containsKey(topicId);

  static String _playUrl(int topicId) {
    final file = _playApiFile[topicId];
    if (file == null) throw Exception('API for this topic is not available yet');
    return '$_base/$file';
  }

  static Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('Server error ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> _postJson(
      Uri uri, Map<String, String> body) async {
    final res =
        await http.post(uri, body: body).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) {
      throw Exception('Server error ${res.statusCode}');
    }
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<QuizOptions> fetchOptions() async {
    final data = await _getJson(Uri.parse(_optionsUrl));
    if (data['status'] != 'ok') throw Exception('Bad response');

    final durations = (data['durations'] as List)
        .map((d) => QuizDuration(
              int.parse(d['value'].toString()),
              d['label'].toString(),
            ))
        .toList();

    final topics = (data['topics'] as List)
        .map((t) => QuizTopic(
              int.parse(t['id'].toString()),
              t['name'].toString(),
              (t['levels'] as List)
                  .map((l) => int.parse(l.toString()))
                  .toList(),
            ))
        .where((t) => _visibleTopicIds.contains(t.id))
        .toList();

    return QuizOptions(durations, topics);
  }

  /// Random new question. null = no questions left for this topic/level.
  static Future<QuizQuestion?> fetchQuestion({
    required int generatorId,
    required int level,
    required List<int> exclude,
  }) async {
    final uri = Uri.parse(_playUrl(generatorId)).replace(queryParameters: {
      'action': 'question',
      'generator_id': '$generatorId',
      'level': '$level',
      if (exclude.isNotEmpty) 'exclude': exclude.join(','),
    });
    final data = await _getJson(uri);
    if (data['status'] == 'empty') return null;
    if (data['status'] != 'ok') throw Exception('Bad response');

    final q = data['question'] as Map<String, dynamic>;
    final segments = (q['segments'] as List)
        .map((s) => QuestionSegment(
              s['text'].toString(),
              s['color']?.toString(),
              s['bold'] == true,
            ))
        .toList();
    final options = (q['options'] as List).map((o) => o.toString()).toList();

    return QuizQuestion(
      int.parse(q['id'].toString()),
      segments,
      options,
      (q['video_id'] ?? '').toString(),
    );
  }

  /// Whether the answer is correct (server tells us; the answer is not sent to the app).
  static Future<AnswerResult> checkAnswer({
    required int topicId,
    required int questionId,
    required int answer, // 1..4
  }) async {
    final uri = Uri.parse(_playUrl(topicId)).replace(queryParameters: {
      'action': 'check',
      'id': '$questionId',
      'ans': '$answer',
    });
    final data = await _getJson(uri);
    if (data['status'] != 'ok') throw Exception('Bad response');
    return AnswerResult(
      data['correct'] == true,
      int.parse(data['correct_option'].toString()),
    );
  }

  // ---------------- score ----------------
  /// Save score when the quiz ends. Server calculates correct/wrong from answers.
  /// answers = [(questionId, chosenOption 1..4), ...]
  static Future<SavedScore> saveScore({
    required int topicId,
    required int level,
    required int durationSeconds,
    required List<MapEntry<int, int>> answers,
  }) async {
    final uid = userId;
    if (uid == null) throw Exception('Not logged in');
    final data = await _postJson(Uri.parse(_scoreUrl), {
      'action': 'save',
      'user_id': '$uid',
      'generator_id': '$topicId',
      'level': '$level',
      'duration': '$durationSeconds',
      'answers': answers.map((e) => '${e.key}:${e.value}').join(','),
    });
    if (data['status'] != 'ok') {
      throw Exception(data['message']?.toString() ?? 'Bad response');
    }
    debugPrint('[QUIZ] save linked=${data['answers_linked']} err=${data['answers_error']}');
    scoreVersion.value++;
    return SavedScore(
      double.parse(data['points'].toString()),
      int.parse(data['attempted'].toString()),
      int.parse(data['correct'].toString()),
      int.parse(data['wrong'].toString()),
      double.parse(data['total_points'].toString()),
      quizNumber: int.tryParse('${data['quiz_number'] ?? ''}'),
      playedAt: data['played_at']?.toString(),
    );
  }

  /// History quiz questions + attempts (from server). Empty list = detail not found.
  static Future<List<AttemptedQuestion>> fetchQuizDetail(int quizNumber) async {
    final uid = userId;
    if (uid == null) return [];
    final uri = Uri.parse(_scoreUrl).replace(queryParameters: {
      'action': 'detail',
      'user_id': '$uid',
      'quiz_number': '$quizNumber',
    });
    final data = await _getJson(uri);
    if (data['status'] != 'ok') {
      throw Exception(data['message']?.toString() ?? 'Bad response');
    }
    debugPrint('[QUIZ] detail debug=${data['debug']}');
    return (data['questions'] as List).map((q) {
      final segs = (q['segments'] as List)
          .map((s) => QuestionSegment(
                s['text'].toString(),
                s['color']?.toString(),
                s['bold'] == true,
              ))
          .toList();
      final opts = (q['options'] as List).map((o) => o.toString()).toList();
      return AttemptedQuestion(
        int.parse(q['id'].toString()),
        segs,
        opts,
        int.parse(q['selected'].toString()),
        int.parse(q['correct_option'].toString()),
      );
    }).toList();
  }

  /// Total + recent quizzes for the Score tab. null = user not logged in.
  static Future<ScoreSummary?> fetchSummary() async {
    final uid = userId;
    if (uid == null) return null;
    final uri = Uri.parse(_scoreUrl)
        .replace(queryParameters: {'action': 'summary', 'user_id': '$uid'});
    final data = await _getJson(uri);
    if (data['status'] != 'ok') throw Exception('Bad response');
    final recent = (data['recent'] as List)
        .map((r) => RecentQuiz(
              r['topic'].toString(),
              int.parse(r['level'].toString()),
              int.parse(r['duration'].toString()),
              int.parse(r['attempted'].toString()),
              int.parse(r['correct'].toString()),
              double.parse(r['points'].toString()),
              r['played_at'].toString(),
              quizNumber: int.tryParse('${r['quiz_number'] ?? ''}'),
            ))
        .toList();
    return ScoreSummary(
      double.parse(data['total_points'].toString()),
      int.parse(data['total_correct'].toString()),
      int.parse(data['total_attempted'].toString()),
      int.parse(data['quizzes'].toString()),
      recent,
    );
  }

  /// period: today | week | month | year
  static Future<LeaderboardData> fetchLeaderboard(String period) async {
    final uri = Uri.parse(_leaderboardUrl).replace(queryParameters: {
      'period': period,
      if (userId != null) 'user_id': '$userId',
    });
    final data = await _getJson(uri);
    if (data['status'] != 'ok') {
      throw Exception(data['message']?.toString() ?? 'Bad response');
    }
    final rows = (data['rows'] as List).map((r) {
      return LeaderboardEntry(
        rank: int.tryParse('${r['rank']}'),
        userId: int.parse(r['user_id'].toString()),
        name: r['name'].toString(),
        picture: (r['picture'] ?? '').toString(),
        points: double.parse(r['points'].toString()),
        correct: int.parse(r['correct'].toString()),
        attempted: int.parse(r['attempted'].toString()),
      );
    }).toList();

    LeaderboardEntry? me;
    final m = data['me'];
    if (m is Map) {
      me = LeaderboardEntry(
        rank: int.tryParse('${m['rank']}'),
        userId: userId ?? 0,
        name: 'You',
        picture: '',
        points: double.parse(m['points'].toString()),
        correct: int.parse(m['correct'].toString()),
        attempted: int.parse(m['attempted'].toString()),
      );
    }
    return LeaderboardData(rows, me);
  }
}