import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';

class CategoryModel {
  final String id;
  final String category;
  final String type; // 'item' or 'service'

  CategoryModel({
    required this.id,
    required this.category,
    required this.type,
  });

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CategoryModel(
      id: doc.id,
      category: data['category'] ?? '',
      type: data['type'] ?? 'item',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'type': type,
    };
  }
}

class SubcategoryModel {
  final String id;
  final String subcategory;
  final String categoryId;

  SubcategoryModel({
    required this.id,
    required this.subcategory,
    required this.categoryId,
  });

  factory SubcategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubcategoryModel(
      id: doc.id,
      subcategory: data['subcategory'] ?? '',
      categoryId: data['category_id'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subcategory': subcategory,
      'category_id': categoryId,
    };
  }
}

class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Cache for categories
  Map<String, Map<String, List<String>>> _categoriesCache = {};
  bool _isInitialized = false;

  /// Get all categories for a specific type (item or service)
  Future<List<CategoryModel>> getCategoriesForType(String type) async {
    try {
      print('🔍 CategoryService: Fetching categories for type: $type');
      
      final querySnapshot = await _firestore
          .collection('categories')
          .where('type', isEqualTo: type)
          .get();

      print('📊 CategoryService: Found ${querySnapshot.docs.length} categories for type $type');
      
      final categories = querySnapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();
      
      // Sort categories alphabetically
      categories.sort((a, b) => a.category.compareTo(b.category));
          
      print('✅ CategoryService: Successfully parsed ${categories.length} categories');
      for (final category in categories) {
        print('   - ${category.category} (ID: ${category.id})');
      }
      
      return categories;
    } catch (e) {
      print('❌ CategoryService Error fetching categories for type $type: $e');
      print('   Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  /// Get subcategories for a specific category ID
  Future<List<SubcategoryModel>> getSubcategoriesForCategory(String categoryId) async {
    try {
      print('🔍 CategoryService: Fetching subcategories for category ID: $categoryId');
      
      final querySnapshot = await _firestore
          .collection('subcategories')
          .where('category_id', isEqualTo: categoryId)
          .get();

      print('📊 CategoryService: Found ${querySnapshot.docs.length} subcategories for category $categoryId');
      
      final subcategories = querySnapshot.docs
          .map((doc) => SubcategoryModel.fromFirestore(doc))
          .toList();
      
      // Sort subcategories alphabetically  
      subcategories.sort((a, b) => a.subcategory.compareTo(b.subcategory));
          
      print('✅ CategoryService: Successfully parsed ${subcategories.length} subcategories');
      for (final subcategory in subcategories) {
        print('   - ${subcategory.subcategory} (ID: ${subcategory.id})');
      }

      return subcategories;
    } catch (e) {
      print('❌ CategoryService Error fetching subcategories for category $categoryId: $e');
      print('   Stack trace: ${StackTrace.current}');
      return [];
    }
  }

  /// Get categories and subcategories in a hierarchical structure
  Future<Map<String, List<String>>> getCategoriesHierarchyForType(String type) async {
    try {
      print('🔄 CategoryService: Fetching categories hierarchy for type $type');
      
      // First, let's debug what's in the database
      await debugAllCategories();
      
      // Get categories for the type
      final categories = await getCategoriesForType(type);
      final Map<String, List<String>> hierarchy = {};

      // For each category, get its subcategories
      for (final category in categories) {
        final subcategories = await getSubcategoriesForCategory(category.id);
        hierarchy[category.category] = subcategories.map((sub) => sub.subcategory).toList();
      }

      print('📈 CategoryService: Received hierarchy with ${hierarchy.length} categories');
      hierarchy.forEach((category, subcategories) {
        print('   📂 $category: ${subcategories.length} subcategories');
      });

      return hierarchy;
    } catch (e) {
      print('❌ CategoryService Error fetching categories hierarchy for type $type: $e');
      print('   Stack trace: ${StackTrace.current}');
      return {};
    }
  }

  // Get item categories (backward compatibility)
  Future<List<Category>> getItemCategories() async {
    final hierarchy = await getCategoriesHierarchyForType('item');
    return _convertHierarchyToCategories(hierarchy);
  }

  // Get service categories (backward compatibility)
  Future<List<Category>> getServiceCategories() async {
    final hierarchy = await getCategoriesHierarchyForType('service');
    return _convertHierarchyToCategories(hierarchy);
  }

  // Get delivery categories (backward compatibility)
  Future<List<Category>> getDeliveryCategories() async {
    final hierarchy = await getCategoriesHierarchyForType('delivery');
    return _convertHierarchyToCategories(hierarchy);
  }

  // Helper method to convert hierarchy to Category objects
  List<Category> _convertHierarchyToCategories(Map<String, List<String>> hierarchy) {
    List<Category> categories = [];
    int order = 1;
    
    hierarchy.forEach((categoryName, subcategoryNames) {
      List<SubCategory> subCategories = [];
      int subOrder = 1;
      
      for (String subName in subcategoryNames) {
        subCategories.add(SubCategory(
          id: '${categoryName}_${subName}'.toLowerCase().replaceAll(' ', '_'),
          name: subName,
          order: subOrder++,
        ));
      }
      
      categories.add(Category(
        id: categoryName.toLowerCase().replaceAll(' ', '_'),
        name: categoryName,
        type: 'item', // Default type
        order: order++,
        subCategories: subCategories,
      ));
    });
    
    return categories;
  }

  /// Check if categories exist for a type, if not return empty
  Future<void> ensureCategoriesExist(String type) async {
    try {
      final existingCategories = await getCategoriesForType(type);
      
      if (existingCategories.isEmpty) {
        print('No categories found for type $type in Firestore. Please import categories from admin panel.');
      }
    } catch (e) {
      print('Error checking categories for type $type: $e');
    }
  }

  /// Get all categories (for admin purposes)
  Future<List<CategoryModel>> getAllCategories() async {
    try {
      final querySnapshot = await _firestore
          .collection('categories')
          .get();

      return querySnapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching all categories: $e');
      return [];
    }
  }

  /// Get all subcategories (for admin purposes)
  Future<List<SubcategoryModel>> getAllSubcategories() async {
    try {
      final querySnapshot = await _firestore
          .collection('subcategories')
          .get();

      return querySnapshot.docs
          .map((doc) => SubcategoryModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching all subcategories: $e');
      return [];
    }
  }

  /// Debug method to check all categories in database
  Future<void> debugAllCategories() async {
    try {
      print('🔍 DEBUG: Checking all categories in database...');
      
      final querySnapshot = await _firestore.collection('categories').get();
      print('📊 DEBUG: Total categories in database: ${querySnapshot.docs.length}');
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        print('   📁 Category: ${data['category']} (Type: ${data['type']}, ID: ${doc.id})');
      }
      
      print('🔍 DEBUG: Checking all subcategories in database...');
      final subQuerySnapshot = await _firestore.collection('subcategories').get();
      print('📊 DEBUG: Total subcategories in database: ${subQuerySnapshot.docs.length}');
      
      for (final doc in subQuerySnapshot.docs) {
        final data = doc.data();
        print('   📁 Subcategory: ${data['subcategory']} (Category ID: ${data['category_id']}, ID: ${doc.id})');
      }
      
    } catch (e) {
      print('❌ DEBUG Error: $e');
      print('   Stack trace: ${StackTrace.current}');
    }
  }

  // Clear cache to force refresh
  void clearCache() {
    _categoriesCache.clear();
    _isInitialized = false;
  }

  // Default categories as fallback
  Map<String, List<String>> _getDefaultCategories(String type) {
    switch (type) {
      case 'item':
        return {
          'Electronics': ['Mobile Phones', 'Laptops & Computers', 'Gaming Consoles', 'TV & Audio', 'Cameras', 'Accessories'],
          'Clothing & Fashion': ['Clothing', 'Shoes', 'Bags', 'Jewelry', 'Accessories'],
          'Home & Garden': ['Furniture', 'Appliances', 'Garden', 'Kitchen Items', 'Home Decor'],
          'Sports & Outdoors': ['Sports Equipment', 'Fitness Gear', 'Outdoor Equipment', 'Exercise'],
          'Books & Media': ['Books', 'Movies', 'Music', 'Games'],
          'Automotive': ['Cars', 'Motorcycles', 'Parts', 'Accessories'],
        };
      case 'service':
        return {
          'Home Services': ['Cleaning', 'Plumbing', 'Electrical', 'Carpentry', 'Painting', 'Gardening'],
          'Personal Services': ['Beauty', 'Fitness Training', 'Tutoring', 'Photography', 'Event Planning'],
          'Professional Services': ['IT Support', 'Legal', 'Financial', 'Consulting', 'Marketing'],
          'Transportation': ['Delivery', 'Moving', 'Taxi Service', 'Courier'],
        };
      case 'delivery':
        return {
          'Food & Beverages': ['Restaurant Food', 'Groceries', 'Beverages', 'Snacks'],
          'Retail Items': ['Clothing', 'Electronics', 'Books', 'General Items'],
          'Documents': ['Legal Documents', 'Business Papers', 'Personal Documents'],
          'Medical': ['Prescriptions', 'Medical Supplies', 'Lab Results'],
        };
      default:
        return {};
    }
  }
}
