import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class FileUploadService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload an image file to Firebase Storage
  static Future<String?> uploadImage({
    required File imageFile,
    required String path,
    required String fileName,
  }) async {
    try {
      final ref = _storage.ref().child(path).child(fileName);
      final uploadTask = await ref.putFile(imageFile);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  /// Pick an image from gallery or camera
  static Future<File?> pickImage({
    required ImageSource source,
  }) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  /// Upload driver verification documents
  static Future<Map<String, String>> uploadDriverDocuments({
    required String driverId,
    required File licenseImage,
    File? profileImage,
    File? vehicleImage,
  }) async {
    final urls = <String, String>{};
    
    try {
      // Upload license image (required)
      final licenseUrl = await uploadImage(
        imageFile: licenseImage,
        path: 'driver_documents/$driverId',
        fileName: 'license_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      if (licenseUrl != null) {
        urls['licenseUrl'] = licenseUrl;
      }

      // Upload profile image (optional)
      if (profileImage != null) {
        final profileUrl = await uploadImage(
          imageFile: profileImage,
          path: 'driver_documents/$driverId',
          fileName: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        if (profileUrl != null) {
          urls['profileUrl'] = profileUrl;
        }
      }

      // Upload vehicle image (optional)
      if (vehicleImage != null) {
        final vehicleUrl = await uploadImage(
          imageFile: vehicleImage,
          path: 'driver_documents/$driverId',
          fileName: 'vehicle_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        if (vehicleUrl != null) {
          urls['vehicleUrl'] = vehicleUrl;
        }
      }

      return urls;
    } catch (e) {
      print('Error uploading driver documents: $e');
      return {};
    }
  }

  /// Delete a file from Firebase Storage
  static Future<bool> deleteFile(String downloadUrl) async {
    try {
      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      return true;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  /// Upload driver document with specific type
  Future<String> uploadDriverDocument(String userId, File file, String documentType) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${documentType}_$timestamp.jpg';
      final ref = _storage.ref().child('driver_documents/$userId/$fileName');
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading driver document: $e');
      throw e;
    }
  }

  /// Upload vehicle image with index
  Future<String> uploadVehicleImage(String userId, File file, int imageIndex) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'vehicle_image_${imageIndex}_$timestamp.jpg';
      final ref = _storage.ref().child('vehicle_images/$userId/$fileName');
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading vehicle image: $e');
      throw e;
    }
  }

  /// Upload file with custom path
  Future<String> uploadFile(File file, String path) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading file: $e');
      throw e;
    }
  }

  /// Upload business document with specific type
  Future<String> uploadBusinessDocument(String userId, File file, String documentType) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${documentType}_$timestamp.jpg';
      final ref = _storage.ref().child('business_documents/$userId/$fileName');
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading business document: $e');
      throw e;
    }
  }
}
