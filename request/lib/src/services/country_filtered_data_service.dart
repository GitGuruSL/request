import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/request_model.dart';
import '../models/price_listing.dart';
import '../models/enhanced_user_model.dart';
import 'country_service.dart';

/// Centralized Country-Based Data Filtering Service for Flutter App
/// Ensures all data queries are filtered by user's registered country
class CountryFilteredDataService {
  static const String _tag = 'CountryFilteredDataService';
  
  static CountryFilteredDataService? _instance;
  static CountryFilteredDataService get instance => _instance ??= CountryFilteredDataService._();
  
  CountryFilteredDataService._();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CountryService _countryService = CountryService.instance;
  
  /// Get current user's country code
  String? get userCountry => _countryService.countryCode;
  String? get userCountryName => _countryService.countryName;
  
  /// Validate user has country set
  void _validateUserCountry() {
    if (userCountry == null || userCountryName == null) {
      throw Exception('User country not set. Please select country in welcome screen.');
    }
  }
  
  // ==================== REQUESTS ====================
  
  /// Get requests filtered by user's country
  Stream<List<RequestModel>> getCountryRequestsStream({
    String? status,
    String? category,
    RequestType? type,
    int limit = 50,
  }) {
    _validateUserCountry();
    
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('requests')
          .where('country', isEqualTo: userCountry);
      
      // Apply additional filters
      if (status != null && status.isNotEmpty) {
        query = query.where('status', isEqualTo: status);
      }
      
      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }
      
      if (type != null) {
        query = query.where('type', isEqualTo: type.name);
      }
      
