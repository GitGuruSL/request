import '../services/category_service.dart';

class CategoryData {
  static final CategoryService _categoryService = CategoryService();
  
  // Cache for categories to avoid repeated Firestore calls
  static Map<String, Map<String, List<String>>> _cachedCategories = {};
  static DateTime? _lastFetchTime;
  static const Duration _cacheValidityDuration = Duration(minutes: 10);

  /// Get categories from Firestore with caching (simplified structure)
  static Future<Map<String, List<String>>> getCategoriesForType(String type) async {
    // Check cache validity
    if (_lastFetchTime != null &&
        DateTime.now().difference(_lastFetchTime!) < _cacheValidityDuration &&
        _cachedCategories.containsKey(type)) {
      print('📦 CategoryData: Using cached categories for type $type');
      return _cachedCategories[type]!;
    }

    try {
      print('🔄 CategoryData: Fetching fresh categories for type $type');
      
      // First, let's debug what's in the database
      await _categoryService.debugAllCategories();
      
      // Fetch fresh data from Firestore using the simplified structure
      final hierarchy = await _categoryService.getCategoriesHierarchyForType(type);
      
      print('📈 CategoryData: Received hierarchy with ${hierarchy.length} categories');
      hierarchy.forEach((category, subcategories) {
        print('   📂 $category: ${subcategories.length} subcategories');
      });
      
      // Update cache
      _cachedCategories[type] = hierarchy;
      _lastFetchTime = DateTime.now();
      
      return hierarchy;
    } catch (e) {
      print('❌ CategoryData Error fetching categories for type $type: $e');
      print('   Stack trace: ${StackTrace.current}');
      
      // Fallback to hardcoded categories if Firestore fails
      return _getHardcodedCategoriesForType(type);
    }
  }

  /// Fallback hardcoded categories (kept for offline support)
  static Map<String, List<String>> _getHardcodedCategoriesForType(String type) {
    final fallbackCategories = {
      'item': {
        'Electronics': [
          'Mobile Phones',
          'Laptops & Computers',
          'Gaming Consoles',
          'TV & Audio',
          'Cameras',
          'Accessories'
        ],
        'Vehicles': [
          'Cars',
          'Motorcycles',
          'Bicycles',
          'Parts & Accessories',
          'Commercial Vehicles'
        ],
        'Home & Garden': [
          'Tools',
          'Furniture', 
          'Household',
          'Garden',
          'Appliances',
          'Kitchen Items'
        ],
        'Fashion': [
          'Clothing',
          'Shoes',
          'Bags',
          'Jewelry',
          'Accessories'
        ],
        'Sports & Recreation': [
          'Fitness Equipment',
          'Sports Gear',
          'Outdoor Equipment',
          'Books & Media'
        ]
      },
      'service': {
        'Home Services': [
          'Cleaning',
          'Plumbing',
          'Electrical',
          'Carpentry',
          'Painting',
          'Gardening'
        ],
        'Transportation': [
          'Delivery',
          'Moving Services',
          'Taxi/Ride',
          'Vehicle Repair'
        ],
        'Professional Services': [
          'Tutoring',
          'Photography',
          'Design',
          'Writing',
          'Translation'
        ],
        'Personal Services': [
          'Beauty & Wellness',
          'Fitness Training',
          'Pet Care',
          'Childcare'
        ],
        'Technical Services': [
          'Computer Repair',
          'Phone Repair',
          'Software Development',
          'IT Support'
        ]
      }
    };

    return fallbackCategories[type] ?? {};
  }

  /// Get main categories for a type
  static Future<List<String>> getMainCategories(String type) async {
    final categoryMap = await getCategoriesForType(type);
    return categoryMap.keys.toList();
  }

  /// Get subcategories for a main category
  static Future<List<String>> getSubcategories(String type, String mainCategory) async {
    final categoryMap = await getCategoriesForType(type);
    return categoryMap[mainCategory] ?? [];
  }

  /// Check if a category/subcategory combination is valid
  static Future<bool> isValidCategory(String type, String category, String subcategory) async {
    final subcategories = await getSubcategories(type, category);
    return subcategories.contains(subcategory);
  }

  /// Clear cache (useful for refreshing data)
  static void clearCache() {
    _cachedCategories.clear();
    _lastFetchTime = null;
  }

  /// Ensure categories exist in Firestore for a type
  static Future<void> ensureCategoriesExist(String type) async {
    await _categoryService.ensureCategoriesExist(type);
  }

  /// Get all categories with subcategories (for admin/debugging)
  static Future<Map<String, Map<String, List<String>>>> getAllCategoriesWithSubcategories() async {
    final itemCategories = await getCategoriesForType('item');
    final serviceCategories = await getCategoriesForType('service');
    
    return {
      'item': itemCategories,
      'service': serviceCategories,
    };
  }

  /// Refresh categories from Firestore (clears cache and fetches fresh data)
  static Future<Map<String, List<String>>> refreshCategoriesForType(String type) async {
    clearCache();
    return await getCategoriesForType(type);
  }
}
