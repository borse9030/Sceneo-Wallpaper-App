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
  final String status; // 'published' or 'draft'

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
    this.status = 'published',
  });

  factory WallpaperModel.fromFirestore(Map<String, dynamic> data, String documentId) {
    List<String> parsedImageUrls = [];
    if (data['imageUrls'] != null) {
      parsedImageUrls = List<String>.from(data['imageUrls']);
    } else if (data['imageUrl'] != null) {
      parsedImageUrls = [data['imageUrl']];
    }

    String tUrl = data['thumbnailUrl'] ?? '';
    if (tUrl.isEmpty && parsedImageUrls.isNotEmpty) {
      String url = parsedImageUrls.first;
      if (url.contains('/upload/') && !url.contains('c_fill')) {
        tUrl = url.replaceFirst('/upload/', '/upload/c_fill,w_400,q_auto,f_auto/');
      } else {
        tUrl = url;
      }
    }

    return WallpaperModel(
      id: documentId,
      title: data['title'] ?? 'Untitled',
      imageUrls: parsedImageUrls,
      thumbnailUrl: tUrl,
      category: data['category'] ?? 'Uncategorized',
      tags: List<String>.from(data['tags'] ?? []),
      resolution: data['resolution'] ?? '4K',
      featured: data['featured'] ?? false,
      trending: data['trending'] ?? false,
      downloads: data['downloads'] ?? 0,
      createdAt: data['createdAt'] != null ? data['createdAt'].toDate() : DateTime.now(),
      dominantColor: data['dominantColor'] ?? '#1A1A2E',
      type: data['type'] ?? 'image',
      previewUrls: List<String>.from(data['previewUrls'] ?? []),
      status: data['status'] ?? 'published',
    );
  }
}
