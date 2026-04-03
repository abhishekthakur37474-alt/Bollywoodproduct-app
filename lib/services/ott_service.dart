import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/home_cache.dart';

class OttService {
  static List _lastKnownFilms = []; // Track last known films

  static Future<List> fetchOtt() async {
    // USE CACHE IF ALREADY LOADED
    if (HomeCache.ott.isNotEmpty) {
      print("[OTT SERVICE] Using cached OTT movies");
      return HomeCache.ott;
    }

    print("[OTT SERVICE] Fetching OTT movies from API");

    try {
      final res = await http.get(
        Uri.parse("https://hindi.bollywoodproduct.com/api-ott-movies.php"),
      );

      print("[OTT SERVICE] Status=${res.statusCode}");

      if (res.statusCode != 200) {
        print("[OTT SERVICE] Non-200 response");
        return [];
      }

      final body = res.body.trim();

      // CRITICAL SAFETY CHECK
      if (!body.startsWith("{") && !body.startsWith("[")) {
        print("[OTT SERVICE] Invalid JSON response");
        print(body.substring(0, body.length > 200 ? 200 : body.length));
        return [];
      }

      final raw = jsonDecode(body);
      final list = raw["films"] ?? [];

      // Reverse list for descending order (latest first)
      final reversedList = List.from(list.reversed);

      // Check for new entries
      if (_lastKnownFilms.isNotEmpty) {
        final newEntries = _findNewEntries(list, _lastKnownFilms);
        if (newEntries.isNotEmpty) {
          print("[OTT SERVICE] NEW MOVIES FOUND: ${newEntries.length}");
          for (int i = 0; i < newEntries.length; i++) {
            final movie = newEntries[i];
            final title = movie["film_name"] ?? "Unknown";
            final platform = movie["ott_platform"] ?? "Unknown";
            print("[NEW MOVIE ${i + 1}] $title on $platform");
          }
        } else {
          print("[OTT SERVICE] No new movies found");
        }
      } else {
        print(
          "[OTT SERVICE] First time loading, tracking ${list.length} movies",
        );
      }

      // Update last known films
      _lastKnownFilms = List.from(list);

      HomeCache.ott = reversedList; // CACHE
      print("[OTT SERVICE] Cached OTT=${reversedList.length}");

      return reversedList;
    } catch (e) {
      print("[OTT SERVICE] Exception: $e");
      return [];
    }
  }

  // Method to find new entries
  static List _findNewEntries(List currentFilms, List lastFilms) {
    final newEntries = <dynamic>[];

    // Check if current films has more items than last known
    if (currentFilms.length > lastFilms.length) {
      // Find films that are not in last known list
      for (final film in currentFilms) {
        final filmId =
            film["film_id"]?.toString() ?? film["ott_id"]?.toString();
        bool isNew = true;

        for (final lastFilm in lastFilms) {
          final lastFilmId =
              lastFilm["film_id"]?.toString() ?? lastFilm["ott_id"]?.toString();
          if (filmId == lastFilmId) {
            isNew = false;
            break;
          }
        }

        if (isNew) {
          newEntries.add(film);
        }
      }
    }

    return newEntries;
  }
}
