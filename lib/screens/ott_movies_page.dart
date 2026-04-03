import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/ott_service.dart';
import '../utils/paginated_list.dart';
import '../utils/data_adapter.dart';
import '../widgets/movie_list_tile.dart';
import 'ott_detail_page.dart';
import '../utils/home_cache.dart';

class OttMoviesPage extends StatefulWidget {
  const OttMoviesPage({super.key});

  @override
  State<OttMoviesPage> createState() => _OttMoviesPageState();
}

class _OttMoviesPageState extends State<OttMoviesPage>
    with AutomaticKeepAliveClientMixin {
  static List _allOttFilms = [];

  Future<List> fetch() async {
    if (HomeCache.ott.isNotEmpty) {
      _allOttFilms = HomeCache.ott;
      return HomeCache.ott;
    }

    final list = await OttService.fetchOtt();
    _allOttFilms = list;
    return list;
  }

  String resolveLanguage(dynamic m) {
    final lang = m["language"] ?? m["film_language"] ?? m["lang"];

    return (lang == null || lang.toString().trim().isEmpty)
        ? "Hindi"
        : lang.toString();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.black,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xff0F0F0F),
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text("Latest OTT Movies"),
        ),
        body: PaginatedList(
          fetch: fetch,
          pageSize: 15,
          builder: (m) {
            final title = DataAdapter.extractTitle(m);
            final language = resolveLanguage(m);
            final poster = DataAdapter.extractPoster(m);
            final id = (m["film_id"] ?? m["unique_id"] ?? "").toString();

            return MovieListTile(
              id: id,
              title: title,
              language: language,
              posterOverride: poster,
              onTap: () {
                print("🟢 [EXPLORE OTT] Total=${_allOttFilms.length}");

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        OttDetailPage(data: m, exploreList: _allOttFilms),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
