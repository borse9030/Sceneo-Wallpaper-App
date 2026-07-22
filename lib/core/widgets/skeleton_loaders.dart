import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../theme/colors.dart';

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? margin;

  const SkeletonBox({
    super.key, 
    this.width, 
    this.height, 
    this.borderRadius,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
      ),
    )
    .animate(onPlay: (controller) => controller.repeat())
    .shimmer(
      duration: 1500.ms, 
      color: Colors.white12, // Subtle glassmorphism shimmer
      angle: 1.0,
    );
  }
}

class WallpaperGridSkeleton extends StatelessWidget {
  final int itemCount;
  const WallpaperGridSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
      sliver: SliverMasonryGrid.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        itemBuilder: (context, index) {
          return SkeletonBox(
            height: index % 2 == 0 ? 250 : 300,
          );
        },
        childCount: itemCount,
      ),
    );
  }
}

class CategoryCardSkeleton extends StatelessWidget {
  const CategoryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonBox(height: 120);
  }
}

class CategoryGridSkeleton extends StatelessWidget {
  final int itemCount;
  const CategoryGridSkeleton({super.key, this.itemCount = 8});

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => const CategoryCardSkeleton(),
          childCount: itemCount,
        ),
      ),
    );
  }
}

class FeaturedCardSkeleton extends StatelessWidget {
  const FeaturedCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const SkeletonBox(
      height: 220,
      margin: EdgeInsets.symmetric(horizontal: 16.0),
      borderRadius: BorderRadius.all(Radius.circular(24)),
    );
  }
}

class HomeScreenSkeleton extends StatelessWidget {
  const HomeScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: const SkeletonBox(width: 120, height: 24),
          ),
        ),
        const SliverToBoxAdapter(
          child: FeaturedCardSkeleton(),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: const SkeletonBox(width: 150, height: 24),
          ),
        ),
        const WallpaperGridSkeleton(itemCount: 4),
      ],
    );
  }
}

class StandardGridSkeleton extends StatelessWidget {
  final int itemCount;
  const StandardGridSkeleton({super.key, this.itemCount = 6});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return const SkeletonBox();
      },
    );
  }
}

class StandardListSkeleton extends StatelessWidget {
  final int itemCount;
  const StandardListSkeleton({super.key, this.itemCount = 10});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => const Divider(color: Colors.white10),
      itemBuilder: (context, index) {
        return const ListTile(
          leading: SkeletonBox(width: 50, height: 50, borderRadius: BorderRadius.all(Radius.circular(8))),
          title: SkeletonBox(width: 150, height: 16, margin: EdgeInsets.only(bottom: 8)),
          subtitle: SkeletonBox(width: 100, height: 14),
        );
      },
    );
  }
}
