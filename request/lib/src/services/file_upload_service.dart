import 'dart:io';

class FileUploadService {
  // Generic file upload
  Future<String> uploadFile(File file, {String? path}) async {
    return _fakeUrl(path);
  }

  Future<String> uploadImage(File file, {String? path}) async => _fakeUrl(path);

  Future<String> uploadDriverDocument(
          String userId, File file, String type) async =>
      _fakeUrl('drivers/$userId/$type');
  Future<String> uploadBusinessDocument(
          String userId, File file, String type) async =>
      _fakeUrl('business/$userId/$type');
  Future<String> uploadVehicleImage(
          String userId, File file, int index) async =>
      _fakeUrl('vehicles/$userId/$index');

  static String _fakeUrl(String? path) =>
      'https://example.com/uploads/${path ?? 'file'}_${DateTime.now().millisecondsSinceEpoch}.jpg';
}
