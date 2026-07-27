import 'dart:math' show min;
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../core/theme/colors.dart';
import '../../core/models/wallpaper_model.dart';
import '../../core/widgets/skeleton_loaders.dart';
import '../../core/services/notification_service.dart';

// Pre-computed color constants — avoids creating objects on every build
const _kBlack80 = Color(0xCC000000);
const _kBlack60 = Color(0x99000000);
const _kBlack40 = Color(0x66000000);
const _kWhite15 = Color(0x26FFFFFF);
const _kWhite38 = Color(0x61FFFFFF);
const _kWhite54 = Color(0x8AFFFFFF);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedCategory;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    try {
      await NotificationService.initialize();
    } catch (e) {
      debugPrint('Notification init error: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _isFiltering => _searchQuery.isNotEmpty || _selectedCategory != null;

  void _clearFilters() {
    _selectedCategory = null;
    _isSearching = false;
    _searchQuery = '';
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('wallpapers')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const HomeScreenSkeleton();
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Error loading wallpapers', style: TextStyle(color: Colors.white)),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          var allWallpapers = docs.map((doc) => WallpaperModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
              
          // Only show published wallpapers to users
          allWallpapers = allWallpapers.where((w) => w.status == 'published').toList();

          if (allWallpapers.isEmpty) {
            return const Center(
              child: Text(
                'No wallpapers yet!\nLong press "Sceneo" to upload some.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _kWhite54, fontSize: 16),
              ),
            );
          }

          // ── Derived data (computed once per snapshot) ──────────────────
          List<WallpaperModel> filteredWallpapers;
          if (_searchQuery.isNotEmpty) {
            final queryWords = _searchQuery.toLowerCase().split(' ').where((w) => w.isNotEmpty).toList();
            filteredWallpapers = allWallpapers.where((w) {
              final searchableString = '${w.title} ${w.category} ${w.tags.join(' ')}'.toLowerCase();
              return queryWords.every((word) => searchableString.contains(word));
            }).toList();
          } else if (_selectedCategory != null) {
            filteredWallpapers =
                allWallpapers.where((w) => w.category == _selectedCategory).toList();
          } else {
            filteredWallpapers = allWallpapers;
          }

          final featuredList = allWallpapers.where((w) => w.featured).toList();
          final displayFeatured =
              featuredList.isNotEmpty ? featuredList : allWallpapers.take(3).toList();
          final trendingList = allWallpapers.where((w) => w.trending).toList();

          // Group by category — ordered alphabetically for consistency
          final Map<String, List<WallpaperModel>> categoryGroups = {};
          for (final w in allWallpapers) {
            if (w.category.isNotEmpty) {
              categoryGroups.putIfAbsent(w.category, () => []).add(w);
            }
          }
          final categories = categoryGroups.keys.toList()..sort();

          return CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            // Cacheextent improves scroll smoothness by pre-rendering off-screen items
            cacheExtent: 500,
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: AppColors.background, // Match solid background
                elevation: 0,
                toolbarHeight: 70,
                title: _isSearching
                    ? TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Search wallpapers...',
                          hintStyle: TextStyle(color: _kWhite54),
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                            _selectedCategory = null;
                          });
                        },
                      )
                    : GestureDetector(
                        onLongPress: () => context.push('/about'),
                        child: const Text(
                          'Sceneo',
                          style: TextStyle(
                            fontWeight: FontWeight.w300,
                            fontSize: 24,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                actions: [
                  IconButton(
                    icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        if (_isSearching) {
                          _clearFilters();
                        } else {
                          _isSearching = true;
                        }
                      });
                    },
                  ),
                ],
              ),

              // ── Featured Carousel ───────────────────────────────────────
              if (!_isFiltering && displayFeatured.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      'Featured',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: CarouselSlider.builder(
                    itemCount: displayFeatured.length,
                    itemBuilder: (context, index, realIndex) =>
                        // RepaintBoundary isolates carousel repaints from the rest of the tree
                        RepaintBoundary(
                          child: FeaturedWallpaperCard(wallpaper: displayFeatured[index]),
                        ),
                    options: CarouselOptions(
                      height: 230,
                      autoPlay: true,
                      pauseAutoPlayOnTouch: true,
                      autoPlayInterval: const Duration(seconds: 5),
                      autoPlayAnimationDuration: const Duration(milliseconds: 700),
                      autoPlayCurve: Curves.easeInOut,
                      enlargeCenterPage: true,
                      enlargeFactor: 0.12,
                      viewportFraction: 0.85,
                    ),
                  ),
                ),
              ],

              // ── Category Filter Chips ───────────────────────────────────
              if (categories.isNotEmpty)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _CategoryHeaderDelegate(
                    height: 54,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      // addAutomaticKeepAlives: false reduces overhead for simple chips
                      addAutomaticKeepAlives: false,
                      itemCount: categories.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _CategoryChip(
                            title: 'All',
                            isSelected: !_isFiltering,
                            onTap: () => setState(_clearFilters),
                          );
                        }
                        final cat = categories[index - 1];
                        return _CategoryChip(
                          title: cat,
                          isSelected: _selectedCategory == cat,
                          onTap: () => setState(() {
                            _selectedCategory = _selectedCategory == cat ? null : cat;
                            _searchQuery = '';
                            _searchController.clear();
                            _isSearching = false;
                          }),
                        );
                      },
                    ),
                  ),
                ),

              // ── FILTERED VIEW ───────────────────────────────────────────
              if (_isFiltering) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      _searchQuery.isNotEmpty
                          ? '${filteredWallpapers.length} results for "$_searchQuery"'
                          : '${filteredWallpapers.length} wallpapers in "$_selectedCategory"',
                      style: const TextStyle(color: _kWhite54, fontSize: 13),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  sliver: filteredWallpapers.isEmpty
                      ? const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(48.0),
                            child: Center(
                              child: Text('No wallpapers found.',
                                  style: TextStyle(color: _kWhite54, fontSize: 16)),
                            ),
                          ),
                        )
                      : SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 0.58,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => RepaintBoundary(
                              child: _UniformGridItem(
                                wallpaper: filteredWallpapers[index],
                                wallpapers: filteredWallpapers,
                                index: index,
                              ),
                            ),
                            childCount: filteredWallpapers.length,
                            // Disable automatic keep-alives for memory efficiency in large grids
                            addAutomaticKeepAlives: false,
                          ),
                        ),
                ),
              ],

              // ── NORMAL VIEW ─────────────────────────────────────────────
              if (!_isFiltering) ...[
                // Trending strip
                if (trendingList.isNotEmpty) ...[
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Row(
                        children: [
                          Icon(Icons.local_fire_department, color: Colors.orange, size: 22),
                          SizedBox(width: 6),
                          Text('Trending Now',
                              style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 210,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        addAutomaticKeepAlives: false,
                        itemCount: trendingList.length,
                        itemBuilder: (context, index) => RepaintBoundary(
                          child: _HorizontalCard(
                            wallpaper: trendingList[index],
                            wallpapers: trendingList,
                            index: index,
                            heroPrefix: 'trending_',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                // Category rows (Netflix-style)
                for (final entry in categoryGroups.entries) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                          GestureDetector(
                            onTap: () => setState(() => _selectedCategory = entry.key),
                            child: Row(
                              children: [
                                Text('See all',
                                    style: TextStyle(fontSize: 13, color: AppColors.accent)),
                                Icon(Icons.chevron_right, color: AppColors.accent, size: 18),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 185,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        addAutomaticKeepAlives: false,
                        itemCount: entry.value.length,
                        itemBuilder: (context, index) => RepaintBoundary(
                          child: _HorizontalCard(
                            wallpaper: entry.value[index],
                            wallpapers: entry.value,
                            index: index,
                            heroPrefix: '${entry.key}_',
                          ),
                        ),
                      ),
                    ),
                  ),
                ],

                // All Wallpapers uniform grid
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(16, 28, 16, 10),
                    child: Text('All Wallpapers',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.58,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => RepaintBoundary(
                        child: _UniformGridItem(
                          wallpaper: allWallpapers[index],
                          wallpapers: allWallpapers,
                          index: index,
                        ),
                      ),
                      childCount: allWallpapers.length,
                      addAutomaticKeepAlives: false,
                    ),
                  ),
                ),
              ],

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          );
        },
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────
// Featured Carousel Card
// ───────────────────────────────────────────────────────────
class FeaturedWallpaperCard extends StatelessWidget {
  final WallpaperModel wallpaper;
  const FeaturedWallpaperCard({super.key, required this.wallpaper});

  @override
  Widget build(BuildContext context) {
    final placeholderColor =
        Color(int.parse(wallpaper.dominantColor.replaceFirst('#', '0xFF')));

    return GestureDetector(
      onTap: () => context.push('/wallpaper',
          extra: {'wallpapers': [wallpaper], 'initialIndex': 0, 'heroPrefix': 'feat_'}),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: _kBlack60, blurRadius: 12, offset: Offset(0, 6)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: wallpaper.imageUrl,
                fit: BoxFit.cover,
                memCacheWidth: 800, // Featured is larger
                fadeInDuration: const Duration(milliseconds: 300),
                placeholder: (context, url) => ColoredBox(color: placeholderColor),
                errorWidget: (context, url, error) =>
                    const ColoredBox(color: AppColors.surfaceLight),
              ),
              // Gradient overlay
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [_kBlack80, Colors.transparent],
                    stops: [0.0, 0.6],
                  ),
                ),
              ),
              // Info
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        wallpaper.title,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          wallpaper.category,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Featured badge
              Positioned(
                top: 12, right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kBlack60,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kWhite38),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 12),
                      SizedBox(width: 4),
                      Text('Featured', style: TextStyle(color: Colors.white, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────
// Horizontal Scroll Card (Trending + Category rows)
// ───────────────────────────────────────────────────────────
class _HorizontalCard extends StatelessWidget {
  final WallpaperModel wallpaper;
  final List<WallpaperModel> wallpapers;
  final int index;
  final String heroPrefix;

  const _HorizontalCard({
    required this.wallpaper,
    required this.wallpapers,
    required this.index,
    required this.heroPrefix,
  });

  @override
  Widget build(BuildContext context) {
    final placeholderColor =
        Color(int.parse(wallpaper.dominantColor.replaceFirst('#', '0xFF')));
    final imageUrl =
        wallpaper.thumbnailUrl.isNotEmpty ? wallpaper.thumbnailUrl : wallpaper.imageUrl;

    return GestureDetector(
      onTap: () => context.push('/wallpaper',
          extra: {'wallpapers': wallpapers, 'initialIndex': index, 'heroPrefix': heroPrefix}),
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        child: Hero(
          tag: '$heroPrefix${wallpaper.id}',
          // Flightshuttlebuilder keeps smooth Hero transitions
          flightShuttleBuilder: (_, animation, __, ___, ____) => AnimatedBuilder(
            animation: animation,
            builder: (_, child) => ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: child,
            ),
            child: CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 400,
                  fadeInDuration: const Duration(milliseconds: 250),
                  placeholder: (context, url) => ColoredBox(color: placeholderColor),
                  errorWidget: (context, url, error) =>
                      const ColoredBox(color: AppColors.surfaceLight),
                ),
                // Title gradient
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [_kBlack80, Colors.transparent],
                        stops: [0.0, 0.7],
                      ),
                    ),
                    child: Text(
                      wallpaper.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      )
          // Light fade-in only — scale on scroll items causes jank
          .animate()
          .fade(
            delay: Duration(milliseconds: min(index, 6) * 50),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          ),
    );
  }
}

