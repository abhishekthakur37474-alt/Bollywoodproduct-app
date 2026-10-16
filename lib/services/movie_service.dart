import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/home_cache.dart';
import '../utils/data_adapter.dart';

class MovieService {
  static Future<List> fetchLatest() async {
    if (HomeCache.latest.isNotEmpty) {
      print("🟢 [SERVICE] Latest movies from cache");
      return HomeCache.latest;
    }

    print("🟡 [SERVICE] Fetching latest movies");
    final res = await http.get(
      Uri.parse("https://bollywoodproduct.com/api-latest-movies.php"),
    );

    if (res.statusCode != 200) return [];

    HomeCache.latest = jsonDecode(res.body)["movies"] ?? [];
    return HomeCache.latest;
  }

  static Future<List> fetchUpcoming() async {
    if (HomeCache.upcoming.isNotEmpty) {
      print("🟢 [SERVICE] Upcoming movies from cache");
      return HomeCache.upcoming;
    }

    print("🟡 [SERVICE] Fetching upcoming movies");
    final res = await http.get(
      Uri.parse("https://www.bollywoodproduct.com/api-upcoming-movies.php"),
    ); // Removed timeout

    if (res.statusCode != 200) return [];

    HomeCache.upcoming = jsonDecode(res.body)["movies"] ?? [];
    return HomeCache.upcoming;
  }

  static Future<List> fetchMovies() async {
    if (HomeCache.movies.isNotEmpty) {
      print("🟢 [SERVICE] Movies from cache");
      return HomeCache.movies;
    }

    print("🟡 [SERVICE] Fetching movies");
    final res = await http.get(
      Uri.parse("https://www.bollywoodproduct.com/api-all-movies.php"),
    ); // Removed timeout

    if (res.statusCode != 200) return [];

    HomeCache.movies = jsonDecode(res.body)["movies"] ?? [];
    return HomeCache.movies;
  }

  static Future<List> fetchFull() async {
    if (HomeCache.full.isNotEmpty) {
      print("=== [SERVICE] Full movies from cache");
      return HomeCache.full;
    }

    print("=== [SERVICE] Fetching full movies");
    final res = await http.get(
      Uri.parse("https://www.bollywoodproduct.com/api-full-movies.php"),
    );

    if (res.statusCode != 200) return [];

    final decoded = jsonDecode(res.body);
    HomeCache.full =
        decoded["data"] ??      // ✅ api-full-movies.php uses "data" key
        decoded["movies"] ??
        (decoded is List ? decoded : []);
    return HomeCache.full;
  }

  /// Lookup latest movie by unique_id (direct field)
  static Future<Map?> fetchLatestByUniqueId(String uniqueId) async {
    final list = HomeCache.latest.isNotEmpty
        ? HomeCache.latest
        : await fetchLatest();

    for (final m in list) {
      if (m["film_unique_id"]?.toString() == uniqueId) return m;
    }
    print("🔴 [SERVICE] latest unique_id=$uniqueId not found");
    return null;
  }

  /// Lookup upcoming movie by unique_id (direct field)
  static Future<Map?> fetchUpcomingByUniqueId(String uniqueId) async {
    final list = HomeCache.upcoming.isNotEmpty
        ? HomeCache.upcoming
        : await fetchUpcoming();

    for (final m in list) {
      if (m["film_unique_id"]?.toString() == uniqueId) return m;
    }
    print("🔴 [SERVICE] upcoming unique_id=$uniqueId not found");
    return null;
  }

  /// Lookup full movie by unique_id extracted from watch_url
  static Future<Map?> fetchFullMovieByUniqueId(String uniqueId) async {
    // Cache hit first
    final list = HomeCache.full.isNotEmpty
        ? HomeCache.full
        : await fetchFull();

    for (final m in list) {
      final id = DataAdapter.extractUniqueIdFromWatchUrl(m as Map);
      if (id == uniqueId) return m;
    }
    print("🔴 [SERVICE] unique_id=$uniqueId not found in full movies");
    return null;
  }

