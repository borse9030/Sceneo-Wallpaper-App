import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../../../core/theme/colors.dart';
import '../../../core/widgets/skeleton_loaders.dart';

class ManageCategoriesView extends StatefulWidget {
  const ManageCategoriesView({super.key});

  @override
  State<ManageCategoriesView> createState() => _ManageCategoriesViewState();
}

class _ManageCategoriesViewState extends State<ManageCategoriesView> {
  final TextEditingController _categoryController = TextEditingController();
  bool _isUploading = false;

  Future<void> _uploadImageForCategory(String docId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? result = await picker.pickImage(source: ImageSource.gallery);
    if (result == null) return;

    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.cloudinary.com/v1_1/dzvmyxmjj/image/upload'),
      );
      final bytes = await result.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: result.name));
      request.fields['upload_preset'] = 'sceneo_uploads';

      final response = await request.send();
      final responseData = await response.stream.toBytes();
      final jsonMap = jsonDecode(String.fromCharCodes(responseData));

      if (response.statusCode == 200) {
        final coverImageUrl = jsonMap['secure_url'];
        await FirebaseFirestore.instance.collection('categories').doc(docId).update({
          'coverImageUrl': coverImageUrl,
        });
        
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Category image updated!')),
          );
        }
      } else {
        throw Exception('Failed to upload image: ${jsonMap['error']['message']}');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _addCategory(int currentTotal) async {
    final name = _categoryController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      _isUploading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('categories').add({
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
        'orderIndex': currentTotal, // Append to the end
      });
      _categoryController.clear();
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category added!')),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _deleteCategory(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('categories').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _onReorder(int oldIndex, int newIndex, List<QueryDocumentSnapshot> docs) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    // Extract data and modify locally first to ensure UI feels instantaneous if needed,
    // but the proper way is to update Firestore and let the stream reload it.
    final List<QueryDocumentSnapshot> localDocs = List.from(docs);
    final item = localDocs.removeAt(oldIndex);
    localDocs.insert(newIndex, item);

    final batch = FirebaseFirestore.instance.batch();
    for (int i = 0; i < localDocs.length; i++) {
      batch.update(localDocs[i].reference, {'orderIndex': i});
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('categories').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const StandardListSkeleton(itemCount: 8);
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)));
              }

              var docs = snapshot.data?.docs ?? [];
              
              // Sort locally to avoid Firestore composite index errors
              docs.sort((a, b) {
                final aData = a.data() as Map<String, dynamic>;
                final bData = b.data() as Map<String, dynamic>;
                final aOrder = aData['orderIndex'] ?? 0;
                final bOrder = bData['orderIndex'] ?? 0;
                
                if (aOrder != bOrder) {
                  return aOrder.compareTo(bOrder);
                }
                
                // Fallback to name or createdAt
                final aName = aData['name'] ?? '';
                final bName = bData['name'] ?? '';
                return aName.compareTo(bName);
              });
              
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _categoryController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'New Category Name',
                              hintStyle: const TextStyle(color: Colors.white38),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _isUploading ? null : () => _addCategory(docs.length),
                          child: _isUploading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Text('Add', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Drag and drop to reorder', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ),
                  ),
                  Expanded(
                    child: docs.isEmpty
                        ? const Center(child: Text('No categories yet', style: TextStyle(color: Colors.white54)))
                        : ReorderableListView.builder(
                            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                            onReorder: (oldIndex, newIndex) => _onReorder(oldIndex, newIndex, docs),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final doc = docs[index];
                              final name = doc['name'] as String;
                              final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                              final coverUrl = data['coverImageUrl'] as String?;

                              return Container(
                                key: ValueKey(doc.id),
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.02),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  leading: coverUrl != null 
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: CachedNetworkImage(
                                            imageUrl: coverUrl, 
                                            width: 40, 
                                            height: 40, 
                                            memCacheWidth: 200, // Small image
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => const Icon(Icons.image, color: Colors.white24),
                                          ),
                                        )
                                      : Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.category, color: Colors.white54),
                                        ),
                                  title: Text(name, style: const TextStyle(color: Colors.white)),
                                  subtitle: const Text('Long press image icon to upload cover', style: TextStyle(color: Colors.white38, fontSize: 12)),
                                  onLongPress: () => _uploadImageForCategory(doc.id),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                                        onPressed: () => _deleteCategory(doc.id),
                                      ),
                                      const Icon(Icons.drag_handle, color: Colors.white54),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
