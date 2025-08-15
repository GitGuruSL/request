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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    print('DEBUG: Loading initial data for product search...');
    setState(() => _isLoading = true);
    
    try {
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
      // Get all products first
      final allProducts = await _pricingService.searchProducts(
        query: '', // Get all products initially
      );
      
      List<MasterProduct> filteredProducts = List.from(allProducts);
      
      // Apply enhanced search filter if query is not empty
      if (_searchController.text.isNotEmpty) {
        // Split search query by comma, period, and space to handle multiple terms
        List<String> searchTerms = _searchController.text
            .toLowerCase()
            .split(RegExp(r'[,.\s]+'))
            .where((term) => term.isNotEmpty)
            .toList();
        
        filteredProducts = filteredProducts.where((product) {
          // Create a searchable string with all product fields
          String searchableContent = [
            product.name,
            product.brand,
            product.category,
            product.subcategory ?? '',
            product.description,
            // Add any additional fields you want to search
          ].join(' ').toLowerCase();
          
          // Check if ALL search terms are found (AND logic)
          return searchTerms.every((term) => 
            searchableContent.contains(term)
          );
        }).toList();
      }
      
      print('DEBUG: Search returned ${filteredProducts.length} products');
      setState(() {
        _products = filteredProducts;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background, // Use app theme background
      appBar: AppBar(
        backgroundColor: theme.colorScheme.background, // Match background
        foregroundColor: theme.textTheme.bodyLarge?.color, // Use theme text color
        title: const Text('Search Products'),
        elevation: 0, // No shadow
        titleSpacing: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildProductGrid()),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextFormField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search products... (use , or . to separate terms)',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white, // White background for the field
          border: InputBorder.none, // No border
        ),
        onChanged: (value) {
          _searchProducts();
        },
      ),
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
              'Try different search terms',
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
