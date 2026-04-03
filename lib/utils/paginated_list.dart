import 'package:flutter/material.dart';

class PaginatedList extends StatefulWidget {
  final Future<List> Function() fetch;
  final Widget Function(dynamic item) builder;
  final EdgeInsets padding;
  final int pageSize;

  const PaginatedList({
    super.key,
    required this.fetch,
    required this.builder,
    this.padding = const EdgeInsets.all(14),
    this.pageSize = 15,
  });

  @override
  State<PaginatedList> createState() => _PaginatedListState();
}

class _PaginatedListState extends State<PaginatedList> {
  final ScrollController _scrollController = ScrollController(); // ✅ ADD
  List allItems = [];
  int currentPage = 1;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    print("🟡 [PAGINATION] Fetching all data");
    final data = await widget.fetch();

    if (!mounted) return;

    setState(() {
      allItems = data;
      loading = false;
    });

    print("🟢 [PAGINATION] Total items: ${allItems.length}");
  }

  int get totalPages => (allItems.length / widget.pageSize).ceil();

  List get pageItems {
    final start = (currentPage - 1) * widget.pageSize;
    final end = (start + widget.pageSize).clamp(0, allItems.length);
    return allItems.sublist(start, end);
  }

  /// ✅ SCROLL TO TOP ON PAGE CHANGE
  void _goToTop() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xffD4AF37)),
      );
    }

    final width = MediaQuery.of(context).size.width;

    return ListView(
      controller: _scrollController, // ✅ ATTACHED
      padding: widget.padding,
      children: [
        ...pageItems.map(widget.builder),

        /// 🔥 PREMIUM PAGINATION
        if (totalPages > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 26),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xff121212),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                  border: Border.all(
                    color: const Color(0xffD4AF37).withOpacity(0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    /// ◀ PREV
                    _arrow(
                      icon: Icons.chevron_left,
                      enabled: currentPage > 1,
                      onTap: () {
                        setState(() => currentPage--);
                        _goToTop(); // ✅ ADD
                        print("🟢 [PAGINATION] Page $currentPage");
                      },
                    ),

                    const SizedBox(width: 6),

                    /// PAGE NUMBERS
                    SizedBox(
                      height: 40,
                      width: width * 0.5,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: totalPages,
                        itemBuilder: (_, i) {
                          final page = i + 1;
                          final active = page == currentPage;

                          return GestureDetector(
                            onTap: () {
                              setState(() => currentPage = page);
                              _goToTop(); // ✅ ADD
                              print("🟢 [PAGINATION] Page $page");
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              width: 38,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: active
                                    ? const Color(0xffD4AF37)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: active
                                      ? Colors.transparent
                                      : Colors.white24,
                                ),
                              ),
                              child: Text(
                                "$page",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: active ? Colors.black : Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(width: 6),

                    /// ▶ NEXT
                    _arrow(
                      icon: Icons.chevron_right,
                      enabled: currentPage < totalPages,
                      onTap: () {
                        setState(() => currentPage++);
                        _goToTop(); // ✅ ADD
                        print("🟢 [PAGINATION] Page $currentPage");
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _arrow({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? Colors.white.withOpacity(0.08)
              : Colors.white.withOpacity(0.03),
        ),
        child: Icon(
          icon,
          size: 22,
          color: enabled ? const Color(0xffD4AF37) : Colors.white24,
        ),
      ),
    );
  }
}
