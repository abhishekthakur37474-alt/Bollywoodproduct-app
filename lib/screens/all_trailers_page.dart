
import 'package:flutter/material.dart';

import '../services/trailer_service.dart';
import '../utils/paginated_list.dart';
import '../utils/data_adapter.dart';
import '../widgets/trailer_card.dart';

class AllTrailersPage extends StatelessWidget {
  const AllTrailersPage({super.key});

  Future<List> fetch() => TrailerService.fetchAllTrailers();

  @override
  Widget build(BuildContext context) {
    return PaginatedList(
      pageSize: 15,
      fetch: fetch,
      builder: (m) => TrailerCard(data: m),
    );
  }
}
