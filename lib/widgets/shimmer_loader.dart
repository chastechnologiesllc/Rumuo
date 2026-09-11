import 'package:flutter/material.dart';

import 'rumuo_shimmer.dart';

/// Fix 2 — Shimmer skeletons with correct 16:9 aspect ratio and blog variant.
/// All skeletons match the exact dimensions of the real cards so there is
/// zero layout shift when content arrives.

enum ShimmerVariant { videoFeed, blogFeed, grid }

class ShimmerLoader extends StatelessWidget {
  final int count;
  final ShimmerVariant variant;
  final int columns;

  const ShimmerLoader({
    super.key,
    this.count = 4,
    this.variant = ShimmerVariant.videoFeed,
    this.columns = 2,
  });

  @override
  Widget build(BuildContext context) {
    final skeleton = RumuoShimmer.fillColor(context);
    final isDesktop = MediaQuery.sizeOf(context).width >= 700;

    Widget child;
    switch (variant) {
      case ShimmerVariant.videoFeed:
        child = isDesktop
            ? _buildVideoGrid(skeleton, count)
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: count,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (_, __) => _VideoShimmerCard(placeholderColor: skeleton),
              );
      case ShimmerVariant.blogFeed:
        child = isDesktop
            ? _buildBlogGrid(skeleton, count)
            : ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: count,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, __) => _BlogShimmerCard(placeholderColor: skeleton),
              );
      case ShimmerVariant.grid:
        child = _buildPlaceholderGrid(skeleton, count, columns);
    }

    return RumuoShimmer(child: child);
  }

  Widget _buildVideoGrid(Color skeleton, int itemCount) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.92,
          crossAxisSpacing: 18,
          mainAxisSpacing: 20,
        ),
        itemCount: itemCount,
        itemBuilder: (_, __) => _VideoShimmerCard(placeholderColor: skeleton),
      );

  Widget _buildBlogGrid(Color skeleton, int itemCount) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.9,
          crossAxisSpacing: 18,
          mainAxisSpacing: 18,
        ),
        itemCount: itemCount,
        itemBuilder: (_, __) => _BlogShimmerCard(placeholderColor: skeleton),
      );

  Widget _buildPlaceholderGrid(Color skeleton, int itemCount, int columns) =>
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          childAspectRatio: 9 / 16,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: itemCount,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: skeleton,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
}

/// 16:9 video card skeleton — matches InlineVideoCard exactly.
class _VideoShimmerCard extends StatelessWidget {
  final Color placeholderColor;

  const _VideoShimmerCard({required this.placeholderColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thumbnail — exact 16:9 aspect ratio.
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            decoration: BoxDecoration(
              color: placeholderColor,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 3), // accent strip height
        const SizedBox(height: 12),
        Container(
          height: 16,
          width: double.infinity,
          decoration: BoxDecoration(
            color: placeholderColor,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 16,
          width: MediaQuery.of(context).size.width * 0.65,
          decoration: BoxDecoration(
            color: placeholderColor,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: placeholderColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 12,
              width: 120,
              decoration: BoxDecoration(
                color: placeholderColor,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Blog card skeleton — matches the 16:9 blog card layout.
class _BlogShimmerCard extends StatelessWidget {
  final Color placeholderColor;

  const _BlogShimmerCard({required this.placeholderColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cover image — 16:9
        AspectRatio(
          aspectRatio: 16 / 9,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: placeholderColor,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: BoxDecoration(
              color: placeholderColor.withValues(alpha: 0.15),
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  height: 14,
                  width: 80,
                  decoration: BoxDecoration(
                    color: placeholderColor,
                    borderRadius: BorderRadius.circular(6),
                  )),
              const SizedBox(height: 8),
              Container(
                  height: 16,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: placeholderColor,
                    borderRadius: BorderRadius.circular(8),
                  )),
              const SizedBox(height: 6),
              Container(
                  height: 16,
                  width: MediaQuery.of(context).size.width * 0.6,
                  decoration: BoxDecoration(
                    color: placeholderColor,
                    borderRadius: BorderRadius.circular(8),
                  )),
            ],
          ),
        ),
      ],
    );
  }
}
