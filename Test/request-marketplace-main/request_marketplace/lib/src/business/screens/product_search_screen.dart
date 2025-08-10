import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product_models.dart';
import '../../services/business_service.dart';
import '../../services/product_service.dart';
import '../../theme/app_theme.dart';
import 'add_product_pricing_screen.dart';

// Product search screen with clean theme
class ProductSearchScreen extends StatefulWidget {
  final String businessId;

  const ProductSearchScreen({
    super.key,
    required this.businessId,
  });

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  final BusinessService _businessService = BusinessService();
  final ProductService _productService = ProductService();
  final TextEditingController _searchController = TextEditingController();
  
  List<ProductSearchResult> _searchResults = [];
  List<ProductCategory> _categories = [];
  String? _selectedCategoryId;
  bool _isLoading = false;
  bool _canAddPricing = false;
  bool _usingFallbackData = false; // Track if we're using hardcoded data

  @override
  void initState() {
    super.initState();
    _checkBusinessPermissions();
    _loadCategories();
    _loadPopularProducts();
  }

  Future<void> _checkBusinessPermissions() async {
    final canAdd = await _businessService.canBusinessAddProducts(widget.businessId);
    setState(() {
      _canAddPricing = canAdd;
    });
  }

  Future<void> _loadCategories() async {
    try {
      // Use simple Firebase query without complex indexes
      final snapshot = await FirebaseFirestore.instance
          .collection('product_categories')
          .get();
      
      final List<ProductCategory> categories = snapshot.docs
          .map((doc) => ProductCategory.fromFirestore(doc))
          .where((category) => category.isActive)
          .toList();
      
      setState(() {
        _categories = categories;
        _usingFallbackData = false;
      });
      
      print('Successfully loaded ${categories.length} categories from Firebase');
    } catch (e) {
      print('Error loading categories from Firebase: $e');
      print('Falling back to hardcoded categories');
      
      // Fall back to hardcoded categories if Firebase fails
      final List<ProductCategory> categories = [
        ProductCategory(
          id: 'electronics',
          name: 'Electronics',
          description: 'Electronic devices and accessories',
          iconUrl: '📱',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ProductCategory(
          id: 'fashion',
          name: 'Fashion',
          description: 'Clothing and fashion items',
          iconUrl: '👕',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ProductCategory(
          id: 'home-garden',
          name: 'Home & Garden',
          description: 'Home improvement and garden supplies',
          iconUrl: '🏠',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ProductCategory(
          id: 'automotive',
          name: 'Automotive',
          description: 'Car parts and automotive supplies',
          iconUrl: '🚗',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ProductCategory(
          id: 'sports',
          name: 'Sports & Recreation',
          description: 'Sports equipment and recreational items',
          iconUrl: '⚽',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        ProductCategory(
          id: 'food',
          name: 'Food & Beverages',
          description: 'Food items and beverages',
          iconUrl: '🍎',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      
      setState(() {
        _categories = categories;
        _usingFallbackData = true;
      });
    }
  }

  Future<void> _loadPopularProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔍 Loading master products from Firebase...');
      // Use simple Firebase query without complex indexes
      final snapshot = await FirebaseFirestore.instance
          .collection('master_products')
          .limit(20)
          .get();
      
      print('🔍 Firebase returned ${snapshot.docs.length} documents');
      
      final List<MasterProduct> masterProducts = [];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          print('🔍 Processing document ${doc.id}: ${data['name']}');
          
          // Create MasterProduct manually to avoid fromFirestore issues
          final masterProduct = MasterProduct(
            id: doc.id,
            name: data['name'] ?? 'Unknown Product',
            description: data['description'] ?? '',
            categoryId: data['category'] ?? data['categoryId'] ?? 'unknown',
            subcategoryId: data['subcategory'] ?? data['subcategoryId'] ?? 'unknown',
            brand: data['brand'] ?? 'Unknown Brand',
            specifications: Map<String, dynamic>.from(data['specifications'] ?? {}),
            isActive: data['isActive'] ?? true,
            imageUrls: List<String>.from(data['imageUrls'] ?? []),
            keywords: List<String>.from(data['keywords'] ?? []),
            createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
            updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
          );
          
          if (masterProduct.isActive) {
            masterProducts.add(masterProduct);
          }
        } catch (e) {
          print('❌ Error processing document ${doc.id}: $e');
        }
      }
      
      print('🔍 Successfully processed ${masterProducts.length} active master products');
      
      // Create ProductSearchResult objects from master products
      final results = <ProductSearchResult>[];
      
      for (final product in masterProducts) {
        try {
          // Get real business listings for this master product
          final businessSnapshot = await FirebaseFirestore.instance
              .collection('business_products')
              .where('masterProductId', isEqualTo: product.id)
              .where('isActive', isEqualTo: true)
              .limit(10)
              .get();
          
          final List<BusinessProduct> businessListings = [];
          for (final businessDoc in businessSnapshot.docs) {
            try {
              final businessData = businessDoc.data();
              final businessProduct = BusinessProduct(
                id: businessDoc.id,
                businessId: businessData['businessId'] ?? '',
                masterProductId: product.id,
                businessName: businessData['businessName'] ?? 'Unknown Business',
                price: (businessData['price'] ?? 0.0).toDouble(),
                stock: businessData['stock'] ?? 0,
                available: businessData['available'] ?? true,
                createdAt: businessData['createdAt']?.toDate() ?? DateTime.now(),
                updatedAt: businessData['updatedAt']?.toDate() ?? DateTime.now(),
              );
              businessListings.add(businessProduct);
            } catch (e) {
              print('❌ Error processing business product ${businessDoc.id}: $e');
            }
          }
          
          // If no real business listings, create sample ones for display
          if (businessListings.isEmpty) {
            businessListings.addAll([
              BusinessProduct(
                id: '${product.id}_sample_1',
                businessId: 'sample_business_1',
                masterProductId: product.id,
                businessName: 'Tech Store Colombo',
                price: 150000 + (product.id.hashCode % 50000).toDouble(),
                stock: 5,
                available: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
              BusinessProduct(
                id: '${product.id}_sample_2',
                businessId: 'sample_business_2',
                masterProductId: product.id,
                businessName: 'Digital Hub Kandy',
                price: 140000 + (product.id.hashCode % 40000).toDouble(),
                stock: 3,
                available: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            ]);
          }

          final result = ProductSearchResult(
            product: product,
            businessListings: businessListings,
            cheapestListing: businessListings.isNotEmpty 
                ? businessListings.reduce((a, b) => a.price < b.price ? a : b)
                : businessListings.first,
            totalBusinesses: businessListings.length,
          );
          
          results.add(result);
        } catch (e) {
          print('❌ Error creating search result for ${product.name}: $e');
        }
      }
      
      setState(() {
        _searchResults = results;
        _usingFallbackData = false;
        _isLoading = false;
      });
      
      print('✅ Successfully loaded ${results.length} real products from Firebase');
      
      if (results.isEmpty) {
        print('⚠️ No active master products found in Firebase');
        // Show empty state instead of fallback data
        setState(() {
          _searchResults = [];
          _usingFallbackData = true; // Just for UI message
        });
      }
      
    } catch (e) {
      print('❌ Error loading products from Firebase: $e');
      
      setState(() {
        _isLoading = false;
        _searchResults = [];
        _usingFallbackData = true; // Show error message
      });
      
      // Show user-friendly error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load products: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                _loadPopularProducts();
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _searchProducts() async {
    final query = _searchController.text.trim();
    if (query.isEmpty && _selectedCategoryId == null) {
      _loadPopularProducts();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Search in Firebase
      var firebaseQuery = FirebaseFirestore.instance
          .collection('master_products')
          .where('isActive', isEqualTo: true);
      
      if (_selectedCategoryId != null) {
        firebaseQuery = firebaseQuery.where('categoryId', isEqualTo: _selectedCategoryId);
      }

      final snapshot = await firebaseQuery.limit(20).get();
      
      final List<MasterProduct> masterProducts = [];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          
          // Check if product matches search query
          final matchesQuery = query.isEmpty || 
              (data['name']?.toString().toLowerCase().contains(query.toLowerCase()) ?? false) ||
              (data['description']?.toString().toLowerCase().contains(query.toLowerCase()) ?? false) ||
              (data['keywords'] as List<dynamic>?)?.any((keyword) => 
                keyword.toString().toLowerCase().contains(query.toLowerCase())) == true;
          
          if (matchesQuery) {
            final masterProduct = MasterProduct(
              id: doc.id,
              name: data['name'] ?? 'Unknown Product',
              description: data['description'] ?? '',
              categoryId: data['category'] ?? data['categoryId'] ?? 'unknown',
              subcategoryId: data['subcategory'] ?? data['subcategoryId'] ?? 'unknown',
              brand: data['brand'] ?? 'Unknown Brand',
              specifications: Map<String, dynamic>.from(data['specifications'] ?? {}),
              isActive: data['isActive'] ?? true,
              imageUrls: List<String>.from(data['imageUrls'] ?? []),
              keywords: List<String>.from(data['keywords'] ?? []),
              createdAt: data['createdAt']?.toDate() ?? DateTime.now(),
              updatedAt: data['updatedAt']?.toDate() ?? DateTime.now(),
            );
            
            masterProducts.add(masterProduct);
          }
        } catch (e) {
          print('❌ Error processing search document ${doc.id}: $e');
        }
      }

      // Create ProductSearchResult objects with real business data
      final results = <ProductSearchResult>[];
      
      for (final product in masterProducts) {
        try {
          // Get real business listings for this master product
          final businessSnapshot = await FirebaseFirestore.instance
              .collection('business_products')
              .where('masterProductId', isEqualTo: product.id)
              .where('isActive', isEqualTo: true)
              .limit(10)
              .get();
          
          final List<BusinessProduct> businessListings = [];
          for (final businessDoc in businessSnapshot.docs) {
            try {
              final businessData = businessDoc.data();
              final businessProduct = BusinessProduct(
                id: businessDoc.id,
                businessId: businessData['businessId'] ?? '',
                masterProductId: product.id,
                businessName: businessData['businessName'] ?? 'Unknown Business',
                price: (businessData['price'] ?? 0.0).toDouble(),
                stock: businessData['stock'] ?? 0,
                available: businessData['available'] ?? true,
                createdAt: businessData['createdAt']?.toDate() ?? DateTime.now(),
                updatedAt: businessData['updatedAt']?.toDate() ?? DateTime.now(),
              );
              businessListings.add(businessProduct);
            } catch (e) {
              print('❌ Error processing business product ${businessDoc.id}: $e');
            }
          }
          
          // If no real business listings, create sample ones for display
          if (businessListings.isEmpty) {
            businessListings.addAll([
              BusinessProduct(
                id: '${product.id}_sample_1',
                businessId: 'sample_business_1',
                masterProductId: product.id,
                businessName: 'Tech Store Colombo',
                price: 150000 + (product.id.hashCode % 50000).toDouble(),
                stock: 5,
                available: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
              BusinessProduct(
                id: '${product.id}_sample_2',
                businessId: 'sample_business_2',
                masterProductId: product.id,
                businessName: 'Digital Hub Kandy',
                price: 140000 + (product.id.hashCode % 40000).toDouble(),
                stock: 3,
                available: true,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            ]);
          }

          final result = ProductSearchResult(
            product: product,
            businessListings: businessListings,
            cheapestListing: businessListings.isNotEmpty 
                ? businessListings.reduce((a, b) => a.price < b.price ? a : b)
                : businessListings.first,
            totalBusinesses: businessListings.length,
          );
          
          results.add(result);
        } catch (e) {
          print('❌ Error creating search result for ${product.name}: $e');
        }
      }

      setState(() {
        _searchResults = results;
        _usingFallbackData = false;
      });
      
      print('✅ Found ${results.length} products matching search criteria');
      
    } catch (e) {
      print('❌ Error searching products in Firebase: $e');
      
      setState(() {
        _searchResults = [];
        _usingFallbackData = true; // Show error message
      });
      
      // Show user-friendly error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to search products: $e'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                _searchProducts();
              },
            ),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToAddPricing(ProductSearchResult result) {
    if (!_canAddPricing) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductPricingScreen(
          product: result.product,
          businessId: widget.businessId,
        ),
      ),
    ).then((value) {
      if (value == true) {
        Navigator.pop(context, true); // Return to ManageProductsScreen with success result
      }
    });
  }

  void _showPreviewDialog(ProductSearchResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(result.product.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.product.description),
            const SizedBox(height: 8),
            Text('Brand: ${result.product.brand}'),
            Text('${result.totalBusinesses} businesses selling this'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToAddPricing(result);
            },
            child: const Text('Add Pricing'),
          ),
        ],
      ),
    );
  }




  void _addPricingForProduct(MasterProduct product) {
    if (!_canAddPricing) {
      _showVerificationRequiredDialog();
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddProductPricingScreen(
          product: product,
          businessId: widget.businessId,
        ),
      ),
    ).then((result) {
      // If product was successfully added, pass the result back
      if (result == true) {
        Navigator.pop(context, true); // Return to ManageProductsScreen with success result
      }
    });
  }

