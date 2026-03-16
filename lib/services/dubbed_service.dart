import 'dart:convert';
import 'package:http/http.dart' as http;

class DubbedService {
  static Future<List> fetchDubbed() async {
    try {
      final response = await http.get(
        Uri.parse("https://hindi.bollywoodproduct.com/api-dubbed-movies.php"),
      );

      if (response.statusCode == 200 && response.body.trim().startsWith("{")) {
        final data = jsonDecode(response.body);
        return data["movies"] ?? [];
      }
    } catch (e) {
      print("🔴 [DUBBED SERVICE] Error: $e");
    }
    return [];
  }
}
