import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter_animate/flutter_animate.dart';
import 'package:palette_generator/palette_generator.dart';
import '../../../core/theme/colors.dart';

class UploadView extends StatefulWidget {
  const UploadView({super.key});

  @override
  State<UploadView> createState() => _UploadViewState();
}

class _UploadViewState extends State<UploadView> {
  List<XFile> _mainFiles = [];
  List<XFile> _previewFiles = [];
  bool _isUploading = false;
  
  String? _selectedCategory;
  String _selectedStatus = 'published';
  bool _isFeatured = false;
  bool _isTrending = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  Future<void> _pickMainFiles() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> results = await picker.pickMultipleMedia();
    if (results.isNotEmpty) {
      setState(() {
        _mainFiles = results;
      });
    }
  }

  Future<void> _pickPreviewFiles() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> results = await picker.pickMultiImage();
    if (results.isNotEmpty) {
      setState(() {
        _previewFiles = results;
      });
    }
  }

  Future<String> _extractDominantColor(XFile file) async {
    try {
      if (kIsWeb) return '#1A1A2E'; // FileImage doesn't work on web easily
      final imageProvider = FileImage(File(file.path));
      final palette = await PaletteGenerator.fromImageProvider(imageProvider);
      final color = palette.dominantColor?.color ?? const Color(0xFF1A1A2E);
      return '#${color.value.toRadixString(16).substring(2, 8).toUpperCase()}';
    } catch (e) {
      return '#1A1A2E';
    }
  }

  Future<void> _uploadToCloudinary() async {
    if (_mainFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one main file.')));
      return;
    }

    if (_titleController.text.trim().isEmpty || _selectedCategory == null || _tagsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all details (Title, Category, Tags).')));
      return;
    }

    setState(() {
      _isUploading = true;
    });

    int successCount = 0;

    try {
      // 1. Upload preview files first
      List<String> uploadedPreviewUrls = [];
      for (final file in _previewFiles) {
        final previewReq = http.MultipartRequest(
          'POST',
          Uri.parse('https://api.cloudinary.com/v1_1/dzvmyxmjj/image/upload'),
        );
        final bytes = await file.readAsBytes();
        previewReq.files.add(http.MultipartFile.fromBytes('file', bytes, filename: file.name));
        previewReq.fields['upload_preset'] = 'sceneo_uploads';
        
        final pResponse = await previewReq.send();
        final pData = await pResponse.stream.toBytes();
        final pJson = jsonDecode(String.fromCharCodes(pData));
        
        if (pResponse.statusCode == 200) {
          uploadedPreviewUrls.add(pJson['secure_url']);
        }
      }

      // 2. Upload main files
      List<String> uploadedMainUrls = [];
      String dominantColor = '#1A1A2E';
      String thumbnailUrl = '';
      bool isVideo = false;

      for (final mainFile in _mainFiles) {
        if (mainFile.name.toLowerCase().endsWith('mp4')) isVideo = true;
        
        // Extract dominant color from the very first image
        if (!isVideo && dominantColor == '#1A1A2E') {
          dominantColor = await _extractDominantColor(mainFile);
        }

        final endpoint = mainFile.name.toLowerCase().endsWith('mp4') ? 'video/upload' : 'image/upload';
        final request = http.MultipartRequest(
          'POST',
          Uri.parse('https://api.cloudinary.com/v1_1/dzvmyxmjj/$endpoint'),
        );
        
        final bytes = await mainFile.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: mainFile.name));
        request.fields['upload_preset'] = 'sceneo_uploads';

        final response = await request.send();
        final responseData = await response.stream.toBytes();
        final jsonMap = jsonDecode(String.fromCharCodes(responseData));

        if (response.statusCode == 200) {
          final secureUrl = jsonMap['secure_url'] as String;
          uploadedMainUrls.add(secureUrl);
          
          if (thumbnailUrl.isEmpty && !isVideo) {
            // Generate auto-thumbnail via Cloudinary transformation
            thumbnailUrl = secureUrl.replaceFirst('/upload/', '/upload/c_fill,w_400,q_auto,f_auto/');
          }
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload main file: ${jsonMap['error']['message']}')));
        }
      }
      
      if (uploadedMainUrls.isNotEmpty) {
        await FirebaseFirestore.instance.collection('wallpapers').add({
          'title': _titleController.text.trim(),
          'imageUrls': uploadedMainUrls,
          'previewUrls': uploadedPreviewUrls,
          'thumbnailUrl': thumbnailUrl.isNotEmpty ? thumbnailUrl : uploadedMainUrls.first,
          'dominantColor': dominantColor,
          'type': isVideo ? 'video' : 'image',
          'category': _selectedCategory,
          'tags': _tagsController.text.split(',').map((e) => e.trim()).toList(),
          'status': _selectedStatus,
          'createdAt': FieldValue.serverTimestamp(),
          'featured': _isFeatured,
          'trending': _isTrending,
        }).timeout(const Duration(seconds: 10));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Successfully uploaded wallpaper pack!')));
        }
      }
      
      setState(() {
        _mainFiles = [];
        _previewFiles = [];
        _titleController.clear();
        _selectedCategory = null;
        _tagsController.clear();
        _isFeatured = false;
        _isTrending = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _isUploading ? null : _pickMainFiles,
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2), style: BorderStyle.solid),
                    ),
                    child: _mainFiles.isNotEmpty 
                        ? Center(child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle, color: AppColors.accent, size: 40),
                              const SizedBox(height: 8),
                              Text('${_mainFiles.length} Main Files', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              Text('Tap to change', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                            ],
                          ))
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cloud_upload, color: Colors.white54, size: 40),
                              SizedBox(height: 8),
                              Text('Select Main Files', style: TextStyle(color: Colors.white54)),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: _isUploading ? null : _pickPreviewFiles,
                  child: Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2), style: BorderStyle.solid),
                    ),
                    child: _previewFiles.isNotEmpty 
                        ? Center(child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.library_add_check, color: AppColors.accent, size: 40),
                              const SizedBox(height: 8),
                              Text('${_previewFiles.length} Previews', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              Text('Tap to change', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                            ],
                          ))
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.photo_library, color: Colors.white54, size: 40),
                              SizedBox(height: 8),
                              Text('Select Previews', style: TextStyle(color: Colors.white54)),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          _buildTextField('Wallpaper Title', _titleController),
          const SizedBox(height: 16),
          
          // Category Dropdown
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('categories').orderBy('name').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator(color: AppColors.accent);
              }
              final docs = snapshot.data?.docs ?? [];
              final categories = docs.map((d) => d['name'] as String).toList();
              
              return DropdownButtonFormField<String>(
                value: _selectedCategory,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Select Category',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
                items: categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCategory = val;
                  });
                },
              );
            },
          ),
          const SizedBox(height: 16),
          // Status Dropdown
          DropdownButtonFormField<String>(
            value: _selectedStatus,
            dropdownColor: AppColors.surface,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Status',
              labelStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
            items: const [
              DropdownMenuItem(value: 'published', child: Text('Published')),
              DropdownMenuItem(value: 'draft', child: Text('Draft')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedStatus = val;
                });
              }
            },
          ),
          const SizedBox(height: 16),
          _buildTextField('Tags (comma separated)', _tagsController),
          const SizedBox(height: 16),
          
          SwitchListTile(
            title: const Text('Mark as Featured', style: TextStyle(color: Colors.white)),
            activeColor: AppColors.accent,
            value: _isFeatured,
            onChanged: (val) => setState(() => _isFeatured = val),
          ),
          SwitchListTile(
            title: const Text('Mark as Trending', style: TextStyle(color: Colors.white)),
            activeColor: AppColors.accent,
            value: _isTrending,
            onChanged: (val) => setState(() => _isTrending = val),
          ),
          
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _isUploading ? null : _uploadToCloudinary,
              child: _isUploading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Upload to Database', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ],
      ).animate().fade(duration: 300.ms).slideY(begin: 0.1, end: 0.0),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
