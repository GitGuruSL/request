import 'dart:io';

class FileUploadService {
  // Generic file upload (renamed internal to avoid static alias clash if needed later)
  Future<String> uploadFile(File file, {String? path}) async => _fakeUrl(path);
  Future<String> uploadImageFile(File file, {String? path}) async =>
      _fakeUrl(path);
  static Future<String> uploadImage(File file, {String? path}) async =>
      FileUploadService()
          .uploadImageFile(file, path: path); // legacy static usage

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
  static Future<String> legacyUploadImage(File file, {String? path}) async =>
      FileUploadService().uploadImageFile(file, path: path); // legacy alias

  static String _fakeUrl(String? path) =>
      'https://example.com/uploads/${path ?? 'file'}_${DateTime.now().millisecondsSinceEpoch}.jpg';
}
