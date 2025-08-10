import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload driver document to Firebase Storage
  Future<String> uploadDriverDocument(
    String userId,
    String fileName,
    File file,
  ) async {
    try {
      final ref = _storage
          .ref()
          .child('driver_documents')
          .child(userId)
          .child(fileName);

      final uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: _getContentType(fileName),
          customMetadata: {
            'uploadedBy': userId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }

  /// Upload business document to Firebase Storage
  Future<String> uploadBusinessDocument(
    String businessId,
    String fileName,
    File file,
  ) async {
    try {
      final ref = _storage
          .ref()
          .child('business_documents')
          .child(businessId)
          .child(fileName);

      final uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: _getContentType(fileName),
          customMetadata: {
            'uploadedBy': businessId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload document: $e');
    }
  }

  /// Upload product image to Firebase Storage
  Future<String> uploadProductImage(
    String productId,
    String fileName,
    File file,
  ) async {
    try {
      final ref = _storage
          .ref()
          .child('product_images')
          .child(productId)
          .child(fileName);

      final uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: _getContentType(fileName),
          customMetadata: {
            'productId': productId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Upload user profile image
  Future<String> uploadProfileImage(
    String userId,
    String fileName,
    File file,
  ) async {
    try {
      final ref = _storage
          .ref()
          .child('profile_images')
          .child(userId)
          .child(fileName);

      final uploadTask = ref.putFile(
        file,
        SettableMetadata(
          contentType: _getContentType(fileName),
          customMetadata: {
            'userId': userId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );

      final snapshot = await uploadTask.whenComplete(() {});
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload profile image: $e');
    }
  }

  /// Delete file from Firebase Storage
  Future<void> deleteFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  /// Get all files in a directory
  Future<List<Reference>> getFilesInDirectory(String path) async {
    try {
      final ref = _storage.ref().child(path);
      final listResult = await ref.listAll();
      return listResult.items;
    } catch (e) {
      throw Exception('Failed to list files: $e');
    }
  }

  /// Get download URL for a file
  Future<String> getDownloadUrl(String path) async {
    try {
      final ref = _storage.ref().child(path);
      return await ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to get download URL: $e');
    }
  }

  /// Get content type based on file extension
  String _getContentType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  /// Generate unique filename
  String generateFileName(String originalName, String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = originalName.split('.').last;
    return '${userId}_${timestamp}.$extension';
  }

  /// Get file size in bytes
  Future<int> getFileSize(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      final metadata = await ref.getMetadata();
      return metadata.size ?? 0;
    } catch (e) {
      throw Exception('Failed to get file size: $e');
    }
  }

  /// Check if file exists
  Future<bool> fileExists(String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Upload multiple files
  Future<List<String>> uploadMultipleFiles(
    String directory,
    String userId,
    List<File> files,
  ) async {
    final List<String> downloadUrls = [];
    
    for (int i = 0; i < files.length; i++) {
      final fileName = generateFileName('image_$i.jpg', userId);
      try {
        final url = await uploadDriverDocument(userId, fileName, files[i]);
        downloadUrls.add(url);
      } catch (e) {
        // Continue with other files even if one fails
        print('Failed to upload file $i: $e');
      }
    }
    
    return downloadUrls;
  }

  /// Get upload progress (for future implementation)
  Stream<TaskSnapshot> getUploadProgress(UploadTask task) {
    return task.snapshotEvents;
  }
}
