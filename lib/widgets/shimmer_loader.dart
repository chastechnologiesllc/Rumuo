import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'rumuo_shimmer.dart';

/// Fix 2 — Shimmer skeletons with correct 16:9 aspect ratio and blog variant.
/// All skeletons match the exact dimensions of the real cards so there is
/// zero layout shift when content arrives.

enum ShimmerVariant { videoFeed, blogFeed, grid, shortsGrid }

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 700;
        Widget child;
        switch (variant) {
          case ShimmerVariant.videoFeed:
            child = isDesktop
                ? _buildVideoGrid(skeleton, count)
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                    itemCount: count < 8 ? 8 : count,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (_, __) => _VideoShimmerCard(placeholderColor: skeleton),
                  );
          case ShimmerVariant.blogFeed:
            child = isDesktop
                ? _buildBlogGrid(skeleton, count)
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                    itemCount: count < 8 ? 8 : count,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, __) => _BlogShimmerCard(placeholderColor: skeleton),
                  );
          case ShimmerVariant.grid:
            child = _buildPlaceholderGrid(skeleton, count, columns);
          case ShimmerVariant.shortsGrid:
            child = _buildShortsGrid(skeleton, count, columns);
        }

        // The scroll view already preserves the existing card geometry. The
        // outer colour makes the loading state occupy every pixel of the
        // screen, including the viewport below the last skeleton row.
        return ColoredBox(
          color: AppTheme.bgColor(context),
          child: RumuoShimmer(child: child),
        );
      },
    );
  }

  Widget _buildVideoGrid(Color skeleton, int itemCount) => GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.08,
          crossAxisSpacing: 18,
          mainAxisSpacing: 20,
        ),
        itemCount: itemCount < 12 ? 12 : itemCount,
        itemBuilder: (_, __) => _VideoShimmerCard(placeholderColor: skeleton),
      );

  Widget _buildBlogGrid(Color skeleton, int itemCount) => GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.08,
          crossAxisSpacing: 18,
          mainAxisSpacing: 18,
        ),
        itemCount: itemCount < 12 ? 12 : itemCount,
        itemBuilder: (_, __) => _BlogShimmerCard(placeholderColor: skeleton),
      );

  Widget _buildPlaceholderGrid(Color skeleton, int itemCount, int columns) =>
      GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          childAspectRatio: columns == 4 ? 0.62 : 1.08,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: itemCount < columns * 4 ? columns * 4 : itemCount,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: skeleton,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

  Widget _buildShortsGrid(Color skeleton, int itemCount, int columns) =>
      GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 110),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          childAspectRatio: 9 / 16,
          crossAxisSpacing: columns == 4 ? 10 : 8,
          mainAxisSpacing: columns == 4 ? 10 : 8,
        ),
        itemCount: itemCount < columns * 4 ? columns * 4 : itemCount,
        itemBuilder: (_, __) => _ShortsShimmerCard(placeholderColor: skeleton),
      );
}

class _ShortsShimmerCard extends StatelessWidget {
  final Color placeholderColor;

  const _ShortsShimmerCard({required this.placeholderColor});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: placeholderColor),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black38],
                stops: [0.45, 1.0],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(height: 3, color: placeholderColor),
          ),
          const Center(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black26,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.play_arrow_rounded,
                    color: Colors.white54, size: 28),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShortLine(widthFactor: 1, color: placeholderColor),
                const SizedBox(height: 5),
                _ShortLine(widthFactor: 0.72, color: placeholderColor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortLine extends StatelessWidget {
  final double widthFactor;
  final Color color;

  const _ShortLine({required this.widthFactor, required this.color});

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
        widthFactor: widthFactor,
        alignment: Alignment.centerLeft,
        child: Container(
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(5),
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
