import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/home_cache.dart';

class MovieService {
  static Future<List> fetchLatest() async {
    if (HomeCache.latest.isNotEmpty) {
      print("🟢 [SERVICE] Latest movies from cache");
      return HomeCache.latest;
    }

    print("🟡 [SERVICE] Fetching latest movies");
    final res = await http.get(
      Uri.parse("https://hindi.bollywoodproduct.com/api-latest-movies.php"),
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
      Uri.parse("https://hindi.bollywoodproduct.com/api-upcoming-movies.php"),
    );

    if (res.statusCode != 200) return [];

    HomeCache.upcoming = jsonDecode(res.body)["movies"] ?? [];
    return HomeCache.upcoming;
  }

  static Future<List> fetchFull() async {
    if (HomeCache.full.isNotEmpty) {
      print("🟢 [SERVICE] Full movies from cache");
      return HomeCache.full;
    }

    print("🟡 [SERVICE] Fetching full movies");
    final res = await http.get(
      Uri.parse("https://hindi.bollywoodproduct.com/api-full-movies.php"),
    );

    if (res.statusCode != 200) return [];

    HomeCache.full = jsonDecode(res.body)["movies"] ?? [];
    return HomeCache.full;
  }
}
