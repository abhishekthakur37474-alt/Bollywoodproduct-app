import 'package:flutter/material.dart';
import 'common.dart';

class CelebrityDetailPage extends StatefulWidget {
  final dynamic celeb;
  const CelebrityDetailPage({super.key, required this.celeb});

  @override
  State<CelebrityDetailPage> createState() => _CelebrityDetailPageState();
}

class _CelebrityDetailPageState extends State<CelebrityDetailPage> {
  dynamic get celeb => widget.celeb;
  final GlobalKey _filmographyKey = GlobalKey();

  String _formatFullDob() {
    final d = celeb['birth_date']?.toString() ?? '';
    final m = celeb['birth_month']?.toString() ?? '';
    final y = celeb['birth_year']?.toString() ?? '';
    if (d.isEmpty || m.isEmpty) return 'Unknown';
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final mInt = int.tryParse(m) ?? 0;
    final monthName = (mInt >= 1 && mInt <= 12) ? months[mInt] : '';
    return '$d $monthName${y.isNotEmpty ? ', $y' : ''}';
  }

  int? _calculateAge() {
    final d = int.tryParse(celeb['birth_date']?.toString() ?? '');
    final m = int.tryParse(celeb['birth_month']?.toString() ?? '');
    final y = int.tryParse(celeb['birth_year']?.toString() ?? '');
    if (d == null || m == null || y == null) return null;
    final now = DateTime.now();
    int age = now.year - y;
    if (now.month < m || (now.month == m && now.day < d)) age--;
    return age;
  }

  bool get _isDeceased {
    final dy = celeb['death_year']?.toString().trim() ?? '';
    return dy.isNotEmpty && dy != '0';
  }

  String _formatFullDeathDate() {
    final d = celeb['death_date']?.toString() ?? '';
    final m = celeb['death_month']?.toString() ?? '';
    final y = celeb['death_year']?.toString() ?? '';
    if (d.isEmpty || m.isEmpty) return 'Unknown';
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final mInt = int.tryParse(m) ?? 0;
    final monthName = (mInt >= 1 && mInt <= 12) ? months[mInt] : '';
    return '$d $monthName${y.isNotEmpty ? ', $y' : ''}';
  }

  int? _calculateAgeAtDeath() {
    final bd = int.tryParse(celeb['birth_date']?.toString() ?? '');
    final bm = int.tryParse(celeb['birth_month']?.toString() ?? '');
    final by = int.tryParse(celeb['birth_year']?.toString() ?? '');
    final dd = int.tryParse(celeb['death_date']?.toString() ?? '');
    final dm = int.tryParse(celeb['death_month']?.toString() ?? '');
    final dyr = int.tryParse(celeb['death_year']?.toString() ?? '');
    if (bd == null || bm == null || by == null ||
        dd == null || dm == null || dyr == null) return null;
    int age = dyr - by;
    if (dm < bm || (dm == bm && dd < bd)) age--;
    return age;
  }

  // ✅ SAME method as common page (home_page.dart): id = film_unique_id
  // (film_unique_id hi asli key hai — unique_id sirf fallback, kabhi missing hoti hai)
  String _extractFilmUniqueId(dynamic film) {
    if (film is! Map) return '';
    return (film['film_unique_id'] ?? film['unique_id'] ?? film['film_id'] ?? '')
        .toString()
        .trim();
  }

