import 'package:flutter/material.dart';
import '../../models/price_listing.dart';
import '../../models/master_product.dart';
import '../../services/pricing_service.dart';
import '../../services/enhanced_user_service.dart';
import '../../theme/app_theme.dart';
import 'product_search_screen.dart';
import 'add_price_listing_screen.dart';

class BusinessPricingDashboard extends StatefulWidget {
  const BusinessPricingDashboard({super.key});

  @override
  State<BusinessPricingDashboard> createState() => _BusinessPricingDashboardState();
}

class _BusinessPricingDashboardState extends State<BusinessPricingDashboard> {
  final PricingService _pricingService = PricingService();
  final EnhancedUserService _userService = EnhancedUserService();
  
  List<PriceListing> _myListings = [];
  bool _isLoading = true;
  bool _isEligible = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userId = _userService.currentUser?.uid;
      if (userId == null) {
        print('DEBUG: No user ID found');
        setState(() => _isLoading = false);
        return;
      }
      
      print('DEBUG: Loading data for userId: $userId');
      _userId = userId;
      final eligible = await _pricingService.isBusinessEligibleForPricing(userId);
      
      print('DEBUG: Business eligible for pricing: $eligible');
      setState(() => _isEligible = eligible);
      
      if (eligible) {
        print('DEBUG: Starting to listen for price listings...');
        _pricingService.getBusinessPriceListings(userId).listen((listings) {
          print('DEBUG: Received ${listings.length} price listings');
          if (mounted) {
            setState(() {
              _myListings = listings;
              _isLoading = false;
            });
          }
        }, onError: (error) {
          print('DEBUG: Error in price listings stream: $error');
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error loading listings: $error')),
            );
          }
        });
        
        // Add a timeout to prevent infinite loading
        Future.delayed(const Duration(seconds: 10), () {
          if (mounted && _isLoading) {
            print('DEBUG: Timeout reached, stopping loading');
            setState(() => _isLoading = false);
          }
        });
      } else {
        setState(() => _isLoading = false);
      }
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

  Future<void> _deleteListing(PriceListing listing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Price Listing'),
        content: Text('Are you sure you want to delete the price listing for "${listing.productName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _pricingService.deletePriceListing(listing.id, listing.masterProductId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Price listing deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting listing: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: const Text('My Price Listings'),
        elevation: 0,
        actions: [
          if (_isEligible)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductSearchScreen(),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildContent() {
    if (!_isEligible) {
      return _buildIneligibleState();
    }

    return Column(
      children: [
        _buildStatsHeader(),
        Expanded(child: _buildListingsList()),
      ],
    );
  }

  Widget _buildIneligibleState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.business_center_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Pricing Feature Not Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This feature is available for businesses in retail, product sales, and manufacturing categories. Service-based businesses are not eligible.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Text(
              'Excluded categories:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• Delivery Services\n• Services\n• Other',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    final totalListings = _myListings.length;
    final totalClicks = _myListings.fold<int>(0, (sum, listing) => sum + listing.clickCount);
    final activeListings = _myListings.where((l) => l.isAvailable).length;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Listings',
              totalListings.toString(),
              Icons.inventory,
              AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Active',
              activeListings.toString(),
              Icons.check_circle,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Total Clicks',
              totalClicks.toString(),
              Icons.mouse,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingsList() {
    if (_myListings.isEmpty) {
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
              'No price listings yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add prices for products to start comparing with competitors',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductSearchScreen(),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Price Listing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myListings.length,
      itemBuilder: (context, index) {
        return _buildListingCard(_myListings[index]);
      },
    );
  }

  Widget _buildListingCard(PriceListing listing) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.productName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${listing.brand} • ${listing.category}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${listing.currency} ${listing.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: listing.isAvailable ? Colors.green : Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        listing.isAvailable ? 'ACTIVE' : 'INACTIVE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Stats
            Row(
              children: [
                Icon(Icons.inventory, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Stock: ${listing.stockQuantity}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.mouse, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Clicks: ${listing.clickCount}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const Spacer(),
                Text(
                  'Updated: ${_formatDate(listing.updatedAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editPriceListing(listing),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Edit'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: const BorderSide(color: AppTheme.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deleteListing(listing),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
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

  // Helper method to create MasterProduct from PriceListing for editing
  MasterProduct _createMasterProductFromListing(PriceListing listing) {
    // This is a simplified approach - create a basic MasterProduct object
    // In a production app, you should fetch the actual MasterProduct from Firestore
    return MasterProduct(
      id: listing.masterProductId,
      name: listing.productName,
      brand: listing.brand,
      category: listing.category,
      subcategory: listing.subcategory,
      description: '', // Would need to fetch from master product
      images: [], // Would need to fetch from master product
      availableVariables: {}, // Would need to fetch from master product
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

    // Method to handle editing price listing by fetching actual master product
  Future<void> _editPriceListing(PriceListing listing) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Fetch the actual master product to get variables and other details
      final masterProductsStream = _pricingService.getMasterProducts(
        searchQuery: '',
        selectedBrand: '',
        selectedCategory: '',
      );
      
      await for (final products in masterProductsStream.take(1)) {
        MasterProduct? masterProduct;
        
        // Try to find the actual master product
        try {
          masterProduct = products.firstWhere(
            (product) => product.id == listing.masterProductId,
          );
        } catch (e) {
          // If not found, create a fallback with basic info but empty variables
          print('Master product not found, creating fallback: $e');
          masterProduct = MasterProduct(
            id: listing.masterProductId,
            name: listing.productName,
            brand: listing.brand,
            category: listing.category,
            subcategory: listing.subcategory,
            description: '',
            images: [],
            availableVariables: {}, // Empty - user won't see variables section
            isActive: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        }
        
        // Close loading dialog
        if (mounted) Navigator.pop(context);
        
        // Navigate to edit screen with proper master product data
        if (mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddPriceListingScreen(
                masterProduct: masterProduct!,
                existingListing: listing,
              ),
            ),
          );
          
          // Refresh the listings after editing
          _loadData();
        }
        break;
      }
    } catch (error) {
      print('Error fetching master product: $error');
      
      // Close loading dialog
      if (mounted) Navigator.pop(context);
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading product details: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return 'Recently';
    }
  }
}
