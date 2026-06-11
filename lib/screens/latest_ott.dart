import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/paginated_list.dart';
import '../widgets/movie_list_tile.dart';
import 'ott_detail_page.dart';

class LatestOttPage extends StatefulWidget {
  const LatestOttPage({super.key});

  @override
  State<LatestOttPage> createState() => _LatestOttPageState();
}

class _LatestOttPageState extends State<LatestOttPage>
    with AutomaticKeepAliveClientMixin {
  static List _allFilms = [];

  Future<List> fetch() async {
    if (_allFilms.isNotEmpty) {
      print("🟢 [LATEST OTT] Using cached ${_allFilms.length} films");
      return _allFilms;
    }

    print("🟡 [LATEST OTT] Fetching from API...");
    final res = await http.get(
      Uri.parse("https://www.bollywoodproduct.com/api-ott-latest-movies.php"),
    );

    if (res.statusCode != 200) return [];

    final raw = jsonDecode(res.body);
    final list = raw["films"] ?? [];
    _allFilms = list;
    print("🟢 [LATEST OTT] Fetched ${list.length} films");
    return list;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PaginatedList(
      fetch: fetch,
      pageSize: 15,
      builder: (m) {
        final title = m["film_name"]?.toString() ?? "Untitled";
        final language = m["ott_language_name"]?.toString() ?? "";
        final poster = m["film_image"]?.toString();
        final id = (m["film_id"] ?? m["ott_id"] ?? "").toString();

        return MovieListTile(
          id: id,
          title: title,
          language: language,
          posterOverride: poster,
          onTap: () {
            print("🟢 [LATEST OTT] Tapped: $title");
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    OttDetailPage(data: m, exploreList: _allFilms),
              ),
            );
          },
        );
      },
    );
  }
}