import 'package:flutter/foundation.dart';

class HomeCache {
  static bool loaded = false;

  static List latest = [];
  static List upcoming = [];
  static List full = [];
  static List ott = [];
  static List dubbed = [];
  static List movies = [];
  static List films = [];          // api-films.php (9048 movies — search)
  static List ottLatest = [];      // api-ott-latest-movies
  static List ottUpcoming = [];    // api-ott-upcoming-movies
  static List trailers = [];       // api-trailers
  static List latestTrailers = []; // api-latest-trailers
  static List mostViewedTrailers = []; // api-most-viewed-trailers

  /// 🔥 NOTIFIER for OTT updates (to refresh UI when background loading completes)
  static final ValueNotifier<List> ottNotifier = ValueNotifier<List>([]);
  static final ValueNotifier<List> dubbedNotifier = ValueNotifier<List>([]);

  /// 🔥 CLEAR ALL CACHED DATA (USE ONLY WHEN YOU WANT FORCE RELOAD)
  static void clear() {
    loaded = false;
    latest.clear();
    upcoming.clear();
    full.clear();
    ott.clear();
    dubbed.clear();
    movies.clear();
    films.clear();           // ✅ CLEAR FILMS TOO
    ottLatest.clear();
    ottUpcoming.clear();
    trailers.clear();
    latestTrailers.clear();
    mostViewedTrailers.clear();
  }
}