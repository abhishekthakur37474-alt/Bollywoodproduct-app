import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../utils/paginated_list.dart';
import '../utils/data_adapter.dart';
import '../widgets/trailer_card.dart';

class MostViewedTrailersPage extends StatelessWidget {
  const MostViewedTrailersPage({super.key});

  static const apiUrl =
      "https://www.bollywoodproduct.com/api-most-viewed-trailers.php";

  Future<List> fetch() async {
    print("🟡 [MOST VIEWED] Fetching trailers (NEW API)");

    final res = await http.get(Uri.parse(apiUrl));

    print("📡 Status Code: ${res.statusCode}");

    if (res.statusCode != 200) return [];

    final raw = jsonDecode(res.body);
    final List rawList = raw["trailers"] ?? [];

    print("📦 Received from API: ${rawList.length}");

    /// ❌ REMOVE FULL MOVIES
    final filtered = rawList.where((m) {
      final title =
      DataAdapter.extractTitle(m).toLowerCase();
      final cat =
      (m["category"] ?? "").toString().toLowerCase();

      return !title.contains("full movie") &&
          !cat.contains("full movie");
    }).toList();

    /// 🔥 GROUP SAME MOVIE (MULTI-LANGUAGE SUPPORT)
    final Map<String, Map> grouped = {};

    for (final item in filtered) {
      final title =
      DataAdapter.extractTitle(item);

      if (!grouped.containsKey(title)) {
        grouped[title] = {
          ...item,
          "trailers": [item],
          "languages": [
            (item["language"] ?? "Unknown").toString()
          ]
        };
      } else {
        grouped[title]!["trailers"].add(item);

        final lang =
        (item["language"] ?? "Unknown").toString();

        if (!grouped[title]!["languages"]
            .contains(lang)) {
          grouped[title]!["languages"].add(lang);
        }
      }
    }

    final finalList = grouped.values.toList();

    print("🟢 FINAL GROUPED COUNT: ${finalList.length}");

    if (finalList.isNotEmpty) {
      print(
          "🥇 First item: ${DataAdapter.extractTitle(finalList.first)}");
    }

    return finalList;
  }

  @override
  Widget build(BuildContext context) {
    return PaginatedList(
      pageSize: 15,
      fetch: fetch,
      builder: (m) => TrailerCard(data: m),
    );
  }
}
