import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/home_cache.dart';

class OttService {
  static List _lastKnownFilms = []; // Track last known films

  static Future<List> fetchOtt() async {
    // USE CACHE IF ALREADY LOADED
    if (HomeCache.ott.isNotEmpty) {
      HomeCache.ottNotifier.value =
          HomeCache.ott; // 🔥 ENSURE NOTIFIER IS UP TO DATE
      print("🟢 [OTT SERVICE] Using cached ${HomeCache.ott.length} OTT movies");
      return HomeCache.ott;
    }

    try {
      final res = await http.get(
        Uri.parse("https://www.bollywoodproduct.com/api-ott-movies.php"),
      );

      if (res.statusCode != 200) {
        return [];
      }

      final body = res.body.trim();

      // CRITICAL SAFETY CHECK
      if (!body.startsWith("{") && !body.startsWith("[")) {
        return [];
      }

      final raw = jsonDecode(body);
      final list = raw["films"] ?? [];

      // 🔥 FAST LOADING: Load first 15 immediately, rest in background
      final fastList = await _loadOttWithPagination(list);

      // Check for new entries
      if (_lastKnownFilms.isNotEmpty) {
        _findNewEntries(fastList, _lastKnownFilms);
      } else {
        _lastKnownFilms = List.from(list);
      }

      HomeCache.ott = fastList; // CACHE
      HomeCache.ottNotifier.value = fastList; // 🔥 NOTIFY UI
      print("🟢 [OTT SERVICE] Cached ${fastList.length} OTT movies");
      return fastList;
    } catch (e) {
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

  // 🔥 FAST PAGINATION: Load first 10 immediately, rest in background
  static Future<List> _loadOttWithPagination(List allMovies) async {
    const pageSize = 10;

    if (allMovies.isEmpty) return [];

    // Step 1: Load first 10 movies with basic data (no YouTube API calls)
    final firstBatch = allMovies.take(pageSize).toList();
    final fastBatch = <Map<String, dynamic>>[];

    for (final movie in firstBatch) {
      final movieMap = Map<String, dynamic>.from(movie as Map);
      movieMap['youtube_upload_date'] = null;
      movieMap['youtube_upload_raw'] = null;
      fastBatch.add(movieMap);
    }

    // Step 2: Load remaining movies in background with smaller batches
    _loadRemainingMoviesInBackground(allMovies.skip(pageSize).toList());

    return fastBatch;
  }

  // Background loading for remaining movies with optimized batching
  static Future<void> _loadRemainingMoviesInBackground(
    List remainingMovies,
  ) async {
    if (remainingMovies.isEmpty) return;

    try {
      final batchSize = 5; // Reduced batch size for faster processing
      for (int i = 0; i < remainingMovies.length; i += batchSize) {
        final batch = remainingMovies.skip(i).take(batchSize).toList();
        final batchWithDates = <Map<String, dynamic>>[];

        for (final movie in batch) {
          final movieMap = Map<String, dynamic>.from(movie as Map);
          final youtubeId = movie["film_youtube"]?.toString() ?? "";

          // Skip YouTube API calls for faster loading
          if (youtubeId.isNotEmpty) {
            movieMap['youtube_upload_date'] = null;
            movieMap['youtube_upload_raw'] = null;
          }

          batchWithDates.add(movieMap);
        }

        // Update cache with this batch
        if (HomeCache.ott.isNotEmpty) {
          HomeCache.ott.addAll(batchWithDates);
          HomeCache.ottNotifier.value = List.from(
            HomeCache.ott,
          ); // 🔥 NOTIFY UI
          print(
            "🟢 [OTT SERVICE] Added ${batchWithDates.length} more movies, total: ${HomeCache.ott.length}",
          );
        }

        // Reduced delay for faster loading
        await Future.delayed(Duration(milliseconds: 50));
      }
    } catch (e) {
      // Background loading failed, but app continues to work
    }
  }
}
