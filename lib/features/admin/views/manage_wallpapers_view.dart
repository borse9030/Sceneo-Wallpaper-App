import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/colors.dart';
import '../../../core/widgets/skeleton_loaders.dart';
import '../../../core/models/wallpaper_model.dart';

class ManageWallpapersView extends StatefulWidget {
  const ManageWallpapersView({super.key});

  @override
  State<ManageWallpapersView> createState() => _ManageWallpapersViewState();
}

class _ManageWallpapersViewState extends State<ManageWallpapersView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  final Set<String> _selectedIds = {};

  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _deleteSelectedWallpapers(BuildContext context) async {
    if (_selectedIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Delete ${_selectedIds.length} Wallpapers?', style: const TextStyle(color: Colors.white)),
        content: const Text('This will remove them from the app permanently.', style: TextStyle(color: Colors.white70)),
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
      final batch = FirebaseFirestore.instance.batch();
      for (final id in _selectedIds) {
        batch.delete(FirebaseFirestore.instance.collection('wallpapers').doc(id));
      }
      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${_selectedIds.length} Wallpapers deleted')));
        setState(() {
          _selectedIds.clear();
        });
      }
    }
  }
  
  Future<void> _changeCategoryForSelected(BuildContext context) async {
    if (_selectedIds.isEmpty) return;
    
    String? newCategory;
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text('Change Category for ${_selectedIds.length} items', style: const TextStyle(color: Colors.white)),
          content: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('categories').orderBy('name').snapshots(),
            builder: (context, snapshot) {
              final docs = snapshot.data?.docs ?? [];
              final categories = docs.map((d) => d['name'] as String).toList();
              
              return DropdownButtonFormField<String>(
                value: newCategory,
                dropdownColor: AppColors.background,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Select New Category',
                  labelStyle: TextStyle(color: Colors.white54),
                ),
                items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                onChanged: (val) {
                  setStateDialog(() => newCategory = val);
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, newCategory != null),
              child: const Text('Apply', style: TextStyle(color: AppColors.accent)),
            ),
          ],
        ),
      ),
    );

    if (confirm == true && newCategory != null) {
      final batch = FirebaseFirestore.instance.batch();
      for (final id in _selectedIds) {
        batch.update(FirebaseFirestore.instance.collection('wallpapers').doc(id), {
          'category': newCategory
        });
      }
      await batch.commit();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Categories updated')));
        setState(() {
          _selectedIds.clear();
        });
      }
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
    String selectedStatus = wallpaper.status;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
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
                            if (val != null) setStateDialog(() => selectedCategory = val);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      dropdownColor: AppColors.background,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        labelStyle: TextStyle(color: Colors.white54),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'published', child: Text('Published')),
                        DropdownMenuItem(value: 'draft', child: Text('Draft')),
                      ],
                      onChanged: (val) {
                        if (val != null) setStateDialog(() => selectedStatus = val);
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
                      'status': selectedStatus,
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
    Query query = FirebaseFirestore.instance
        .collection('wallpapers')
        .orderBy('createdAt', descending: true);
        
    return Column(
      children: [
        // ── Controls Header ──
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          color: _isSelectionMode ? AppColors.accent.withOpacity(0.2) : AppColors.surface,
          child: _isSelectionMode 
            ? Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => setState(() => _selectedIds.clear()),
                  ),
                  Text('${_selectedIds.length} Selected', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.category, color: Colors.blueAccent),
                    tooltip: 'Change Category',
                    onPressed: () => _changeCategoryForSelected(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    tooltip: 'Delete Selected',
                    onPressed: () => _deleteSelectedWallpapers(context),
                  ),
                ],
              )
            : Column(
                children: [
                  // Search Bar
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search by title or tags...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      prefixIcon: const Icon(Icons.search, color: Colors.white54),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close, color: Colors.white54),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                  const SizedBox(height: 12),
                  // Category Dropdown
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('categories').orderBy('name').snapshots(),
                    builder: (context, snapshot) {
                      final docs = snapshot.data?.docs ?? [];
                      final categories = ['All Categories', ...docs.map((d) => d['name'] as String)];
                      
                      return DropdownButtonFormField<String>(
                        value: _selectedCategory ?? 'All Categories',
                        dropdownColor: AppColors.surface,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                        onChanged: (val) {
                          setState(() => _selectedCategory = val);
                        },
                      );
                    },
                  ),
                ],
              ),
        ),
        
        // ── Grid View ──
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: query.snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const StandardGridSkeleton(itemCount: 8);
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
              }

              final docs = snapshot.data?.docs ?? [];
              
              var wallpapers = docs.map((doc) => WallpaperModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id)).toList();

              // Local Category Filtering
              if (_selectedCategory != null && _selectedCategory != 'All Categories') {
                wallpapers = wallpapers.where((w) => w.category == _selectedCategory).toList();
              }

              // Local Search Filtering
              if (_searchQuery.isNotEmpty) {
                final queryWords = _searchQuery.toLowerCase().split(' ').where((w) => w.isNotEmpty).toList();
                wallpapers = wallpapers.where((w) {
                  final searchableString = '${w.title} ${w.category} ${w.tags.join(' ')}'.toLowerCase();
                  return queryWords.every((word) => searchableString.contains(word));
                }).toList();
              }

              if (wallpapers.isEmpty) {
                return const Center(
                  child: Text('No wallpapers found', style: TextStyle(color: Colors.white54)),
                );
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
                itemCount: wallpapers.length,
                itemBuilder: (context, index) {
                  final wallpaper = wallpapers[index];
                  final isSelected = _selectedIds.contains(wallpaper.id);

                  return RepaintBoundary(
                    child: GestureDetector(
                      onLongPress: () => _toggleSelection(wallpaper.id),
                      onTap: () {
                        if (_isSelectionMode) {
                          _toggleSelection(wallpaper.id);
                        } else {
                          _showEditDialog(context, wallpaper);
                        }
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: wallpaper.thumbnailUrl,
                              fit: BoxFit.cover,
                              memCacheWidth: 400,
                              placeholder: (context, url) => ColoredBox(
                                color: Color(int.parse(wallpaper.dominantColor.replaceFirst('#', '0xFF'))),
                              ),
                              errorWidget: (context, url, error) => const ColoredBox(color: AppColors.surfaceLight),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border: isSelected ? Border.all(color: AppColors.accent, width: 4) : null,
                                color: isSelected ? AppColors.accent.withOpacity(0.3) : Colors.transparent,
                              ),
                            ),
                            Container(
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                // Top row: Draft Badge & Selection check
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (wallpaper.status == 'draft')
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.orangeAccent, borderRadius: BorderRadius.circular(8)),
                                        child: const Text('DRAFT', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                      )
                                    else
                                      const SizedBox(),
                                    if (_isSelectionMode)
                                      Icon(
                                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                                        color: isSelected ? AppColors.accent : Colors.white54,
                                      ),
                                  ],
                                ),
                                // Bottom row: Info
                                Column(
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
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
