import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/home_cache.dart';

class OttService {
  static Future<List> fetchOtt() async {
    // ✅ USE CACHE IF ALREADY LOADED
    if (HomeCache.ott.isNotEmpty) {
      print("🟢 [OTT SERVICE] Using cached OTT movies");
      return HomeCache.ott;
    }

    print("🟡 [OTT SERVICE] Fetching OTT movies from API");

    try {
      final res = await http.get(
        Uri.parse("https://hindi.bollywoodproduct.com/api-ott-movies.php"),
      );

      print("🟡 [OTT SERVICE] Status=${res.statusCode}");

      if (res.statusCode != 200) {
        print("🔴 [OTT SERVICE] Non-200 response");
        return [];
      }

      final body = res.body.trim();

      // 🔥 CRITICAL SAFETY CHECK
      if (!body.startsWith("{") && !body.startsWith("[")) {
        print("🔴 [OTT SERVICE] Invalid JSON response");
        print(body.substring(0, body.length > 200 ? 200 : body.length));
        return [];
      }

      final raw = jsonDecode(body);
      final list = raw["films"] ?? [];

      HomeCache.ott = list; // ✅ CACHE
      print("🟢 [OTT SERVICE] Cached OTT=${list.length}");

      return list;
    } catch (e) {
      print("🔴 [OTT SERVICE] Exception: $e");
      return [];
    }
  }
}
