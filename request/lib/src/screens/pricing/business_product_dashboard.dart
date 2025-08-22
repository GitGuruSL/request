import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/pricing_service.dart';
import '../../services/enhanced_user_service.dart';
import '../../services/file_upload_service.dart';
import '../../theme/app_theme.dart';

class BusinessProductDashboard extends StatefulWidget {
  const BusinessProductDashboard({super.key});

  @override
  State<BusinessProductDashboard> createState() =>
      _BusinessProductDashboardState();
}

class _BusinessProductDashboardState extends State<BusinessProductDashboard> {
  final PricingService _pricingService = PricingService();
  final EnhancedUserService _userService = EnhancedUserService();
  final FileUploadService _fileUploadService = FileUploadService();
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _countryProducts = [];
  List<dynamic> _myPriceListings = [];
  bool _isSearching = false;
  bool _isLoadingMyPrices = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadCountryProducts(),
      _loadMyPriceListings(),
    ]);
  }

  Future<void> _loadCountryProducts() async {
    setState(() => _isSearching = true);
    try {
      final products =
          await _pricingService.searchProducts(query: '', limit: 50);
      setState(() {
        _countryProducts = products;
        _isSearching = false;
      });
    } catch (e) {
      print('Error loading country products: $e');
      setState(() => _isSearching = false);
    }
  }

  Future<void> _loadMyPriceListings() async {
    setState(() => _isLoadingMyPrices = true);
    try {
      final userId = _userService.currentUser?.uid;
      if (userId == null) return;

      await for (final listings
          in _pricingService.getBusinessPriceListings(userId).take(1)) {
        setState(() {
          _myPriceListings = listings;
          _isLoadingMyPrices = false;
        });
        break;
      }
    } catch (e) {
      print('Error loading my price listings: $e');
      setState(() => _isLoadingMyPrices = false);
    }
  }

  Future<void> _searchProducts() async {
    if (_searchController.text.trim().isEmpty) {
      _loadCountryProducts();
      return;
    }

    setState(() => _isSearching = true);
    try {
      final products = await _pricingService.searchProducts(
        query: _searchController.text.trim(),
        limit: 50,
      );
      setState(() {
        _countryProducts = products;
        _isSearching = false;
      });
    } catch (e) {
      print('Error searching products: $e');
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundColor,
          foregroundColor: AppTheme.textPrimary,
          title: const Text('Product Dashboard'),
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Add Prices', icon: Icon(Icons.add_business)),
              Tab(text: 'My Prices', icon: Icon(Icons.price_check)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAddPricesTab(),
            _buildMyPricesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAddPricesTab() {
    return Column(
      children: [
        _buildSearchSection(),
        Expanded(child: _buildProductsList()),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Search products to add your prices',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search products (iPhone, Samsung TV, Rice, etc.)',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _loadCountryProducts();
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
            onChanged: (value) => setState(() {}),
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

    if (_countryProducts.isEmpty) {
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
      itemCount: _countryProducts.length,
      itemBuilder: (context, index) {
        final product = _countryProducts[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(dynamic product) {
    final name = product.name ?? 'Unknown Product';
    final brand = product.brand ?? '';
    final hasExistingPrice = _myPriceListings
        .any((listing) => listing.masterProductId == product.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  if (hasExistingPrice) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'PRICE ADDED',
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
            ),
            ElevatedButton(
              onPressed: () => _addEditPrice(product),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    hasExistingPrice ? Colors.orange : AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text(hasExistingPrice ? 'Edit Price' : 'Add Price'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyPricesTab() {
    if (_isLoadingMyPrices) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_myPriceListings.isEmpty) {
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
              'No prices added yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add prices for products to start selling',
              style: TextStyle(color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myPriceListings.length,
      itemBuilder: (context, index) {
        final listing = _myPriceListings[index];
        return _buildMyPriceCard(listing);
      },
    );
  }

  Widget _buildMyPriceCard(dynamic listing) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.productName ?? 'Product',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        listing.brand ?? '',
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
                      '${listing.currency ?? 'LKR'} ${listing.price?.toStringAsFixed(2) ?? '0.00'}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: listing.isAvailable == true
                            ? Colors.green
                            : Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        listing.isAvailable == true ? 'ACTIVE' : 'INACTIVE',
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
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editPrice(listing),
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
                    onPressed: () => _deletePrice(listing),
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

  void _addEditPrice(dynamic product) {
    _showPriceDialog(product: product);
  }

  void _editPrice(dynamic listing) {
    _showPriceDialog(existingListing: listing);
  }

  void _showPriceDialog({dynamic product, dynamic existingListing}) {
    final isEditing = existingListing != null;
    final TextEditingController priceController = TextEditingController(
      text: isEditing ? existingListing.price?.toString() ?? '' : '',
    );
    final TextEditingController whatsappController = TextEditingController(
      text: isEditing ? existingListing.whatsappNumber ?? '' : '',
    );
    final TextEditingController websiteController = TextEditingController(
      text: isEditing ? existingListing.productLink ?? '' : '',
    );

    List<File> selectedImages = [];
    List<String> existingImageUrls =
        isEditing ? List<String>.from(existingListing.productImages ?? []) : [];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Edit Price' : 'Add Price'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  Text(
                    isEditing
                        ? existingListing.productName ?? 'Product'
                        : product.name ?? 'Product',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Price input
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Price (LKR)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // WhatsApp number
                  TextField(
                    controller: whatsappController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'WhatsApp Number (Optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Website/Product link
                  TextField(
                    controller: websiteController,
                    decoration: const InputDecoration(
                      labelText: 'Website/Product Link (Optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Images section
                  const Text(
                    'Product Images',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),

                  // Show existing images
                  if (existingImageUrls.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: existingImageUrls
                          .map((url) => Stack(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: NetworkImage(url),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: -4,
                                    right: -4,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, size: 16),
                                      onPressed: () {
                                        setDialogState(() {
                                          existingImageUrls.remove(url);
                                        });
                                      },
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Show selected new images
                  if (selectedImages.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selectedImages
                          .map((file) => Stack(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: FileImage(file),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: -4,
                                    right: -4,
                                    child: IconButton(
                                      icon: const Icon(Icons.close, size: 16),
                                      onPressed: () {
                                        setDialogState(() {
                                          selectedImages.remove(file);
                                        });
                                      },
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Add image button
                  OutlinedButton.icon(
                    onPressed: () async {
                      final ImagePicker picker = ImagePicker();
                      final XFile? image =
                          await picker.pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        setDialogState(() {
                          selectedImages.add(File(image.path));
                        });
                      }
                    },
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('Add Image'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _savePrice(
                  product: product,
                  existingListing: existingListing,
                  price: priceController.text,
                  whatsapp: whatsappController.text,
                  website: websiteController.text,
                  newImages: selectedImages,
                  existingImages: existingImageUrls,
                );
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: Text(isEditing ? 'Update' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePrice({
    dynamic product,
    dynamic existingListing,
    required String price,
    required String whatsapp,
    required String website,
    required List<File> newImages,
    required List<String> existingImages,
  }) async {
    if (price.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a price'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Upload new images
      List<String> imageUrls = List.from(existingImages);
      for (final imageFile in newImages) {
        final imageUrl = await _fileUploadService.uploadFile(
          imageFile,
          path: 'price_listings/${DateTime.now().millisecondsSinceEpoch}',
        );
        imageUrls.add(imageUrl);
      }

      // Create API payload
      final apiPayload = {
        'masterProductId': existingListing?.masterProductId ?? product.id,
        'title': existingListing?.productName ?? product.name,
        'price': double.parse(price),
        'currency': 'LKR',
        'countryCode': 'LK',
        'categoryId': '732f29d3-637b-4c20-9c6d-e90f472143f7', // Electronics
        'images': imageUrls,
        if (whatsapp.isNotEmpty) 'whatsapp': whatsapp,
        if (website.isNotEmpty) 'website': website,
      };

      final success = await _pricingService.addOrUpdatePriceListing(apiPayload);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(existingListing != null
                ? 'Price updated successfully!'
                : 'Price added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadData(); // Refresh data
      } else {
        throw Exception('Failed to save price');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving price: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deletePrice(dynamic listing) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Price'),
        content: Text(
            'Are you sure you want to delete the price for "${listing.productName}"?'),
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
        await _pricingService.deletePriceListing(
            listing.id, listing.masterProductId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Price deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadData(); // Refresh data
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting price: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
