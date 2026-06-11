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
      Uri.parse("https://bollywoodproduct.com/api-latest-movies.php"),
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
      Uri.parse("https://www.bollywoodproduct.com/api-upcoming-movies.php"),
    ); // Removed timeout

    if (res.statusCode != 200) return [];

    HomeCache.upcoming = jsonDecode(res.body)["movies"] ?? [];
    return HomeCache.upcoming;
  }

  static Future<List> fetchMovies() async {
    if (HomeCache.movies.isNotEmpty) {
      print("🟢 [SERVICE] Movies from cache");
      return HomeCache.movies;
    }

    print("🟡 [SERVICE] Fetching movies");
    final res = await http.get(
      Uri.parse("https://www.bollywoodproduct.com/api-all-movies.php"),
    ); // Removed timeout

    if (res.statusCode != 200) return [];

    HomeCache.movies = jsonDecode(res.body)["movies"] ?? [];
    return HomeCache.movies;
  }

  static Future<List> fetchFull() async {
    if (HomeCache.full.isNotEmpty) {
      print("=== [SERVICE] Full movies from cache");
      return HomeCache.full;
    }

    print("=== [SERVICE] Fetching full movies");
    final res = await http.get(
      Uri.parse("https://www.bollywoodproduct.com/api-full-movies.php"),
    );

    if (res.statusCode != 200) return [];

    HomeCache.full = jsonDecode(res.body)["movies"] ?? [];
    return HomeCache.full;
  }

  static Future<List> fetchTrailers() async {
    print("=== [SERVICE] Fetching trailers");
    final res = await http.get(
      Uri.parse("https://hindi.bollywoodproduct.com/api-trailers.php"),
    );

    if (res.statusCode != 200) return [];

    final responseData = jsonDecode(res.body);
    final allTrailers = responseData["trailers"] ?? [];

    // Filter only items with 'full' keyword in categorySlug
    final filteredTrailers = allTrailers.where((trailer) {
      final categorySlug =
          trailer["categorySlug"]?.toString().toLowerCase() ?? "";
      return categorySlug.contains("full");
    }).toList();

    print(
      "=== [SERVICE] Filtered trailers: ${filteredTrailers.length} items with 'full' category",
    );
    return filteredTrailers;
  }

  static Future<List> fetchLatestTrailers() async {
    print("=== [SERVICE] Fetching latest trailers");
    final res = await http.get(
      Uri.parse("https://www.bollywoodproduct.com/api-latest-trailers.php"),
    );

    if (res.statusCode != 200) return [];

    final responseData = jsonDecode(res.body);
    final allTrailers = responseData["trailers"] ?? [];

    // Filter only items with 'full' keyword in categorySlug
    final filteredTrailers = allTrailers.where((trailer) {
      final categorySlug =
          trailer["categorySlug"]?.toString().toLowerCase() ?? "";
      return categorySlug.contains("full");
    }).toList();

    print(
      "=== [SERVICE] Filtered latest trailers: ${filteredTrailers.length} items with 'full' category",
    );
    return filteredTrailers;
  }
}
