import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:umusaruro_p2p/core/theme/app_colors.dart';

class LoadingShimmer extends StatelessWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const LoadingShimmer({
    super.key,
    required this.height,
    this.width,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.divider,
      highlightColor: Colors.white,
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

// Card-shaped shimmer for project list loading state
class ProjectCardShimmer extends StatelessWidget {
  const ProjectCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LoadingShimmer(height: 160, borderRadius: 8),
            SizedBox(height: 12),
            LoadingShimmer(height: 18, width: 200),
            SizedBox(height: 8),
            LoadingShimmer(height: 14, width: 150),
            SizedBox(height: 12),
            LoadingShimmer(height: 8),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                LoadingShimmer(height: 14, width: 80),
                LoadingShimmer(height: 14, width: 80),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
