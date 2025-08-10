// Product Service for managing centralized product system
// Handles AI-powered product addition, business product management, and price comparison

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import '../models/product_models.dart';
import '../models/business_models.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Collection references
  CollectionReference get _categoriesRef => _firestore.collection('product_categories');
  CollectionReference get _masterProductsRef => _firestore.collection('master_products');
  CollectionReference get _businessProductsRef => _firestore.collection('business_products');
  CollectionReference get _clicksRef => _firestore.collection('product_clicks');

  /// Get all product categories (hierarchical)
  Future<List<ProductCategory>> getProductCategories({String? parentId}) async {
    Query query = _categoriesRef
        .where('isActive', isEqualTo: true)
        .orderBy('name');
    
    if (parentId != null) {
      query = query.where('parentCategoryId', isEqualTo: parentId);
    } else {
      query = query.where('parentCategoryId', isNull: true);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => ProductCategory.fromFirestore(doc))
        .toList();
  }

  /// Get category by ID
  Future<ProductCategory?> getCategoryById(String categoryId) async {
    try {
      final doc = await _categoriesRef.doc(categoryId).get();
      if (doc.exists) {
        return ProductCategory.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting category: $e');
      return null;
    }
  }

  /// Get business products by master product ID
  Future<List<BusinessProduct>> getBusinessProductsByMasterProduct(String masterProductId) async {
    try {
      final snapshot = await _businessProductsRef
          .where('masterProductId', isEqualTo: masterProductId)
          .where('isActive', isEqualTo: true)
          .where('available', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => BusinessProduct.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting business products by master product: $e');
      return [];
    }
  }

  /// Search products with price comparison
  Future<List<ProductSearchResult>> searchProducts({
    required String query,
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    String? location,
    int limit = 20,
  }) async {
    try {
      // Build master products query
      Query masterQuery = _masterProductsRef
          .where('isActive', isEqualTo: true);

      if (categoryId != null) {
        masterQuery = masterQuery.where('categoryId', isEqualTo: categoryId);
      }

      // For now, get all and filter locally (in production, use Algolia or similar)
      final masterSnapshot = await masterQuery.limit(limit).get();
      
      List<ProductSearchResult> results = [];

      for (final masterDoc in masterSnapshot.docs) {
        final masterProduct = MasterProduct.fromFirestore(masterDoc);
        
        // Check if product matches search query
        if (!_matchesSearchQuery(masterProduct, query)) continue;

        // Get business listings for this product
        final businessListings = await _getBusinessListingsForProduct(
          masterProduct.id,
          minPrice: minPrice,
          maxPrice: maxPrice,
          location: location,
        );

        if (businessListings.isNotEmpty) {
          // Sort by price (cheapest first)
          businessListings.sort((a, b) => a.price.compareTo(b.price));
          
          final cheapest = businessListings.first;
          final priceRange = businessListings.length > 1 
              ? businessListings.last.price - businessListings.first.price
              : null;

          results.add(ProductSearchResult(
            product: masterProduct,
            businessListings: businessListings,
            cheapestListing: cheapest,
            priceRange: priceRange,
            totalBusinesses: businessListings.length,
          ));
        }
      }

      // Sort results by cheapest price
      results.sort((a, b) => 
          (a.cheapestListing?.price ?? double.infinity).compareTo(
          b.cheapestListing?.price ?? double.infinity));

      return results;
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }

  /// Get business listings for a specific product
  Future<List<BusinessProduct>> _getBusinessListingsForProduct(
    String masterProductId, {
    double? minPrice,
    double? maxPrice,
    String? location,
  }) async {
    Query query = _businessProductsRef
        .where('masterProductId', isEqualTo: masterProductId)
        .where('isActive', isEqualTo: true);

    if (minPrice != null) {
      query = query.where('price', isGreaterThanOrEqualTo: minPrice);
    }

    if (maxPrice != null) {
      query = query.where('price', isLessThanOrEqualTo: maxPrice);
    }

    final snapshot = await query.get();
    final listings = snapshot.docs
        .map((doc) => BusinessProduct.fromFirestore(doc))
        .where((product) => product.isInStock) // Only in-stock products
        .toList();

    // TODO: Filter by location if specified
    return listings;
  }

  /// Check if master product matches search query
  bool _matchesSearchQuery(MasterProduct product, String query) {
    final searchTerms = query.toLowerCase().split(' ');
    final productText = '${product.name} ${product.description} ${product.brand} ${product.keywords.join(' ')}'.toLowerCase();
    
    return searchTerms.every((term) => productText.contains(term));
  }

  /// Add product via AI (simulated - in production, integrate with actual AI service)
  Future<String?> addProductViaAI({
    required String productName,
    required String categoryId,
    String? productUrl,
    String? description,
  }) async {
    try {
      // Simulate AI processing
      final aiData = await _simulateAIProcessing(productName, productUrl);
      
      final masterProduct = MasterProduct(
        id: '', // Will be set by Firestore
        name: aiData['name'] ?? productName,
        description: aiData['description'] ?? description ?? '',
        categoryId: categoryId,
        subcategoryId: aiData['subcategoryId'] ?? '',
        brand: aiData['brand'] ?? 'Unknown',
        specifications: aiData['specifications'] ?? {},
        imageUrls: List<String>.from(aiData['imageUrls'] ?? []),
        keywords: List<String>.from(aiData['keywords'] ?? []),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        aiData: ProductAIData(
          source: productUrl ?? 'manual_input',
          confidence: aiData['confidence'] ?? 0.8,
          processedAt: DateTime.now(),
          extractedData: aiData,
        ),
      );

      final docRef = await _masterProductsRef.add(masterProduct.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error adding product via AI: $e');
      return null;
    }
  }

  /// Simulate AI processing (replace with actual AI service)
  Future<Map<String, dynamic>> _simulateAIProcessing(String productName, String? url) async {
    // Simulate processing delay
    await Future.delayed(Duration(seconds: 2));

    // Simulate AI extracted data
    final random = Random();
    return {
      'name': productName,
      'description': 'AI-generated description for $productName',
      'brand': _extractBrandFromName(productName),
      'specifications': {
        'color': ['Black', 'White', 'Silver'][random.nextInt(3)],
        'weight': '${random.nextInt(500) + 100}g',
      },
      'imageUrls': [
        'https://via.placeholder.com/300x300?text=${Uri.encodeComponent(productName)}',
      ],
      'keywords': productName.toLowerCase().split(' ') + ['electronics', 'gadget'],
      'confidence': 0.8 + (random.nextDouble() * 0.2),
      'subcategoryId': '',
    };
  }

  String _extractBrandFromName(String productName) {
    final commonBrands = ['Apple', 'Samsung', 'Sony', 'LG', 'HP', 'Dell', 'Nike', 'Adidas'];
    for (final brand in commonBrands) {
      if (productName.toLowerCase().contains(brand.toLowerCase())) {
        return brand;
      }
    }
    return 'Generic';
  }

  /// Add business product listing from BusinessProduct object
  Future<String?> addBusinessProductFromObject(BusinessProduct businessProduct) async {
    try {
      final docRef = await _businessProductsRef.add(businessProduct.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error adding business product: $e');
      return null;
    }
  }

  /// Add business product listing
  Future<String?> addBusinessProduct({
    required String businessId,
    required String masterProductId,
    required double price,
    double? originalPrice,
    required ProductDeliveryInfo deliveryInfo,
    required ProductWarrantyInfo warrantyInfo,
    List<String> additionalImages = const [],
    String? businessUrl,
    String? businessPhone,
    String? businessWhatsapp,
    required ProductAvailability availability,
    Map<String, dynamic> businessSpecificData = const {},
  }) async {
    try {
      final businessProduct = BusinessProduct(
        id: '', // Will be set by Firestore
        businessId: businessId,
        masterProductId: masterProductId,
        price: price,
        originalPrice: originalPrice,
        deliveryInfo: deliveryInfo,
        warrantyInfo: warrantyInfo,
        additionalImages: additionalImages,
        businessUrl: businessUrl,
        businessPhone: businessPhone,
        businessWhatsapp: businessWhatsapp,
        availability: availability,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        businessSpecificData: businessSpecificData,
      );

      final docRef = await _businessProductsRef.add(businessProduct.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error adding business product: $e');
      return null;
    }
  }

  /// Update business product
  Future<bool> updateBusinessProduct(String productId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = Timestamp.fromDate(DateTime.now());
      await _businessProductsRef.doc(productId).update(updates);
      return true;
    } catch (e) {
      print('Error updating business product: $e');
      return false;
    }
  }

  /// Get business products for a specific business
  Future<List<BusinessProduct>> getBusinessProducts(String businessId) async {
    try {
      final snapshot = await _businessProductsRef
          .where('businessId', isEqualTo: businessId)
          .get();

      return snapshot.docs
          .map((doc) => BusinessProduct.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting business products: $e');
      return [];
    }
  }

  /// Get enriched business products with master product information
  Future<List<ProductSearchResult>> getEnrichedBusinessProducts(String businessId) async {
    try {
      final businessProducts = await getBusinessProducts(businessId);
      List<ProductSearchResult> results = [];

      for (final businessProduct in businessProducts) {
        // Get the master product
        final masterProduct = await getMasterProduct(businessProduct.masterProductId);
        if (masterProduct != null) {
          results.add(ProductSearchResult(
            product: masterProduct,
            businessListings: [businessProduct],
            cheapestListing: businessProduct,
            totalBusinesses: 1,
            priceRange: 0,
          ));
        }
      }

      return results;
    } catch (e) {
      print('Error getting enriched business products: $e');
      return [];
    }
  }

  /// Get a specific business product by ID
  Future<BusinessProduct?> getBusinessProduct(String productId) async {
    try {
      final doc = await _businessProductsRef.doc(productId).get();
      if (doc.exists) {
        return BusinessProduct.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting business product: $e');
      return null;
    }
  }

  /// Delete business product
  Future<void> deleteBusinessProduct(String productId) async {
    try {
      await _businessProductsRef.doc(productId).delete();
      print('Business product deleted: $productId');
    } catch (e) {
      print('Error deleting business product: $e');
      throw Exception('Failed to delete business product: $e');
    }
  }

  /// Record product click for revenue tracking
  Future<void> recordProductClick({
    required String businessProductId,
    required String userId,
    String? sessionId,
    String? referrer,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final click = ProductClick(
        id: '', // Will be set by Firestore
        businessProductId: businessProductId,
        userId: userId,
        sessionId: sessionId,
        clickedAt: DateTime.now(),
        referrer: referrer,
        metadata: metadata,
      );

      // Add click record
      await _clicksRef.add(click.toFirestore());

      // Increment click count on business product
      await _businessProductsRef.doc(businessProductId).update({
        'clickCount': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error recording product click: $e');
    }
  }

  /// Get popular products (by click count)
  Future<List<ProductSearchResult>> getPopularProducts({
    String? categoryId,
    int limit = 10,
  }) async {
    try {
      Query query = _businessProductsRef
          .where('isActive', isEqualTo: true)
          .orderBy('clickCount', descending: true);

      if (categoryId != null) {
        // Need to join with master products to filter by category
        // For now, get all and filter locally
      }

      final snapshot = await query.limit(limit * 3).get(); // Get more to account for filtering
      
      List<ProductSearchResult> results = [];
      Set<String> seenMasterProducts = {};

      for (final doc in snapshot.docs) {
        final businessProduct = BusinessProduct.fromFirestore(doc);
        
        // Skip if we already have this master product
        if (seenMasterProducts.contains(businessProduct.masterProductId)) continue;
        seenMasterProducts.add(businessProduct.masterProductId);

        // Get master product
        final masterProduct = await getMasterProduct(businessProduct.masterProductId);
        if (masterProduct == null) continue;

        // Filter by category if specified
        if (categoryId != null && masterProduct.categoryId != categoryId) continue;

        // Get all business listings for this product
        final businessListings = await _getBusinessListingsForProduct(masterProduct.id);
        businessListings.sort((a, b) => a.price.compareTo(b.price));

        results.add(ProductSearchResult(
          product: masterProduct,
          businessListings: businessListings,
          cheapestListing: businessListings.isNotEmpty ? businessListings.first : null,
          priceRange: businessListings.length > 1 
              ? businessListings.last.price - businessListings.first.price 
              : null,
          totalBusinesses: businessListings.length,
        ));

        if (results.length >= limit) break;
      }

      return results;
    } catch (e) {
      print('Error getting popular products: $e');
      return [];
    }
  }

  /// Get master product by ID
  Future<MasterProduct?> getMasterProduct(String productId) async {
    try {
      final doc = await _masterProductsRef.doc(productId).get();
      if (doc.exists) {
        return MasterProduct.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting master product: $e');
      return null;
    }
  }

  /// Get price alerts for a user
  Stream<List<ProductSearchResult>> getPriceAlerts(String userId) {
    // TODO: Implement user price alerts
    // This would track products user is interested in and notify of price changes
    return Stream.value([]);
  }

  /// Bulk update prices (for businesses with auto-update enabled)
  Future<void> bulkUpdatePrices(String businessId, Map<String, double> productPrices) async {
    try {
      final batch = _firestore.batch();
      
      for (final entry in productPrices.entries) {
        final productRef = _businessProductsRef.doc(entry.key);
        batch.update(productRef, {
          'price': entry.value,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error bulk updating prices: $e');
    }
  }

  /// Get price history for a product (for analytics)
  Future<List<Map<String, dynamic>>> getPriceHistory(String masterProductId) async {
    try {
      // This would require a separate price_history collection
      // For now, return empty list
      return [];
    } catch (e) {
      print('Error getting price history: $e');
      return [];
    }
  }

  /// Get recommended products based on user behavior
  Future<List<ProductSearchResult>> getRecommendedProducts(String userId) async {
    try {
      // Simple recommendation based on popular products for now
      // In production, use ML algorithms based on user behavior
      return await getPopularProducts(limit: 5);
    } catch (e) {
      print('Error getting recommended products: $e');
      return [];
    }
  }

  /// Search master products by category
  Future<List<MasterProduct>> searchMasterProducts({
    String? categoryId,
    String? query,
    int limit = 20,
  }) async {
    try {
      Query queryRef = _masterProductsRef.where('isActive', isEqualTo: true);
      
      if (categoryId != null) {
        queryRef = queryRef.where('categoryId', isEqualTo: categoryId);
      }
      
      queryRef = queryRef.limit(limit);
      
      final snapshot = await queryRef.get();
      List<MasterProduct> products = snapshot.docs
          .map((doc) => MasterProduct.fromFirestore(doc))
          .toList();
      
      // If query is provided, filter by name/description
      if (query != null && query.isNotEmpty) {
        final lowerQuery = query.toLowerCase();
        products = products.where((product) =>
          product.name.toLowerCase().contains(lowerQuery) ||
          product.description.toLowerCase().contains(lowerQuery) ||
          product.keywords.any((keyword) => keyword.toLowerCase().contains(lowerQuery))
        ).toList();
      }
      
      return products;
    } catch (e) {
      print('Error searching master products: $e');
      return [];
    }
  }

  /// Create a new master product
  Future<String> createMasterProduct(MasterProduct product) async {
    try {
      final docRef = await _masterProductsRef.add(product.toFirestore());
      print('Master product created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error creating master product: $e');
      throw Exception('Failed to create master product: $e');
    }
  }

  /// Create a new business product
  Future<String> createBusinessProduct(BusinessProduct product) async {
    try {
      final docRef = await _businessProductsRef.add(product.toFirestore());
      print('Business product created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error creating business product: $e');
      throw Exception('Failed to create business product: $e');
    }
  }
}
