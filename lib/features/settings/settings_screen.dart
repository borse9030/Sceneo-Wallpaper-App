import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool isAutoWallpaperEnabled;
  InterstitialAd? _interstitialAd;

  @override
  void initState() {
    super.initState();
    isAutoWallpaperEnabled = Hive.box('settings').get('daily_wallpaper', defaultValue: false);
    _loadInterstitialAd();
  }

  void _loadInterstitialAd() {
    if (kIsWeb) return;
    InterstitialAd.load(
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, err) {
              ad.dispose();
              _loadInterstitialAd();
            },
          );
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (err) {
          if (kDebugMode) print('Settings ad failed to load: ${err.message}');
        },
      ),
    );
  }

  void _showAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
    }
  }

  @override
  void dispose() {
    _interstitialAd?.dispose();
    super.dispose();
  }

  void _toggleAutoWallpaper(bool value) {
    setState(() {
      isAutoWallpaperEnabled = value;
    });
    Hive.box('settings').put('daily_wallpaper', value);
    
    if (value) {
      if (!kIsWeb) {
        Workmanager().registerPeriodicTask(
          "dailyWallpaperTask",
          "dailyWallpaperTask",
          frequency: const Duration(hours: 24),
          constraints: Constraints(networkType: NetworkType.connected),
        );
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Daily Auto-Wallpaper enabled!'), backgroundColor: AppColors.accent),
      );
      _showAd();
    } else {
      if (!kIsWeb) {
        Workmanager().cancelByUniqueName("dailyWallpaperTask");
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daily Auto-Wallpaper disabled.'), backgroundColor: Colors.white38),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            backgroundColor: AppColors.background.withOpacity(0.95),
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'Settings',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 22,
                letterSpacing: 1.0,
              ),
            ).animate().fade().slideY(begin: 0.2, end: 0.0),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader('General'),
                _buildSettingsTile(
                  icon: Icons.cleaning_services,
                  title: 'Clear Cache',
                  subtitle: 'Free up local storage',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Image cache cleared successfully!'),
                        backgroundColor: AppColors.accent,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                ),
                if (!kIsWeb)
                  _buildSettingsTile(
                    icon: Icons.wallpaper,
                    title: 'Daily Wallpaper Shuffle',
                    subtitle: isAutoWallpaperEnabled ? 'Enabled (Every 24h)' : 'Disabled',
                    trailing: Switch(
                      value: isAutoWallpaperEnabled,
                      activeColor: AppColors.accent,
                      onChanged: _toggleAutoWallpaper,
                    ),
                    onTap: () => _toggleAutoWallpaper(!isAutoWallpaperEnabled),
                  ),
                const SizedBox(height: 24),
                _buildSectionHeader('Legal'),
                _buildSettingsTile(
                  icon: Icons.privacy_tip,
                  title: 'Privacy Policy',
                  onTap: () => context.push('/legal', extra: 'privacy'),
                ),
                _buildSettingsTile(
                  icon: Icons.description,
                  title: 'Terms of Service',
                  onTap: () => context.push('/legal', extra: 'terms'),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('App Info'),
                _buildSettingsTile(
                  icon: Icons.info_outline,
                  title: 'About Sceneo',
                  subtitle: 'Version 1.0.0',
                  onTap: () {},
                ),
                const SizedBox(height: 50),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    ).animate().fade(delay: 100.ms).slideX(begin: -0.1);
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.3),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.accent, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing ?? const Icon(Icons.chevron_right, color: Colors.white38),
            ],
          ),
        ),
      ).animate().fade(delay: 200.ms).slideY(begin: 0.1),
    );
  }
}