// ───────────────────────────────────────────────────────────
// Uniform Portrait Grid Item (fixed 9:16 aspect ratio)
// ───────────────────────────────────────────────────────────
class _UniformGridItem extends StatelessWidget {
  final WallpaperModel wallpaper;
  final List<WallpaperModel> wallpapers;
  final int index;

  const _UniformGridItem({
    required this.wallpaper,
    required this.wallpapers,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final placeholderColor =
        Color(int.parse(wallpaper.dominantColor.replaceFirst('#', '0xFF')));
    final imageUrl =
        wallpaper.thumbnailUrl.isNotEmpty ? wallpaper.thumbnailUrl : wallpaper.imageUrl;

    return GestureDetector(
      onTap: () => context.push('/wallpaper',
          extra: {'wallpapers': wallpapers, 'initialIndex': index, 'heroPrefix': 'grid_'}),
      child: Hero(
        tag: 'grid_${wallpaper.id}',
        flightShuttleBuilder: (_, animation, __, ___, ____) => AnimatedBuilder(
          animation: animation,
          builder: (_, child) => ClipRRect(borderRadius: BorderRadius.circular(16), child: child),
          child: CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                memCacheWidth: 400,
                fadeInDuration: const Duration(milliseconds: 250),
                placeholder: (context, url) => ColoredBox(color: placeholderColor),
                errorWidget: (context, url, error) => const ColoredBox(
                  color: AppColors.surfaceLight,
                  child: Icon(Icons.broken_image, color: _kWhite38),
                ),
              ),
              // Title gradient
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 28, 10, 10),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [_kBlack80, Colors.transparent],
                      stops: [0.0, 0.8],
                    ),
                  ),
                  child: Text(
                    wallpaper.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              // Video badge
              if (wallpaper.type == 'video')
                const Positioned(
                  top: 8, right: 8,
                  child: _VideoBadge(),
                ),
            ],
          ),
        ),
      )
          // Cap animation delay at index 8 — beyond that no delay needed
          .animate()
          .fade(
            delay: Duration(milliseconds: min(index, 8) * 35),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
          )
          .slideY(
            begin: 0.06,
            end: 0,
            delay: Duration(milliseconds: min(index, 8) * 35),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOut,
          ),
    );
  }
}

