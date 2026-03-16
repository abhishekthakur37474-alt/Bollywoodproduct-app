import 'package:flutter/material.dart';
import '../widgets/movie_tile.dart';
import '../utils/data_adapter.dart';

class OttDetailPage extends StatelessWidget {
  final Map data;
  final List exploreList;

  const OttDetailPage({
    super.key,
    required this.data,
    required this.exploreList,
  });

  @override
  Widget build(BuildContext context) {
    final title = data["film_name"] ?? "Untitled";
    final year = data["year_release"]?.toString() ?? "";
    final releaseDate = data["release_date"]?.toString() ?? "";
    final platform = data["ott_platform"] ?? "";
    final image = data["film_image"];

    final cast = (data["lead_cast"] ?? []) as List;
    final directors = (data["directors"] ?? []) as List;
    final genres = (data["genres"] ?? []) as List;
    /// ✅ OTT RATINGS
    final ratings = data["ratings"] ?? {};
    final cbfcRating = ratings["cbfc_rating"]?.toString() ?? "";
    final certificateNo = ratings["certificate_no"]?.toString() ?? "";
    final certificateDate = ratings["certificate_date"]?.toString() ?? "";
    final imdb = ratings["imdb_rating"]?.toString() ?? "";
    final rotten = ratings["rotten_tomato_rating"]?.toString() ?? "";


    return Scaffold(
      backgroundColor: const Color(0xff0F0F0F),
      appBar: AppBar(
        title: Text(title),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        children: [
          if (image != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(image, fit: BoxFit.cover),
            ),

          const SizedBox(height: 20),

          /// TITLE
          Text(
            "$title (${year})",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          if (releaseDate.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              "Release Date: $releaseDate",
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 14,
              ),
            ),
          ],

          const SizedBox(height: 18),

          /// 🎥 OTT PLATFORM
          if (platform.isNotEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.amber.shade700,
                      Colors.amber.shade500,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.ondemand_video,
                        color: Colors.black, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      platform,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),
          /// ✅ OTT RATINGS SECTION
          if (cbfcRating.isNotEmpty)
            section("CBFC Rating", [cbfcRating]),

          if (certificateNo.isNotEmpty)
            section("Certificate No.", [certificateNo]),

          if (certificateDate.isNotEmpty)
            section("Certificate Date", [certificateDate]),

          if (imdb.isNotEmpty && imdb != "N.A")
            section("IMDb Rating", [imdb]),

          if (rotten.isNotEmpty && rotten != "N.A")
            section("Rotten Tomato", [rotten]),


          const SizedBox(height: 28),

          if (cast.isNotEmpty)
            section("Starring",
                cast.map((e) => e["name"].toString()).toList()),

          if (directors.isNotEmpty)
            section("Directors",
                directors.map((e) => e["name"].toString()).toList()),

          if (genres.isNotEmpty)
            section("Genres",
                genres.map((e) => e["name"].toString()).toList()),

          const SizedBox(height: 18),

          const Text(
            "Explore More Movies like this",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 10),

          SizedBox(
            height: 150,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: exploreList.length,
              itemBuilder: (context, i) {
                final m = exploreList[i];
                final title = DataAdapter.extractTitle(m);
                final year = DataAdapter.extractYear(m);
                final poster = DataAdapter.extractPoster(m);
                final id =
                (m["film_id"] ?? m["unique_id"] ?? "").toString();

                return Container(
                  width: 130,
                  margin: const EdgeInsets.only(right: 10),
                  child: MovieTile(
                    id: id,
                    title: title,
                    year: year,
                    posterOverride: poster,
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OttDetailPage(
                            data: m,
                            exploreList: exploreList,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 4),
        ],
      ),
    );
  }



  Widget section(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        ...items.map((e) =>
            Text(e, style: const TextStyle(color: Colors.white70))),
        const SizedBox(height: 18),
      ],
    );
  }
}
