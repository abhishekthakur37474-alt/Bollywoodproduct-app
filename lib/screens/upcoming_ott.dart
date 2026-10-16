import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/paginated_list.dart';
import '../widgets/movie_list_tile.dart';
import 'common.dart';

class UpcomingOttPage extends StatefulWidget {
  const UpcomingOttPage({super.key});

  @override
  State<UpcomingOttPage> createState() => _UpcomingOttPageState();
}

class _UpcomingOttPageState extends State<UpcomingOttPage>
    with AutomaticKeepAliveClientMixin {
  static List _allFilms = [];

  Future<List> fetch() async {
    if (_allFilms.isNotEmpty) {
      print("🟢 [UPCOMING OTT] Using cached ${_allFilms.length} films");
      return _allFilms;
    }

    print("🟡 [UPCOMING OTT] Fetching from API...");
    final res = await http.get(
      Uri.parse("https://www.bollywoodproduct.com/api-ott-upcoming-movies.php"),
    );

    if (res.statusCode != 200) return [];

    final raw = jsonDecode(res.body);
    final list = raw["films"] ?? [];
    _allFilms = list;
    print("🟢 [UPCOMING OTT] Fetched ${list.length} films");
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
        final uniqueId =
            (m["film_unique_id"] ?? m["film_id"] ?? m["ott_id"] ?? "")
                .toString();

        return MovieListTile(
          id: uniqueId,
          title: title,
          language: language,
          posterOverride: poster,
          onTap: () {
            if (uniqueId.isEmpty) {
              print("🔴 [UPCOMING OTT TAP] unique_id empty, film=$title");
              return;
            }
            print("🟢 [UPCOMING OTT] Tapped: $title → unique_id=$uniqueId");
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CommonScreen(
                  uniqueId: uniqueId,
                  posterUrl: poster,
                  language: language,
                  onlyFullTrailers: false,
                  ottPlatform: m["ott_platform"]?.toString(),
                  ottLink: m["ott_link"]?.toString(),
                  exploreList: _allFilms,
                ),
              ),
            );
          },
        );
      },
    );
  }
}