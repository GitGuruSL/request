// Price Comparison Screen - Central hub for product search and price comparison
// Features AI-powered product search, business listings, and click-through revenue

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_models.dart';
import '../models/business_models.dart';
import '../services/product_service.dart';
import '../services/business_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'product_detail_screen.dart';

class PriceComparisonScreen extends StatefulWidget {
  const PriceComparisonScreen({super.key});

  @override
  State<PriceComparisonScreen> createState() => _PriceComparisonScreenState();
}

class _PriceComparisonScreenState extends State<PriceComparisonScreen> {
  final ProductService _productService = ProductService();
  final BusinessService _businessService = BusinessService();
  final TextEditingController _searchController = TextEditingController();
  
  List<ProductSearchResult> _searchResults = [];
  List<MasterProduct> _uniqueProducts = [];
  List<ProductCategory> _categories = [];
  String? _selectedCategoryId;
  bool _isLoading = false;
  bool _isSearching = false;
  
  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadPopularProducts();
  }

  Future<void> _loadCategories() async {
    try {
      // Use hardcoded categories to bypass Firestore index requirements
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
          name: 'Fashion & Clothing',
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
          iconUrl: '🏡',
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
      });
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  Future<void> _loadPopularProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _productService.getPopularProducts(limit: 10);
      setState(() {
        _searchResults = results;
        _extractUniqueProducts(results);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading popular products: $e');
    }
  }

  void _extractUniqueProducts(List<ProductSearchResult> results) {
    final productMap = <String, MasterProduct>{};
    for (final result in results) {
      productMap[result.product.id] = result.product;
    }
    _uniqueProducts = productMap.values.toList();
  }

  void _onProductClick(MasterProduct product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(
          productId: product.id,
          productName: product.name,
        ),
      ),
    );
  }

  Future<void> _searchProducts() async {
    if (_searchController.text.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _productService.searchProducts(
        query: _searchController.text.trim(),
        categoryId: _selectedCategoryId,
        limit: 20,
      );
      
      setState(() {
        _searchResults = results;
        _extractUniqueProducts(results);
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
      print('Error searching products: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBFE),
      appBar: AppBar(
        title: const Text(
          'Price Comparison',
          style: TextStyle(
            color: Color(0xFF1D1B20),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1D1B20),
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Search Header
          Container(
            padding: const EdgeInsets.all(20),
            color: const Color(0xFFFFFBFE),
            child: Column(
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF49454F),
                        fontSize: 16,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF49454F),
                      ),
                      suffixIcon: _isSearching
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF6750A4),
                                ),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Color(0xFF49454F),
                              ),
                            onPressed: () {
                              _searchController.clear();
                              _loadPopularProducts(); // Load popular products when clearing search
                            },
                          ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    onSubmitted: (_) => _searchProducts(),
                  ),
                ),
                const SizedBox(height: 12),
                // Category Filter
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: const Text(
                              'All',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            selected: _selectedCategoryId == null,
                            selectedColor: const Color(0xFF6750A4),
                            backgroundColor: Colors.white,
                            checkmarkColor: Colors.white,
                            labelStyle: TextStyle(
                              color: _selectedCategoryId == null 
                                  ? Colors.white 
                                  : const Color(0xFF1D1B20),
                            ),
                            side: BorderSide.none,
                            elevation: 0,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategoryId = null;
                              });
                              if (_searchController.text.isNotEmpty) {
                                _searchProducts();
                              } else {
                                _loadPopularProducts();
                              }
                            },
                          ),
                        );
                      }
                      
                      final category = _categories[index - 1];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            category.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          selected: _selectedCategoryId == category.id,
                          selectedColor: const Color(0xFF6750A4),
                          backgroundColor: Colors.white,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: _selectedCategoryId == category.id 
                                ? Colors.white 
                                : const Color(0xFF1D1B20),
                          ),
                          side: BorderSide.none,
                          elevation: 0,
                          onSelected: (selected) {
                            setState(() {
                              _selectedCategoryId = selected ? category.id : null;
                            });
                            if (_searchController.text.isNotEmpty) {
                              _searchProducts();
                            } else {
                              _loadPopularProducts();
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Results Section
          Expanded(
            child: Column(
              children: [
                // Results Header
                if (_searchResults.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Colors.grey[50],
                    child: Text(
                      _searchController.text.trim().isEmpty 
                          ? '🔥 Popular Products' 
                          : '🔍 Search Results for "${_searchController.text.trim()}"',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                
                // Results List
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _uniqueProducts.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _uniqueProducts.length,
                              itemBuilder: (context, index) {
                                final product = _uniqueProducts[index];
                                // Find the price range for this product
                                final productResult = _searchResults.firstWhere(
                                  (result) => result.product.id == product.id,
                                );
                                return UniqueProductCard(
                                  product: product,
                                  productResult: productResult,
                                  onProductClick: _onProductClick,
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "price_comparison_fab", // Unique hero tag
        onPressed: () {
          // Navigate to add product screen for businesses
          Navigator.pushNamed(context, '/add-product');
        },
        backgroundColor: Colors.blue[600],
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No products found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching with different keywords',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class UniqueProductCard extends StatelessWidget {
  final MasterProduct product;
  final ProductSearchResult productResult;
  final Function(MasterProduct) onProductClick;

  const UniqueProductCard({
    super.key,
    required this.product,
    required this.productResult,
    required this.onProductClick,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate price range
    final prices = productResult.businessListings
        .map((listing) => listing.price)
        .toList()
      ..sort();
    
    final minPrice = prices.isNotEmpty ? prices.first : 0.0;
    final maxPrice = prices.isNotEmpty ? prices.last : 0.0;
    final sellerCount = productResult.businessListings.length;

    return GestureDetector(
      onTap: () => onProductClick(product),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                  child: product.imageUrls.isNotEmpty
                      ? Image.network(
                          product.imageUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image_not_supported, size: 40),
                        )
                      : const Icon(Icons.image_not_supported, size: 40),
                ),
              ),
              const SizedBox(width: 16),
              
              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1B20),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.brand,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF49454F),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          'LKR ${minPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1D1B20),
                          ),
                        ),
                        if (minPrice != maxPrice) ...[
                          const Text(
                            ' - ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF49454F),
                            ),
                          ),
                          Text(
                            '${maxPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF49454F),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$sellerCount seller${sellerCount > 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6750A4),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Arrow Icon
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Color(0xFF49454F),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductComparisonCard extends StatelessWidget {
  final ProductSearchResult result;
  final Function(BusinessProduct) onProductClick;

  const ProductComparisonCard({
    super.key,
    required this.result,
    required this.onProductClick,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Product Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Product Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: result.product.imageUrls.isNotEmpty
                        ? Image.network(
                            result.product.imageUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.image_not_supported),
                          )
                        : const Icon(Icons.image_not_supported),
                  ),
                ),
                const SizedBox(width: 16),
                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.product.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.product.brand,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            result.priceRangeDisplay,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          if (result.bestDiscountDisplay != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                result.bestDiscountDisplay!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${result.totalBusinesses} seller${result.totalBusinesses == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Business Listings
          if (result.businessListings.isNotEmpty)
            Column(
              children: result.businessListings.take(3).map((listing) {
                return BusinessListingTile(
                  listing: listing,
                  isLowest: listing == result.cheapestListing,
                  onTap: () => onProductClick(listing),
                );
              }).toList(),
            ),
          
          // Show More Button
          if (result.businessListings.length > 3)
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextButton(
                onPressed: () {
                  _showAllListings(context, result);
                },
                child: Text('View all ${result.businessListings.length} sellers'),
              ),
            ),
        ],
      ),
    );
  }

  void _showAllListings(BuildContext context, ProductSearchResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  result.product.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: result.businessListings.length,
                    itemBuilder: (context, index) {
                      final listing = result.businessListings[index];
                      return BusinessListingTile(
                        listing: listing,
                        isLowest: listing == result.cheapestListing,
                        onTap: () {
                          Navigator.pop(context);
                          onProductClick(listing);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class BusinessListingTile extends StatefulWidget {
  final BusinessProduct listing;
  final bool isLowest;
  final VoidCallback onTap;

  const BusinessListingTile({
    super.key,
    required this.listing,
    required this.isLowest,
    required this.onTap,
  });

  @override
  State<BusinessListingTile> createState() => _BusinessListingTileState();
}

class _BusinessListingTileState extends State<BusinessListingTile> {
  BusinessProfile? _business;
  bool _isLoadingBusiness = true;

  @override
  void initState() {
    super.initState();
    _loadBusinessInfo();
  }

  Future<void> _loadBusinessInfo() async {
    try {
      final businessService = BusinessService();
      final business = await businessService.getBusinessProfile(widget.listing.businessId);
      setState(() {
        _business = business;
        _isLoadingBusiness = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingBusiness = false;
      });
      print('Error loading business info: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
        color: widget.isLowest ? Colors.green[50] : null,
      ),
      child: ListTile(
        onTap: widget.onTap,
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Business Logo
            GestureDetector(
              onTap: () {
                if (_business != null) {
                  _showBusinessProfile(context, _business!);
                }
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _isLoadingBusiness
                    ? const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : (_business?.basicInfo.logoUrl != null && _business!.basicInfo.logoUrl.isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              _business!.basicInfo.logoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.business, size: 20),
                            ),
                          )
                        : const Icon(Icons.business, size: 20),
              ),
            ),
            if (widget.isLowest) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'LOWEST',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        title: Row(
          children: [
            Text(
              'LKR ${widget.listing.price.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.listing.originalPrice != null && widget.listing.originalPrice! > widget.listing.price) ...[
              const SizedBox(width: 8),
              Text(
                'LKR ${widget.listing.originalPrice!.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 12,
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isLoadingBusiness 
                  ? 'Loading business...' 
                  : _business?.basicInfo.name ?? 'Unknown Business',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text('Delivery: LKR ${widget.listing.deliveryInfo?.cost?.toStringAsFixed(2) ?? '0.00'}'),
            Text('Warranty: ${widget.listing.warrantyInfo?.months ?? 0} months'),
            if (!widget.listing.isInStock)
              const Text(
                'Out of Stock',
                style: TextStyle(color: Colors.red),
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }

  void _showBusinessProfile(BuildContext context, BusinessProfile business) {
    showDialog(
      context: context,
      builder: (context) => BusinessProfileDialog(business: business),
    );
  }
}

class BusinessProfileDialog extends StatefulWidget {
  final BusinessProfile business;

  const BusinessProfileDialog({super.key, required this.business});

  @override
  State<BusinessProfileDialog> createState() => _BusinessProfileDialogState();
}

class _BusinessProfileDialogState extends State<BusinessProfileDialog> {
  late ProductService _productService;
  List<ProductSearchResult> _businessProducts = [];
  bool _isLoadingProducts = true;

  @override
  void initState() {
    super.initState();
    _productService = ProductService();
    _loadBusinessProducts();
  }

  Future<void> _loadBusinessProducts() async {
    try {
      final products = await _productService.getEnrichedBusinessProducts(widget.business.id);
      setState(() {
        _businessProducts = products;
        _isLoadingProducts = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingProducts = false;
      });
      print('Error loading business products: $e');
    }
  }

  Future<void> _buyProduct(ProductSearchResult productResult) async {
    try {
      final businessProduct = productResult.businessListings.first;
      
      // Record click for revenue tracking
      await _productService.recordProductClick(
        businessProductId: businessProduct.id,
        userId: 'current_user_id', // Replace with actual user ID
        referrer: 'business_profile_dialog',
        metadata: {
          'business_id': widget.business.id,
          'business_name': widget.business.basicInfo.name,
        },
      );

      // Launch business URL if available
      if (businessProduct.businessUrl != null && businessProduct.businessUrl!.isNotEmpty) {
        final url = Uri.parse(businessProduct.businessUrl!);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to open product link')),
          );
        }
      } else {
        // Show contact options for the product
        _showContactOptions(productResult);
      }
    } catch (e) {
      print('Error handling product purchase: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error opening product link')),
      );
    }
  }

  void _showContactOptions(ProductSearchResult productResult) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Contact Business for ${productResult.product.name}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            if (widget.business.basicInfo.phone.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.phone),
                title: Text('Call ${widget.business.basicInfo.phone}'),
                onTap: () async {
                  final url = Uri.parse('tel:${widget.business.basicInfo.phone}');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                  Navigator.pop(context);
                },
              ),
            if (widget.business.basicInfo.whatsapp != null)
              ListTile(
                leading: const Icon(Icons.message),
                title: Text('WhatsApp ${widget.business.basicInfo.whatsapp}'),
                onTap: () async {
                  final url = Uri.parse('https://wa.me/${widget.business.basicInfo.whatsapp}?text=Hi, I\'m interested in ${productResult.product.name}');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                  Navigator.pop(context);
                },
              ),
            if (widget.business.basicInfo.email != null)
              ListTile(
                leading: const Icon(Icons.email),
                title: Text('Email ${widget.business.basicInfo.email}'),
                onTap: () async {
                  final url = Uri.parse('mailto:${widget.business.basicInfo.email}?subject=Inquiry about ${productResult.product.name}');
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url);
                  }
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: Column(
          children: [
            // Business Header with Logo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue[600],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Business Logo
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: widget.business.basicInfo.logoUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(28),
                                child: Image.network(
                                  widget.business.basicInfo.logoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.business, size: 30, color: Colors.grey),
                                ),
                              )
                            : const Icon(Icons.business, size: 30, color: Colors.grey),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.business.basicInfo.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.business.basicInfo.description,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.white70),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.business.basicInfo.address.fullAddress,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.phone, size: 16, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        widget.business.basicInfo.phone,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Products Section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shopping_bag, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Products (${_businessProducts.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    // Products List
                    Expanded(
                      child: _isLoadingProducts
                          ? const Center(child: CircularProgressIndicator())
                          : _businessProducts.isEmpty
                              ? const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.inventory_2, size: 64, color: Colors.grey),
                                      SizedBox(height: 16),
                                      Text(
                                        'No products available',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _businessProducts.length,
                                  itemBuilder: (context, index) {
                                    final productResult = _businessProducts[index];
                                    final product = productResult.product;
                                    final businessProduct = productResult.businessListings.first;
                                    
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.04),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          children: [
                                            Row(
                                              children: [
                                                // Product Image (business or master product image)
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Container(
                                                    width: 80,
                                                    height: 80,
                                                    color: Colors.grey[200],
                                                    child: _getProductImage(businessProduct, product),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                
                                                // Product Info
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        product.name,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.bold,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        product.brand,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey[600],
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      Row(
                                                        children: [
                                                          Text(
                                                            'LKR ${businessProduct.price.toStringAsFixed(2)}',
                                                            style: const TextStyle(
                                                              fontSize: 16,
                                                              fontWeight: FontWeight.bold,
                                                              color: Colors.green,
                                                            ),
                                                          ),
                                                          if (businessProduct.originalPrice != null && 
                                                              businessProduct.originalPrice! > businessProduct.price) ...[
                                                            const SizedBox(width: 8),
                                                            Text(
                                                              'LKR ${businessProduct.originalPrice!.toStringAsFixed(2)}',
                                                              style: const TextStyle(
                                                                fontSize: 12,
                                                                decoration: TextDecoration.lineThrough,
                                                                color: Colors.grey,
                                                              ),
                                                            ),
                                                          ],
                                                        ],
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            businessProduct.isInStock 
                                                                ? Icons.check_circle 
                                                                : Icons.cancel,
                                                            size: 14,
                                                            color: businessProduct.isInStock 
                                                                ? Colors.green 
                                                                : Colors.red,
                                                          ),
                                                          const SizedBox(width: 4),
                                                          Text(
                                                            businessProduct.isInStock 
                                                                ? 'In Stock' 
                                                                : 'Out of Stock',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: businessProduct.isInStock 
                                                                  ? Colors.green 
                                                                  : Colors.red,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            
                                            // Additional Product Images (if any)
                                            if (businessProduct.additionalImages.isNotEmpty) ...[
                                              const SizedBox(height: 12),
                                              SizedBox(
                                                height: 60,
                                                child: ListView.builder(
                                                  scrollDirection: Axis.horizontal,
                                                  itemCount: businessProduct.additionalImages.length,
                                                  itemBuilder: (context, imgIndex) {
                                                    return Container(
                                                      margin: const EdgeInsets.only(right: 8),
                                                      child: ClipRRect(
                                                        borderRadius: BorderRadius.circular(6),
                                                        child: Image.network(
                                                          businessProduct.additionalImages[imgIndex],
                                                          width: 60,
                                                          height: 60,
                                                          fit: BoxFit.cover,
                                                          errorBuilder: (context, error, stackTrace) =>
                                                              Container(
                                                                width: 60,
                                                                height: 60,
                                                                color: Colors.grey[200],
                                                                child: const Icon(Icons.image_not_supported),
                                                              ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                            
                                            // Buy Now Button
                                            const SizedBox(height: 12),
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton.icon(
                                                onPressed: businessProduct.isInStock 
                                                    ? () => _buyProduct(productResult)
                                                    : null,
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.orange,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                                ),
                                                icon: const Icon(Icons.shopping_cart),
                                                label: Text(
                                                  businessProduct.businessUrl != null && businessProduct.businessUrl!.isNotEmpty
                                                      ? 'Buy Now - Visit Store'
                                                      : 'Contact Business',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Footer Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  if (widget.business.basicInfo.website != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final url = Uri.parse(widget.business.basicInfo.website!);
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.language),
                        label: const Text('Visit Website'),
                      ),
                    ),
                  if (widget.business.basicInfo.website != null)
                    const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final url = Uri.parse('tel:${widget.business.basicInfo.phone}');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url);
                        }
                      },
                      icon: const Icon(Icons.phone),
                      label: const Text('Call Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getProductImage(BusinessProduct businessProduct, MasterProduct product) {
    // Prioritize business-specific images, then master product images
    List<String> imagesToTry = [
      ...businessProduct.additionalImages,
      ...product.imageUrls,
    ];

    if (imagesToTry.isNotEmpty) {
      return Image.network(
        imagesToTry.first,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.image_not_supported),
      );
    } else {
      return const Icon(Icons.image_not_supported);
    }
  }
}
