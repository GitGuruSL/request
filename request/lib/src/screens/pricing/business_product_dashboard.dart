import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../services/pricing_service.dart';
import '../../services/enhanced_user_service.dart';
import '../../services/file_upload_service.dart';
import '../../services/api_client.dart';
import '../../services/rest_auth_service.dart';
import '../../theme/glass_theme.dart';
import '../../services/user_registration_service.dart';

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
  List<dynamic> _countryVariables =
      []; // Available variables from country table
  bool _isSearching = false;
  bool _isLoadingMyPrices = false;
  bool _isSeller = true; // gated after registration check

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    print('DEBUG: Starting _loadData()...');

    // Determine if user is an approved business (seller)
    try {
      print('DEBUG: Checking user business registration...');
      final regs =
          await UserRegistrationService.instance.getUserRegistrations();
      _isSeller = regs?.isApprovedBusiness == true;
      print('DEBUG: User is seller: $_isSeller');
    } catch (e) {
      print('DEBUG: Error checking business registration: $e');
      _isSeller = false;
    }

    if (!_isSeller) {
      print(
          'DEBUG: User is not an approved business, showing registration prompt');
      setState(() {});
      return;
    }

    print('DEBUG: Loading data for approved business...');
    try {
      await Future.wait([
        _loadCountryProducts(),
        _loadMyPriceListings(),
        _loadCountryVariables(),
      ]).timeout(const Duration(seconds: 30));
      print('DEBUG: All data loaded successfully');
    } catch (e) {
      print('DEBUG: Error loading data: $e');
      // Continue anyway, individual methods have their own error handling
    }
  }

  Future<void> _loadCountryProducts() async {
    setState(() => _isSearching = true);
    try {
      // Use getAllCountryProducts for loading all available products to add prices for
      final products =
          await _pricingService.getAllCountryProducts(query: '', limit: 50);
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
      // Try multiple ways to get the user ID
      String? userId = _userService.currentUser?.uid;

      if (userId == null) {
        // Try getting from auth service
        final authUser = RestAuthService.instance.currentUser;
        userId = authUser?.id;
        print('DEBUG: Got user ID from auth service: $userId');
      }

      if (userId == null) {
        print('DEBUG: No user logged in, skipping price listings load');
        setState(() => _isLoadingMyPrices = false);
        return;
      }

      print('DEBUG: Loading price listings for user: $userId');
      await for (final listings
          in _pricingService.getBusinessPriceListings(userId).take(1)) {
        print('DEBUG: Loaded ${listings.length} price listings');
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

  Future<void> _loadCountryVariables() async {
    print('DEBUG: Starting to load country variables...');
    try {
      // Get country variables from the backend
      final response = await ApiClient.instance.get<Map<String, dynamic>>(
        '/api/country-variable-types', // API endpoint for country variables
        queryParameters: {
          'country': 'LK', // Pass country code as query parameter
        },
      );

      print('DEBUG: API response success: ${response.isSuccess}');
      print('DEBUG: API response data: ${response.data}');

      if (response.isSuccess && response.data != null) {
        final responseData = response.data!;
        final variablesArray = responseData['data'] as List<dynamic>?;

        print('DEBUG: Variables array length: ${variablesArray?.length}');

        if (variablesArray != null) {
          setState(() {
            _countryVariables = variablesArray.map((variable) {
              return {
                'id': variable['id'],
                'name': variable['name'],
                'type': variable['type'],
                'values': List<String>.from(variable['possibleValues'] ?? []),
                'description': variable['description'],
                'country_code': variable['country_code'],
                'is_active': variable['is_active'],
                'required': variable['required'] ?? false,
              };
            }).toList();
          });

          print('DEBUG: Loaded ${_countryVariables.length} country variables');
          print(
              'DEBUG: Variables: ${_countryVariables.map((v) => v['name']).join(', ')}');
        } else {
          print('DEBUG: Variables array is null');
        }
      } else {
        print('Failed to load country variables: ${response.error}');
        // Fallback to sample data if API fails
        _loadFallbackVariables();
      }
    } catch (e) {
      print('Error loading country variables: $e');
      // Fallback to sample data if API fails
      _loadFallbackVariables();
    }

    // Temporary: Always load fallback for testing
    if (_countryVariables.isEmpty) {
      print('DEBUG: No variables loaded from API, using fallback');
      _loadFallbackVariables();
    }
  }

  void _loadFallbackVariables() {
    setState(() {
      _countryVariables = [
        {
          'id': '1',
          'name': 'Color',
          'type': 'select',
          'values': ['Red', 'Blue', 'Green', 'Black', 'White', 'Yellow']
        },
        {
          'id': '2',
          'name': 'Size',
          'type': 'select',
          'values': ['XS', 'S', 'M', 'L', 'XL', 'XXL']
        },
        {
          'id': '3',
          'name': 'Material',
          'type': 'select',
          'values': ['Cotton', 'Polyester', 'Silk', 'Wool', 'Leather']
        },
        {'id': '4', 'name': 'Brand', 'type': 'text', 'values': []}
      ];
    });
  }

  Future<void> _searchProducts() async {
    if (_searchController.text.trim().isEmpty) {
      _loadCountryProducts();
      return;
    }

    setState(() => _isSearching = true);
    try {
      // Use getAllCountryProducts for searching all available products
      final products = await _pricingService.getAllCountryProducts(
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
    if (!_isSeller) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Product Dashboard'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified_outlined,
                    size: 72, color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  'Become a verified business to add prices',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Submit your business verification. Once approved, you can add and manage your product prices.',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/business-registration'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Register Business'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Container(
        decoration: GlassTheme.backgroundGradient,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: GlassTheme.colors.textPrimary,
            title: Text('Product Dashboard', style: GlassTheme.titleLarge),
            elevation: 0,
            bottom: TabBar(
              labelColor: GlassTheme.colors.textPrimary,
              unselectedLabelColor: GlassTheme.colors.textSecondary,
              tabs: const [
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
                borderSide: BorderSide(color: GlassTheme.colors.primaryBlue),
              ),
            ),
            onChanged: (value) {
              setState(() {});
              // Live search with debounce
              if (value.length >= 2) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_searchController.text == value) {
                    _searchProducts();
                  }
                });
              } else if (value.isEmpty) {
                _loadCountryProducts();
              }
            },
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
                backgroundColor: hasExistingPrice
                    ? Colors.orange
                    : GlassTheme.colors.primaryBlue,
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: GlassTheme.colors.primaryBlue,
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
                      foregroundColor: GlassTheme.colors.primaryBlue,
                      side: BorderSide(color: GlassTheme.colors.primaryBlue),
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
    print('DEBUG: Editing price listing: ${listing.id}');
    print('DEBUG: Existing selectedVariables: ${listing.selectedVariables}');
    print('DEBUG: Existing subcategory: ${listing.subcategory}');
    _showPriceDialog(existingListing: listing);
  }

  void _showPriceDialog({dynamic product, dynamic existingListing}) {
    print(
        'DEBUG: Opening price dialog, country variables count: ${_countryVariables.length}');
    print(
        'DEBUG: Country variables: ${_countryVariables.map((v) => v['name']).join(', ')}');

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
    final TextEditingController qtyController = TextEditingController(
      text: isEditing ? existingListing.stockQuantity?.toString() ?? '1' : '1',
    );
    final TextEditingController modelController = TextEditingController(
      text: isEditing ? existingListing.modelNumber ?? '' : '',
    );

    List<File> selectedImages = [];
    List<String> existingImageUrls =
        isEditing ? List<String>.from(existingListing.productImages ?? []) : [];

    // Track selected variables for two-step selection
    Map<String, bool> enabledVariables = {};
    Map<String, String> selectedVariableValues = isEditing
        ? Map<String, String>.from(existingListing.selectedVariables ?? {})
        : {};

    print('DEBUG: selectedVariableValues loaded: $selectedVariableValues');

    // Initialize enabled variables based on existing selections
    if (isEditing && selectedVariableValues.isNotEmpty) {
      print('DEBUG: Initializing enabled variables from existing data');
      for (var variable in _countryVariables) {
        final variableName = variable['name'];
        enabledVariables[variableName] =
            selectedVariableValues.containsKey(variableName);
        print(
            'DEBUG: Variable $variableName enabled: ${enabledVariables[variableName]}');
      }
    } else {
      print('DEBUG: No existing variable values to load');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
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

                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          isEditing ? 'Edit Price' : 'Add Price',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      // Product name
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isEditing
                              ? existingListing.productName ?? 'Product'
                              : product?.name ?? 'Product',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Price and Quantity Row
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Price (LKR) *',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.attach_money),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: qtyController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Quantity',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.inventory),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Model Number
                      TextField(
                        controller: modelController,
                        decoration: const InputDecoration(
                          labelText: 'Model Number (Optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.model_training),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Two-Step Variable Selection
                      // Temporarily always show variables for debugging
                      if (true) ...[
                        Text(
                          'Product Variables (${_countryVariables.length} available)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Debug info
                        if (_countryVariables.isEmpty) ...[
                          const Text(
                            'DEBUG: No variables loaded - forcing fallback',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              setDialogState(() {
                                _countryVariables = [
                                  {
                                    'id': '1',
                                    'name': 'Color',
                                    'type': 'select',
                                    'values': [
                                      'Red',
                                      'Blue',
                                      'Green',
                                      'Black',
                                      'White'
                                    ]
                                  },
                                  {
                                    'id': '2',
                                    'name': 'Size',
                                    'type': 'select',
                                    'values': ['XS', 'S', 'M', 'L', 'XL']
                                  },
                                ];
                              });
                            },
                            child: const Text('Load Test Variables'),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // Show variables if available
                        if (_countryVariables.isNotEmpty) ...[
                          // Step 1: Select which variables to use
                          const Text(
                            'Step 1: Select which variables you want to specify',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Compact variable selection using chips
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 4.0,
                            children: _countryVariables.map((variable) {
                              final variableName = variable['name'];
                              final isSelected =
                                  enabledVariables[variableName] ?? false;

                              return FilterChip(
                                label: Text(
                                  variableName,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 13,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (bool selected) {
                                  setDialogState(() {
                                    enabledVariables[variableName] = selected;
                                    if (!selected) {
                                      // Remove value when variable is disabled
                                      selectedVariableValues
                                          .remove(variableName);
                                    }
                                  });
                                },
                                backgroundColor: Colors.grey[200],
                                selectedColor: Colors.blue,
                                checkmarkColor: Colors.white,
                                side: BorderSide.none, // Remove border
                                elevation: 0, // Remove shadow for flatter look
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 16),

                          // Step 2: Select values for enabled variables
                          if (enabledVariables.values
                              .any((enabled) => enabled)) ...[
                            const Text(
                              'Step 2: Select values for chosen variables',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._countryVariables.where((variable) {
                              final variableName = variable['name'];
                              return enabledVariables[variableName] ?? false;
                            }).map((variable) {
                              final variableName = variable['name'];
                              final variableType = variable['type'];
                              final variableValues =
                                  List<String>.from(variable['values'] ?? []);

                              if (variableType == 'text') {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: TextField(
                                    decoration: InputDecoration(
                                      labelText: variableName,
                                      border: const OutlineInputBorder(),
                                    ),
                                    onChanged: (value) {
                                      selectedVariableValues[variableName] =
                                          value;
                                    },
                                    controller: TextEditingController(
                                      text: selectedVariableValues[
                                              variableName] ??
                                          '',
                                    ),
                                  ),
                                );
                              } else {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: DropdownButtonFormField<String>(
                                    value: selectedVariableValues[variableName],
                                    decoration: InputDecoration(
                                      labelText: variableName,
                                      border: const OutlineInputBorder(),
                                    ),
                                    items: [
                                      DropdownMenuItem<String>(
                                        value: null,
                                        child: Text('Select $variableName'),
                                      ),
                                      ...variableValues
                                          .map<DropdownMenuItem<String>>(
                                              (value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                    ],
                                    onChanged: (value) {
                                      setDialogState(() {
                                        if (value != null && value.isNotEmpty) {
                                          selectedVariableValues[variableName] =
                                              value;
                                        } else {
                                          selectedVariableValues
                                              .remove(variableName);
                                        }
                                      });
                                    },
                                  ),
                                );
                              }
                            }).toList(),
                          ],
                          const SizedBox(height: 16),
                        ], // Close the inner if (_countryVariables.isNotEmpty)
                      ], // Close the outer if (true)

                      // Contact Information Section
                      const Text(
                        'Contact Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // WhatsApp number
                      TextField(
                        controller: whatsappController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'WhatsApp Number (Optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                          hintText: '+94xxxxxxxxx',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Website/Product link
                      TextField(
                        controller: websiteController,
                        decoration: const InputDecoration(
                          labelText: 'Website/Product Link (Optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.link),
                          hintText: 'https://...',
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Images section
                      const Text(
                        'Product Images',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Show existing images
                      if (existingImageUrls.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: existingImageUrls
                              .map((url) => Stack(
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          image: DecorationImage(
                                            image: NetworkImage(url),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () {
                                            setDialogState(() {
                                              existingImageUrls.remove(url);
                                            });
                                          },
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 12),
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
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          image: DecorationImage(
                                            image: FileImage(file),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 4,
                                        right: 4,
                                        child: GestureDetector(
                                          onTap: () {
                                            setDialogState(() {
                                              selectedImages.remove(file);
                                            });
                                          },
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              size: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Add image button
                      OutlinedButton.icon(
                        onPressed: () async {
                          final ImagePicker picker = ImagePicker();
                          final XFile? image = await picker.pickImage(
                              source: ImageSource.gallery);
                          if (image != null) {
                            setDialogState(() {
                              selectedImages.add(File(image.path));
                            });
                          }
                        },
                        icon: const Icon(Icons.add_photo_alternate),
                        label: const Text('Add Image'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),

                // Bottom buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () async {
                            await _savePrice(
                              product: product,
                              existingListing: existingListing,
                              price: priceController.text,
                              whatsapp: whatsappController.text,
                              website: websiteController.text,
                              quantity: qtyController.text,
                              modelNumber: modelController.text,
                              variables: selectedVariableValues,
                              newImages: selectedImages,
                              existingImages: existingImageUrls,
                            );
                            if (context.mounted) Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GlassTheme.colors.primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child:
                              Text(isEditing ? 'Update Price' : 'Save Price'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
    required String quantity,
    required String modelNumber,
    required Map<String, String> variables,
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
        'subCategoryId': existingListing?.subcategory ??
            product.subcategory ??
            '6a8b9c2d-e3f4-5678-9abc-def123456789', // Default subcategory
        'images': imageUrls,
        'stockQuantity': int.tryParse(quantity) ?? 1,
        if (modelNumber.isNotEmpty) 'modelNumber': modelNumber,
        if (variables.isNotEmpty) 'selectedVariables': variables,
        if (whatsapp.isNotEmpty) 'whatsapp': whatsapp,
        if (website.isNotEmpty) 'website': website,
        // Add listing ID for updates
        if (existingListing != null) 'id': existingListing.id,
      };

      print('DEBUG: API payload: $apiPayload');

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
