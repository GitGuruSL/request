import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ImageUploadService {
  static final ImageUploadService _instance = ImageUploadService._internal();
  factory ImageUploadService() => _instance;
  ImageUploadService._internal();

  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Pick multiple images from gallery
  Future<List<XFile>?> pickMultipleImages({int maxImages = 4}) async {
    try {
      final List<XFile> images = await _picker.pickMultipleMedia(
        limit: maxImages,
        imageQuality: 80,
      );
      
      // Filter only images
      final imageFiles = images.where((file) {
        final extension = file.path.split('.').last.toLowerCase();
        return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension);
      }).toList();

      return imageFiles.isNotEmpty ? imageFiles : null;
    } catch (e) {
      print('Error picking images: $e');
      return null;
    }
  }

  // Pick single image from gallery
  Future<XFile?> pickSingleImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      return image;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  // Pick image from camera
  Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      return image;
    } catch (e) {
      print('Error picking image from camera: $e');
      return null;
    }
  }

  // Upload single image to Firebase Storage
  Future<String?> uploadImage(XFile imageFile, String path) async {
    try {
      final String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final Reference ref = _storage.ref().child('$path/$fileName');
      
      late UploadTask uploadTask;
      
      if (kIsWeb) {
        // For web platform
        final bytes = await imageFile.readAsBytes();
        uploadTask = ref.putData(bytes);
      } else {
        // For mobile platforms
        uploadTask = ref.putFile(File(imageFile.path));
      }

      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Upload multiple images to Firebase Storage
  Future<List<String>> uploadMultipleImages(List<XFile> imageFiles, String path) async {
    final List<String> downloadUrls = [];
    
    for (int i = 0; i < imageFiles.length; i++) {
      final String? url = await uploadImage(imageFiles[i], '$path/image_$i');
      if (url != null) {
        downloadUrls.add(url);
      }
    }
    
    return downloadUrls;
  }

  // Delete image from Firebase Storage
  Future<bool> deleteImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  // Delete multiple images
  Future<void> deleteMultipleImages(List<String> imageUrls) async {
    for (final String url in imageUrls) {
      await deleteImage(url);
    }
  }

  // Compress image size (optional utility)
  Future<XFile?> compressImage(XFile imageFile, {int quality = 80}) async {
    try {
      // This is a basic implementation
      // You might want to use packages like flutter_image_compress for better compression
      return imageFile;
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }

  // Show image source selection dialog
  Future<XFile?> showImageSourceDialog(context) async {
    return await showDialog<XFile?>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await pickImageFromCamera();
                  Navigator.pop(context, image);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final image = await pickSingleImage();
                  Navigator.pop(context, image);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
