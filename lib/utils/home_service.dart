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
      /// ✅ api-films.php added here too (now fast — light query + gzip) so
      /// search suggestions have data ready as soon as splash finishes,
      /// instead of waiting for background _loadExtraData().
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
        http.get(
          Uri.parse("https://www.bollywoodproduct.com/api-films.php"),
        ),
      ]);

      final latestRes = criticalResults[0];
      final upcomingRes = criticalResults[1];
      final fullRes = criticalResults[2];
      final filmsRes = criticalResults[3];

      if (latestRes.statusCode == 200 &&
          latestRes.body.trim().startsWith("{")) {
        HomeCache.latest = jsonDecode(latestRes.body)["movies"] ?? [];
        // 🔥 FIX: notifier set — home_page ka "latest" section ab
        // build ke baad bhi data aane pe auto-refresh ho jayega.
        HomeCache.latestNotifier.value = HomeCache.latest;
      }

      if (upcomingRes.statusCode == 200 &&
          upcomingRes.body.trim().startsWith("{")) {
        HomeCache.upcoming = jsonDecode(upcomingRes.body)["movies"] ?? [];
        HomeCache.upcomingNotifier.value = HomeCache.upcoming; // 🔥 FIX
        print(
          "🟢 [HOME SERVICE] Upcoming movies loaded: ${HomeCache.upcoming.length}",
        );
      }

      if (fullRes.statusCode == 200) {
        final body = fullRes.body.trim();
        final decoded = jsonDecode(body);
        HomeCache.full =
            decoded["data"] ??      // ✅ api-full-movies.php uses "data" key
            decoded["movies"] ??
            (decoded is List ? decoded : []);
        HomeCache.fullNotifier.value = HomeCache.full; // 🔥 FIX
        print("🟢 [HOME SERVICE] Full movies loaded: ${HomeCache.full.length}");
      }

      if (filmsRes.statusCode == 200 && filmsRes.body.trim().startsWith("{")) {
        final decoded = jsonDecode(filmsRes.body);
        final films = (decoded["movies"] ?? []) as List;
        HomeCache.films = films;
        _precomputeSearchFields(HomeCache.films); // 🔥 do this ONCE, not per keystroke
        print("🟢 [HOME SERVICE] Films loaded for search: ${HomeCache.films.length}");
      }

      // 🔥 Load remaining data in background after critical data is ready.
      // ⚠️ FIX: dubbed, ott, movies ab ek saath Future.wait() me nahi baandhe —
      // pehle sab ek group me the, isliye dubbed (jo fast hai) bhi slow OTT/movies
      // ke complete hone tak UI me nahi dikhta tha. Ab har ek apna independent
      // path leta hai, jo jaldi khatam ho wo turant notifier update kar deta hai.
      Future.microtask(() async {
        try {
          // 🔥 Dubbed fires on its own — updates UI the moment ITS OWN
          // API responds, without waiting on ott/movies.
          DubbedService.fetchDubbedMovies().then((dubbed) {
            HomeCache.dubbed = dubbed;
            HomeCache.dubbedNotifier.value = dubbed;
            print("🟢 [HOME SERVICE] Dubbed loaded fast: ${dubbed.length}");
          }).catchError((e) {
            print("🔴 [HOME SERVICE] Dubbed loading error: $e");
          });

          OttService.fetchOtt().then((ott) {
            HomeCache.ott = ott;
            print("🟢 [HOME SERVICE] Ott loaded: ${ott.length}");
          }).catchError((e) {
            print("🔴 [HOME SERVICE] Ott loading error: $e");
          });

          MovieService.fetchMovies().then((movies) {
            HomeCache.movies = movies;
            print("🟢 [HOME SERVICE] Movies loaded: ${movies.length}");
          }).catchError((e) {
            print("🔴 [HOME SERVICE] Movies loading error: $e");
          });

          // 🔥 Load extra APIs (including films) in background
          _loadExtraData();

          print("🟢 [HOME SERVICE] Background data dispatched");
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
        // ❌ api-films.php removed from here — now loaded earlier in criticalResults
        // so search suggestions are ready as soon as splash screen finishes.
      ]);

      _parseList(results[0], ["films"], HomeCache.ottLatest);
      _parseList(results[1], ["films"], HomeCache.ottUpcoming);
      _parseList(results[2], ["trailers"], HomeCache.trailers);
      _parseList(results[3], ["trailers"], HomeCache.latestTrailers);
      _parseList(results[4], ["trailers"], HomeCache.mostViewedTrailers);

      print(
        "🟢 [HOME SERVICE] Extra data loaded: "
        "ottLatest=${HomeCache.ottLatest.length}, "
        "ottUpcoming=${HomeCache.ottUpcoming.length}, "
        "trailers=${HomeCache.trailers.length}",
      );
    } catch (e) {
      print("🔴 [HOME SERVICE] Extra data error: $e");
    }
  }

  /// 🔥 Precompute lowercase title/language ONCE when films are loaded,
  /// instead of every keystroke in search screen. Big perf win for 9687 items.
  static void _precomputeSearchFields(List films) {
    for (final m in films) {
      if (m is Map) {
        final title = (m["name"] ?? m["film_name"] ?? m["title"] ?? "").toString();
        final lang = (m["main_lang"] ?? m["film_lang"] ?? m["language"] ?? "").toString();
        m['_title_lower'] = title.toLowerCase().trim();
        m['_lang_lower'] = lang.toLowerCase().trim();
      }
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