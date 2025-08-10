import 'package:cloud_firestore/cloud_firestore.dart';

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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      // Get categories for the type
      final categories = await getCategoriesForType(type);
      final Map<String, List<String>> hierarchy = {};

      // For each category, get its subcategories
      for (final category in categories) {
        final subcategories = await getSubcategoriesForCategory(category.id);
        hierarchy[category.category] = subcategories.map((sub) => sub.subcategory).toList();
      }

      return hierarchy;
    } catch (e) {
      print('Error fetching categories hierarchy for type $type: $e');
      return {};
    }
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
}
