import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:async_wallpaper/async_wallpaper.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:dio/dio.dart';
import 'package:video_player/video_player.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../core/models/wallpaper_model.dart';
import '../../core/theme/colors.dart';

class WallpaperDetailScreen extends StatefulWidget {
  final List<WallpaperModel> wallpapers;
  final int initialIndex;
  final String heroPrefix;

  const WallpaperDetailScreen({super.key, required this.wallpapers, this.initialIndex = 0, this.heroPrefix = 'home_'});

  @override
  State<WallpaperDetailScreen> createState() => _WallpaperDetailScreenState();
}

class _WallpaperDetailScreenState extends State<WallpaperDetailScreen> {
  late bool _isFavorite;
  late final Box favoritesBox;
  late int _currentIndex;
  late PageController _pageController;
  int _currentInnerIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    favoritesBox = Hive.box('favorites');
    _checkIfFavorite();
  }

  void _checkIfFavorite() {
    setState(() {
      _isFavorite = favoritesBox.containsKey(widget.wallpapers[_currentIndex].id);
    });
  }

  Future<void> _toggleFavorite() async {
    final wallpaperId = widget.wallpapers[_currentIndex].id;
    try {
      if (_isFavorite) {
        await favoritesBox.delete(wallpaperId);
        setState(() {
          _isFavorite = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from favorites'), duration: Duration(seconds: 1)),
          );
        }
      } else {
        await favoritesBox.put(wallpaperId, true);
        setState(() {
          _isFavorite = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to favorites!'), duration: Duration(seconds: 1), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to favorite: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: widget.wallpapers.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
                _currentInnerIndex = 0;
                _checkIfFavorite();
              });
            },
            itemBuilder: (context, index) {
              final wallpaper = widget.wallpapers[index];
              final allImages = [...wallpaper.imageUrls, ...wallpaper.previewUrls];

              return PageView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: allImages.length,
                onPageChanged: (innerIndex) {
                  if (index == _currentIndex) {
                    setState(() {
                      _currentInnerIndex = innerIndex;
                    });
                  }
                },
                itemBuilder: (context, innerIndex) {
                  final imageUrl = allImages[innerIndex];
                  final isPreview = innerIndex >= wallpaper.imageUrls.length;
                  final isVideo = !isPreview && wallpaper.type == 'video' && innerIndex == 0;
                  
                  bool isFirstMainImage = innerIndex == 0;

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: isFirstMainImage 
                            ? '${widget.heroPrefix}${wallpaper.id}' 
                            : '${widget.heroPrefix}${wallpaper.id}_img_$innerIndex',
                        child: InteractiveViewer(
                          minScale: 1.0,
                          maxScale: 4.0,
                          child: isVideo
                              ? _LiveWallpaperPlayer(url: imageUrl)
                              : CachedNetworkImage(
                                  imageUrl: imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Color(int.parse(wallpaper.dominantColor.replaceFirst('#', '0xFF'))),
                                  ),
                                  errorWidget: (context, url, error) => const Icon(Icons.error),
                                ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          
          Positioned(
            top: 60,
            left: 20,
            child: SafeArea(
              child: _GlassButton(
                icon: Icons.arrow_back_ios_new,
                onTap: () => context.pop(),
              ),
            ),
          ),

          Positioned(
            top: 60,
            right: 20,
            child: SafeArea(
              child: _GlassButton(
                icon: _isFavorite ? Icons.favorite : Icons.favorite_border,
                iconColor: _isFavorite ? Colors.redAccent : Colors.white,
                onTap: _toggleFavorite,
              ),
            ),
          ),

          Builder(
            builder: (context) {
              final currentWallpaper = widget.wallpapers[_currentIndex];
              final isPreview = _currentInnerIndex >= currentWallpaper.imageUrls.length;
              final currentImageUrl = _currentInnerIndex < currentWallpaper.imageUrls.length 
                  ? currentWallpaper.imageUrls[_currentInnerIndex] 
                  : currentWallpaper.previewUrls[_currentInnerIndex - currentWallpaper.imageUrls.length];
              
              if (!isPreview) {
                return Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _BottomPanel(
                    wallpaper: currentWallpaper,
                    currentImageUrl: currentImageUrl,
                  )
                      .animate()
                      .fade(delay: 300.ms)
                      .slideY(begin: 1.0, end: 0.0, curve: Curves.easeOutCubic),
                );
              } else {
                final previewNum = _currentInnerIndex - currentWallpaper.imageUrls.length + 1;
                return Positioned(
                  bottom: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Preview $previewNum of ${currentWallpaper.previewUrls.length}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              }
            }
          ),

          Builder(
            builder: (context) {
              final currentWallpaper = widget.wallpapers[_currentIndex];
              final totalImages = currentWallpaper.imageUrls.length + currentWallpaper.previewUrls.length;
              if (totalImages <= 1) return const SizedBox.shrink();
              
              return Positioned(
                 bottom: 120, 
                 left: 0, right: 0,
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: List.generate(
                     totalImages,
                     (i) => Container(
                       margin: const EdgeInsets.symmetric(horizontal: 4),
                       width: _currentInnerIndex == i ? 10 : 6,
                       height: _currentInnerIndex == i ? 10 : 6,
                       decoration: BoxDecoration(
                         color: _currentInnerIndex == i ? Colors.white : Colors.white54,
                         shape: BoxShape.circle,
                         boxShadow: const [
                           BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 1))
                         ]
                       ),
                     ),
                   ),
                 ),
              );
            }
          ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  const _GlassButton({required this.icon, required this.onTap, this.iconColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
    );
  }
}

class _BottomPanel extends StatefulWidget {
  final WallpaperModel wallpaper;
  final String currentImageUrl;

  const _BottomPanel({required this.wallpaper, required this.currentImageUrl});

  @override
  State<_BottomPanel> createState() => _BottomPanelState();
}

class _BottomPanelState extends State<_BottomPanel> {
  bool _isApplying = false;
  bool _isDownloading = false;
  InterstitialAd? _interstitialAd;

  @override
  void initState() {
    super.initState();
    _loadInterstitialAd();
  }

  void _loadInterstitialAd() {
    if (kIsWeb) return; 

    InterstitialAd.load(
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712' // Reverted to Test ID for safe testing
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
          print('Failed to load an interstitial ad: ${err.message}');
        },
      ),
    );
  }

  void _showAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (ad, err) {
          ad.dispose();
          _loadInterstitialAd();
        },
      );
      _interstitialAd!.show();
      _interstitialAd = null;
    }
  }

  Future<void> _downloadWallpaper() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final currentWallpaper = widget.wallpaper;
      final isVideo = currentWallpaper.type == 'video';
      final ext = isVideo ? 'mp4' : 'jpg';
      final mime = isVideo ? MimeType.mpeg : MimeType.jpeg;
      
      if (kIsWeb || Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        final response = await Dio().get(
          widget.currentImageUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        await FileSaver.instance.saveFile(
          name: currentWallpaper.id,
          bytes: response.data,
          fileExtension: ext,
          mimeType: mime,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Downloaded successfully!'), backgroundColor: Colors.green),
          );
        }
      } else {
        final appDir = await getTemporaryDirectory();
        final savePath = '${appDir.path}/${currentWallpaper.id}.$ext';
        await Dio().download(widget.currentImageUrl, savePath);
        final result = await ImageGallerySaverPlus.saveFile(savePath);
        
        if (mounted) {
          if (result != null && result['isSuccess'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Saved to Gallery!'), backgroundColor: Colors.green),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed: ${result?['errorMessage'] ?? 'Unknown'}'), backgroundColor: Colors.redAccent),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed: $e';
        if (e is DioException) {
          if (e.type == DioExceptionType.connectionError || e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.unknown) {
            errorMessage = 'No internet connection. Please check your network and try again.';
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
        _showAd();
      }
    }
  }

  Future<void> _applyWallpaper(WallpaperTarget target) async {
    setState(() {
      _isApplying = true;
    });

    try {
      final currentWallpaper = widget.wallpaper;
      
      if (currentWallpaper.type == 'video') {
        // Videos must be downloaded first for async_wallpaper
        final appDir = await getTemporaryDirectory();
        final savePath = '${appDir.path}/${currentWallpaper.id}.mp4';
        
        if (!File(savePath).existsSync()) {
          await Dio().download(widget.currentImageUrl, savePath);
        }
        
        await AsyncWallpaper.setLiveWallpaper(
          LiveWallpaperRequest(
            filePath: savePath,
            goToHome: false,
          ),
        );
      } else {
        await AsyncWallpaper.setWallpaper(
          WallpaperRequest(
            target: target,
            sourceType: WallpaperSourceType.url,
            source: widget.currentImageUrl,
            goToHome: false,
          ),
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wallpaper Applied Successfully!'), backgroundColor: Colors.green),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        String errorMessage = 'Failed: ${e.message}';
        if (e.message != null && (e.message!.toLowerCase().contains('connect') || e.message!.toLowerCase().contains('network') || e.message!.toLowerCase().contains('host'))) {
            errorMessage = 'No internet connection. Please check your network and try again.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isApplying = false;
        });
        _showAd();
      }
    }
  }

  void _showApplyOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white38, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              const Text('Set Wallpaper', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.home, color: Colors.white),
                title: const Text('Home Screen', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _applyWallpaper(WallpaperTarget.home);
                },
              ),
              ListTile(
                leading: const Icon(Icons.lock, color: Colors.white),
                title: const Text('Lock Screen', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _applyWallpaper(WallpaperTarget.lock);
                },
              ),
              ListTile(
                leading: const Icon(Icons.phonelink_setup, color: Colors.white),
                title: const Text('Both Screens', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _applyWallpaper(WallpaperTarget.both);
                },
              ),
              const SizedBox(height: 24), // SafeArea
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
              Text(
                widget.wallpaper.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _InfoChip(text: widget.wallpaper.category, icon: Icons.category),
                  const SizedBox(width: 8),
                  _InfoChip(text: widget.wallpaper.resolution, icon: Icons.hd),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isDownloading ? null : _downloadWallpaper,
                      icon: _isDownloading ? const SizedBox.shrink() : const Icon(Icons.download),
                      label: _isDownloading 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                          : const Text('Download'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isApplying ? null : _showApplyOptions,
                      icon: _isApplying ? const SizedBox.shrink() : const Icon(Icons.wallpaper),
                      label: _isApplying 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2)) 
                          : const Text('Apply'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20), // SafeArea bottom padding
            ],
          ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String text;
  final IconData icon;

  const _InfoChip({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _LiveWallpaperPlayer extends StatefulWidget {
  final String url;
  const _LiveWallpaperPlayer({required this.url});

  @override
  State<_LiveWallpaperPlayer> createState() => _LiveWallpaperPlayerState();
}

class _LiveWallpaperPlayerState extends State<_LiveWallpaperPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
        _controller.setLooping(true);
        _controller.setVolume(0.0);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller.value.size.width,
          height: _controller.value.size.height,
          child: VideoPlayer(_controller),
        ),
      ),
    );
  }
}

