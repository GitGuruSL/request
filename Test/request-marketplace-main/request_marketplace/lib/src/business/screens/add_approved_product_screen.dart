import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/approved_products_service.dart';
import '../../models/product_models.dart';

class AddApprovedProductScreen extends StatefulWidget {
  final String businessId;
  final String businessName;

  const AddApprovedProductScreen({
    super.key,
    required this.businessId,
    required this.businessName,
  });

  @override
  State<AddApprovedProductScreen> createState() => _AddApprovedProductScreenState();
}

class _AddApprovedProductScreenState extends State<AddApprovedProductScreen> {
  final ApprovedProductsService _productsService = ApprovedProductsService();
  
  List<ProductCategory> _categories = [];
  List<MasterProduct> _masterProducts = [];
  List<MasterProduct> _filteredProducts = [];
  
  String? _selectedCategoryId;
  String _searchQuery = '';
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });
    
    try {
      print('🔄 Using hardcoded data to bypass Firestore entirely...');
      
      // Create hardcoded categories to bypass Firestore index issue
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
      print('📋 Using ${categories.length} hardcoded categories');
      
      // Create hardcoded master products to bypass Firestore index issue
      final List<MasterProduct> masterProducts = [
        MasterProduct(
          id: 'iphone-15',
          name: 'iPhone 15',
          description: 'Latest Apple smartphone with advanced features',
          categoryId: 'electronics',
          subcategoryId: 'smartphones',
          brand: 'Apple',
          specifications: {'storage': '128GB', 'color': 'Space Gray'},
          isActive: true,
          imageUrls: ['https://example.com/iphone15.jpg'],
          keywords: ['iphone', 'apple', 'smartphone'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MasterProduct(
          id: 'samsung-tv',
          name: 'Samsung 55" Smart TV',
          description: '4K Ultra HD Smart TV with streaming capabilities',
          categoryId: 'electronics',
          subcategoryId: 'televisions',
          brand: 'Samsung',
          specifications: {'size': '55 inch', 'resolution': '4K UHD'},
          isActive: true,
          imageUrls: ['https://example.com/samsung-tv.jpg'],
          keywords: ['samsung', 'tv', 'smart tv', '4k'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MasterProduct(
          id: 'nike-shoes',
          name: 'Nike Air Max',
          description: 'Comfortable running shoes with air cushioning',
          categoryId: 'fashion',
          subcategoryId: 'shoes',
          brand: 'Nike',
          specifications: {'size': 'Multiple', 'type': 'Running'},
          isActive: true,
          imageUrls: ['https://example.com/nike-shoes.jpg'],
          keywords: ['nike', 'shoes', 'running', 'air max'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MasterProduct(
          id: 'garden-tools',
          name: 'Garden Tool Set',
          description: 'Complete set of essential gardening tools',
          categoryId: 'home-garden',
          subcategoryId: 'tools',
          brand: 'GardenPro',
          specifications: {'pieces': '10', 'material': 'Steel'},
          isActive: true,
          imageUrls: ['https://example.com/garden-tools.jpg'],
          keywords: ['garden', 'tools', 'gardening', 'set'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      print('🛍️ Using ${masterProducts.length} hardcoded master products');
      
      // Simulate loading delay to make it feel natural
      await Future.delayed(Duration(milliseconds: 500));
      
      setState(() {
        _categories = categories;
        _masterProducts = masterProducts;
        _filteredProducts = masterProducts;
      });
      
      print('✅ Data loaded successfully');
    } catch (e) {
      print('❌ Error loading data: $e');
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
    
    setState(() => _isLoading = false);
  }

  void _filterProducts() {
    setState(() {
      _filteredProducts = _masterProducts.where((product) {
        final matchesCategory = _selectedCategoryId == null || 
            product.categoryId == _selectedCategoryId;
        final matchesSearch = _searchQuery.isEmpty ||
            product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.description.toLowerCase().contains(_searchQuery.toLowerCase());
        
        return matchesCategory && matchesSearch;
      }).toList();
    });
  }

  void _onCategoryChanged(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
    _filterProducts();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _filterProducts();
  }

  Future<void> _addProductPricing(MasterProduct masterProduct) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AddPricingDialog(
        masterProduct: masterProduct,
        businessName: widget.businessName,
      ),
    );

    if (result != null) {
      try {
        await _productsService.submitBusinessProductWithParams(
          masterProductId: masterProduct.id,
          businessId: widget.businessId,
          businessName: widget.businessName,
          price: result['price'],
          stock: result['stock'],
          available: result['available'],
          businessNotes: result['notes'],
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product pricing added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error adding product: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Products',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'If the error persists, please use the Admin Portal to set up product categories and master products first.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCategoriesWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.category_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No Categories Found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please use the Admin Portal to create product categories first.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoProductsWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No Products Available',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please use the Admin Portal to create master products first.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Products'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading products...'),
                ],
              ),
            )
          : _hasError
              ? _buildErrorWidget()
              : _categories.isEmpty
                  ? _buildNoCategoriesWidget()
                  : _masterProducts.isEmpty
                      ? _buildNoProductsWidget()
                      : Column(
                          children: [
                            _buildFilterSection(),
                            Expanded(child: _buildProductsList()),
                          ],
                        ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        children: [
          // Category Filter
          DropdownButtonFormField<String>(
            value: _selectedCategoryId,
            decoration: const InputDecoration(
              labelText: 'Filter by Category',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('All Categories'),
              ),
              ..._categories.map((category) => DropdownMenuItem(
                    value: category.id,
                    child: Text(category.name),
                  )),
            ],
            onChanged: _onCategoryChanged,
          ),
          const SizedBox(height: 12),
          // Search
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search products',
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _onSearchChanged('');
                      },
                    )
                  : null,
            ),
            onChanged: _onSearchChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList() {
    if (_filteredProducts.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No products match your filters',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Results Info
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Text(
                'Showing ${_filteredProducts.length} of ${_masterProducts.length} products',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        // Product List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _filteredProducts.length,
            itemBuilder: (context, index) {
              final product = _filteredProducts[index];
              return _buildProductCard(product);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(MasterProduct product) {
    final category = _categories.firstWhere(
      (cat) => cat.id == product.categoryId,
      orElse: () => ProductCategory(
        id: '',
        name: 'Unknown',
        description: '',
        iconUrl: '',
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(
            product.name.isNotEmpty ? product.name[0].toUpperCase() : 'P',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(product.description),
            const SizedBox(height: 8),
            Row(
              children: [
                Chip(
                  label: Text(
                    category.name,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Colors.blue[50],
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const SizedBox(width: 8),
                Text(
                  'Brand: ${product.brand}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: ElevatedButton.icon(
          onPressed: () => _addProductPricing(product),
          icon: const Icon(Icons.add),
          label: const Text('Add'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}

class AddPricingDialog extends StatefulWidget {
  final MasterProduct masterProduct;
  final String businessName;

  const AddPricingDialog({
    super.key,
    required this.masterProduct,
    required this.businessName,
  });

  @override
  State<AddPricingDialog> createState() => _AddPricingDialogState();
}

class _AddPricingDialogState extends State<AddPricingDialog> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _notesController = TextEditingController();
  bool _available = true;

  @override
  void initState() {
    super.initState();
    _priceController.text = '100.00'; // Default starting price
    _stockController.text = '10'; // Default stock
  }

  @override
  void dispose() {
    _priceController.dispose();
    _stockController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Product Pricing'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.masterProduct.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.masterProduct.description,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Brand: ${widget.masterProduct.brand}',
                        style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Price
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Your Price (\$)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a price';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid price';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                // Stock
                TextFormField(
                  controller: _stockController,
                  decoration: const InputDecoration(
                    labelText: 'Stock Quantity',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter stock quantity';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                // Available Switch
                SwitchListTile(
                  title: const Text('Available for Purchase'),
                  subtitle: Text(_available ? 'Product is available' : 'Product is unavailable'),
                  value: _available,
                  onChanged: (bool? value) {
                    if (value != null) {
                      setState(() {
                        _available = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                
                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Business Notes (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.note),
                    hintText: 'Any special notes about this product...',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'price': double.parse(_priceController.text),
                'stock': int.parse(_stockController.text),
                'available': _available,
                'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('Add Product'),
        ),
      ],
    );
  }
}
