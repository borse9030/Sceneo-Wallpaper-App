import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/home/main_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/wallpaper/wallpaper_detail_screen.dart';
import '../../features/wallpaper/category_screen.dart';
import '../../features/wallpaper/favorites_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/settings/legal_screen.dart';
import '../../features/admin/decoy_screen.dart';
import '../../features/admin/admin_upload_screen.dart';
import '../../core/models/wallpaper_model.dart';

final goRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (context, state) => CustomTransitionPage(
        child: const MainScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    ),
    GoRoute(
      path: '/wallpaper',
      pageBuilder: (context, state) {
        final extra = state.extra;
        List<WallpaperModel> wallpapers = [];
        int initialIndex = 0;
        String heroPrefix = 'home_';

        if (extra is Map) {
          if (extra.containsKey('wallpapers')) {
            wallpapers = extra['wallpapers'] as List<WallpaperModel>;
            initialIndex = extra['initialIndex'] as int? ?? 0;
          } else if (extra.containsKey('wallpaper')) {
            wallpapers = [extra['wallpaper'] as WallpaperModel];
          }
          heroPrefix = extra['heroPrefix'] as String? ?? 'home_';
        } else if (extra is WallpaperModel) {
          wallpapers = [extra];
        }

        return CustomTransitionPage(
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          child: WallpaperDetailScreen(wallpapers: wallpapers, initialIndex: initialIndex, heroPrefix: heroPrefix),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutQuart,
              reverseCurve: Curves.easeInQuart,
            );
            return FadeTransition(
              opacity: curvedAnimation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(curvedAnimation),
                child: child,
              ),
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/category',
      pageBuilder: (context, state) {
        final category = state.extra as String;
        return CustomTransitionPage(
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          child: CategoryScreen(category: category),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutQuart,
              reverseCurve: Curves.easeInQuart,
            );
            return FadeTransition(
              opacity: curvedAnimation,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(curvedAnimation),
                child: child,
              ),
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/favorites',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          child: const FavoritesScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutQuart,
              reverseCurve: Curves.easeInQuart,
            );
            return FadeTransition(
              opacity: curvedAnimation,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(curvedAnimation),
                child: child,
              ),
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          child: const SettingsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutQuart,
              reverseCurve: Curves.easeInQuart,
            );
            return FadeTransition(
              opacity: curvedAnimation,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(curvedAnimation),
                child: child,
              ),
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/legal',
      pageBuilder: (context, state) {
        final type = state.extra as String;
        return CustomTransitionPage(
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          child: LegalScreen(type: type),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutQuart,
              reverseCurve: Curves.easeInQuart,
            );
            return FadeTransition(
              opacity: curvedAnimation,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(curvedAnimation),
                child: child,
              ),
            );
          },
        );
      },
    ),
    GoRoute(
      path: '/about',
      builder: (context, state) => const DecoyScreen(),
    ),
    GoRoute(
      path: '/admin',
      pageBuilder: (context, state) {
        return CustomTransitionPage(
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          child: const AdminDashboardScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutQuart,
              reverseCurve: Curves.easeInQuart,
            );
            return FadeTransition(
              opacity: curvedAnimation,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(curvedAnimation),
                child: child,
              ),
            );
          },
        );
      },
    ),
  ],
);
