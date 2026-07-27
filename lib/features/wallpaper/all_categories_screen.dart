import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/colors.dart';
import '../../core/models/wallpaper_model.dart';
import '../../core/widgets/skeleton_loaders.dart';

class AllCategoriesScreen extends StatelessWidget {
  const AllCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        cacheExtent: 500,
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'Categories',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 22,
                letterSpacing: 1.0,
              ),
            ).animate().fade().slideY(begin: 0.2, end: 0.0),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('wallpapers').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, wallpaperSnapshot) {
              if (wallpaperSnapshot.connectionState == ConnectionState.waiting) {
                return const CategoryGridSkeleton(itemCount: 8);
              }

                final wallpaperDocs = wallpaperSnapshot.data?.docs ?? [];
                final allWallpapers = wallpaperDocs.map((doc) => WallpaperModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('categories').snapshots(),
                  builder: (context, catSnapshot) {
                    var catDocs = catSnapshot.data?.docs ?? [];
                    
                    // Sort locally to avoid Firestore composite index errors
                    catDocs.sort((a, b) {
                      final aData = a.data() as Map<String, dynamic>;
                      final bData = b.data() as Map<String, dynamic>;
                      final aOrder = aData['orderIndex'] ?? 0;
                      final bOrder = bData['orderIndex'] ?? 0;
                      
                      if (aOrder != bOrder) {
                        return aOrder.compareTo(bOrder);
                      }
                      
                      final aName = aData['name'] ?? '';
                      final bName = bData['name'] ?? '';
                      return aName.compareTo(bName);
                    });

                    final Set<String> uniqueCategories = {};
                    final Map<String, String> categoryCoverMap = {};

                    for (var doc in catDocs) {
                      final name = doc['name'] as String;
                      uniqueCategories.add(name);
                      
                      final data = doc.data() as Map<String, dynamic>;
                      if (data.containsKey('coverImageUrl') && data['coverImageUrl'] != null) {
                        categoryCoverMap[name] = data['coverImageUrl'] as String;
                      }
                    }
                    
                    for (var w in allWallpapers) {
                      uniqueCategories.add(w.category);
                    }
                    final categories = ['All', ...uniqueCategories.toList()];

                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.2,
                        ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final categoryName = categories[index];
                          
                          // Find a cover image for this category
                          String? coverImageUrl;
                          if (categoryCoverMap.containsKey(categoryName)) {
                            coverImageUrl = categoryCoverMap[categoryName];
                          } else if (categoryName == 'All' && allWallpapers.isNotEmpty) {
                            coverImageUrl = allWallpapers.first.thumbnailUrl;
                          } else {
                            try {
                              final catWallpapers = allWallpapers.where((w) => w.category == categoryName);
                              if (catWallpapers.isNotEmpty) {
                                coverImageUrl = catWallpapers.first.thumbnailUrl;
                              }
                            } catch (_) {}
                          }

                          return _CategoryCard(
                            title: categoryName,
                            coverImageUrl: coverImageUrl,
                            index: index,
                            onTap: () {
                              context.push('/category', extra: categoryName);
                            },
                          );
                        },
                        childCount: categories.length,
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)), // Space for bottom nav
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String title;
  final String? coverImageUrl;
  final int index;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.title,
    this.coverImageUrl,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: AppColors.surface.withOpacity(0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (coverImageUrl != null)
                CachedNetworkImage(
                  imageUrl: coverImageUrl!,
                  fit: BoxFit.cover,
                  memCacheWidth: 400,
                  placeholder: (context, url) => Container(color: AppColors.surface),
                  errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.white54),
                )
              else
                Container(
                  color: AppColors.accent.withOpacity(0.2),
                  child: const Center(child: Icon(Icons.category, color: Colors.white24, size: 40)),
                ),
              // Premium Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.85),
                      Colors.black.withOpacity(0.2),
                    ],
                  ),
                ),
              ),
              // Title
              Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animate().fade(delay: (50 * index).ms).scale(begin: const Offset(0.9, 0.9)),
    );
  }
}
