class WallpaperModel {
  final String id;
  final String title;
  final List<String> imageUrls;
  String get imageUrl => imageUrls.isNotEmpty ? imageUrls.first : '';
  final String thumbnailUrl;
  final String category;
  final List<String> tags;
  final String resolution;
  final bool featured;
  final bool trending;
  final int downloads;
  final DateTime createdAt;
  final String dominantColor;
  final String type; // 'image' or 'video'
  final List<String> previewUrls;

  WallpaperModel({
    required this.id,
    required this.title,
    required this.imageUrls,
    required this.thumbnailUrl,
    required this.category,
    required this.tags,
    required this.resolution,
    this.featured = false,
    this.trending = false,
    this.downloads = 0,
    required this.createdAt,
    required this.dominantColor,
    this.type = 'image',
    this.previewUrls = const [],
  });

  factory WallpaperModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    List<String> parsedImageUrls = [];
    if (data['imageUrls'] != null) {
      parsedImageUrls = List<String>.from(data['imageUrls']);
    } else if (data['imageUrl'] != null) {
      parsedImageUrls = [data['imageUrl']];
    }

    return WallpaperModel(
      id: documentId,
      title: data['title'] ?? 'Untitled',
      imageUrls: parsedImageUrls,
      thumbnailUrl: parsedImageUrls.isNotEmpty ? parsedImageUrls.first : '',      category: data['category'] ?? 'Uncategorized',
      tags: List<String>.from(data['tags'] ?? []),
      resolution: data['resolution'] ?? '4K',
      featured: data['featured'] ?? false,
      trending: data['trending'] ?? false,
      downloads: data['downloads'] ?? 0,
      createdAt: data['createdAt'] != null ? data['createdAt'].toDate() : DateTime.now(),
      dominantColor: data['dominantColor'] ?? '#1A1A2E',
      type: data['type'] ?? 'image',
      previewUrls: List<String>.from(data['previewUrls'] ?? []),
    );
  }
}
