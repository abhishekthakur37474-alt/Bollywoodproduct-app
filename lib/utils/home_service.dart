import 'dart:convert';
import 'package:http/http.dart' as http;
import 'home_cache.dart';
import '../services/ott_service.dart';
import '../services/dubbed_service.dart';
import '../services/movie_service.dart';

class HomeService {
  static bool _loading = false;

  static Future<void> loadAllHomeData() async {
    if (_loading) {
      return;
    }

    _loading = true;

    try {
      /// 🔥 STEP 1: Load critical data first without timeout for splash screen
      final criticalResults = await Future.wait([
        http.get(
          Uri.parse("https://bollywoodproduct.com/api-latest-movies.php"),
        ),
        http.get(
          Uri.parse("https://www.bollywoodproduct.com/api-upcoming-movies.php"),
        ),
        http.get(
          Uri.parse("https://www.bollywoodproduct.com/api-full-movies.php"),
        ),
      ]);

      final latestRes = criticalResults[0];
      final upcomingRes = criticalResults[1];
      final fullRes = criticalResults[2];

      if (latestRes.statusCode == 200 &&
          latestRes.body.trim().startsWith("{")) {
        HomeCache.latest = jsonDecode(latestRes.body)["movies"] ?? [];
      }

      if (upcomingRes.statusCode == 200 &&
          upcomingRes.body.trim().startsWith("{")) {
        HomeCache.upcoming = jsonDecode(upcomingRes.body)["movies"] ?? [];
        print(
          "🟢 [HOME SERVICE] Upcoming movies loaded: ${HomeCache.upcoming.length}",
        );
      }

      if (fullRes.statusCode == 200) {
        final body = fullRes.body.trim();
        final decoded = jsonDecode(body);
        HomeCache.full =
            decoded["movies"] ??
            decoded["data"] ??
            (decoded is List ? decoded : []);
        print("🟢 [HOME SERVICE] Full movies loaded: ${HomeCache.full.length}");
      }

      // 🔥 Load remaining data in background after critical data is ready
      Future.microtask(() async {
        try {
          final backgroundResults = await Future.wait([
            OttService.fetchOtt(),
            MovieService.fetchMovies(),
            DubbedService.fetchDubbedMovies(),
          ]);

          HomeCache.ott = backgroundResults[0];
          HomeCache.movies = backgroundResults[1];
          HomeCache.dubbed = backgroundResults[2];
          HomeCache.dubbedNotifier.value = backgroundResults[2];

          // 🔥 Load extra APIs (including films) in background
          _loadExtraData();

          print("🟢 [HOME SERVICE] Background data loaded");
        } catch (e) {
          print("🔴 [HOME SERVICE] Background loading error: $e");
        }
      });

      HomeCache.loaded = true;
      print("🟢 [HOME SERVICE] Critical data loaded successfully");
    } catch (e) {
      print("🔴 [HOME SERVICE] Error loading data: $e");
      _loading = false;
    }

    _loading = false;
  }

  static Future<void> _loadExtraData() async {
    try {
      final results = await Future.wait([
        http.get(Uri.parse("https://www.bollywoodproduct.com/api-ott-latest-movies.php")),
        http.get(Uri.parse("https://www.bollywoodproduct.com/api-ott-upcoming-movies.php")),
        http.get(Uri.parse("https://hindi.bollywoodproduct.com/api-trailers.php")),
        http.get(Uri.parse("https://www.bollywoodproduct.com/api-latest-trailers.php")),
        http.get(Uri.parse("https://www.bollywoodproduct.com/api-most-viewed-trailers.php")),
        http.get(Uri.parse("https://www.bollywoodproduct.com/api-films.php")), // ✅ NEW
      ]);

      _parseList(results[0], ["films"], HomeCache.ottLatest);
      _parseList(results[1], ["films"], HomeCache.ottUpcoming);
      _parseList(results[2], ["trailers"], HomeCache.trailers);
      _parseList(results[3], ["trailers"], HomeCache.latestTrailers);
      _parseList(results[4], ["trailers"], HomeCache.mostViewedTrailers);
      _parseList(results[5], ["movies"], HomeCache.films); // ✅ NEW

      print(
        "🟢 [HOME SERVICE] Extra data loaded: "
        "ottLatest=${HomeCache.ottLatest.length}, "
        "ottUpcoming=${HomeCache.ottUpcoming.length}, "
        "trailers=${HomeCache.trailers.length}, "
        "films=${HomeCache.films.length}",
      );
    } catch (e) {
      print("🔴 [HOME SERVICE] Extra data error: $e");
    }
  }

  static void _parseList(dynamic res, List<String> keys, List target) {
    try {
      if (res.statusCode != 200) return;
      final body = res.body.trim();
      if (!body.startsWith("{") && !body.startsWith("[")) return;
      final decoded = jsonDecode(body);
      for (final key in keys) {
        if (decoded[key] is List) {
          target.addAll(decoded[key]);
          return;
        }
      }
      if (decoded is List) target.addAll(decoded);
    } catch (_) {}
  }
}