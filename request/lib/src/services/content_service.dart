import 'package:cloud_firestore/cloud_firestore.dart';
import 'country_service.dart';

class ContentService {
  static final ContentService _instance = ContentService._internal();
  static ContentService get instance => _instance;
  ContentService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch country-specific and global pages
  Future<List<ContentPage>> getPages() async {
    try {
      final countryCode = CountryService.instance.countryCode?.toUpperCase();
      
      List<ContentPage> pages = [];
      
      // Get global pages that are published or approved
      final globalQuery = await _firestore
          .collection('content_pages')
          .where('type', isEqualTo: 'centralized')
          .where('status', whereIn: ['published', 'approved'])
          .orderBy('createdAt', descending: false)
          .get();
      
      for (var doc in globalQuery.docs) {
        pages.add(ContentPage.fromFirestore(doc));
      }
      
      // Get country-specific pages if country is set
      if (countryCode != null) {
        final countryQuery = await _firestore
            .collection('content_pages')
            .where('type', isEqualTo: 'country_specific')
            .where('targetCountry', isEqualTo: countryCode)
            .where('status', whereIn: ['published', 'approved'])
            .orderBy('createdAt', descending: false)
            .get();
        
        for (var doc in countryQuery.docs) {
          pages.add(ContentPage.fromFirestore(doc));
        }
      }
      
      // Sort by display order and creation date
      pages.sort((a, b) {
        int orderCompare = (a.displayOrder ?? 999).compareTo(b.displayOrder ?? 999);
        if (orderCompare != 0) return orderCompare;
        return a.createdAt.compareTo(b.createdAt);
      });
      
      return pages;
    } catch (e) {
      print('Error fetching content pages: $e');
      return [];
    }
  }

  // Get specific page by slug
  Future<ContentPage?> getPageBySlug(String slug) async {
    try {
      final countryCode = CountryService.instance.countryCode?.toUpperCase();
      
      // Try country-specific first
      if (countryCode != null) {
        final countryQuery = await _firestore
            .collection('content_pages')
            .where('slug', isEqualTo: slug)
            .where('type', isEqualTo: 'country_specific')
            .where('targetCountry', isEqualTo: countryCode)
            .where('status', whereIn: ['published', 'approved'])
            .limit(1)
            .get();
        
        if (countryQuery.docs.isNotEmpty) {
          return ContentPage.fromFirestore(countryQuery.docs.first);
        }
      }
      
      // Try global pages
      final globalQuery = await _firestore
          .collection('content_pages')
          .where('slug', isEqualTo: slug)
          .where('type', isEqualTo: 'centralized')
          .where('status', whereIn: ['published', 'approved'])
          .limit(1)
          .get();
      
      if (globalQuery.docs.isNotEmpty) {
        return ContentPage.fromFirestore(globalQuery.docs.first);
      }
      
      return null;
    } catch (e) {
      print('Error fetching page by slug: $e');
      return null;
    }
  }

  // Get pages by category
  Future<List<ContentPage>> getPagesByCategory(String category) async {
    try {
      final pages = await getPages();
      return pages.where((page) => page.category == category).toList();
    } catch (e) {
      print('Error fetching pages by category: $e');
      return [];
    }
  }
}

class ContentPage {
  final String id;
  final String title;
  final String slug;
  final String content;
  final String category;
  final String type;
  final String? targetCountry;
  final String status;
  final int? displayOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata;

  ContentPage({
    required this.id,
    required this.title,
    required this.slug,
    required this.content,
    required this.category,
    required this.type,
    this.targetCountry,
    required this.status,
    this.displayOrder,
    required this.createdAt,
    required this.updatedAt,
    this.metadata,
  });

  factory ContentPage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ContentPage(
      id: doc.id,
      title: data['title'] ?? '',
      slug: data['slug'] ?? '',
      content: data['content'] ?? '',
      category: data['category'] ?? '',
      type: data['type'] ?? '',
      targetCountry: data['targetCountry'],
      status: data['status'] ?? 'draft',
      displayOrder: data['displayOrder'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'slug': slug,
      'content': content,
      'category': category,
      'type': type,
      'targetCountry': targetCountry,
      'status': status,
      'displayOrder': displayOrder,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }
}
