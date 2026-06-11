import 'dart:convert';
import 'package:http/http.dart' as http;

class TrailerService {
  static Future<List> fetchAllTrailers() async {
    print("🟡 [SERVICE] Fetching all trailers");

    final res = await http.get(
      Uri.parse("https://hindi.bollywoodproduct.com/api-trailers.php"),
    );

    if (res.statusCode != 200) return [];

    final list = jsonDecode(res.body)["trailers"] ?? [];

    return list.where((m) {
      final title = (m["film_name"] ?? "").toString().toLowerCase();
      final cat = (m["category"] ?? "").toString().toLowerCase();
      return !title.contains("full movie") && !cat.contains("full movie");
    }).toList();
  }

  /// 🔥 LATEST TRAILERS
  static Future<List> fetchLatestTrailers() async {
    print("🟡 [SERVICE] Fetching LATEST trailers");

    final res = await http.get(
      Uri.parse("https://www.bollywoodproduct.com/api-latest-trailers.php"),
    );

    if (res.statusCode != 200) return [];

    final body = jsonDecode(res.body);
    final rawList = body["trailers"] ?? [];

    if (rawList is! List) return [];

    return rawList;
  }
}