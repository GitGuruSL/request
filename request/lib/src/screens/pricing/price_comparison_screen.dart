import 'package:flutter/material.dart';
import '../../models/price_listing.dart';
import '../../services/pricing_service.dart';
import '../../theme/app_theme.dart';

class PriceComparisonScreen extends StatefulWidget {
  const PriceComparisonScreen({super.key});

  @override
  State<PriceComparisonScreen> createState() => _PriceComparisonScreenState();
}

class _PriceComparisonScreenState extends State<PriceComparisonScreen> {
  final PricingService _pricingService = PricingService();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _products = [];
  List<PriceListing> _priceListings = [];
  bool _isSearching = false;
  bool _isLoadingPrices = false;
  String? _selectedProductId;
  String? _selectedProductName;

  @override
  void initState() {
    super.initState();
    _loadPopularProducts();
  }

  Future<void> _loadPopularProducts() async {
    setState(() => _isSearching = true);
    try {
      final products =
          await _pricingService.searchProducts(query: '', limit: 20);
      setState(() {
        _products = products;
        _isSearching = false;
      });
    } catch (e) {
      print('Error loading popular products: $e');
      setState(() => _isSearching = false);
    }
  }

  Future<void> _searchProducts() async {
    if (_searchController.text.trim().isEmpty) {
      _loadPopularProducts();
      return;
    }

    setState(() => _isSearching = true);
    try {
      final products = await _pricingService.searchProducts(
        query: _searchController.text.trim(),
        limit: 50,
      );
      setState(() {
        _products = products;
        _isSearching = false;
      });
    } catch (e) {
      print('Error searching products: $e');
      setState(() => _isSearching = false);
    }
  }

  Future<void> _loadPricesForProduct(
      String productId, String productName) async {
    setState(() {
      _isLoadingPrices = true;
      _selectedProductId = productId;
      _selectedProductName = productName;
      _priceListings = [];
    });

    try {
      await for (final listings
          in _pricingService.getPriceListingsForProduct(productId).take(1)) {
        setState(() {
          _priceListings = listings;
          _isLoadingPrices = false;
        });
      }
    } catch (e) {
      print('Error loading prices: $e');
      setState(() => _isLoadingPrices = false);
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedProductId = null;
      _selectedProductName = null;
      _priceListings = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        title: const Text('Price Comparison'),
        elevation: 0,
        actions: [
          if (_selectedProductId != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearSelection,
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchSection(),
          Expanded(
            child: _selectedProductId == null
                ? _buildProductsList()
                : _buildPriceComparisonList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search for products (iPhone, Samsung TV, Rice, etc.)',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _loadPopularProducts();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryColor),
              ),
            ),
            onChanged: (value) {
              setState(() {});
              if (value.isEmpty) {
                _loadPopularProducts();
              }
            },
            onSubmitted: (value) => _searchProducts(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _searchProducts,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Search Products'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(dynamic product) {
    final name = product.name ?? 'Unknown Product';
    final brand = product.brand ?? '';
    final listingCount = product.businessListingsCount ?? 0;
    final minPrice = product.minPrice;
    final maxPrice = product.maxPrice;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _loadPricesForProduct(product.id, name),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (brand.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        brand,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.store,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$listingCount sellers',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (minPrice != null && maxPrice != null) ...[
                          const SizedBox(width: 16),
                          Text(
                            'LKR ${minPrice.toStringAsFixed(0)} - ${maxPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceComparisonList() {
    return Column(
      children: [
        // Selected product header
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedProductName ?? '',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Comparing prices from ${_priceListings.length} sellers',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Price listings
        Expanded(
          child: _isLoadingPrices
              ? const Center(child: CircularProgressIndicator())
              : _priceListings.isEmpty
                  ? _buildNoPricesFound()
                  : _buildPricesList(),
        ),
      ],
    );
  }

  Widget _buildNoPricesFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.price_check_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No prices available yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Be the first to know when businesses add prices for this product',
            style: TextStyle(color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPricesList() {
    // Sort by price (cheapest first)
    final sortedListings = List<PriceListing>.from(_priceListings)
      ..sort((a, b) => a.price.compareTo(b.price));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedListings.length,
      itemBuilder: (context, index) {
        final listing = sortedListings[index];
        final isLowestPrice = index == 0;

        return _buildPriceCard(listing, isLowestPrice);
      },
    );
  }

  Widget _buildPriceCard(PriceListing listing, bool isLowestPrice) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isLowestPrice
            ? const BorderSide(color: Colors.green, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with price and badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${listing.currency} ${listing.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isLowestPrice
                                  ? Colors.green
                                  : AppTheme.primaryColor,
                            ),
                          ),
                          if (isLowestPrice) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'LOWEST PRICE',
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
                      const SizedBox(height: 4),
                      Text(
                        listing.businessName ?? 'Business',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Product details
            if (listing.modelNumber?.isNotEmpty == true) ...[
              Text(
                'Model: ${listing.modelNumber}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Contact info
            Row(
              children: [
                Icon(
                  Icons.business,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  listing.businessName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Contact buttons
            Row(
              children: [
                if (listing.whatsappNumber?.isNotEmpty == true) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _contactBusiness('whatsapp', listing.whatsappNumber!),
                      icon: const Icon(Icons.phone, size: 16),
                      label: const Text('WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (listing.productLink?.isNotEmpty == true) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _contactBusiness('website', listing.productLink!),
                      icon: const Icon(Icons.web, size: 16),
                      label: const Text('Website'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _contactBusiness(String type, String contact) {
    // Track the contact attempt
    _pricingService.trackProductClick(
      listingId: _selectedProductId,
      masterProductId: _selectedProductId,
      businessId: null, // We'd need to pass this from the listing
    );

    // Here you would implement the actual contact functionality
    // For WhatsApp: launch WhatsApp with the number
    // For Website: launch the website URL
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Contact: $contact'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