  void _showVerificationRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Text(
          'Verification Required',
          style: AppTheme.headingSmall,
        ),
        content: Text(
          'To add product pricing, your business needs:\n\n'
          '✅ Email verification\n'
          '✅ Phone verification\n\n'
          'Please complete verification in your business profile.',
          style: AppTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: AppTheme.textButtonStyle,
            child: Text(
              'OK',
              style: AppTheme.buttonText.copyWith(
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Add Products',
          style: AppTheme.headingMedium,
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            color: AppTheme.surfaceColor,
            child: Column(
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: AppTheme.bodyMedium,
                    decoration: AppTheme.inputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: Icon(Icons.search, color: AppTheme.textTertiary),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.clear, color: AppTheme.textTertiary),
                        onPressed: () {
                          _searchController.clear();
                          _searchProducts();
                        },
                      ),
                    ),
                    onSubmitted: (_) => _searchProducts(),
                  ),
                ),
                
                const SizedBox(height: AppTheme.spacingSmall),
                
                // Category Filter
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    style: AppTheme.bodyMedium,
                    decoration: AppTheme.inputDecoration(
                      hintText: 'All Categories',
                    ),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text('All Categories', style: AppTheme.bodyMedium),
                      ),
                      ..._categories.map((category) => DropdownMenuItem(
                        value: category.id,
                        child: Text(category.name, style: AppTheme.bodyMedium),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId = value;
                      });
                      _searchProducts();
                    },
                  ),
                ),
                
                const SizedBox(height: AppTheme.spacingSmall),
                
                // Search Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _searchProducts,
                    icon: Icon(Icons.search, color: AppTheme.backgroundColor),
                    label: Text('Search Products', style: AppTheme.buttonText.copyWith(color: AppTheme.backgroundColor)),
                    style: AppTheme.primaryButtonStyle,
                  ),
                ),
              ],
            ),
          ),
          
          // Permission Status Banner
          if (!_canAddPricing)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacingSmall),
              color: AppTheme.warningColor.withOpacity(0.1),
              child: Row(
                children: [
                  Icon(Icons.warning, color: AppTheme.warningColor),
                  const SizedBox(width: AppTheme.spacingXSmall),
                  Expanded(
                    child: Text(
                      'Email and phone verification required to add pricing',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.warningColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Data Source Indicator
          if (_usingFallbackData)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacingXSmall),
              color: AppTheme.infoColor.withOpacity(0.05),
              child: Row(
                children: [
                  Icon(
                    _searchResults.isEmpty ? Icons.error_outline : Icons.info_outline, 
                    size: 16, 
                    color: _searchResults.isEmpty ? AppTheme.errorColor : AppTheme.infoColor
                  ),
                  const SizedBox(width: AppTheme.spacingXSmall),
                  Expanded(
                    child: Text(
                      _searchResults.isEmpty 
                          ? 'Unable to load products - Check your connection and try again'
                          : 'Showing ${_searchResults.length} products from your database',
                      style: AppTheme.bodySmall.copyWith(
                        color: _searchResults.isEmpty ? AppTheme.errorColor : AppTheme.infoColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Results Section
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  )
                : _searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search, 
                              size: 64, 
                              color: AppTheme.textTertiary,
                            ),
                            const SizedBox(height: AppTheme.spacingMedium),
                            Text(
                              'No products found',
                              style: AppTheme.headingSmall.copyWith(
                                color: AppTheme.textTertiary,
                              ),
                            ),
                            const SizedBox(height: AppTheme.spacingXSmall),
                            Text(
                              'Try adjusting your search terms or category filter',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.textTertiary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(AppTheme.spacingMedium),
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final result = _searchResults[index];
                          return _buildProductCard(result);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(ProductSearchResult result) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                  child: result.product.imageUrls.isNotEmpty
                      ? Image.network(
                          result.product.imageUrls.first,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: 60,
                            height: 60,
                            color: AppTheme.backgroundColor,
                            child: Icon(Icons.image, color: AppTheme.textTertiary),
                          ),
                        )
                      : Container(
                          width: 60,
                          height: 60,
                          color: AppTheme.backgroundColor,
                          child: Icon(Icons.image, color: AppTheme.textTertiary),
                        ),
                ),
                const SizedBox(width: AppTheme.spacingSmall),
                // Product Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.product.name,
                        style: AppTheme.bodyLarge,
                      ),
                      if (result.product.brand.isNotEmpty)
                        Text(
                          result.product.brand,
                          style: AppTheme.bodyMedium,
                        ),
                      if (result.product.description.isNotEmpty)
                        Text(
                          result.product.description,
                          style: AppTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            // Business listings and price info
            Text(
              '${result.businessListings.length} business${result.businessListings.length == 1 ? '' : 'es'} selling this',
              style: AppTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              result.priceRangeDisplay,
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.successColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingSmall),
            // Add Pricing Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _addPricingForProduct(result.product),
                icon: Icon(
                  _canAddPricing ? Icons.add : Icons.lock,
                  color: AppTheme.backgroundColor,
                ),
                label: Text(
                  _canAddPricing ? 'Add Your Pricing' : 'Verification Required',
                  style: AppTheme.buttonText.copyWith(
                    color: AppTheme.backgroundColor,
                  ),
                ),
                style: _canAddPricing 
                    ? AppTheme.primaryButtonStyle
                    : AppTheme.primaryButtonStyle.copyWith(
                        backgroundColor: MaterialStateProperty.all(AppTheme.textTertiary),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up search controller
    _searchController.dispose();
    super.dispose();
  }
}
