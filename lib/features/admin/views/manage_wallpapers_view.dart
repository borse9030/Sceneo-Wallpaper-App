import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/skeleton_loaders.dart';
import '../../../core/models/wallpaper_model.dart';

class ManageWallpapersView extends StatelessWidget {
  const ManageWallpapersView({super.key});

  Future<void> _deleteWallpaper(BuildContext context, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Wallpaper?', style: TextStyle(color: Colors.white)),
        content: const Text('This will remove it from the app permanently.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('wallpapers').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wallpaper deleted')));
    }
  }

  Future<void> _toggleFlag(String docId, String field, bool currentValue) async {
    await FirebaseFirestore.instance.collection('wallpapers').doc(docId).update({
      field: !currentValue,
    });
  }

  Future<void> _showEditDialog(BuildContext context, WallpaperModel wallpaper) async {
    final titleController = TextEditingController(text: wallpaper.title);
    final tagsController = TextEditingController(text: wallpaper.tags.join(', '));
    String selectedCategory = wallpaper.category;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('Edit Wallpaper', style: TextStyle(color: Colors.white)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        labelStyle: TextStyle(color: Colors.white54),
                      ),
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('categories').orderBy('name').snapshots(),
                      builder: (context, snapshot) {
                        final docs = snapshot.data?.docs ?? [];
                        final categories = docs.map((d) => d['name'] as String).toList();
                        
                        // Ensure the current category exists in the list to prevent dropdown errors
                        if (!categories.contains(selectedCategory) && categories.isNotEmpty) {
                          selectedCategory = categories.first;
                        }

                        return DropdownButtonFormField<String>(
                          value: categories.contains(selectedCategory) ? selectedCategory : null,
                          dropdownColor: AppColors.background,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            labelStyle: TextStyle(color: Colors.white54),
                          ),
                          items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => selectedCategory = val);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: tagsController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Tags (comma separated)',
                        labelStyle: TextStyle(color: Colors.white54),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                TextButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance.collection('wallpapers').doc(wallpaper.id).update({
                      'title': titleController.text.trim(),
                      'category': selectedCategory,
                      'tags': tagsController.text.split(',').map((e) => e.trim()).toList(),
                    });
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Save', style: TextStyle(color: AppColors.accent)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('wallpapers').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const StandardGridSkeleton(itemCount: 8);
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading wallpapers', style: TextStyle(color: Colors.white)));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No wallpapers found', style: TextStyle(color: Colors.white54)));
        }

        return GridView.builder(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.7,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final wallpaper = WallpaperModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);

            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: CachedNetworkImageProvider(wallpaper.thumbnailUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withOpacity(0.9), Colors.transparent],
                  ),
                ),
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      wallpaper.title,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => _toggleFlag(wallpaper.id, 'featured', wallpaper.featured),
                              child: Icon(
                                wallpaper.featured ? Icons.star : Icons.star_border,
                                color: wallpaper.featured ? Colors.amber : Colors.white54,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _toggleFlag(wallpaper.id, 'trending', wallpaper.trending),
                              child: Icon(
                                wallpaper.trending ? Icons.local_fire_department : Icons.local_fire_department_outlined,
                                color: wallpaper.trending ? Colors.deepOrange : Colors.white54,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => _showEditDialog(context, wallpaper),
                              child: const Icon(Icons.edit, color: Colors.blueAccent, size: 20),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _deleteWallpaper(context, wallpaper.id),
                              child: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ).animate().fade(delay: (20 * index).ms).scale(begin: const Offset(0.95, 0.95));
          },
        );
      },
    );
  }
}
