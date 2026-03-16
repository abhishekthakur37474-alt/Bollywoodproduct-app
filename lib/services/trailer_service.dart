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
      return !title.contains("full movie") &&
          !cat.contains("full movie");
    }).toList();
  }

  /// 🔥 LATEST TRAILERS (SAME API)
  static Future<List> fetchLatestTrailers() async {
    print("🟡 [SERVICE] Fetching LATEST trailers (GROUPED)");

    final res = await http.get(
      Uri.parse("https://www.bollywoodproduct.com/api-latest-trailers.php"),
    );

    if (res.statusCode != 200) return [];

    final body = jsonDecode(res.body);
    final rawList = body["trailers"] ?? [];

    if (rawList is! List) return [];

    Map<String, Map> grouped = {};

    for (var item in rawList) {
      final title = (item["film_name"] ?? "").toString();
      final language = (item["language"] ?? "Hindi").toString();

      if (!grouped.containsKey(title)) {
        grouped[title] = {
          "film_name": title,
          "languages": [language],
          "trailers": [item],
        };
      } else {
        grouped[title]!["languages"].add(language);
        grouped[title]!["trailers"].add(item);
      }
    }

    return grouped.values.toList();
  }



}
