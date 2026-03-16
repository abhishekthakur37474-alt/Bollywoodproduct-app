class HomeCache {
  static bool loaded = false;

  static List latest = [];
  static List upcoming = [];
  static List full = [];
  static List ott = []; // ✅ OTT CACHE ADDED
  static List dubbed = []; // ✅ DUBBED CACHE ADDED

  /// 🔥 CLEAR ALL CACHED DATA (USE ONLY WHEN YOU WANT FORCE RELOAD)
  static void clear() {
    loaded = false;
    latest.clear();
    upcoming.clear();
    full.clear();
    ott.clear(); // ✅ CLEAR OTT TOO
    dubbed.clear(); // ✅ CLEAR DUBBED TOO
  }
}
