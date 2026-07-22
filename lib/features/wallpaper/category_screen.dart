import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/models/wallpaper_model.dart';
import '../../core/theme/colors.dart';
import '../home/home_screen.dart'; // For WallpaperGridItem
import '../../core/widgets/skeleton_loaders.dart';

class CategoryScreen extends StatelessWidget {
  final String category; // 'All' or a specific category name

  const CategoryScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final title = category == 'All' ? 'All Wallpapers' : category;

    return Scaffold(
      backgroundColor: AppColors.background, // Match the app's standard background
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            backgroundColor: AppColors.background.withOpacity(0.95),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            centerTitle: true,
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 22,
                letterSpacing: 1.0,
              ),
            ).animate().fade().slideY(begin: 0.2, end: 0.0),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('wallpapers').orderBy('createdAt', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const WallpaperGridSkeleton();
              }

              if (snapshot.hasError) {
                return const SliverFillRemaining(
                  child: Center(child: Text('Error loading wallpapers', style: TextStyle(color: Colors.white))),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              final allWallpapers = docs.map((doc) => WallpaperModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
              
              final displayWallpapers = category == 'All' 
                  ? allWallpapers 
                  : allWallpapers.where((w) => w.category == category).toList();

              if (displayWallpapers.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No wallpapers found in this category.',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                sliver: SliverMasonryGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  itemBuilder: (context, index) {
                    return WallpaperGridItem(wallpaper: displayWallpapers[index], wallpapers: displayWallpapers, index: index, heroPrefix: 'cat_');
                  },
                  childCount: displayWallpapers.length,
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)), // Bottom padding
        ],
      ),
    );
  }
}
