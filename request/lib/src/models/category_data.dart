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

  /// Clear cache to force refresh from Firestore
  static void clearCache() {
    _cachedCategories.clear();
    _lastFetchTime = null;
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
          'Taxi/Ride Services',
          'Courier Services'
        ],
        'Personal Services': [
          'Beauty & Hair',
          'Fitness Training',
          'Tutoring',
          'Photography',
          'Event Planning'
        ],
        'Professional Services': [
          'IT Support',
          'Legal Services',
          'Financial Services',
          'Consulting',
          'Marketing'
        ],
        'Healthcare': [
          'Medical Consultation',
          'Therapy',
          'Wellness',
          'Nutrition'
        ]
      },
      'delivery': {
        'Food & Beverages': [
          'Restaurant Food',
          'Groceries',
          'Beverages',
          'Snacks'
        ],
        'Retail Items': [
          'Clothing',
          'Electronics',
          'Books',
          'General Items'
        ],
        'Documents': [
          'Legal Documents',
          'Business Papers',
          'Personal Documents'
        ],
        'Medical': [
          'Prescriptions',
          'Medical Supplies',
          'Lab Results'
        ]
      }
    };

    return fallbackCategories[type] ?? {};
  }
}
