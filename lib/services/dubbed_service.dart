import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/home_cache.dart';

class DubbedService {
  static Future<List> fetchDubbedMovies() async {
    // ✅ USE CACHE IF ALREADY LOADED
    if (HomeCache.dubbed.isNotEmpty) {
      print(
        "🟢 [DUBBED SERVICE] Using cached dubbed movies: ${HomeCache.dubbed.length}",
      );
      return HomeCache.dubbed;
    }

    print("[DUBBED SERVICE] Fetching dubbed movies from API");

    try {
      final res = await http.get(
        Uri.parse("https://www.bollywoodproduct.com/api-dubbed-movies.php"),
      ); // Removed timeout for splash screen

      if (res.statusCode != 200) {
        print("[DUBBED SERVICE] Non-200 response: ${res.statusCode}");
        return [];
      }

      final body = res.body.trim();

      // 🔥 CRITICAL SAFETY CHECK
      if (!body.startsWith("{") && !body.startsWith("[")) {
        print("🔴 [DUBBED SERVICE] Invalid JSON response");
        return [];
      }

      final raw = jsonDecode(body);
      final list = raw["data"] ?? raw["movies"] ?? [];
      print("🟡 [DUBBED SERVICE] Found ${list.length} dubbed movies");

      // ✅ OPTIMIZED: Skip sorting for faster loading, sort later if needed
      print("🟢 [DUBBED SERVICE] Loaded ${list.length} dubbed movies quickly");

      HomeCache.dubbed = List.from(list); // ✅ CACHE
      print("🟢 [DUBBED SERVICE] Cached dubbed=${list.length}");

      return list;
    } catch (e) {
      print("🔴 [DUBBED SERVICE] Exception: $e");
      return [];
    }
  }
}
