class DataAdapter {
  static String extractTitle(dynamic item) {
    return item["dubbed_film_name"] ?? // ✅ DUBBED MOVIES
        item["film_name"] ??
        item["name"] ??
        item["title"] ??
        item["movie_name"] ??
        "Untitled";
  }

  static String? extractPoster(dynamic item) {
    // First try direct poster fields (prioritize film_image_url for upcoming movies)
    final poster =
        item["film_image_url"] ?? // ✅ UPCOMING MOVIES API
        item["youtube_thumbnail"] ?? // ✅ DUBBED MOVIES
        item["film_image"] ??
        item["poster_image_url"] ??
        item["poster"] ??
        item["image"] ??
        item["thumbnail"] ??
        item["poster_url"] ??
        item["movie_poster"];

    if (poster != null && poster.toString().trim().isNotEmpty) {
      String posterUrl = poster.toString();
      // Fix YouTube URL format
      if (posterUrl.startsWith("https://img.youtube.com/")) {
        posterUrl = posterUrl.replaceFirst("https://", "https://");
      }
      print("🟢 [POSTER] Found poster: $posterUrl");
      return posterUrl;
    }

    // Try YouTube image URL
    final youtubeImage = item["youtube_image_url"];
    if (youtubeImage != null && youtubeImage.toString().trim().isNotEmpty) {
      String youtubeUrl = youtubeImage.toString();
      // Fix YouTube URL format
      if (youtubeUrl.startsWith("https://img.youtube.com/")) {
        youtubeUrl = youtubeUrl.replaceFirst("https://", "https://");
      }
      print("🟢 [POSTER] Found YouTube image: $youtubeUrl");
      return youtubeUrl;
    }

    // Extract YouTube ID and generate thumbnail URL
    final youtubeId = extractYoutubeId(item);
    if (youtubeId != null) {
      final thumbnailUrl =
          "https://img.youtube.com/vi/$youtubeId/hqdefault.jpg";
      print("🟢 [POSTER] Generated YouTube thumbnail: $thumbnailUrl");
      return thumbnailUrl;
    }

    // Try trailers array for YouTube ID
    if (item["trailers"] is List) {
      final trailers = item["trailers"] as List;
      for (final trailer in trailers) {
        final ytId = extractYoutubeId(trailer);
        if (ytId != null) {
          final thumbnailUrl = "https://img.youtube.com/vi/$ytId/hqdefault.jpg";
          print("🟢 [POSTER] Found YouTube from trailers: $thumbnailUrl");
          return thumbnailUrl;
        }
      }
    }

    // For movies with no poster info, try to get from API using unique_id
    final uniqueId = item["unique_id"]?.toString();
    if (uniqueId != null && uniqueId.isNotEmpty) {
      print(
        "🟡 [POSTER] No direct poster found, will try API for ID: $uniqueId",
      );
      // Return null to trigger API call in MovieListTile
      return null;
    }

    print("🔴 [POSTER] No poster found for item: ${item.keys.toList()}");
    return null;
  }

  static String? _parseLanguages(String? langStr) {
    if (langStr == null || langStr.trim().isEmpty) return null;

    // Check if it consists of numeric codes separated by commas or spaces
    final isCodes = RegExp(r'^[\d,\s]+$').hasMatch(langStr);

    if (isCodes) {
      final codes = langStr.replaceAll(RegExp(r'[^0-9,]'), '').split(',');
      final langs = codes
          .where((c) => c.trim().isNotEmpty)
          .map((code) => _mapLanguageCode(code.trim()))
          .toSet()
          .toList();

      if (langs.isNotEmpty) {
        return langs.join(", ");
      }
    }

    return langStr.trim();
  }

  /// ✅ NEW: LANGUAGE EXTRACTOR
  static String extractLanguage(dynamic item) {
    // First try ott_language_name field (for OTT movies)
    final ottLang = item["ott_language_name"]?.toString();
    if (ottLang != null && ottLang.trim().isNotEmpty) {
      return ottLang.trim();
    }

    // Then try main_lang field (numeric code)
    final mainLang = _parseLanguages(item["main_lang"]?.toString());
    if (mainLang != null && mainLang.isNotEmpty) {
      return mainLang;
    }

    // Then try other language fields
    final langStr =
        item["film_lang"] ?? // ✅ FULL MOVIES API
        item["language"] ??
        item["movie_language"] ??
        item["lang"] ??
        item["film_language"];

    final parsedLang = _parseLanguages(langStr?.toString());
    if (parsedLang != null && parsedLang.isNotEmpty) {
      return parsedLang;
    }

    return ""; // No default language
  }

  static String extractCategorySlug(dynamic item) {
    return item["trailer_category"] ?? // ✅ FULL MOVIES API
        item["categorySlug"] ??
        item["category"] ??
        item["type"] ??
        ""; // ✅ No default category for latest movies
  }

  /// NEW: MAP LANGUAGE CODE TO LANGUAGE NAME
  static String _mapLanguageCode(String code) {
    final langMap = {
      "3": "English",
      "5": "Hindi",
      "20": "Tamil",
      "21": "Malayalam",
      "22": "Bhojpuri",
      "25": "Telugu",
      "26": "Kannada",
      "30": "Spanish",
    };

    return langMap[code] ?? "Hindi"; // Default to Hindi if code not found
  }

  /// ✅ NEW: DUBBED LANGUAGE EXTRACTOR
  static String extractDubbedLanguage(dynamic item) {
    final dubbedLangStr =
        item["dubbed_film_language"] ??
        item["dubbed_language"] ??
        item["dubbed_in"] ??
        item["dubbed"] ??
        item["audio_language"];

    final parsedDubbed = _parseLanguages(dubbedLangStr?.toString());
    if (parsedDubbed != null && parsedDubbed.isNotEmpty) {
      return parsedDubbed;
    }

    return extractLanguage(item); // Fallback to regular language
  }

  static String extractYear(dynamic item) {
    final yr = item["year_release"] ?? item["release_year"] ?? item["year"];

    if (yr == null || yr.toString().trim().isEmpty) return "";
    return yr.toString();
  }

  /// ✅ NEW: PARSE FULL_DATE (DD-MM-YYYY) to DateTime for sorting
  static DateTime? parseFullDate(dynamic item) {
    final dateStr = item["full_date"]?.toString();
    if (dateStr == null || dateStr.isEmpty) return null;

    try {
      // Format: DD-MM-YYYY
      final parts = dateStr.split("-");
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      print("🔴 [DATE PARSE] Failed to parse date: $dateStr");
    }
    return null;
  }

  static String? extractYoutubeId(dynamic item) {
    String? raw;

    if (item is Map) {
      raw =
          item["film_watch_url"] ?? // ✅ FULL MOVIES API
          item["youtube_watch_url"] ?? // ✅ DUBBED MOVIES
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
