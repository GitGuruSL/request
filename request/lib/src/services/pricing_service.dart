import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/price_listing.dart';
import '../models/master_product.dart';

class PricingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collections
  final String _priceListingsCollection = 'price_listings';
  final String _masterProductsCollection = 'master_products';
  final String _businessVerificationCollection = 'new_business_verifications';
  final String _productClicksCollection = 'product_clicks';

  // Check if business is eligible for pricing feature
  Future<bool> isBusinessEligibleForPricing(String userId) async {
    try {
      final businessDoc = await _firestore
          .collection(_businessVerificationCollection)
          .doc(userId)
          .get();

      if (!businessDoc.exists) {
        print('DEBUG: Business document does not exist for userId: $userId');
        return false;
      }

      final businessData = businessDoc.data()!;
      final category = businessData['businessCategory'] as String?;
      
      print('DEBUG: Business category found: "$category"');
      
      // Exclude delivery services, services, and other
      if (category == null) {
        print('DEBUG: Business category is null');
        return false;
      }
      
      final excludedCategories = [
        'delivery services',
        'services', 
        'other'
      ];
      
      final categoryLower = category.toLowerCase();
      final isExcluded = excludedCategories.contains(categoryLower);
      
      print('DEBUG: Category (lowercase): "$categoryLower"');
      print('DEBUG: Excluded categories: $excludedCategories');
      print('DEBUG: Is excluded: $isExcluded');
      print('DEBUG: Is eligible: ${!isExcluded}');
      
      return !isExcluded;
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
    print('DEBUG: Getting price listings for masterProductId: $masterProductId');
    return _firestore
        .collection(_priceListingsCollection)
        .where('masterProductId', isEqualTo: masterProductId)
        .where('isAvailable', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          print('DEBUG: Got ${snapshot.docs.length} price listings for product $masterProductId');
          final listings = snapshot.docs
              .map((doc) {
                try {
                  return PriceListing.fromFirestore(doc);
                } catch (e) {
                  print('DEBUG: Error parsing price listing ${doc.id}: $e');
                  return null;
                }
              })
              .where((listing) => listing != null)
              .cast<PriceListing>()
              .toList();
          
          // Sort manually by price (cheapest first)
          listings.sort((a, b) => a.price.compareTo(b.price));
          return listings;
        });
  }

  // Get business price listings
  Stream<List<PriceListing>> getBusinessPriceListings(String businessId) {
    print('DEBUG: Getting price listings for businessId: $businessId');
    return _firestore
        .collection(_priceListingsCollection)
        .where('businessId', isEqualTo: businessId)
        .snapshots()
        .map((snapshot) {
          print('DEBUG: Firestore snapshot received with ${snapshot.docs.length} documents');
          final listings = snapshot.docs
              .map((doc) {
                print('DEBUG: Processing document: ${doc.id}');
                try {
                  return PriceListing.fromFirestore(doc);
                } catch (e) {
                  print('DEBUG: Error parsing document ${doc.id}: $e');
                  print('DEBUG: Document data: ${doc.data()}');
                  rethrow;
                }
              })
              .toList();
          
          // Sort manually since orderBy might not be indexed
          listings.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
          return listings;
        });
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
      print('DEBUG: Searching products with query: "$query", category: $category, brand: $brand');
      
      // Start with basic query
      Query masterQuery = _firestore.collection(_masterProductsCollection)
          .where('isActive', isEqualTo: true);

      if (category != null) {
        masterQuery = masterQuery.where('category', isEqualTo: category);
        print('DEBUG: Added category filter: $category');
      }

      print('DEBUG: Executing Firestore query...');
      final masterResults = await masterQuery.get();
      print('DEBUG: Got ${masterResults.docs.length} documents from Firestore');
      
      List<MasterProduct> products = [];
      for (final doc in masterResults.docs) {
        try {
          final product = MasterProduct.fromFirestore(doc);
          products.add(product);
          print('DEBUG: Successfully parsed product: ${product.name}');
        } catch (e) {
          print('DEBUG: Error parsing product ${doc.id}: $e');
          print('DEBUG: Document data: ${doc.data()}');
        }
      }

      print('DEBUG: Total products parsed: ${products.length}');

      // Filter by search query
      if (query.isNotEmpty) {
        final searchTerm = query.toLowerCase();
        print('DEBUG: Filtering by search term: "$searchTerm"');
        final originalCount = products.length;
        products = products.where((product) {
          final matches = product.name.toLowerCase().contains(searchTerm) ||
                 product.brand.toLowerCase().contains(searchTerm) ||
                 product.description.toLowerCase().contains(searchTerm);
          if (matches) {
            print('DEBUG: Product "${product.name}" matches search term');
          }
          return matches;
        }).toList();
        print('DEBUG: After search filter: ${products.length}/$originalCount products');
      }

      // Filter by brand
      if (brand != null) {
        print('DEBUG: Filtering by brand: $brand');
        final originalCount = products.length;
        products = products.where((product) => product.brand == brand).toList();
        print('DEBUG: After brand filter: ${products.length}/$originalCount products');
      }

      // Filter by price range if specified
      if (minPrice != null || maxPrice != null) {
        print('DEBUG: Filtering by price range: $minPrice - $maxPrice');
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
      print('DEBUG: Getting categories from master_products collection');
      final snapshot = await _firestore.collection(_masterProductsCollection)
          .where('isActive', isEqualTo: true)
          .get();

      print('DEBUG: Got ${snapshot.docs.length} documents for categories');
      final categories = <String>{};
      for (final doc in snapshot.docs) {
        final category = doc.data()['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categories.add(category);
          print('DEBUG: Found category: $category');
        }
      }

      final result = categories.toList()..sort();
      print('DEBUG: Final categories list: $result');
      return result;
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  // Get brands for filter
  Future<List<String>> getBrands() async {
    try {
      print('DEBUG: Getting brands from master_products collection');
      final snapshot = await _firestore.collection(_masterProductsCollection)
          .where('isActive', isEqualTo: true)
          .get();

      print('DEBUG: Got ${snapshot.docs.length} documents for brands');
      final brands = <String>{};
      for (final doc in snapshot.docs) {
        final brand = doc.data()['brand'] as String?;
        if (brand != null && brand.isNotEmpty) {
          brands.add(brand);
          print('DEBUG: Found brand: $brand');
        }
      }

      final result = brands.toList()..sort();
      print('DEBUG: Final brands list: $result');
      return result;
    } catch (e) {
      print('Error getting brands: $e');
      return [];
    }
  }
}