  /// Fetch + normalize api-film.php detail json by unique_id
  static Future<Map?> fetchFilmDetailByUniqueId(String uniqueId) async {
    final url =
        "https://www.bollywoodproduct.com/language-subdomain/api-film.php?unique_id=$uniqueId";
    print("🟡 [FILM DETAIL] GET $url");
    try {
      final res = await http.get(Uri.parse(url));
      if (res.statusCode != 200) return null;
      final decoded = jsonDecode(res.body);
      if (decoded is! Map) return null;

      // ✅ api-film.php returns {"status","total_film_count","data":[{...}]}
      // same flat shape as api-full-movies.php item — NO normalize/rename, use as-is
      final list = decoded["data"];
      if (list is! List || list.isEmpty) return null;
      final film = Map.from(list.first as Map);

      // raw response attach kr do FAB "View JSON" ke liye
      film["_raw_debug_json"] = const JsonEncoder.withIndent("  ").convert(decoded);

      // 🟡 DEBUG: selected fields print — common page pr dikhne wale data
      print("🟡 [FILM DETAIL] selected fields:");
      print("  film_name: ${film["film_name"]}");
      print("  film_lang: ${film["film_lang"]}");
      print("  genre_list: ${film["genre_list"]}");
      print("  release_date_formatted: ${film["release_date_formatted"]}");
      print("  cbfc_rating: ${film["cbfc_rating"]}");
      print("  running_time_minutes: ${film["running_time_minutes"]}");
      print("  running_time_seconds: ${film["running_time_seconds"]}");
      print("  featuring_cast: ${film["featuring_cast"]}");
      print("  lead_cast: ${film["lead_cast"]}");
      print("  directors: ${film["directors"]}");
      print("  producers: ${film["producers"]}");
      print("  film_image_url: ${film["film_image_url"]}");
      print("  film_watch_url: ${film["film_watch_url"]}");

      return film;
    } catch (e) {
      print("🔴 [FILM DETAIL] error: $e");
      return null;
    }
  }

  /// 🟡 DEBUG: raw api-film.php response by unique_id (as-is, no parsing)
  static Future<String> fetchFilmRawJson(String uniqueId) async {
    final url =
        "https://www.bollywoodproduct.com/language-subdomain/api-film.php?unique_id=$uniqueId";
    print("🟡 [RAW FILM] GET $url");
    try {
      final res = await http.get(Uri.parse(url));
      print("🟡 [RAW FILM] status=${res.statusCode}");
      if (res.statusCode != 200) return "ERROR: status ${res.statusCode}";
      try {
        final decoded = jsonDecode(res.body);
        return const JsonEncoder.withIndent("  ").convert(decoded);
      } catch (_) {
        return res.body; // not JSON, return raw
      }
    } catch (e) {
      print("🔴 [RAW FILM] error: $e");
      return "ERROR: $e";
    }
  }

  static Future<List> fetchTrailers() async {
    print("=== [SERVICE] Fetching trailers");
    final res = await http.get(
      Uri.parse("https://hindi.bollywoodproduct.com/api-trailers.php"),
    );

    if (res.statusCode != 200) return [];

    final responseData = jsonDecode(res.body);
    final allTrailers = responseData["trailers"] ?? [];

    // Filter only items with 'full' keyword in categorySlug
    final filteredTrailers = allTrailers.where((trailer) {
      final categorySlug =
          trailer["categorySlug"]?.toString().toLowerCase() ?? "";
      return categorySlug.contains("full");
    }).toList();

    print(
      "=== [SERVICE] Filtered trailers: ${filteredTrailers.length} items with 'full' category",
    );
    return filteredTrailers;
  }

  static Future<List> fetchLatestTrailers() async {
    print("=== [SERVICE] Fetching latest trailers");
    final res = await http.get(
      Uri.parse("https://www.bollywoodproduct.com/api-latest-trailers.php"),
    );

    if (res.statusCode != 200) return [];

    final responseData = jsonDecode(res.body);
    final allTrailers = responseData["trailers"] ?? [];

    // Filter only items with 'full' keyword in categorySlug
    final filteredTrailers = allTrailers.where((trailer) {
      final categorySlug =
          trailer["categorySlug"]?.toString().toLowerCase() ?? "";
      return categorySlug.contains("full");
    }).toList();

    print(
      "=== [SERVICE] Filtered latest trailers: ${filteredTrailers.length} items with 'full' category",
    );
    return filteredTrailers;
  }
}