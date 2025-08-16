import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/master_product.dart';
import '../../models/price_listing.dart';
import '../../services/pricing_service.dart';
import '../../services/enhanced_user_service.dart';
import '../../services/comprehensive_notification_service.dart';
import '../../services/country_filtered_data_service.dart';
import '../../theme/app_theme.dart';
import 'add_price_listing_screen.dart';
import 'business_profile_modal.dart';

class PriceComparisonScreen extends StatefulWidget {
  final MasterProduct product;

  const PriceComparisonScreen({
    super.key,
    required this.product,
  });

  @override
  State<PriceComparisonScreen> createState() => _PriceComparisonScreenState();
}

class _PriceComparisonScreenState extends State<PriceComparisonScreen> {
  final PricingService _pricingService = PricingService();
  final EnhancedUserService _userService = EnhancedUserService();
  final ComprehensiveNotificationService _notificationService = ComprehensiveNotificationService();
  
  List<PriceListing> _priceListings = [];
  bool _isLoading = true;
  bool _canAddListing = false;
  String? _currentUserId;
  Map<String, String> _availableAttributes = {};
  Set<String> _notifiedBusinesses = {}; // Track which businesses we've already notified

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    print('DEBUG: Loading price comparison data for product: ${widget.product.name}');
    try {
      final userId = _userService.currentUser?.uid;
      if (userId != null) {
        _currentUserId = userId;
        print('DEBUG: Checking if user can add listing...');
        final canAdd = await _pricingService.isBusinessEligibleForPricing(userId);
        print('DEBUG: User can add listing: $canAdd');
        setState(() => _canAddListing = canAdd);
      }

      // Load available attributes for display
      await _loadAvailableAttributes();

      print('DEBUG: Starting to listen for price listings...');
      _pricingService.getPriceListingsForProduct(widget.product.id).listen((listings) {
        print('DEBUG: Received ${listings.length} price listings');
        if (mounted) {
          setState(() {
            _priceListings = listings;
            _isLoading = false;
          });
          
          // Send product inquiry notifications for newly visible listings
          _sendProductInquiryNotifications(listings);
        }
      }, onError: (error) {
        print('DEBUG: Error in price listings stream: $error');
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading price listings: $error')),
          );
        }
      });

      // Add timeout to prevent infinite loading
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && _isLoading) {
          print('DEBUG: Timeout reached, stopping loading');
          setState(() => _isLoading = false);
        }
      });
    } catch (e) {
      print('DEBUG: Exception in _loadData: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _loadAvailableAttributes() async {
    try {
      // Use country-filtered data service to get only active variable types
      final CountryFilteredDataService countryService = CountryFilteredDataService.instance;
      final activeVariableTypesData = await countryService.getActiveVariableTypes();

      final attributes = <String, String>{};
      for (final data in activeVariableTypesData) {
        final id = data['id'] ?? '';
        final name = data['name'] ?? id;
        if (id.isNotEmpty) {
          attributes[id] = name;
        }
      }

      if (mounted) {
        setState(() {
          _availableAttributes = attributes;
        });
      }
    } catch (e) {
      print('DEBUG: Error loading attributes: $e');
    }
  }

  String _formatAttributes(Map<String, String> selectedVariables) {
    final formattedAttributes = <String>[];
    for (final entry in selectedVariables.entries) {
      final attributeName = _availableAttributes[entry.key] ?? entry.key;
      formattedAttributes.add('$attributeName: ${entry.value}');
    }
    return formattedAttributes.join(' • ');
  }

  Future<void> _trackAndLaunchUrl(String url, PriceListing listing) async {
    if (_currentUserId != null) {
      await _pricingService.trackProductClick(
        listingId: listing.id,
        businessId: listing.businessId,
        masterProductId: listing.masterProductId,
        userId: _currentUserId!,
      );
    }

    final uri = Uri.parse(url.startsWith('http') ? url : 'https://$url');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the link')),
        );
      }
    }
  }

  Future<void> _launchWhatsApp(String number, String productName) async {
    final message = Uri.encodeComponent('Hi! I\'m interested in $productName');
    final whatsappUrl = 'https://wa.me/$number?text=$message';
    
    final uri = Uri.parse(whatsappUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp')),
        );
      }
    }
  }

  void _showBusinessProfile(String businessId) {
    showDialog(
      context: context,
      builder: (context) => BusinessProfileModal(businessId: businessId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        title: Text(widget.product.name),
        elevation: 0,
        actions: [
          if (_canAddListing)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _navigateToAddListing(),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildProductHeader(),
          Expanded(child: _buildPriceListings()),
        ],
      ),
    );
  }

  Widget _buildProductHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Product image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[100],
                ),
                child: widget.product.images.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.product.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.image, color: Colors.grey[400]),
                        ),
                      )
                    : Icon(Icons.image, color: Colors.grey[400]),
              ),
              
              const SizedBox(width: 16),
              
              // Product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.product.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.product.brand,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.product.category} • ${widget.product.subcategory}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (widget.product.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              widget.product.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Stats
          Row(
            children: [
              _buildStatChip(
                icon: Icons.store,
                label: '${_priceListings.length} sellers',
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              if (_priceListings.isNotEmpty)
                _buildStatChip(
                  icon: Icons.trending_down,
                  label: 'From LKR ${_getMinPrice().toStringAsFixed(2)}',
                  color: Colors.green,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceListings() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_priceListings.isEmpty) {
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
              'No prices listed yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first to list your price for this product',
              style: TextStyle(color: Colors.grey[500]),
            ),
            if (_canAddListing) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _navigateToAddListing(),
                icon: const Icon(Icons.add),
                label: const Text('Add Price'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _priceListings.length,
      itemBuilder: (context, index) {
        return _buildPriceListingCard(_priceListings[index], index);
      },
    );
  }

  Widget _buildPriceListingCard(PriceListing listing, int index) {
    final isLowest = index == 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isLowest ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isLowest 
            ? const BorderSide(color: Colors.green, width: 1)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with business info and price
            Row(
              children: [
                // Business logo
                GestureDetector(
                  onTap: () => _showBusinessProfile(listing.businessId),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: listing.businessLogo.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              listing.businessLogo,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Center(
                                    child: Text(
                                      listing.businessName[0].toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ),
                            ),
                          )
                        : Center(
                            child: Text(
                              listing.businessName[0].toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Business info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => _showBusinessProfile(listing.businessId),
                        child: Text(
                          listing.businessName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (listing.rating > 0)
                        Row(
                          children: [
                            Icon(Icons.star_rounded, size: 16, color: Colors.orange[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${listing.rating.toStringAsFixed(1)} (${listing.reviewCount})',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                
                // Price section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (isLowest)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'BEST PRICE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Text(
                      '${listing.currency} ${listing.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            // Product variables
            if (listing.selectedVariables.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _formatAttributes(listing.selectedVariables),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
            
            // Product images
            if (listing.productImages.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: listing.productImages.length,
                  itemBuilder: (context, imageIndex) {
                    return Container(
                      width: 60,
                      height: 60,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[100],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          listing.productImages[imageIndex],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.image, color: Colors.grey[400]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            
            // Stock and interaction info
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(
                    listing.stockQuantity > 0 ? Icons.inventory_2_rounded : Icons.info_outline,
                    size: 16,
                    color: listing.stockQuantity > 0 ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      listing.stockQuantity > 0
                          ? 'In Stock: ${listing.stockQuantity} units'
                          : 'Contact for availability',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (listing.clickCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${listing.clickCount} views',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // Action buttons
            const SizedBox(height: 16),
            Row(
              children: [
                // Contact WhatsApp
                if (listing.whatsappNumber?.isNotEmpty == true)
                  Expanded(
                    child: Container(
                      height: 40,
                      child: OutlinedButton.icon(
                        onPressed: () => _launchWhatsApp(
                          listing.whatsappNumber!,
                          listing.productName,
                        ),
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: const Text(
                          'WhatsApp',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green[600],
                          side: BorderSide(color: Colors.green[600]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
                
                if (listing.whatsappNumber?.isNotEmpty == true && 
                    listing.productLink?.isNotEmpty == true)
                  const SizedBox(width: 8),
                
                // Visit store
                if (listing.productLink?.isNotEmpty == true)
                  Expanded(
                    child: Container(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: () => _trackAndLaunchUrl(listing.productLink!, listing),
                        icon: const Icon(Icons.storefront_rounded, size: 18),
                        label: const Text(
                          'Visit Store',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  double _getMinPrice() {
    if (_priceListings.isEmpty) return 0.0;
    return _priceListings.map((l) => l.price).reduce((a, b) => a < b ? a : b);
  }

  void _navigateToAddListing() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddPriceListingScreen(
          masterProduct: widget.product,
        ),
      ),
    );
  }

  // Send product inquiry notifications to businesses
  Future<void> _sendProductInquiryNotifications(List<PriceListing> listings) async {
    try {
      final userId = _currentUserId;
      if (userId == null) return;

      final userModel = await _userService.getCurrentUserModel();
      if (userModel == null) return;

      for (final listing in listings) {
        // Don't notify the same business multiple times
        if (_notifiedBusinesses.contains(listing.businessId)) continue;
        
        // Don't notify if the user is viewing their own listing
        if (listing.businessId == userId) continue;

        await _notificationService.notifyProductInquiry(
          businessId: listing.businessId,
          businessName: listing.businessName,
          productName: listing.productName,
          inquirerId: userId,
          inquirerName: userModel.name,
        );

        _notifiedBusinesses.add(listing.businessId);
      }
    } catch (e) {
      print('Error sending product inquiry notifications: $e');
    }
  }
}
