import 'package:flutter/material.dart';
import '../../models/master_product.dart';
import '../../services/pricing_service.dart';
import '../../theme/app_theme.dart';
import 'price_comparison_screen.dart';

class ProductSearchScreen extends StatefulWidget {
  const ProductSearchScreen({super.key});

  @override
  State<ProductSearchScreen> createState() => _ProductSearchScreenState();
}

class _ProductSearchScreenState extends State<ProductSearchScreen> {
  final PricingService _pricingService = PricingService();
  final TextEditingController _searchController = TextEditingController();
  
  List<MasterProduct> _products = [];
  List<String> _categories = [];
  List<String> _brands = [];
  bool _isLoading = false;
  
  String? _selectedCategory;
  String? _selectedBrand;
  double? _minPrice;
  double? _maxPrice;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    print('DEBUG: Loading initial data for product search...');
    setState(() => _isLoading = true);
    
    try {
      print('DEBUG: Getting categories and brands...');
      final categories = await _pricingService.getCategories();
      final brands = await _pricingService.getBrands();
      
      print('DEBUG: Got ${categories.length} categories and ${brands.length} brands');
      setState(() {
        _categories = categories;
        _brands = brands;
        _isLoading = false;
      });
      
      print('DEBUG: Starting initial product search...');
      await _searchProducts();
    } catch (e) {
      print('DEBUG: Error in _loadInitialData: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _searchProducts() async {
    print('DEBUG: Searching products with query: "${_searchController.text}"');
    setState(() => _isLoading = true);
    
    try {
      final products = await _pricingService.searchProducts(
        query: _searchController.text,
        category: _selectedCategory,
        brand: _selectedBrand,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
      );
      
      print('DEBUG: Search returned ${products.length} products');
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      print('DEBUG: Error in _searchProducts: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching products: $e')),
        );
      }
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedBrand = null;
      _minPrice = null;
      _maxPrice = null;
      _searchController.clear();
    });
    _searchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        title: const Text('Search Products'),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(child: _buildProductGrid()),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
  color: AppTheme.backgroundColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _searchProducts();
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppTheme.backgroundColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onSubmitted: (_) => _searchProducts(),
          ),
          
          const SizedBox(height: 16),
          
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  'Category',
                  _selectedCategory,
                  () => _showCategoryFilter(),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Brand',
                  _selectedBrand,
                  () => _showBrandFilter(),
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'Price Range',
                  _minPrice != null || _maxPrice != null ? 'Set' : null,
                  () => _showPriceRangeFilter(),
                ),
                const SizedBox(width: 8),
                if (_selectedCategory != null || 
                    _selectedBrand != null || 
                    _minPrice != null || 
                    _maxPrice != null)
                  TextButton.icon(
                    onPressed: _clearFilters,
                    icon: const Icon(Icons.clear_all, size: 16),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value, VoidCallback onTap) {
    final selected = value != null;
    return FilterChip(
      label: Text(
        selected ? '$label: $value' : label,
        style: TextStyle(
          color: selected ? AppTheme.textPrimary : AppTheme.textSecondary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      backgroundColor: Colors.transparent,
      selectedColor: Colors.transparent,
      showCheckmark: false,
      side: BorderSide.none,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildProductGrid() {
    if (_isLoading) {
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
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        return _buildProductCard(_products[index]);
      },
    );
  }

  Widget _buildProductCard(MasterProduct product) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToProductPrices(product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  color: Colors.grey[100],
                ),
                child: product.images.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: Image.network(
                          product.images.first,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                        ),
                      )
                    : _buildPlaceholderImage(),
              ),
            ),
            
            // Product info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.brand,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${product.businessListingsCount} sellers',
                          style: TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Icon(
        Icons.image,
        size: 48,
        color: Colors.grey[400],
      ),
    );
  }

  void _navigateToProductPrices(MasterProduct product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PriceComparisonScreen(product: product),
      ),
    );
  }

  void _showCategoryFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Category'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('All Categories'),
                onTap: () {
                  setState(() => _selectedCategory = null);
                  Navigator.pop(context);
                  _searchProducts();
                },
                selected: _selectedCategory == null,
              ),
              ..._categories.map((category) => ListTile(
                title: Text(category),
                onTap: () {
                  setState(() => _selectedCategory = category);
                  Navigator.pop(context);
                  _searchProducts();
                },
                selected: _selectedCategory == category,
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _showBrandFilter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Brand'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              ListTile(
                title: const Text('All Brands'),
                onTap: () {
                  setState(() => _selectedBrand = null);
                  Navigator.pop(context);
                  _searchProducts();
                },
                selected: _selectedBrand == null,
              ),
              ..._brands.map((brand) => ListTile(
                title: Text(brand),
                onTap: () {
                  setState(() => _selectedBrand = brand);
                  Navigator.pop(context);
                  _searchProducts();
                },
                selected: _selectedBrand == brand,
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _showPriceRangeFilter() {
    final minController = TextEditingController(text: _minPrice?.toString());
    final maxController = TextEditingController(text: _maxPrice?.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Price Range'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: minController,
              decoration: const InputDecoration(
                labelText: 'Min Price',
                prefixText: 'LKR ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: maxController,
              decoration: const InputDecoration(
                labelText: 'Max Price',
                prefixText: 'LKR ',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _minPrice = null;
                _maxPrice = null;
              });
              Navigator.pop(context);
              _searchProducts();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _minPrice = double.tryParse(minController.text);
                _maxPrice = double.tryParse(maxController.text);
              });
              Navigator.pop(context);
              _searchProducts();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
