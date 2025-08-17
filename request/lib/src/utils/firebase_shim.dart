/// Temporary Firebase shim for incremental migration.
/// Remove after replacing all Firestore & FirebaseAuth usages.

class Timestamp {
  final DateTime _value;
  Timestamp.fromDate(DateTime dt) : _value = dt;
  DateTime toDate() => _value;
  @override
  String toString() => 'Timestamp($_value)';
}

class FieldValue {
  static dynamic serverTimestamp() => DateTime.now();
  static dynamic delete() => _DeleteMarker();
}

// ---- Minimal Firestore-like stubs (no-op implementations) ----
class DocumentSnapshot {
  final String id;
  final Map<String, dynamic> _data;
  DocumentSnapshot(this.id, [Map<String, dynamic>? data]) : _data = data ?? {};
  Map<String, dynamic> data() => _data;
}

class QuerySnapshot {
  final List<DocumentSnapshot> docs;
  QuerySnapshot(this.docs);
}

class _CollectionRef {
  final String path;
  _CollectionRef(this.path);
  _CollectionRef where(String field, {dynamic isEqualTo}) => this;
  _CollectionRef limit(int n) => this;
  Future<QuerySnapshot> get() async => QuerySnapshot(const []);
  _DocRef doc([String? id]) => _DocRef(id ?? 'placeholder');
}

class _DocRef {
  final String id;
  _DocRef(this.id);
  Future<DocumentSnapshot> get() async => DocumentSnapshot(id);
  Future<void> update(Map<String, dynamic> data) async {}
  Future<void> set(Map<String, dynamic> data, {bool merge = false}) async {}
}

class FirebaseFirestore {
  FirebaseFirestore._();
  static final FirebaseFirestore instance = FirebaseFirestore._();
  _CollectionRef collection(String path) => _CollectionRef(path);
}

// ---- Minimal Storage stubs ----
class FirebaseStorage {
  FirebaseStorage._();
  static final FirebaseStorage instance = FirebaseStorage._();
  _StorageRef ref([String? path]) => _StorageRef(path ?? '');
}

class _StorageRef {
  final String path;
  _StorageRef(this.path);
  _StorageRef child(String childPath) => _StorageRef('$path/$childPath');
  Future<_UploadTask> putData(List<int> bytes, [dynamic metadata]) async =>
      _UploadTask();
  Future<String> getDownloadURL() async => 'https://example.com/file.jpg';
}

class _UploadTask {
  Future<void> whenComplete(Function() fn) async => fn();
}

class _DeleteMarker {
  @override
  String toString() => 'FieldValue.delete()';
}

DateTime? parseLegacyDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is Timestamp) return v.toDate();
  if (v is String) {
    try {
      return DateTime.parse(v);
    } catch (_) {
      return null;
    }
  }
  return null;
}

class LegacyUserLike {
  final String uid;
  final String? email;
  final String? phoneNumber;
  LegacyUserLike(this.uid, {this.email, this.phoneNumber});
}

LegacyUserLike? mapRestUser(dynamic u) {
  if (u == null) return null;
  try {
    final id = (u.id ?? u.uid).toString();
    return LegacyUserLike(id,
        email: u.email?.toString(), phoneNumber: u.phone?.toString());
  } catch (_) {
    return null;
  }
}
