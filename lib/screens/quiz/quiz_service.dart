import 'dart:convert';
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

class QuizService {
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
}