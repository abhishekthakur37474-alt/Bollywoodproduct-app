import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/home_cache.dart';

class DubbedService {
  static Future<List> fetchDubbed() async {
    // ✅ USE CACHE IF ALREADY LOADED
    if (HomeCache.dubbed.isNotEmpty) {
      print(
        "🟢 [DUBBED SERVICE] Using cached dubbed movies: ${HomeCache.dubbed.length}",
      );
      return HomeCache.dubbed;
    }

    print("🟡 [DUBBED SERVICE] Fetching dubbed movies from API");

    try {
      final res = await http.get(
        Uri.parse("https://www.bollywoodproduct.com/api-dubbed-movies.php"),
      );

      print("🟡 [DUBBED SERVICE] Status=${res.statusCode}");
      print("🟡 [DUBBED SERVICE] Body length=${res.body.length}");

      if (res.statusCode != 200) {
        print("🔴 [DUBBED SERVICE] Non-200 response");
        return [];
      }

      final body = res.body.trim();
      print(
        "🟡 [DUBBED SERVICE] Body starts with: ${body.substring(0, body.length > 50 ? 50 : body.length)}",
      );

      // 🔥 CRITICAL SAFETY CHECK
      if (!body.startsWith("{") && !body.startsWith("[")) {
        print("🔴 [DUBBED SERVICE] Invalid JSON response");
        print(body.substring(0, body.length > 200 ? 200 : body.length));
        return [];
      }

      final raw = jsonDecode(body);
      print("🟡 [DUBBED SERVICE] Parsed JSON keys: ${raw.keys.toList()}");

      final list = raw["data"] ?? raw["movies"] ?? [];
      print("🟡 [DUBBED SERVICE] Found ${list.length} dubbed movies");

      HomeCache.dubbed = list; // ✅ CACHE
      print("🟢 [DUBBED SERVICE] Cached dubbed=${list.length}");

      return list;
    } catch (e) {
      print("🔴 [DUBBED SERVICE] Exception: $e");
      return [];
    }
  }
}
