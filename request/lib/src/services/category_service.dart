import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';

class CategoryService {
  static final CategoryService _instance = CategoryService._internal();
  factory CategoryService() => _instance;
  CategoryService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Cache for categories
  Map<String, List<Category>> _categoriesCache = {};
  bool _isInitialized = false;

  // Get categories by type (item, service, delivery, etc.)
  Future<List<Category>> getCategoriesByType(String type) async {
    try {
      if (_categoriesCache.containsKey(type) && _isInitialized) {
        return _categoriesCache[type]!;
      }

      final querySnapshot = await _firestore
          .collection('product_categories')
          .where('type', isEqualTo: type)
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      final categories = querySnapshot.docs
          .map((doc) => Category.fromFirestore(doc))
          .toList();

      _categoriesCache[type] = categories;
      _isInitialized = true;

      return categories;
    } catch (e) {
      print('Error fetching categories for type $type: $e');
      return _getDefaultCategories(type);
    }
  }

  // Get item categories
  Future<List<Category>> getItemCategories() async {
    return getCategoriesByType('item');
  }

  // Get service categories
  Future<List<Category>> getServiceCategories() async {
    return getCategoriesByType('service');
  }

  // Get delivery categories
  Future<List<Category>> getDeliveryCategories() async {
    return getCategoriesByType('delivery');
  }

  // Get all categories
  Future<Map<String, List<Category>>> getAllCategories() async {
    try {
      final querySnapshot = await _firestore
          .collection('categories')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .get();

      final categories = querySnapshot.docs
          .map((doc) => Category.fromFirestore(doc))
          .toList();

      // Group by type
      final Map<String, List<Category>> groupedCategories = {};
      for (final category in categories) {
        if (!groupedCategories.containsKey(category.type)) {
          groupedCategories[category.type] = [];
        }
        groupedCategories[category.type]!.add(category);
      }

      _categoriesCache = groupedCategories;
      _isInitialized = true;

      return groupedCategories;
    } catch (e) {
      print('Error fetching all categories: $e');
      return {
        'item': _getDefaultCategories('item'),
        'service': _getDefaultCategories('service'),
        'delivery': _getDefaultCategories('delivery'),
      };
    }
  }

  // Clear cache to force refresh
  void clearCache() {
    _categoriesCache.clear();
    _isInitialized = false;
  }

  // Listen to category changes
  Stream<List<Category>> listenToCategoriesByType(String type) {
    return _firestore
        .collection('categories')
        .where('type', isEqualTo: type)
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Category.fromFirestore(doc))
            .toList());
  }

  // Default categories as fallback
  List<Category> _getDefaultCategories(String type) {
    switch (type) {
      case 'item':
        return [
          Category(id: '1', name: 'Electronics', type: 'item', order: 1),
          Category(id: '2', name: 'Clothing & Fashion', type: 'item', order: 2),
          Category(id: '3', name: 'Home & Garden', type: 'item', order: 3),
          Category(id: '4', name: 'Sports & Outdoors', type: 'item', order: 4),
          Category(id: '5', name: 'Books & Media', type: 'item', order: 5),
          Category(id: '6', name: 'Automotive', type: 'item', order: 6),
          Category(id: '7', name: 'Health & Beauty', type: 'item', order: 7),
          Category(id: '8', name: 'Toys & Games', type: 'item', order: 8),
          Category(id: '9', name: 'Other', type: 'item', order: 9),
        ];
      case 'service':
        return [
          Category(id: '1', name: 'Home Services', type: 'service', order: 1),
          Category(id: '2', name: 'Professional Services', type: 'service', order: 2),
          Category(id: '3', name: 'Personal Care', type: 'service', order: 3),
          Category(id: '4', name: 'Education & Training', type: 'service', order: 4),
          Category(id: '5', name: 'Health & Wellness', type: 'service', order: 5),
          Category(id: '6', name: 'Business Services', type: 'service', order: 6),
          Category(id: '7', name: 'Creative Services', type: 'service', order: 7),
          Category(id: '8', name: 'Event Services', type: 'service', order: 8),
          Category(id: '9', name: 'Other Services', type: 'service', order: 9),
        ];
      case 'delivery':
        return [
          Category(id: '1', name: 'Food & Beverages', type: 'delivery', order: 1),
          Category(id: '2', name: 'Documents & Papers', type: 'delivery', order: 2),
          Category(id: '3', name: 'Packages & Parcels', type: 'delivery', order: 3),
          Category(id: '4', name: 'Groceries & Shopping', type: 'delivery', order: 4),
          Category(id: '5', name: 'Medicine & Healthcare', type: 'delivery', order: 5),
          Category(id: '6', name: 'Furniture & Large Items', type: 'delivery', order: 6),
          Category(id: '7', name: 'Electronics & Fragile', type: 'delivery', order: 7),
          Category(id: '8', name: 'Other Delivery', type: 'delivery', order: 8),
        ];
      default:
        return [];
    }
  }
}
