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

  Future<void> _searchProducts([String? query]) async {
    final searchQuery = query ?? _searchController.text.trim();
    if (searchQuery.isEmpty) {
      _loadPopularProducts();
      return;
    }

    setState(() => _isSearching = true);
    try {
      final products = await _pricingService.searchProducts(
        query: searchQuery,
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

  Widget _buildSearchSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search for products (iPhone, Samsung TV, Rice, etc.)',
          prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
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
            borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onChanged: (value) {
          setState(() {});
          if (value.length >= 2) {
            _searchProducts(value);
          } else if (value.isEmpty) {
            _loadPopularProducts();
          }
        },
      ),
    );
  }

  Widget _buildProductCard(dynamic product) {
    final name = product.name ?? 'Unknown Product';
    final brand = product.brand ?? '';
    final listingCount =
        product.listingCount ?? product.businessListingsCount ?? 0;
    final minPrice = product.minPrice;
    final maxPrice = product.maxPrice;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _loadPricesForProduct(product.id, name),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Product image
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: product.images != null && product.images.isNotEmpty
                        ? Image.network(
                            product.images.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPlaceholderImage(name);
                            },
                          )
                        : _buildPlaceholderImage(name),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      if (brand.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          brand,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.store_outlined,
                                  size: 14,
                                  color: AppTheme.primaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$listingCount sellers',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (minPrice != null && maxPrice != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Starting from',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  'LKR ${minPrice.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(String productName) {
    final name = productName.toLowerCase();
    IconData icon;
    Color backgroundColor;

    if (name.contains('iphone') ||
        name.contains('samsung') ||
        name.contains('phone')) {
      icon = Icons.smartphone;
      backgroundColor = Colors.blue[100]!;
    } else if (name.contains('laptop') ||
        name.contains('macbook') ||
        name.contains('dell')) {
      icon = Icons.laptop;
      backgroundColor = Colors.purple[100]!;
    } else if (name.contains('tv') || name.contains('television')) {
      icon = Icons.tv;
      backgroundColor = Colors.green[100]!;
    } else if (name.contains('watch')) {
      icon = Icons.watch;
      backgroundColor = Colors.orange[100]!;
    } else if (name.contains('headphone') || name.contains('earphone')) {
      icon = Icons.headphones;
      backgroundColor = Colors.red[100]!;
    } else if (name.contains('camera')) {
      icon = Icons.camera_alt;
      backgroundColor = Colors.indigo[100]!;
    } else if (name.contains('shoe') ||
        name.contains('nike') ||
        name.contains('jordan')) {
      icon = Icons.sports_baseball;
      backgroundColor = Colors.teal[100]!;
    } else if (name.contains('car') || name.contains('vehicle')) {
      icon = Icons.directions_car;
      backgroundColor = Colors.cyan[100]!;
    } else {
      icon = Icons.shopping_bag;
      backgroundColor = Colors.grey[200]!;
    }

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: Colors.grey[700],
        size: 24,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            isLowestPrice ? Border.all(color: Colors.green, width: 2) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with business logo, price and badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Business Logo
                GestureDetector(
                  onTap: () => _showBusinessBottomSheet(listing),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[100],
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: listing.businessLogo.isNotEmpty
                          ? Image.network(
                              listing.businessLogo,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildBusinessLogoPlaceholder(
                                    listing.businessName);
                              },
                            )
                          : _buildBusinessLogoPlaceholder(listing.businessName),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
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
                      GestureDetector(
                        onTap: () => _showBusinessBottomSheet(listing),
                        child: Text(
                          listing.businessName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.primaryColor,
                            decoration: TextDecoration.underline,
                          ),
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

  Widget _buildBusinessLogoPlaceholder(String businessName) {
    final firstLetter =
        businessName.isNotEmpty ? businessName[0].toUpperCase() : 'B';
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.7),
            AppTheme.primaryColor,
          ],
        ),
      ),
      child: Center(
        child: Text(
          firstLetter,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showBusinessBottomSheet(PriceListing listing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Business header
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.grey[100],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: listing.businessLogo.isNotEmpty
                                ? Image.network(
                                    listing.businessLogo,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildBusinessLogoPlaceholder(
                                          listing.businessName);
                                    },
                                  )
                                : _buildBusinessLogoPlaceholder(
                                    listing.businessName),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                listing.businessName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Verified Business',
                                  style: TextStyle(
                                    color: Colors.green[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Product offer
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            listing.productName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                '${listing.currency} ${listing.price.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'In Stock',
                                  style: TextStyle(
                                    color: Colors.orange[700],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Business info
                    const Text(
                      'Business Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildInfoRow(
                        Icons.business, 'Business Type', 'Electronics Store'),
                    _buildInfoRow(Icons.star, 'Rating',
                        '${listing.rating}/5.0 (${listing.reviewCount} reviews)'),
                    _buildInfoRow(
                        Icons.location_on, 'Location', 'Colombo, Sri Lanka'),
                    _buildInfoRow(
                        Icons.verified, 'Verified', 'Business verified'),

                    const SizedBox(height: 20),

                    // Payment methods
                    const Text(
                      'Payment Methods',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildPaymentMethod('Cash'),
                        const SizedBox(width: 8),
                        _buildPaymentMethod('Card'),
                        const SizedBox(width: 8),
                        _buildPaymentMethod('Transfer'),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Action buttons
                    Row(
                      children: [
                        if (listing.whatsappNumber?.isNotEmpty == true) ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _contactBusiness(
                                  'whatsapp', listing.whatsappNumber!),
                              icon: const Icon(Icons.chat, size: 18),
                              label: const Text('WhatsApp'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _contactBusiness(
                                'website', listing.productLink ?? ''),
                            icon: const Icon(Icons.shopping_bag, size: 18),
                            label: Text('Shop at ${listing.businessName}'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod(String method) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        method,
        style: TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
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