  void _navigateToMoviePage(BuildContext context, dynamic film) {
    final uniqueId = _extractFilmUniqueId(film);
    if (uniqueId.isEmpty) {
      print("🔴 [CELEB TAP] unique_id empty, film=${film is Map ? film['name'] : film}");
      return;
    }
    final poster = film is Map ? (film['thumbnail']?.toString() ?? '') : '';
    final language = film is Map ? (film['language']?.toString() ?? '') : '';
    print("🟢 [CELEB TAP] → unique_id=$uniqueId");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CommonScreen(
          uniqueId: uniqueId,
          posterUrl: poster.isNotEmpty ? poster : null,
          language: language.isNotEmpty ? language : null,
          onlyFullTrailers: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = celeb['name']?.toString().trim() ?? 'Unknown';
    final roles = celeb['roles']?.toString() ?? '';
    final realName = celeb['real_name']?.toString() ?? '';
    final nickname = celeb['nickname']?.toString() ?? '';
    final gender = celeb['gender']?.toString() ?? '';
    final nationality = celeb['nationality']?.toString() ?? '';
    final noOfFilms = celeb['no_of_films']?.toString() ?? '';
    final totalMovies = celeb['total_movies']?.toString() ?? noOfFilms;
    final isDeceased = _isDeceased;
    final age = isDeceased ? _calculateAgeAtDeath() : _calculateAge();
    final birthYear = celeb['birth_year']?.toString() ?? '';
    final deathYear = celeb['death_year']?.toString() ?? '';
    final lifespan = (birthYear.isNotEmpty && deathYear.isNotEmpty)
        ? '$birthYear - $deathYear'
        : null;

    final List<dynamic> upcomingMovies = celeb['upcoming_movies'] ?? [];
    final List<dynamic> filmography = celeb['filmography'] ?? [];

    final pastFilmography = filmography;

    final initials =
        name.trim().isNotEmpty
            ? name
                .trim()
                .split(' ')
                .take(2)
                .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
                .join()
            : '?';

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF0D0D0D),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF8B0000), Color(0xFF0D0D0D)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 50),
                        Container(
                          width: 110,
                          height: 110,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFFE50914), Color(0xFF8B0000)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 36,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (isDeceased && lifespan != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '($lifespan)',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        if (roles.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            roles,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Stats row
                  Row(
                    children: [
                      if (totalMovies.isNotEmpty)
                        Expanded(
                          child: GestureDetector(
                            onTap: filmography.isNotEmpty ? () {
                              Scrollable.ensureVisible(
                                _filmographyKey.currentContext!,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeInOut,
                              );
                            } : null,
                            child: _StatBox(
                              value: totalMovies,
                              label: 'Movies',
                              icon: Icons.movie_outlined,
                            ),
                          ),
                        ),
                      if (totalMovies.isNotEmpty && age != null)
                        const SizedBox(width: 12),
                      if (age != null)
                        Expanded(
                          child: _StatBox(
                            value: '$age',
                            label: 'Age',
                            icon: Icons.cake_outlined,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── About
                  const Text(
                    'About',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: Column(
                      children: [
                        _DetailRow(
                          icon: Icons.cake_outlined,
                          label: isDeceased ? 'Birth Anniversary' : 'Birthday',
                          value: _formatFullDob(),
                        ),
                        if (gender.isNotEmpty)
                          _DetailRow(
                            icon: Icons.wc_outlined,
                            label: 'Gender',
                            value: gender,
                          ),
                        if (realName.isNotEmpty)
                          _DetailRow(
                            icon: Icons.person_outline,
                            label: 'Born As',
                            value: realName,
                          ),
                        if (nickname.isNotEmpty)
                          _DetailRow(
                            icon: Icons.tag,
                            label: 'Nickname',
                            value: nickname,
                          ),
                        if (nationality.isNotEmpty)
                          _DetailRow(
                            icon: Icons.flag_outlined,
                            label: 'Nationality/Citizenship',
                            value: nationality,
                            isLast: !isDeceased,
                          ),
                        if (isDeceased)
                          _DetailRow(
                            icon: Icons.local_florist_outlined,
                            label: 'Death Anniversary',
                            value: _formatFullDeathDate(),
                            isLast: true,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Upcoming Movies
                  if (upcomingMovies.isNotEmpty) ...[
                    _SectionHeader(
                      icon: Icons.upcoming_outlined,
                      title: 'Upcoming Movies',
                      count: upcomingMovies.length,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 186,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: upcomingMovies.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (ctx, i) {
                          final film = upcomingMovies[i];
                          final uid = _extractFilmUniqueId(film);
                          return GestureDetector(
                            onTap: uid.isNotEmpty ? () => _navigateToMoviePage(context, film) : null,
                            child: _MovieCard(movie: film, showYear: true),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // ── Filmography
                  if (filmography.isNotEmpty) ...[
                    SizedBox(key: _filmographyKey, height: 0),
                    _SectionHeader(
                      icon: Icons.video_library_outlined,
                      title: 'Filmography',
                      count: filmography.length,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(14),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.06)),
                      ),
                      child: ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: filmography.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: Colors.white.withOpacity(0.06),
                          indent: 16,
                          endIndent: 16,
                        ),
                        itemBuilder: (ctx, i) {
                          final film = filmography[i];
                          final uid = _extractFilmUniqueId(film);
                          return GestureDetector(
                            onTap: uid.isNotEmpty ? () => _navigateToMoviePage(context, film) : null,
                            child: _FilmographyRow(film: film),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WIDGETS
// ─────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final int count;
  const _SectionHeader(
      {required this.icon, required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: const Color(0xFFE50914),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Icon(icon, color: const Color(0xFFE50914), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

class _MovieCard extends StatelessWidget {
  final dynamic movie;
  final bool showYear;
  const _MovieCard({required this.movie, this.showYear = false});

  @override
  Widget build(BuildContext context) {
    final name = movie['name']?.toString() ?? '';
    final thumbnail = movie['thumbnail']?.toString() ?? '';
    final releaseDate = movie['release_date']?.toString() ?? '';

    return Container(
      width: 130,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(14)),
            child: thumbnail.isNotEmpty
                ? Image.network(
                    thumbnail,
                    height: 110,
                    width: 130,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _ThumbFallback(name: name),
                  )
                : _ThumbFallback(name: name),
          ),
          // Name
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 2),
            child: Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.3),
            ),
          ),
          // Release date
          if (releaseDate.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Text(
                releaseDate,
                style: const TextStyle(
                    color: Color(0xFFE6C15A),
                    fontSize: 11,
                    fontWeight: FontWeight.w500),
              ),
            ),
        ],
      ),
    );
  }
}

class _ThumbFallback extends StatelessWidget {
  final String name;
  const _ThumbFallback({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      width: 130,
      color: const Color(0xFF2A1A1A),
      alignment: Alignment.center,
      child: Icon(Icons.movie_outlined,
          color: Colors.white.withOpacity(0.2), size: 28),
    );
  }
}

class _FilmographyRow extends StatelessWidget {
  final dynamic film;
  const _FilmographyRow({required this.film});

  @override
  Widget build(BuildContext context) {
    final name = film['name']?.toString() ?? '';
    final type = film['type']?.toString() ?? '';
    final language = film['language']?.toString() ?? '';
    final year = film['year_release']?.toString() ?? '';
    final thumbnail = film['thumbnail']?.toString() ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Row(
        children: [
          // Mini thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: thumbnail.isNotEmpty
                ? Image.network(
                    thumbnail,
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _FilmThumbFallback(),
                  )
                : _FilmThumbFallback(),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    if (language.isNotEmpty)
                      _FilmChip(label: language),
                    if (language.isNotEmpty && type.isNotEmpty)
                      const SizedBox(width: 6),
                    if (type.isNotEmpty)
                      _FilmChip(label: type),
                  ],
                ),
              ],
            ),
          ),
          if (year.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                year,
                style: const TextStyle(
                    color: Color(0xFFE6C15A),
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilmThumbFallback extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: const Color(0xFF2A1A1A),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.movie_outlined,
          color: Colors.white.withOpacity(0.2), size: 20),
    );
  }
}

class _FilmChip extends StatelessWidget {
  final String label;
  const _FilmChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style:
            TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _StatBox(
      {required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFE50914), size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFE50914), size: 18),
              const SizedBox(width: 12),
              SizedBox(
                width: 100,
                child: Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            color: Colors.white.withOpacity(0.06),
            indent: 16,
            endIndent: 16,
          ),
      ],
    );
  }
}