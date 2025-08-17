/// ContentService & ContentPage placeholders for migrated REST version.
class ContentPage {
  final String id;
  final String slug;
  final String title;
  final String type; // centralized | country_specific
  final String? category;
  final String? targetCountry;
  final String status; // published | draft
  final DateTime updatedAt;
  final Map<String, dynamic>? metadata; // arbitrary extra data
  final String content; // page body / markdown / html

  ContentPage({
    required this.id,
    required this.slug,
    required this.title,
    required this.type,
    this.category,
    this.targetCountry,
    this.status = 'published',
    this.metadata,
    this.content = '',
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();
}

class ContentService {
  ContentService._();
  static final ContentService instance = ContentService._();

  Future<List<ContentPage>> getPages() async {
    // TODO: call REST endpoint when available
    return [];
  }

  Future<ContentPage?> getPageBySlug(String slug) async {
    return null;
  }
}
