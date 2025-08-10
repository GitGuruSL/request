import 'package:flutter/material.dart';
import '../models/product_models.dart';
import '../models/business_models.dart';
import '../services/product_service.dart';
import '../services/business_service.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final String productName;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    required this.productName,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductService _productService = ProductService();
  final BusinessService _businessService = BusinessService();
  
  List<BusinessProduct> _businessListings = [];
  bool _isLoading = true;
  String _sortBy = 'price_low'; // price_low, price_high, delivery_time, warranty
  String _selectedLocation = 'all';
  
  @override
  void initState() {
    super.initState();
    _loadProductListings();
  }

  Future<void> _loadProductListings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await _productService.searchProducts(
        query: '',
        categoryId: null,
      );
      
      // Find all business listings for this specific product
      final productListings = <BusinessProduct>[];
      for (final result in results) {
        if (result.product.id == widget.productId) {
          productListings.addAll(result.businessListings);
        }
      }
      
      setState(() {
        _businessListings = productListings;
        _sortListings();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading product listings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _sortListings() {
    switch (_sortBy) {
      case 'price_low':
        _businessListings.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        _businessListings.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'delivery_time':
        _businessListings.sort((a, b) => (a.deliveryInfo?.estimatedDays ?? 99).compareTo(b.deliveryInfo?.estimatedDays ?? 99));
        break;
      case 'warranty':
        _businessListings.sort((a, b) => (b.warrantyInfo?.months ?? 0).compareTo(a.warrantyInfo?.months ?? 0));
        break;
    }
  }

  void _showBusinessDetails(BusinessProduct listing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BusinessDetailsModal(
        businessId: listing.businessId,
        productListing: listing,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBFE),
      appBar: AppBar(
        title: Text(
          widget.productName,
          style: const TextStyle(
            color: Color(0xFF1D1B20),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1D1B20),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Color(0xFF1D1B20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Filters and Sort
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFE7E0EC),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Sort Dropdown
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _sortBy,
                    decoration: InputDecoration(
                      labelText: 'Sort by',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'price_low', child: Text('Price: Low to High')),
                      DropdownMenuItem(value: 'price_high', child: Text('Price: High to Low')),
                      DropdownMenuItem(value: 'delivery_time', child: Text('Fastest Delivery')),
                      DropdownMenuItem(value: 'warranty', child: Text('Best Warranty')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _sortBy = value;
                          _sortListings();
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                // Filter Button
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implement filter modal
                  },
                  icon: const Icon(Icons.filter_list, size: 18),
                  label: const Text('Filter'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE7E0EC)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Product Listings
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _businessListings.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Color(0xFF9CA3AF),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No listings found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _businessListings.length,
                        itemBuilder: (context, index) {
                          final listing = _businessListings[index];
                          final isLowest = index == 0 && _sortBy == 'price_low';
                          
                          return GestureDetector(
                            onTap: () => _showBusinessDetails(listing),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isLowest ? const Color(0xFFE8F5E8) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Business Logo Placeholder
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE7E0EC),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.store,
                                      color: Color(0xFF6750A4),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  
                                  // Business Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'LKR ${listing.price.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1D1B20),
                                              ),
                                            ),
                                            if (isLowest) ...[
                                              const SizedBox(width: 8),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF4CAF50),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'LOWEST',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          listing.businessName ?? listing.businessId, // Use business name if available
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: Color(0xFF1D1B20),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              'Delivery: LKR ${listing.deliveryInfo?.cost?.toStringAsFixed(2) ?? '0.00'}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF49454F),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Text(
                                              'Warranty: ${listing.warrantyInfo?.months ?? 0} months',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF49454F),
                                              ),
                                            ),
                                          ],
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
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class BusinessDetailsModal extends StatefulWidget {
  final String businessId;
  final BusinessProduct productListing;

  const BusinessDetailsModal({
    super.key,
    required this.businessId,
    required this.productListing,
  });

  @override
  State<BusinessDetailsModal> createState() => _BusinessDetailsModalState();
}

class _BusinessDetailsModalState extends State<BusinessDetailsModal> {
  final BusinessService _businessService = BusinessService();
  BusinessProfile? _business;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBusinessDetails();
  }

  Future<void> _loadBusinessDetails() async {
    try {
      final business = await _businessService.getBusinessProfile(widget.businessId);
      setState(() {
        _business = business;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading business details: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE7E0EC),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text(
                  'Business Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1B20),
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _business == null
                    ? const Center(child: Text('Business not found'))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Business Info
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F2FA),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _business!.basicInfo.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1D1B20),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _business!.basicInfo.description,
                                    style: const TextStyle(
                                      color: Color(0xFF49454F),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Icon(Icons.email, size: 16, color: Color(0xFF49454F)),
                                      const SizedBox(width: 8),
                                      Text(
                                        _business!.basicInfo.email,
                                        style: const TextStyle(color: Color(0xFF49454F)),
                                      ),
                                    ],
                                  ),
                                  if (_business!.basicInfo.phone.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        const Icon(Icons.phone, size: 16, color: Color(0xFF49454F)),
                                        const SizedBox(width: 8),
                                        Text(
                                          _business!.basicInfo.phone,
                                          style: const TextStyle(color: Color(0xFF49454F)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Product Details
                            const Text(
                              'Product Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1D1B20),
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFE7E0EC)),
                              ),
                              child: Column(
                                children: [
                                  _buildDetailRow('Price', 'LKR ${widget.productListing.price.toStringAsFixed(2)}'),
                                  const Divider(),
                                  _buildDetailRow('Delivery Cost', 'LKR ${widget.productListing.deliveryInfo?.cost?.toStringAsFixed(2) ?? '0.00'}'),
                                  const Divider(),
                                  _buildDetailRow('Delivery Days', '${widget.productListing.deliveryInfo?.estimatedDays ?? 0} days'),
                                  const Divider(),
                                  _buildDetailRow('Warranty', '${widget.productListing.warrantyInfo?.months ?? 0} months'),
                                  if (widget.productListing.stock > 0) ...[
                                    const Divider(),
                                    _buildDetailRow('In Stock', '${widget.productListing.stock} available'),
                                  ],
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Action Button
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () {
                                  // TODO: Implement contact business or visit store
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6750A4),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Contact Business',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF49454F),
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF1D1B20),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
