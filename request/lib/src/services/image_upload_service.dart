import 'package:image_picker/image_picker.dart';

class ImageUploadService {
  final ImagePicker _picker = ImagePicker();

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

  Future<String?> uploadImage(XFile file, String path) async {
    return 'https://example.com/images/$path.jpg';
  }

  Future<void> deleteImage(String url) async {
    // no-op stub
  }
}
