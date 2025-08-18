import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class ImageUploadService {
  final ImagePicker _picker = ImagePicker();
  
  // For development - use local backend
  static const String _baseUrl = 'http://localhost:3001';

  Future<List<XFile>?> pickMultipleImages({int maxImages = 5}) async {
    try {
      final images = await _picker.pickMultiImage();
      if (images.length > maxImages) {
        return images.take(maxImages).toList();
      }
      return images;
    } catch (_) {
      return null;
    }
  }

  Future<String?> uploadImage(XFile file, String uploadPath) async {
    try {
      final bytes = await file.readAsBytes();
      final fileName = path.basename(file.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueFileName = '${timestamp}_$fileName';
      
      // Create multipart request
      final uri = Uri.parse('$_baseUrl/api/upload');
      final request = http.MultipartRequest('POST', uri);
      
      // Add file
      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: uniqueFileName,
        ),
      );
      
      // Add upload path
      request.fields['path'] = uploadPath;
      
      final response = await request.send();
      
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = jsonDecode(responseBody);
        return data['url'] as String?;
      } else {
        print('Image upload failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error uploading image: $e');
      // Fallback to local file path for development
      return 'file://${file.path}';
    }
  }

  Future<void> deleteImage(String url) async {
    try {
      if (url.startsWith('http')) {
        await http.delete(
          Uri.parse('$_baseUrl/api/upload'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'url': url}),
        );
      }
    } catch (e) {
      print('Error deleting image: $e');
    }
  }
}
