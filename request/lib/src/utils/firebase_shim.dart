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
