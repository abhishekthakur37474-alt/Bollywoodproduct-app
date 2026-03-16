class DataAdapter {
  static String extractTitle(dynamic item) {
    return item["film_name"] ??
        item["name"] ??
        item["title"] ??
        item["movie_name"] ??
        "Untitled";
  }

  static String? extractPoster(dynamic item) {
    // First try direct poster fields
    final poster =
        item["film_image"] ??
        item["poster_image_url"] ??
        item["poster"] ??
        item["image"] ??
        item["thumbnail"];

    if (poster != null && poster.toString().trim().isNotEmpty) {
      return poster.toString();
    }

    // Try YouTube image URL
    final youtubeImage = item["youtube_image_url"];
    if (youtubeImage != null && youtubeImage.toString().trim().isNotEmpty) {
      return youtubeImage.toString();
    }

    // Extract YouTube ID and generate thumbnail URL
    final youtubeId = extractYoutubeId(item);
    if (youtubeId != null) {
      return "https://img.youtube.com/vi/$youtubeId/0.jpg";
    }

    // Try trailers array for YouTube ID
    if (item["trailers"] is List) {
      final trailers = item["trailers"] as List;
      for (final trailer in trailers) {
        final ytId = extractYoutubeId(trailer);
        if (ytId != null) {
          return "https://img.youtube.com/vi/$ytId/0.jpg";
        }
      }
    }

    return null;
  }

  /// ✅ NEW: LANGUAGE EXTRACTOR
  static String extractLanguage(dynamic item) {
    final lang =
        item["language"] ??
        item["movie_language"] ??
        item["lang"] ??
        item["film_language"];

    if (lang == null || lang.toString().trim().isEmpty) {
      return "Hindi"; // ✅ sensible default
    }

    return lang.toString();
  }

  static String extractYear(dynamic item) {
    final yr = item["year_release"] ?? item["release_year"] ?? item["year"];

    if (yr == null || yr.toString().trim().isEmpty) return "";
    return yr.toString();
  }

  static String? extractYoutubeId(dynamic item) {
    String? raw;

    if (item is Map) {
      raw =
          item["youtube_id"] ??
          item["video_id"] ??
          item["youtube_url"] ??
          item["video_url"] ??
          item["teaser"] ??
          item["trailer"] ??
          item["watch_url"] ??
          item["embed_url"];
    } else if (item is String) {
      raw = item;
    }

    if (raw == null) return null;

    final url = raw.toString().trim();

    if (url.isEmpty) return null;

    // ✅ If already clean 11-char ID
    if (!url.contains("http") && url.length == 11) {
      return url;
    }

    // ✅ Extract ID from ANY YouTube format
    final regExp = RegExp(
      r'(?:v=|\/embed\/|youtu\.be\/|\/v\/)([0-9A-Za-z_-]{11})',
    );

    final match = regExp.firstMatch(url);

    return match?.group(1);
  }
}
