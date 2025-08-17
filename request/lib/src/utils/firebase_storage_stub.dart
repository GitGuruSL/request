// Generated stub to replace firebase_storage during migration.
class FirebaseStorage {
  FirebaseStorage._();
  static final FirebaseStorage instance = FirebaseStorage._();
  Reference ref([String? path]) => Reference(path ?? '');
}

class Reference {
  final String path;
  Reference(this.path);
  Reference child(String childPath) => Reference('$path/$childPath');
  UploadTask putFile(dynamic file, [dynamic metadata]) => UploadTask();
  Future<String> getDownloadURL() async => 'https://example.com/file.jpg';
}

class UploadTask {
  Reference get ref => Reference('');
  Future<void> whenComplete(Function() fn) async => fn();
}
