import 'package:flutter/material.dart';

class SkeletonMovieTile extends StatelessWidget {
  const SkeletonMovieTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 10,
            width: 100,
            color: Colors.white10,
          ),
          const SizedBox(height: 6),
          Container(
            height: 10,
            width: 60,
            color: Colors.white10,
          ),
        ],
      ),
    );
  }
}
