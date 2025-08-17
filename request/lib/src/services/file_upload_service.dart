import 'dart:io';

class FileUploadService {
  // Generic file upload (renamed internal to avoid static alias clash if needed later)
  Future<String> uploadFile(File file, {String? path}) async => _fakeUrl(path);
  Future<String> uploadImageFile(File file, {String? path}) async =>
      _fakeUrl(path);
  static Future<String> uploadImage({
    File? file,
    File? imageFile,
    String? path,
    String? fileName, // ignored in stub
  }) async =>
      FileUploadService()
          .uploadImageFile(imageFile ?? file ?? File('placeholder'), // ignored
              path: path); // legacy static usage

  Future<String> uploadDriverDocument(
          String userId, File file, String type) async =>
      _fakeUrl('drivers/$userId/$type');
  Future<String> uploadBusinessDocument(
          String userId, File file, String type) async =>
      _fakeUrl('business/$userId/$type');
  Future<String> uploadVehicleImage(
          String userId, File file, int index) async =>
      _fakeUrl('vehicles/$userId/$index');

  // Legacy static helper alias (screens expecting static call). Name adjusted to avoid clash.
  static Future<String> legacyUploadImage({
    File? file,
    File? imageFile,
    String? path,
    String? fileName,
  }) async =>
      FileUploadService().uploadImageFile(
          imageFile ?? file ?? File('placeholder'),
          path: path); // legacy alias

  static String _fakeUrl(String? path) =>
      'https://example.com/uploads/${path ?? 'file'}_${DateTime.now().millisecondsSinceEpoch}.jpg';
}
