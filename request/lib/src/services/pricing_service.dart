import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/price_listing.dart';
import '../models/master_product.dart';

class PricingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  final String _priceListingsCollection = 'price_listings';
  final String _masterProductsCollection = 'master_products';
  final String _businessVerificationCollection = 'business_verification';
  final String _productClicksCollection = 'product_clicks';

  // Check if business is eligible for pricing feature
  Future<bool> isBusinessEligibleForPricing(String userId) async {
    try {
      final businessDoc = await _firestore
          .collection(_businessVerificationCollection)
          .doc(userId)
          .get();

      if (!businessDoc.exists) return false;

      final businessData = businessDoc.data()!;
      final category = businessData['businessCategory'] as String?;
      
      // Exclude delivery services, services, and other
      if (category == null) return false;
      
      final excludedCategories = [
        'delivery services',
        'services', 
        'other'
      ];
      
      return !excludedCategories.contains(category.toLowerCase());
    } catch (e) {
      print('Error checking business eligibility: $e');
      return false;
    }
  }

  // Get master products with search and filters
  Stream<List<MasterProduct>> getMasterProducts({
    String? searchQuery,
    String? category,
    String? subcategory,
    String? brand,
  }) {
    Query query = _firestore.collection(_masterProductsCollection)
        .where('isActive', isEqualTo: true);

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    if (subcategory != null) {
      query = query.where('subcategory', isEqualTo: subcategory);
    }

    if (brand != null) {
      query = query.where('brand', isEqualTo: brand);
    }

    return query.snapshots().map((snapshot) {
      List<MasterProduct> products = snapshot.docs
          .map((doc) => MasterProduct.fromFirestore(doc))
          .toList();

      // Filter by search query if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        products = products.where((product) {
          return product.name.toLowerCase().contains(query) ||
                 product.brand.toLowerCase().contains(query) ||
                 product.description.toLowerCase().contains(query);
        }).toList();
      }

      return products;
    });
  }

  // Get price listings for a specific product
  Stream<List<PriceListing>> getPriceListingsForProduct(String masterProductId) {
    return _firestore
        .collection(_priceListingsCollection)
        .where('masterProductId', isEqualTo: masterProductId)
        .where('isAvailable', isEqualTo: true)
        .orderBy('price', descending: false) // Cheapest first
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PriceListing.fromFirestore(doc))
            .toList());
  }

  // Get business price listings
  Stream<List<PriceListing>> getBusinessPriceListings(String businessId) {
    return _firestore
        .collection(_priceListingsCollection)
        .where('businessId', isEqualTo: businessId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PriceListing.fromFirestore(doc))
            .toList());
  }

  // Add or update price listing
  Future<void> addOrUpdatePriceListing(PriceListing priceListing) async {
    try {
      final docRef = priceListing.id.isEmpty
          ? _firestore.collection(_priceListingsCollection).doc()
          : _firestore.collection(_priceListingsCollection).doc(priceListing.id);

      final updatedListing = priceListing.copyWith(
        id: docRef.id,
        updatedAt: DateTime.now(),
      );

      await docRef.set(updatedListing.toFirestore(), SetOptions(merge: true));
      
      // Update master product business count
      await _updateMasterProductBusinessCount(priceListing.masterProductId);
    } catch (e) {
      print('Error adding/updating price listing: $e');
      rethrow;
    }
  }

  // Delete price listing
  Future<void> deletePriceListing(String listingId, String masterProductId) async {
    try {
      await _firestore.collection(_priceListingsCollection).doc(listingId).delete();
      await _updateMasterProductBusinessCount(masterProductId);
    } catch (e) {
      print('Error deleting price listing: $e');
      rethrow;
    }
  }

  // Track product link click
  Future<void> trackProductClick({
    required String listingId,
    required String businessId,
    required String masterProductId,
    required String userId,
  }) async {
    try {
      // Increment click count in price listing
      await _firestore.collection(_priceListingsCollection).doc(listingId).update({
        'clickCount': FieldValue.increment(1),
      });

      // Log detailed click for analytics
      await _firestore.collection(_productClicksCollection).add({
        'listingId': listingId,
        'businessId': businessId,
        'masterProductId': masterProductId,
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'clickType': 'product_link',
      });
    } catch (e) {
      print('Error tracking product click: $e');
      rethrow;
    }
  }

  // Get business profile for display
  Future<Map<String, dynamic>?> getBusinessProfile(String businessId) async {
    try {
      final businessDoc = await _firestore
          .collection(_businessVerificationCollection)
          .doc(businessId)
          .get();

      if (!businessDoc.exists) return null;

      final data = businessDoc.data()!;
      
      // Get business stats
      final listingsQuery = await _firestore
          .collection(_priceListingsCollection)
          .where('businessId', isEqualTo: businessId)
          .get();

      final totalListings = listingsQuery.docs.length;
      final totalClicks = listingsQuery.docs.fold<int>(
        0, 
        (sum, doc) => sum + (doc.data()['clickCount'] as int? ?? 0),
      );

      return {
        'businessName': data['businessName'],
        'businessEmail': data['businessEmail'],
        'businessPhone': data['businessPhone'],
        'businessAddress': data['businessAddress'],
        'businessCategory': data['businessCategory'],
        'businessDescription': data['businessDescription'],
        'businessLogo': data['businessLogoUrl'],
        'whatsappNumber': data['whatsappNumber'],
        'website': data['website'],
        'totalListings': totalListings,
        'totalClicks': totalClicks,
        'joinDate': data['createdAt'],
        'isVerified': data['isVerified'] ?? false,
      };
    } catch (e) {
      print('Error getting business profile: $e');
      return null;
    }
  }

  // Update master product business count
  Future<void> _updateMasterProductBusinessCount(String masterProductId) async {
    try {
      final listingsQuery = await _firestore
          .collection(_priceListingsCollection)
          .where('masterProductId', isEqualTo: masterProductId)
          .where('isAvailable', isEqualTo: true)
          .get();

      final uniqueBusinesses = <String>{};
      for (final doc in listingsQuery.docs) {
        uniqueBusinesses.add(doc.data()['businessId']);
      }

      await _firestore.collection(_masterProductsCollection)
          .doc(masterProductId)
          .update({
        'businessListingsCount': uniqueBusinesses.length,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating master product business count: $e');
    }
  }

  // Search products with advanced filters
  Future<List<MasterProduct>> searchProducts({
    required String query,
    String? category,
    String? brand,
    double? minPrice,
    double? maxPrice,
  }) async {
    try {
      // Start with basic query
      Query masterQuery = _firestore.collection(_masterProductsCollection)
          .where('isActive', isEqualTo: true);

      if (category != null) {
        masterQuery = masterQuery.where('category', isEqualTo: category);
      }

      final masterResults = await masterQuery.get();
      List<MasterProduct> products = masterResults.docs
          .map((doc) => MasterProduct.fromFirestore(doc))
          .toList();

      // Filter by search query
      if (query.isNotEmpty) {
        final searchTerm = query.toLowerCase();
        products = products.where((product) {
          return product.name.toLowerCase().contains(searchTerm) ||
                 product.brand.toLowerCase().contains(searchTerm) ||
                 product.description.toLowerCase().contains(searchTerm);
        }).toList();
      }

      // Filter by brand
      if (brand != null) {
        products = products.where((product) => product.brand == brand).toList();
      }

      // Filter by price range if specified
      if (minPrice != null || maxPrice != null) {
        List<MasterProduct> priceFilteredProducts = [];
        
        for (final product in products) {
          final priceListings = await _firestore
              .collection(_priceListingsCollection)
              .where('masterProductId', isEqualTo: product.id)
              .where('isAvailable', isEqualTo: true)
              .get();

          if (priceListings.docs.isNotEmpty) {
            final prices = priceListings.docs
                .map((doc) => (doc.data()['price'] as num).toDouble())
                .toList();
            
            final minProductPrice = prices.reduce((a, b) => a < b ? a : b);
            final maxProductPrice = prices.reduce((a, b) => a > b ? a : b);

            bool matchesPriceRange = true;
            if (minPrice != null && maxProductPrice < minPrice) {
              matchesPriceRange = false;
            }
            if (maxPrice != null && minProductPrice > maxPrice) {
              matchesPriceRange = false;
            }

            if (matchesPriceRange) {
              priceFilteredProducts.add(product);
            }
          }
        }
        products = priceFilteredProducts;
      }

      return products;
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }

  // Get categories for filter
  Future<List<String>> getCategories() async {
    try {
      final snapshot = await _firestore.collection(_masterProductsCollection)
          .where('isActive', isEqualTo: true)
          .get();

      final categories = <String>{};
      for (final doc in snapshot.docs) {
        final category = doc.data()['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categories.add(category);
        }
      }

      return categories.toList()..sort();
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  // Get brands for filter
  Future<List<String>> getBrands() async {
    try {
      final snapshot = await _firestore.collection(_masterProductsCollection)
          .where('isActive', isEqualTo: true)
          .get();

      final brands = <String>{};
      for (final doc in snapshot.docs) {
        final brand = doc.data()['brand'] as String?;
        if (brand != null && brand.isNotEmpty) {
          brands.add(brand);
        }
      }

      return brands.toList()..sort();
    } catch (e) {
      print('Error getting brands: $e');
      return [];
    }
  }
}
