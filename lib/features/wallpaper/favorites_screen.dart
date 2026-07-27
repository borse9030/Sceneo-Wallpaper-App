import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/models/wallpaper_model.dart';
import '../../core/theme/colors.dart';
import '../home/home_screen.dart'; // For WallpaperGridItem
import '../../core/widgets/skeleton_loaders.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

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
              'Favorites',
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
              var allWallpapers = docs.map((doc) => WallpaperModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();
              
              allWallpapers = allWallpapers.where((w) => w.status == 'published').toList();
              
              return ValueListenableBuilder(
                valueListenable: Hive.box('favorites').listenable(),
                builder: (context, Box favoritesBox, _) {
                  final displayWallpapers = allWallpapers.where((w) => favoritesBox.containsKey(w.id)).toList();

                  if (displayWallpapers.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: Text(
                          'No favorite wallpapers yet.',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.58,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return RepaintBoundary(
                            child: WallpaperGridItem(
                              wallpaper: displayWallpapers[index], 
                              wallpapers: displayWallpapers, 
                              index: index, 
                              heroPrefix: 'fav_'
                            ),
                          );
                        },
                        childCount: displayWallpapers.length,
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
