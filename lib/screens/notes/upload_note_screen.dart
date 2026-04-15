import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../core/repositories/campus_repository.dart';
import '../../core/network/logger.dart';

class UploadNoteScreen extends StatefulWidget {
  const UploadNoteScreen({super.key});

  @override
  State<UploadNoteScreen> createState() => _UploadNoteScreenState();
}

class _UploadNoteScreenState extends State<UploadNoteScreen> {
  final _titleController = TextEditingController();
  final _subjectController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  PlatformFile? _selectedFile;
  bool _isUploading = false;

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;
        });
      }
    } catch (e) {
      AppLogger.info('Error picking file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking file: $e')),
        );
      }
    }
  }

  Future<void> _handleUpload() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF file')),
      );
      return;
    }

    if (_titleController.text.isEmpty || _subjectController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      List<int> bytes;
      if (kIsWeb) {
        bytes = _selectedFile!.bytes?.toList() ?? [];
      } else {
        bytes = await File(_selectedFile!.path!).readAsBytes();
      }

      if (bytes.isEmpty) {
        throw Exception('File data is empty. Please select the file again.');
      }

      await CampusRepository().uploadNote(
        title: _titleController.text.trim(),
        subject: _subjectController.text.trim(),
        description: _descriptionController.text.trim(),
        fileName: _selectedFile!.name,
        fileBytes: bytes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Note uploaded successfully!'), backgroundColor: Colors.green),
        );
        context.pop();
      }
    } catch (e) {
      AppLogger.info('Upload failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.softShadow,
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppTheme.textPrimary,
              size: 20,
            ),
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Upload Note',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File picker
            GestureDetector(
              onTap: _isUploading ? null : _pickFile,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36),
                decoration: BoxDecoration(
                  color: _selectedFile != null 
                      ? (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF)) 
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: _selectedFile != null
                        ? AppTheme.primary
                        : (Theme.of(context).brightness == Brightness.dark ? Colors.white10 : AppTheme.cardBorder),
                    width: 2,
                  ),
                  boxShadow: AppTheme.softShadow,
                ),
                child: _selectedFile != null
                    ? Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.picture_as_pdf_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            _selectedFile!.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${(_selectedFile!.size / 1024 / 1024).toStringAsFixed(2)} MB',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (!_isUploading)
                            GestureDetector(
                              onTap: _pickFile,
                              child: Text(
                                'Change file',
                                style: TextStyle(
                                  color: AppTheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                      )
                    : Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.inputBg,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.cloud_upload_rounded,
                              size: 36,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Tap to select PDF file',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Supports PDF up to 10MB',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 26),

            Text('Title *', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 10),
            TextFormField(
              controller: _titleController,
              enabled: !_isUploading,
              decoration: const InputDecoration(
                hintText: 'e.g., Advanced Vector Calculus',
                prefixIcon: Icon(
                  Icons.title_rounded,
                  size: 20,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 22),

            Text('Subject *', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 10),
            TextFormField(
              controller: _subjectController,
              enabled: !_isUploading,
              decoration: const InputDecoration(
                hintText: 'e.g., Mathematics',
                prefixIcon: Icon(
                  Icons.book_rounded,
                  size: 20,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 22),

            Text('Description', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 10),
            TextFormField(
              controller: _descriptionController,
              enabled: !_isUploading,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Brief description of the notes...',
                contentPadding: const EdgeInsets.all(18),
                fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1B4B) : AppTheme.inputBg,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _handleUpload,
                icon: _isUploading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.upload_rounded, size: 20),
                label: Text(_isUploading ? 'Uploading...' : 'Upload Note'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
