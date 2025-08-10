import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class DocumentUploadWidget extends StatelessWidget {
  final Function(File) onFileSelected;
  final String buttonText;
  final bool allowMultiple;

  const DocumentUploadWidget({
    super.key,
    required this.onFileSelected,
    this.buttonText = 'Upload',
    this.allowMultiple = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF6750A4).withOpacity(0.1),
      ),
      child: IconButton(
        onPressed: () => _showUploadOptions(context),
        icon: const Icon(
          Icons.upload_file,
          color: Color(0xFF6750A4),
          size: 20,
        ),
        tooltip: buttonText,
      ),
    );
  }

  void _showUploadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Document Source',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1B20),
              ),
            ),
            const SizedBox(height: 24),
            
            // Camera Option
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF6750A4).withOpacity(0.1),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Color(0xFF6750A4),
                ),
              ),
              title: const Text(
                'Take Photo',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1B20),
                ),
              ),
              subtitle: const Text(
                'Use camera to capture document',
                style: TextStyle(
                  color: Color(0xFF49454F),
                  fontSize: 14,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera(context);
              },
            ),
            
            const SizedBox(height: 12),
            
            // Gallery Option
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF6750A4).withOpacity(0.1),
                ),
                child: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF6750A4),
                ),
              ),
              title: const Text(
                'Choose from Gallery',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1B20),
                ),
              ),
              subtitle: const Text(
                'Select image from your gallery',
                style: TextStyle(
                  color: Color(0xFF49454F),
                  fontSize: 14,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery(context);
              },
            ),
            
            const SizedBox(height: 12),
            
            // File Picker Option
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF6750A4).withOpacity(0.1),
                ),
                child: const Icon(
                  Icons.description,
                  color: Color(0xFF6750A4),
                ),
              ),
              title: const Text(
                'Choose File',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1B20),
                ),
              ),
              subtitle: const Text(
                'Select PDF or image file',
                style: TextStyle(
                  color: Color(0xFF49454F),
                  fontSize: 14,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickFile(context);
              },
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromCamera(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        onFileSelected(File(image.path));
      }
    } catch (e) {
      _showError(context, 'Error taking photo: $e');
    }
  }

  Future<void> _pickImageFromGallery(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      
      if (allowMultiple) {
        final List<XFile>? images = await picker.pickMultiImage(
          imageQuality: 80,
          maxWidth: 1920,
          maxHeight: 1080,
        );

        if (images != null && images.isNotEmpty) {
          // For now, just pick the first image
          // TODO: Handle multiple files properly
          onFileSelected(File(images.first.path));
        }
      } else {
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 80,
          maxWidth: 1920,
          maxHeight: 1080,
        );

        if (image != null) {
          onFileSelected(File(image.path));
        }
      }
    } catch (e) {
      _showError(context, 'Error selecting image: $e');
    }
  }

  Future<void> _pickFile(BuildContext context) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: allowMultiple,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          onFileSelected(File(file.path!));
        }
      }
    } catch (e) {
      _showError(context, 'Error selecting file: $e');
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
