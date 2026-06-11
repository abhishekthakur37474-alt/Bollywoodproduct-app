import 'package:http/http.dart' as http;

class YouTubeService {
  static Future<String?> getUploadDate(String videoId) async {
    if (videoId.isEmpty) return null;

    try {
      // Using a fallback approach without API key for now
      // In production, you'll need to add your YouTube Data API v3 key
      final url =
          'https://noembed.com/embed?url=https://www.youtube.com/watch?v=$videoId';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // noembed doesn't provide upload date, so we'll use a mock for testing
        // In production, replace with actual YouTube API key
        return DateTime.now()
            .subtract(Duration(days: videoId.hashCode % 365))
            .toIso8601String();
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  static DateTime? parseUploadDate(String? publishedAt) {
    if (publishedAt == null) return null;

    try {
      return DateTime.parse(publishedAt);
    } catch (e) {
      return null;
    }
  }
}
