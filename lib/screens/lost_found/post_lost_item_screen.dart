import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../core/repositories/campus_repository.dart';
import '../../core/network/logger.dart';

class PostLostItemScreen extends StatefulWidget {
  const PostLostItemScreen({super.key});

  @override
  State<PostLostItemScreen> createState() => _PostLostItemScreenState();
}

class _PostLostItemScreenState extends State<PostLostItemScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  
  String _selectedType = 'Lost';
  XFile? _imageFile;
  bool _isPosting = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() => _imageFile = image);
    }
  }

  Future<void> _handleSubmit() async {
    if (_titleController.text.isEmpty || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      // In a real app, we'd upload the image first and get a URL.
      // For now, we'll post metadata and add a placeholder or simple logic.
      await CampusRepository().reportLostFoundItem(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        type: _selectedType,
        imageUrl: null, // Image upload implementation would go here
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Item reported as $_selectedType successfully!'),
            backgroundColor: _selectedType == 'Lost' ? Colors.red : Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      AppLogger.info('Failed to report item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Report Item', style: Theme.of(context).textTheme.titleLarge),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type selector
            Text('Type', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _isPosting ? null : () => setState(() => _selectedType = 'Lost'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _selectedType == 'Lost' ? const Color(0xFFDC2626) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _selectedType == 'Lost' ? Colors.transparent : const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded, color: _selectedType == 'Lost' ? Colors.white : const Color(0xFFDC2626), size: 20),
                          const SizedBox(width: 8),
                          Text('Lost', style: TextStyle(color: _selectedType == 'Lost' ? Colors.white : AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: _isPosting ? null : () => setState(() => _selectedType = 'Found'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: _selectedType == 'Found' ? const Color(0xFF059669) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _selectedType == 'Found' ? Colors.transparent : const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, color: _selectedType == 'Found' ? Colors.white : const Color(0xFF059669), size: 20),
                          const SizedBox(width: 8),
                          Text('Found', style: TextStyle(color: _selectedType == 'Found' ? Colors.white : AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Image picker
            Text('Photo', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _isPosting ? null : _pickImage,
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 2),
                ),
                child: _imageFile != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: kIsWeb 
                              ? Image.network(_imageFile!.path, fit: BoxFit.cover)
                              : Image.file(File(_imageFile!.path), fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => setState(() => _imageFile = null),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                                child: const Icon(Icons.close, color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_rounded, size: 40, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text('Tap to add a photo', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text('Helps others identify the item', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 24),

            Text('Item Name *', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              enabled: !_isPosting,
              decoration: const InputDecoration(hintText: 'e.g., MacBook Pro Charger', prefixIcon: Icon(Icons.inventory_2_rounded)),
            ),
            const SizedBox(height: 24),

            Text('Description', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              enabled: !_isPosting,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe the item, any identifying marks, color, brand...',
                contentPadding: const EdgeInsets.all(20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                fillColor: AppTheme.inputBg,
                filled: true,
              ),
            ),
            const SizedBox(height: 24),

            Text('Location *', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationController,
              enabled: !_isPosting,
              decoration: const InputDecoration(hintText: 'Where was it lost/found?', prefixIcon: Icon(Icons.location_on_rounded)),
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isPosting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedType == 'Lost' ? const Color(0xFFDC2626) : const Color(0xFF059669),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isPosting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Report as $_selectedType', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
