import 'package:cloud_firestore/cloud_firestore.dart';
import 'country_service.dart';

class LegalDocument {
  final String id;
  final String countryCode;
  final String type; // 'privacy' or 'terms'
  final String title;
  final String content;
  final String version;
  final DateTime lastUpdated;
  final bool isActive;

  LegalDocument({
    required this.id,
    required this.countryCode,
    required this.type,
    required this.title,
    required this.content,
    required this.version,
    required this.lastUpdated,
    required this.isActive,
  });

  factory LegalDocument.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LegalDocument(
      id: doc.id,
      countryCode: data['countryCode'] ?? '',
      type: data['type'] ?? '',
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      version: data['version'] ?? '1.0',
      lastUpdated: (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'countryCode': countryCode,
      'type': type,
      'title': title,
      'content': content,
      'version': version,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
      'isActive': isActive,
    };
  }
}

class LegalDocumentsService {
  static final LegalDocumentsService _instance = LegalDocumentsService._internal();
  factory LegalDocumentsService() => _instance;
  LegalDocumentsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CountryService _countryService = CountryService.instance;

  // Collection reference
  CollectionReference get _collection => _firestore.collection('legal_documents');

  // Get privacy policy for current user's country
  Future<LegalDocument?> getPrivacyPolicy({String? countryCode}) async {
    final userCountryCode = countryCode ?? _countryService.countryCode ?? 'LK';
    
    try {
      final QuerySnapshot snapshot = await _collection
          .where('type', isEqualTo: 'privacy')
          .where('countryCode', isEqualTo: userCountryCode)
          .where('isActive', isEqualTo: true)
          .orderBy('lastUpdated', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return LegalDocument.fromFirestore(snapshot.docs.first);
      }

      // Fallback to default/global privacy policy if country-specific not found
      final fallbackSnapshot = await _collection
          .where('type', isEqualTo: 'privacy')
          .where('countryCode', isEqualTo: 'GLOBAL')
          .where('isActive', isEqualTo: true)
          .orderBy('lastUpdated', descending: true)
          .limit(1)
          .get();

      if (fallbackSnapshot.docs.isNotEmpty) {
        return LegalDocument.fromFirestore(fallbackSnapshot.docs.first);
      }

      return null;
    } catch (e) {
      print('Error fetching privacy policy: $e');
      return null;
    }
  }

  // Get terms and conditions for current user's country
  Future<LegalDocument?> getTermsAndConditions({String? countryCode}) async {
    final userCountryCode = countryCode ?? _countryService.countryCode ?? 'LK';
    
    try {
      final QuerySnapshot snapshot = await _collection
          .where('type', isEqualTo: 'terms')
          .where('countryCode', isEqualTo: userCountryCode)
          .where('isActive', isEqualTo: true)
          .orderBy('lastUpdated', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return LegalDocument.fromFirestore(snapshot.docs.first);
      }

      // Fallback to default/global terms if country-specific not found
      final fallbackSnapshot = await _collection
          .where('type', isEqualTo: 'terms')
          .where('countryCode', isEqualTo: 'GLOBAL')
          .where('isActive', isEqualTo: true)
          .orderBy('lastUpdated', descending: true)
          .limit(1)
          .get();

      if (fallbackSnapshot.docs.isNotEmpty) {
        return LegalDocument.fromFirestore(fallbackSnapshot.docs.first);
      }

      return null;
    } catch (e) {
      print('Error fetching terms and conditions: $e');
      return null;
    }
  }

  // Get both privacy policy and terms for a country
  Future<Map<String, LegalDocument?>> getLegalDocuments({String? countryCode}) async {
    final futures = await Future.wait([
      getPrivacyPolicy(countryCode: countryCode),
      getTermsAndConditions(countryCode: countryCode),
    ]);

    return {
      'privacy': futures[0],
      'terms': futures[1],
    };
  }

  // Get all legal documents for admin (country-specific)
  Future<List<LegalDocument>> getAllDocuments({String? countryCode}) async {
    try {
      Query query = _collection.orderBy('lastUpdated', descending: true);
      
      if (countryCode != null) {
        query = query.where('countryCode', isEqualTo: countryCode);
      }

      final QuerySnapshot snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => LegalDocument.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching all documents: $e');
      return [];
    }
  }

  // Stream legal documents for real-time updates
  Stream<List<LegalDocument>> streamDocuments({String? countryCode}) {
    Query query = _collection.orderBy('lastUpdated', descending: true);
    
    if (countryCode != null) {
      query = query.where('countryCode', isEqualTo: countryCode);
    }

    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => LegalDocument.fromFirestore(doc)).toList());
  }

  // Check if user needs to accept updated legal documents
  Future<bool> hasUpdatedDocuments({String? countryCode, DateTime? lastAccepted}) async {
    if (lastAccepted == null) return true;

    final docs = await getLegalDocuments(countryCode: countryCode);
    
    for (final doc in docs.values) {
      if (doc != null && doc.lastUpdated.isAfter(lastAccepted)) {
        return true;
      }
    }
    
    return false;
  }

  // Get current legal document versions for tracking user acceptance
  Future<Map<String, String>> getCurrentVersions({String? countryCode}) async {
    final docs = await getLegalDocuments(countryCode: countryCode);
    
    return {
      'privacyVersion': docs['privacy']?.version ?? '1.0',
      'termsVersion': docs['terms']?.version ?? '1.0',
    };
  }

  // Create or update legal document (admin function)
  Future<String?> createOrUpdateDocument(LegalDocument document) async {
    try {
      if (document.id.isEmpty) {
        // Create new document
        final docRef = await _collection.add(document.toFirestore());
        return docRef.id;
      } else {
        // Update existing document
        await _collection.doc(document.id).update(document.toFirestore());
        return document.id;
      }
    } catch (e) {
      print('Error creating/updating document: $e');
      return null;
    }
  }

  // Delete legal document (admin function)
  Future<bool> deleteDocument(String documentId) async {
    try {
      await _collection.doc(documentId).delete();
      return true;
    } catch (e) {
      print('Error deleting document: $e');
      return false;
    }
  }

  // Get countries with legal documents
  Future<List<String>> getCountriesWithDocuments() async {
    try {
      final QuerySnapshot snapshot = await _collection.get();
      final Set<String> countries = {};
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final countryCode = data['countryCode'] as String?;
        if (countryCode != null) {
          countries.add(countryCode);
        }
      }
      
      return countries.toList()..sort();
    } catch (e) {
      print('Error fetching countries with documents: $e');
      return [];
    }
  }
}
