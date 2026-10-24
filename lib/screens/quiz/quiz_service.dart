import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// ---------------- dropdown options ----------------
class QuizDuration {
  final int value; // seconds (web me quiz_duration)
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
/// Question text ka ek tukda (web me <strong>/<span style="color:..">)
class QuestionSegment {
  final String text;
  final String? colorHex; // "#RRGGBB" ya null
  final bool bold;
  const QuestionSegment(this.text, this.colorHex, this.bold);
}

class QuizQuestion {
  final int id;
  final List<QuestionSegment> segments;
  final List<String> options; // 4 options
  final String videoId; // YouTube id (khali ho sakta hai, jaise topic 11)
  const QuizQuestion(this.id, this.segments, this.options, this.videoId);
}

class AnswerResult {
  final bool correct;
  final int correctOption; // 1..4
  const AnswerResult(this.correct, this.correctOption);
}

// ---------------- score ----------------
class SavedScore {
  final double points; // is quiz ke points (server ne nikale)
  final int attempted;
  final int correct;
  final int wrong;
  final double totalPoints; // all-time total
  const SavedScore(
      this.points, this.attempted, this.correct, this.wrong, this.totalPoints);
}

class RecentQuiz {
  final String topic;
  final int level;
  final int duration; // seconds
  final int attempted;
  final int correct;
  final double points;
  final String playedAt;
  const RecentQuiz(this.topic, this.level, this.duration, this.attempted,
      this.correct, this.points, this.playedAt);
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
  /// Logged-in user ki id (bollywoodprodu `users.id`).
  /// Login ke baad set karo: `QuizService.userId = id;`  Logout pe null.
  /// null ho to score save/show nahi hoga.
  static int? userId;

  /// Score save hone pe +1 hota hai, Score tab isse refresh hota hai.
  static final ValueNotifier<int> scoreVersion = ValueNotifier<int>(0);

  static const _scoreUrl = '$_base/quiz-score-api.php';

  static const _base = 'https://www.bollywoodproduct.com/quiz';
  static const _optionsUrl = '$_base/quiz-options-api.php';

  /// Har topic ki apni API file (topic id -> file name).
  /// Naya topic banao to yaha ek line add karo.
  /// NOTE: id=4 ki API abhi nahi bani, isliye wo topic "coming soon" dikhega.
  static const _playApiFile = {
    1: 'guess-the-singer-api.php', // Guess the Singer
    2: 'song-music-director-api.php', // Song (Music Director)
    3: 'song-lyricist-api.php', // Song (Lyricist)
    5: 'director-of-upcoming-film-api.php', // Director of Upcoming Film
    6: 'film-director-api.php', // Film Director
    7: 'film-producer-api.php', // Film Producer
    8: 'producer-of-upcoming-film-api.php', // Upcoming Film Producers
    9: 'production-house-of-upcoming-film-api.php', // Upcoming Films of Production House
    10: 'production-house-of-film-api.php', // Film Production House
    11: 'find-actor-of-film-api.php', // Find Actor of Film
  };

  /// Is topic ki API bani hai ya nahi.
  static bool hasApi(int topicId) => _playApiFile.containsKey(topicId);

  static String _playUrl(int topicId) {
    final file = _playApiFile[topicId];
    if (file == null) throw Exception('Is topic ki API abhi nahi bani');
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
        .toList();

    return QuizOptions(durations, topics);
  }

  /// Random naya question. null = is topic/level me aur question nahi bacha.
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

  /// Answer sahi hai ya nahi (server batata hai, answer app me nahi aata).
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
  /// Quiz khatam hone pe score save. Server answers se khud sahi/galat nikalta hai.
  /// answers = [(questionId, chosenOption 1..4), ...]
  static Future<SavedScore> saveScore({
    required int topicId,
    required int level,
    required int durationSeconds,
    required List<MapEntry<int, int>> answers,
  }) async {
    final uid = userId;
    if (uid == null) throw Exception('Login nahi hai');
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
    scoreVersion.value++;
    return SavedScore(
      double.parse(data['points'].toString()),
      int.parse(data['attempted'].toString()),
      int.parse(data['correct'].toString()),
      int.parse(data['wrong'].toString()),
      double.parse(data['total_points'].toString()),
    );
  }

  /// Score tab ke liye total + recent quizzes. null = user login nahi.
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
}