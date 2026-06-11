import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'celebrity_detail_page.dart';

class CelebrityPage extends StatefulWidget {
  const CelebrityPage({super.key});

  @override
  State<CelebrityPage> createState() => _CelebrityPageState();
}

class _CelebrityPageState extends State<CelebrityPage> {
  // ── Birthday Today — page increments, limit always 20
  final List<dynamic> _todayList = [];
  int _todayApiPage = 1;
  bool _todayLoadingMore = false;
  bool _todayHasMore = true;
  bool _todayInitialLoading = true;

  // ── Birthday Tomorrow — load all at once
  List<dynamic> _tomorrowList = [];
  bool _tomorrowLoading = true;

  String? _error;

  final ScrollController _todayScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initialFetch();
  }

  @override
  void dispose() {
    _todayScrollController.dispose();
    super.dispose();
  }

  Future<void> _initialFetch() async {
    try {
      await Future.wait([_fetchTodayPage(), _fetchAllTomorrow()]);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _todayInitialLoading = false);
    }
  }

  Future<void> _fetchTodayPage() async {
    final uri = Uri.parse(
      'https://bollywoodproduct.com/api-today-cast-birthday.php'
      '?page=$_todayApiPage&limit=20',
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) return;

    final data = json.decode(res.body);
    final List pageData = data['data'] ?? [];
    

    setState(() {
      _todayList.addAll(pageData); 
      _todayList.sort((a, b) {
        final aF = int.tryParse(a['no_of_films']?.toString() ?? '') ?? 0;
        final bF = int.tryParse(b['no_of_films']?.toString() ?? '') ?? 0;
        return bF.compareTo(aF);
      });
      _todayApiPage++;
      _todayHasMore = pageData.length >= 20;
    });
  }

  Future<void> _loadMoreToday() async {
    if (_todayLoadingMore || !_todayHasMore) return;
    setState(() => _todayLoadingMore = true);
    try {
      await _fetchTodayPage();
    } finally {
      setState(() => _todayLoadingMore = false);
    }
  }

  Future<void> _fetchAllTomorrow() async {
    final List<dynamic> result = [];
    int page = 1;
    bool hasMore = true;

    while (hasMore && page <= 10) {
      final uri = Uri.parse(
        'https://www.bollywoodproduct.com/api-tommorow-cast-birthday.php'
        '?page=$page&limit=20',
      );
      final res = await http.get(uri);
      if (res.statusCode != 200) break;

      final data = json.decode(res.body);
      final List pageData = data['data'] ?? [];
      result.addAll(pageData);
      hasMore = pageData.length >= 20;
      page++;
    }

    result.sort((a, b) {
      final aF = int.tryParse(a['no_of_films']?.toString() ?? '') ?? 0;
      final bF = int.tryParse(b['no_of_films']?.toString() ?? '') ?? 0;
      return bF.compareTo(aF);
    });
    setState(() {
      _tomorrowList = result;
      _tomorrowLoading = false;
    });
  }

  Future<void> _onRefresh() async {
    setState(() {
      _todayList.clear();
      _tomorrowList.clear();
      _todayApiPage = 1;
      _todayHasMore = true;
      _todayInitialLoading = true;
      _tomorrowLoading = true;
      _error = null;
    });
    await _initialFetch();
  }

  String _fmtTabDate(DateTime d) {
    const months = ['','Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '(${d.day} ${months[d.month]})';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.black,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: const Color(0xFF0F0F0F),
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            title: const Text(
              'Celebrity',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
            ),
          ),
          body: Column(
            children: [
              // ── PILL TABS
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF161616),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TabBar(
                    dividerColor: Colors.transparent,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: const LinearGradient(
                        colors: [Color(0xffE6C15A), Color(0xffC9A43A)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.white70,
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    tabs: [
                      Tab(text: 'Today  ${_fmtTabDate(DateTime.now())}'),
                      Tab(text: 'Tomorrow  ${_fmtTabDate(DateTime.now().add(const Duration(days: 1)))}'),
                    ],
                  ),
                ),
              ),

              // ── TAB CONTENT
              Expanded(
                child: _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Something went wrong',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 16),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _onRefresh,
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE50914)),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : TabBarView(
                        children: [
                          _buildTodayTab(),
                          _buildTomorrowTab(),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodayTab() {
    if (_todayInitialLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFE50914)));
    }
    if (_todayList.isEmpty) {
      return const _EmptyState(label: 'No birthdays today');
    }
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color(0xFFE50914),
      child: CustomScrollView(
        controller: _todayScrollController,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CelebrityCard(celeb: _todayList[i]),
                ),
                childCount: _todayList.length,
              ),
            ),
          ),

          // ── SEE MORE / loading
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: _todayLoadingMore
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFFE50914)),
                      ),
                    )
                  : _todayHasMore
                      ? Center(
                          child: TextButton(
                            onPressed: _loadMoreToday,
                            child: const Text(
                              'See More',
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            'All caught up 🎂',
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 12),
                          ),
                        ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 10)),
        ],
      ),
    );
  }

  Widget _buildTomorrowTab() {
    if (_tomorrowLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFFE50914)));
    }
    if (_tomorrowList.isEmpty) {
      return const _EmptyState(label: 'No birthdays tomorrow');
    }
    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: const Color(0xFFE50914),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        itemCount: _tomorrowList.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (ctx, i) => _CelebrityCard(celeb: _tomorrowList[i]),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WIDGETS
// ─────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String label;
  const _EmptyState({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(label,
          style:
              TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
    );
  }
}

class _CelebrityCard extends StatelessWidget {
  final dynamic celeb;
  const _CelebrityCard({required this.celeb});

  String _formatDob() {
    final d = celeb['birth_date']?.toString() ?? '';
    final m = celeb['birth_month']?.toString() ?? '';
    final y = celeb['birth_year']?.toString() ?? '';
    if (d.isEmpty || m.isEmpty) return '';
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final mInt = int.tryParse(m) ?? 0;
    final monthName = (mInt >= 1 && mInt <= 12) ? months[mInt] : ''  ;
    return '$d $monthName${y.isNotEmpty ? ' $y' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final name = celeb['name']?.toString().trim() ?? 'Unknown';
    final roles = celeb['roles']?.toString() ?? '';
    final dob = _formatDob();
    final initials = name.trim().isNotEmpty
        ? name.trim().split(' ').take(2)
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
            .join()
        : '?';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CelebrityDetailPage(celeb: celeb)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color(0xFFE50914), Color(0xFF8B0000)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              alignment: Alignment.center,
              child: Text(initials,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600)),
                  if (roles.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(roles,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12)),
                  ],
                  if (dob.isNotEmpty) ...[],
                ],
              ),
            ),
            Icon(Icons.chevron_right,
                color: Colors.white.withOpacity(0.2), size: 20),
          ],
        ),
      ),
    );
  }
}