// Extracted as a const widget — Flutter reuses the element, no rebuilds
class _VideoBadge extends StatelessWidget {
  const _VideoBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: _kBlack60,
        shape: BoxShape.circle,
      ),
      child: const Padding(
        padding: EdgeInsets.all(4),
        child: Icon(Icons.play_circle_fill, color: Colors.white, size: 18),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────
// Category Chip — animated selection state
// ───────────────────────────────────────────────────────────
class _CategoryChip extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({required this.title, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? AppColors.accent : _kWhite15,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : const [],
        ),
        child: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 13,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────
// Legacy exports (used by other screens)
// ───────────────────────────────────────────────────────────
class WallpaperGridItem extends StatelessWidget {
  final WallpaperModel wallpaper;
  final List<WallpaperModel> wallpapers;
  final int index;
  final String heroPrefix;

  const WallpaperGridItem({
    super.key,
    required this.wallpaper,
    required this.wallpapers,
    required this.index,
    this.heroPrefix = 'home_',
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        wallpaper.thumbnailUrl.isNotEmpty ? wallpaper.thumbnailUrl : wallpaper.imageUrl;
    return GestureDetector(
      onTap: () => context.push('/wallpaper',
          extra: {'wallpapers': wallpapers, 'initialIndex': index, 'heroPrefix': heroPrefix}),
      child: Hero(
        tag: '$heroPrefix${wallpaper.id}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 250),
            placeholder: (context, url) => ColoredBox(
              color: Color(int.parse(wallpaper.dominantColor.replaceFirst('#', '0xFF'))),
            ),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        ),
      ),
    );
  }
}

class CategoryChip extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryChip(
      {super.key, required this.title, this.isSelected = false, required this.onTap});

  @override
  Widget build(BuildContext context) =>
      _CategoryChip(title: title, isSelected: isSelected, onTap: onTap);
}

class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _CategoryHeaderDelegate({required this.child, required this.height});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      height: height,
      child: child,
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _CategoryHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.height != height;
  }
}
