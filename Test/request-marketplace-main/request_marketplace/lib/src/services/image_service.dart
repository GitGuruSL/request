import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;

class ImageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Upload multiple images to Firebase Storage for responses
  Future<List<String>> uploadResponseImages(List<File> images, String requestId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    if (images.isEmpty) {
      return [];
    }

    List<String> downloadUrls = [];
    
    for (int i = 0; i < images.length; i++) {
      try {
        final file = images[i];
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i${path.extension(file.path)}';
        final reference = _storage
            .ref()
            .child('response_images')
            .child(user.uid)
            .child(requestId)
            .child(fileName);

        print('📤 ImageService: Uploading image ${i + 1}/${images.length}: $fileName');
        
        // Upload the file
        final uploadTask = reference.putFile(file);
        final snapshot = await uploadTask.whenComplete(() => null);
        
        // Get the download URL
        final downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
        
        print('✅ ImageService: Image uploaded successfully: $downloadUrl');
      } catch (e) {
        print('❌ ImageService: Failed to upload image ${i + 1}: $e');
        // Continue with other images even if one fails
      }
    }
    
    print('🎯 ImageService: Uploaded ${downloadUrls.length}/${images.length} images successfully');
    return downloadUrls;
  }

  /// Upload multiple images to Firebase Storage for requests
  Future<List<String>> uploadRequestImages(List<File> images, String requestId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }

    if (images.isEmpty) {
      return [];
    }

    List<String> downloadUrls = [];
    
    for (int i = 0; i < images.length; i++) {
      try {
        final file = images[i];
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_$i${path.extension(file.path)}';
        final reference = _storage
            .ref()
            .child('request_images')
            .child(user.uid)
            .child(requestId)
            .child(fileName);

        print('📤 ImageService: Uploading request image ${i + 1}/${images.length}: $fileName');
        
        // Upload the file
        final uploadTask = reference.putFile(file);
        final snapshot = await uploadTask.whenComplete(() => null);
        
        // Get the download URL
        final downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
        
        print('✅ ImageService: Request image uploaded successfully: $downloadUrl');
      } catch (e) {
        print('❌ ImageService: Failed to upload request image ${i + 1}: $e');
        // Continue with other images even if one fails
      }
    }
    
    print('🎯 ImageService: Uploaded ${downloadUrls.length}/${images.length} request images successfully');
    return downloadUrls;
  }

  /// Delete images from Firebase Storage
  Future<void> deleteImages(List<String> imageUrls) async {
    for (String url in imageUrls) {
      try {
        final ref = _storage.refFromURL(url);
        await ref.delete();
        print('✅ ImageService: Deleted image: $url');
      } catch (e) {
        print('❌ ImageService: Failed to delete image $url: $e');
      }
    }
  }
}