      query = query
          .orderBy('createdAt', descending: true)
          .limit(limit);
      
      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return RequestModel.fromMap(data);
        }).toList();
      });
    } catch (e) {
      print('$_tag Error in getCountryRequestsStream: $e');
      rethrow;
    }
  }
  
  /// Get single request by ID (with country validation)
  Future<RequestModel?> getRequestById(String requestId) async {
    _validateUserCountry();
    
    try {
      final doc = await _firestore.collection('requests').doc(requestId).get();
      
      if (!doc.exists) return null;
      
      final data = doc.data()!;
      data['id'] = doc.id; // Add document ID
      final request = RequestModel.fromMap(data);
      
      // Validate request belongs to user's country
      if (request.country != userCountry) {
        print('$_tag Access denied: Request from different country');
        return null;
      }
      
      return request;
    } catch (e) {
      print('$_tag Error getting request by ID: $e');
      return null;
    }
  }
  
  /// Get user's own requests
  Stream<List<RequestModel>> getUserRequestsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    _validateUserCountry();
    
    return _firestore
        .collection('requests')
        .where('requesterId', isEqualTo: user.uid)
        .where('country', isEqualTo: userCountry)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id; // Add document ID to the data
        return RequestModel.fromMap(data);
      }).toList();
    });
  }
  
  // ==================== RESPONSES ====================
  
  /// Get responses for a request (country-filtered)
  Stream<List<ResponseModel>> getResponsesForRequestStream(String requestId) {
    _validateUserCountry();
    
    return _firestore
        .collection('responses')
        .where('requestId', isEqualTo: requestId)
        .where('country', isEqualTo: userCountry)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ResponseModel.fromMap(data);
      }).toList();
    });
  }
  
  /// Get user's responses (what they've responded to)
  Stream<List<ResponseModel>> getUserResponsesStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    _validateUserCountry();
    
    return _firestore
        .collection('responses')
        .where('responderId', isEqualTo: user.uid)
        .where('country', isEqualTo: userCountry)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return ResponseModel.fromMap(data);
      }).toList();
    });
  }
  
  // ==================== PRICE LISTINGS ====================
  
  /// Get price listings filtered by country
  Stream<List<PriceListing>> getPriceListingsStream({
    String? category,
    String? businessId,
    bool activeOnly = true,
    int limit = 50,
  }) {
    _validateUserCountry();
    
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('price_listings')
          .where('country', isEqualTo: userCountry);
      
      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }
      
      if (businessId != null && businessId.isNotEmpty) {
        query = query.where('businessId', isEqualTo: businessId);
      }
      
      if (activeOnly) {
        query = query.where('isActive', isEqualTo: true);
      }
      
      query = query
          .orderBy('createdAt', descending: true)
          .limit(limit);
      
      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          return PriceListing.fromFirestore(doc);
        }).toList();
      });
    } catch (e) {
      print('$_tag Error in getPriceListingsStream: $e');
      rethrow;
    }
  }
  
  /// Get business's price listings
  Stream<List<PriceListing>> getBusinessPriceListingsStream(String businessId) {
    _validateUserCountry();
    
    return _firestore
        .collection('price_listings')
        .where('businessId', isEqualTo: businessId)
        .where('country', isEqualTo: userCountry)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PriceListing.fromFirestore(doc);
      }).toList();
    });
  }
  
  // ==================== USERS & BUSINESSES ====================
  
  /// Get businesses in user's country
  Stream<List<Map<String, dynamic>>> getCountryBusinessesStream({
    bool verifiedOnly = true,
    String? category,
    int limit = 50,
  }) {
    _validateUserCountry();
    
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('new_business_verifications')
          .where('country', isEqualTo: userCountry);
      
      if (verifiedOnly) {
        query = query.where('verificationStatus', isEqualTo: 'approved');
      }
      
      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }
      
      query = query
          .orderBy('createdAt', descending: true)
          .limit(limit);
      
      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          return {'id': doc.id, ...doc.data()};
        }).toList();
      });
    } catch (e) {
      print('$_tag Error in getCountryBusinessesStream: $e');
      rethrow;
    }
  }
  
  /// Get drivers in user's country
  Stream<List<Map<String, dynamic>>> getCountryDriversStream({
    bool verifiedOnly = true,
    String? vehicleType,
    int limit = 50,
  }) {
    _validateUserCountry();
    
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('driver_verification')
          .where('country', isEqualTo: userCountry);
      
      if (verifiedOnly) {
        query = query.where('verificationStatus', isEqualTo: 'approved');
      }
      
      if (vehicleType != null && vehicleType.isNotEmpty) {
        query = query.where('vehicleType', isEqualTo: vehicleType);
      }
      
      query = query
          .orderBy('createdAt', descending: true)
          .limit(limit);
      
      return query.snapshots().map((snapshot) {
        return snapshot.docs.map((doc) {
          return {'id': doc.id, ...doc.data()};
        }).toList();
      });
    } catch (e) {
      print('$_tag Error in getCountryDriversStream: $e');
      rethrow;
    }
  }
  
  // ==================== VALIDATION & UTILITIES ====================
  
  /// Validate data belongs to user's country before operations
  Future<bool> validateDataCountryAccess(String collection, String documentId) async {
    _validateUserCountry();
    
    try {
      final doc = await _firestore.collection(collection).doc(documentId).get();
      
      if (!doc.exists) return false;
      
      final data = doc.data();
      final dataCountry = data?['country'];
      
      return dataCountry == userCountry;
    } catch (e) {
      print('$_tag Error validating country access: $e');
      return false;
    }
  }
  
  /// Ensure data includes country information when creating
  Map<String, dynamic> addCountryToData(Map<String, dynamic> data) {
    _validateUserCountry();
    
    return {
      ...data,
      'country': userCountry,
      'countryName': userCountryName,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
  
  /// Search within country-filtered data
  Future<List<Map<String, dynamic>>> searchInCountry({
    required String collection,
    required String searchField,
    required String searchTerm,
    int limit = 20,
  }) async {
    _validateUserCountry();
    
    try {
      // Note: Firestore doesn't support full-text search natively
      // This is a simple prefix search
      final query = await _firestore
          .collection(collection)
          .where('country', isEqualTo: userCountry)
          .where(searchField, isGreaterThanOrEqualTo: searchTerm)
          .where(searchField, isLessThanOrEqualTo: searchTerm + '\\uf8ff')
          .limit(limit)
          .get();
      
      return query.docs.map((doc) {
        return {'id': doc.id, ...doc.data()};
      }).toList();
    } catch (e) {
      print('$_tag Error searching in country: $e');
      return [];
    }
  }
  
  /// Get country-specific statistics for user
  Future<Map<String, int>> getCountryStats() async {
    _validateUserCountry();
    
    try {
      final futures = await Future.wait([
        _firestore.collection('requests').where('country', isEqualTo: userCountry).get(),
        _firestore.collection('responses').where('country', isEqualTo: userCountry).get(),
        _firestore.collection('price_listings').where('country', isEqualTo: userCountry).get(),
        _firestore.collection('new_business_verifications')
            .where('country', isEqualTo: userCountry)
            .where('verificationStatus', isEqualTo: 'approved')
            .get(),
        _firestore.collection('driver_verification')
            .where('country', isEqualTo: userCountry)
            .where('verificationStatus', isEqualTo: 'approved')
            .get(),
      ]);
      
      return {
        'requests': futures[0].docs.length,
        'responses': futures[1].docs.length,
        'priceListings': futures[2].docs.length,
        'businesses': futures[3].docs.length,
        'drivers': futures[4].docs.length,
      };
    } catch (e) {
      print('$_tag Error getting country stats: $e');
      return {};
    }
  }

  // ==================== COUNTRY-SPECIFIC PRODUCTS & CATEGORIES ====================

  /// Get active categories for user's country
  Future<List<Map<String, dynamic>>> getActiveCategories({String? type}) async {
    try {
      // Check if user country is set, fallback to 'LK' for development
      final country = userCountry ?? 'LK';
      print('$_tag getActiveCategories: Using country = $country, type = $type');
      
      // Get all categories
      Query<Map<String, dynamic>> categoriesQuery = _firestore.collection('categories');
      if (type != null) {
        categoriesQuery = categoriesQuery.where('type', isEqualTo: type);
      }
      final categoriesSnapshot = await categoriesQuery.get();
      print('$_tag getActiveCategories: Found ${categoriesSnapshot.docs.length} total categories');
      
      // Get country-specific activations
      final countryActivationsSnapshot = await _firestore
          .collection('country_categories')
          .where('country', isEqualTo: country)
          .get();
      print('$_tag getActiveCategories: Found ${countryActivationsSnapshot.docs.length} activation records');
      
      final countryActivations = <String, bool>{};
      for (final doc in countryActivationsSnapshot.docs) {
        final data = doc.data();
        countryActivations[data['categoryId']] = data['isActive'] ?? false;
      }
      
      // Filter active categories
      final activeCategories = <Map<String, dynamic>>[];
      for (final doc in categoriesSnapshot.docs) {
        final categoryId = doc.id;
        final isActive = countryActivations[categoryId] ?? false; // Now using strict filtering
        
        if (isActive) {
          activeCategories.add({...doc.data(), 'id': categoryId});
        }
      }
      
      print('$_tag getActiveCategories: Returning ${activeCategories.length} active categories');
      return activeCategories;
    } catch (e) {
      print('$_tag Error getting active categories: $e');
      return [];
    }
  }

  /// Get active subcategories for user's country
  Future<List<Map<String, dynamic>>> getActiveSubcategories({String? categoryId}) async {
    try {
      // Check if user country is set, fallback to 'LK' for development
      final country = userCountry ?? 'LK';
      print('$_tag getActiveSubcategories: Using country = $country, categoryId = $categoryId');
      
      // Get country-specific activations first
      final countryActivationsSnapshot = await _firestore
          .collection('country_subcategories')
          .where('country', isEqualTo: country)
          .get();
      print('$_tag getActiveSubcategories: Found ${countryActivationsSnapshot.docs.length} activation records');
      
      final countryActivations = <String, bool>{};
      for (final doc in countryActivationsSnapshot.docs) {
        final data = doc.data();
        countryActivations[data['subcategoryId']] = data['isActive'] ?? false;
      }
      
      // Get the IDs of active subcategories
      final activeSubcategoryIds = countryActivations.entries
          .where((entry) => entry.value == true)
          .map((entry) => entry.key)
          .toList();
      
      print('$_tag getActiveSubcategories: Found ${activeSubcategoryIds.length} active subcategory IDs');
      
      if (activeSubcategoryIds.isEmpty) {
        print('$_tag getActiveSubcategories: No active subcategories found');
        return [];
      }

      // Split IDs into chunks of 30 (Firestore whereIn limit)
      final activeSubcategories = <Map<String, dynamic>>[];
      const int chunkSize = 30;
      
      for (int i = 0; i < activeSubcategoryIds.length; i += chunkSize) {
        final chunk = activeSubcategoryIds.skip(i).take(chunkSize).toList();
        
        print('$_tag getActiveSubcategories: Processing chunk ${(i ~/ chunkSize) + 1} with ${chunk.length} IDs');
        
        // Get subcategories that are active in this country
        Query<Map<String, dynamic>> subcategoriesQuery = _firestore
            .collection('subcategories')
            .where(FieldPath.documentId, whereIn: chunk);
        
        // Apply category filter if specified
        if (categoryId != null) {
          subcategoriesQuery = subcategoriesQuery.where('categoryId', isEqualTo: categoryId);
        }
        
        final subcategoriesSnapshot = await subcategoriesQuery.get();
        print('$_tag getActiveSubcategories: Found ${subcategoriesSnapshot.docs.length} subcategories in chunk ${(i ~/ chunkSize) + 1}');
        
        final chunkSubcategories = subcategoriesSnapshot.docs
            .map((doc) => {...doc.data(), 'id': doc.id})
            .toList();
            
        activeSubcategories.addAll(chunkSubcategories);
      }
      
      print('$_tag getActiveSubcategories: Returning ${activeSubcategories.length} active subcategories');
      return activeSubcategories;
    } catch (e) {
      print('$_tag Error getting active subcategories: $e');
      return [];
    }
  }

  /// Get active products for user's country
  Future<List<Map<String, dynamic>>> getActiveProducts() async {
    try {
      // Check if user country is set, fallback to 'LK' for development
      final country = userCountry ?? 'LK';
      print('$_tag getActiveProducts: Using country = $country');
      
      // Get country-specific activations first
      final countryActivationsSnapshot = await _firestore
          .collection('country_products')
          .where('country', isEqualTo: country)
          .get();
      print('$_tag getActiveProducts: Found ${countryActivationsSnapshot.docs.length} activation records');
      
      final countryActivations = <String, bool>{};
      for (final doc in countryActivationsSnapshot.docs) {
        final data = doc.data();
        countryActivations[data['productId']] = data['isActive'] ?? false;
      }
      
      // Get the IDs of active products
      final activeProductIds = countryActivations.entries
          .where((entry) => entry.value == true)
          .map((entry) => entry.key)
          .toList();
      
      print('$_tag getActiveProducts: Found ${activeProductIds.length} active product IDs');
      
      if (activeProductIds.isEmpty) {
        print('$_tag getActiveProducts: No active products found');
        return [];
      }
      
      // Get products that are active in this country
      final productsQuery = await _firestore
          .collection('master_products')
          .where(FieldPath.documentId, whereIn: activeProductIds)
          .get();
      
      print('$_tag getActiveProducts: Found ${productsQuery.docs.length} active products');
      
      final activeProducts = productsQuery.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
      
      print('$_tag getActiveProducts: Returning ${activeProducts.length} active products');
      return activeProducts;
    } catch (e) {
      print('$_tag Error getting active products: $e');
      return [];
    }
  }

  /// Get active brands for user's country
  Future<List<Map<String, dynamic>>> getActiveBrands() async {
    try {
      // Check if user country is set, fallback to 'LK' for development
      final country = userCountry ?? 'LK';
      print('$_tag getActiveBrands: Using country = $country');
      
      // Get all brands
      final brandsSnapshot = await _firestore.collection('brands').get();
      print('$_tag getActiveBrands: Found ${brandsSnapshot.docs.length} total brands');
      
      // Get country-specific activations
      final countryActivationsSnapshot = await _firestore
          .collection('country_brands')
          .where('country', isEqualTo: country)
          .get();
      print('$_tag getActiveBrands: Found ${countryActivationsSnapshot.docs.length} activation records');
      
      final countryActivations = <String, bool>{};
      for (final doc in countryActivationsSnapshot.docs) {
        final data = doc.data();
        countryActivations[data['brandId']] = data['isActive'] ?? false;
      }
      
      // Filter active brands
      final activeBrands = <Map<String, dynamic>>[];
      for (final doc in brandsSnapshot.docs) {
        final brandId = doc.id;
        final isActive = countryActivations[brandId] ?? false; // Now using strict filtering
        
        if (isActive) {
          activeBrands.add({...doc.data(), 'id': brandId});
        }
      }
      
      print('$_tag getActiveBrands: Returning ${activeBrands.length} active brands');
      return activeBrands;
    } catch (e) {
      print('$_tag Error getting active brands: $e');
      return [];
    }
  }

    /// Get active variable types for user's country
  Future<List<Map<String, dynamic>>> getActiveVariableTypes() async {
    try {
      // Check if user country is set, fallback to 'LK' for development
      final country = userCountry ?? 'LK';
      print('$_tag getActiveVariableTypes: Using country = $country');
      
      // Get all variable types
      final variableTypesSnapshot = await _firestore.collection('variable_types').get();
      print('$_tag getActiveVariableTypes: Found ${variableTypesSnapshot.docs.length} total variable types');
      
      // Get country-specific activations
      final countryActivationsSnapshot = await _firestore
          .collection('country_variable_types')
          .where('country', isEqualTo: country)
          .get();
      print('$_tag getActiveVariableTypes: Found ${countryActivationsSnapshot.docs.length} activation records');
      
      final countryActivations = <String, bool>{};
      for (final doc in countryActivationsSnapshot.docs) {
        final data = doc.data();
        countryActivations[data['variableTypeId']] = data['isActive'] ?? false;
      }
      
      // Filter active variable types
      final activeVariableTypes = <Map<String, dynamic>>[];
      for (final doc in variableTypesSnapshot.docs) {
        final variableTypeId = doc.id;
        final isActive = countryActivations[variableTypeId] ?? false; // Now using strict filtering
        
        if (isActive) {
          activeVariableTypes.add({...doc.data(), 'id': variableTypeId});
        }
      }
      
      print('$_tag getActiveVariableTypes: Returning ${activeVariableTypes.length} active variable types');
      return activeVariableTypes;
    } catch (e) {
      print('$_tag Error getting active variable types: $e');
      return [];
    }
  }
}
