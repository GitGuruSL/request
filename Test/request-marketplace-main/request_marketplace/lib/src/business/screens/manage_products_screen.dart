import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product_models.dart';
import '../../services/business_service.dart';
import '../../services/product_service.dart';
import 'edit_product_screen.dart';
import 'product_search_screen.dart';

class ManageProductsScreen extends StatefulWidget {
  final String businessId;

  const ManageProductsScreen({
    super.key,
    required this.businessId,
  });

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  final BusinessService _businessService = BusinessService();
  final ProductService _productService = ProductService();
  
  List<BusinessProduct> _businessProducts = [];
  Map<String, MasterProduct> _masterProducts = {};
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadBusinessProducts();
  }

  Future<void> _loadBusinessProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load business products using ProductService (includes isActive filter)
      final productService = ProductService();
      final businessProducts = await productService.getBusinessProducts(widget.businessId);

      // Load corresponding master products
      final masterProductIds = businessProducts
          .map((bp) => bp.masterProductId)
          .toSet()
          .toList();

      final Map<String, MasterProduct> masterProducts = {};
      
      print('🔍 Debug: Looking up master product IDs: $masterProductIds');
      
      // Debug: Also check what's available in master_products collection
      try {
        print('🔍 Debug: Checking all master products in collection...');
        final allMasterProducts = await FirebaseFirestore.instance
            .collection('master_products')
            .limit(10)
            .get();
        
        for (final doc in allMasterProducts.docs) {
          final data = doc.data();
          print('🔍 Debug: Available master product - ID: ${doc.id}, Name: ${data['name']}, Brand: ${data['brand']}');
        }
      } catch (e) {
        print('🔍 Debug: Error checking master products: $e');
      }
      
      for (final productId in masterProductIds) {
        try {
          print('🔍 Debug: Loading master product: $productId');
          final masterDoc = await FirebaseFirestore.instance
              .collection('master_products')
              .doc(productId)
              .get();
              
          if (masterDoc.exists) {
            masterProducts[productId] = MasterProduct.fromFirestore(masterDoc);
            print('🔍 Debug: Found master product: ${masterDoc.id} - ${masterDoc.data()?['name']}');
          } else {
            print('🔍 Debug: Master product not found: $productId');
            
            // Try to find by alternative search (for cases like "samsung-tv" slug)
            if (productId.contains('-')) {
              print('🔍 Debug: Attempting to find product by name/brand containing: $productId');
              try {
                final searchTerms = productId.split('-');
                final searchQuery = await FirebaseFirestore.instance
                    .collection('master_products')
                    .where('brand', isEqualTo: searchTerms[0].toLowerCase())
                    .limit(5)
                    .get();
                
                for (final searchDoc in searchQuery.docs) {
                  final searchData = searchDoc.data();
                  print('🔍 Debug: Found potential match - ID: ${searchDoc.id}, Name: ${searchData['name']}, Brand: ${searchData['brand']}');
                  
                  // Use the first match for now
                  if (masterProducts[productId] == null) {
                    masterProducts[productId] = MasterProduct.fromFirestore(searchDoc);
                    print('🔍 Debug: Using ${searchDoc.id} as fallback for $productId');
                    break;
                  }
                }
              } catch (e) {
                print('🔍 Debug: Fallback search failed: $e');
              }
            }
          }
        } catch (e) {
          print('Error loading master product $productId: $e');
        }
      }

      setState(() {
        _businessProducts = businessProducts;
        _masterProducts = masterProducts;
        _isLoading = false;
      });

      print('🔍 Debug: Loaded ${businessProducts.length} business products for businessId: ${widget.businessId}');
      for (final product in businessProducts) {
        print('  - Product ID: ${product.id}, Master ID: ${product.masterProductId}, Price: ${product.price}, Active: ${product.isActive}');
      }
    } catch (e) {
      print('Error loading business products: $e');
      setState(() {
        _isLoading = false;
      });
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading products: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleProductAvailability(BusinessProduct product, bool available) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      // Update in Firestore
      await FirebaseFirestore.instance
          .collection('business_products')
          .doc(product.id)
          .update({
        'available': available,
        'updatedAt': Timestamp.now(),
      });

      // Find and update local state
      final index = _businessProducts.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        // Create a new BusinessProduct with updated availability
        final updatedProduct = BusinessProduct(
          id: product.id,
          businessId: product.businessId,
          masterProductId: product.masterProductId,
          businessName: product.businessName,
          price: product.price,
          stock: product.stock,
          available: available,
          businessNotes: product.businessNotes,
          status: product.status,
          submittedBy: product.submittedBy,
          originalPrice: product.originalPrice,
          deliveryInfo: product.deliveryInfo,
          warrantyInfo: product.warrantyInfo,
          additionalImages: product.additionalImages,
          businessUrl: product.businessUrl,
          businessPhone: product.businessPhone,
          businessWhatsapp: product.businessWhatsapp,
          availability: product.availability,
          clickCount: product.clickCount,
          createdAt: product.createdAt,
          updatedAt: DateTime.now(),
          isActive: product.isActive,
          businessSpecificData: product.businessSpecificData,
        );

        setState(() {
          _businessProducts[index] = updatedProduct;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product ${available ? 'enabled' : 'disabled'} successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error updating product availability: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Future<void> _deleteProduct(BusinessProduct product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: const Text('Are you sure you want to remove this product from your business? This action cannot be undone.'),
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
        await FirebaseFirestore.instance
            .collection('business_products')
            .doc(product.id)
            .delete();

        setState(() {
          _businessProducts.removeWhere((p) => p.id == product.id);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product removed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print('Error deleting product: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting product: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _editProduct(BusinessProduct product, MasterProduct? masterProduct) async {
    if (masterProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product information not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditProductScreen(
          businessProduct: product,
          masterProduct: masterProduct,
        ),
      ),
    );

    // Refresh the list if product was updated
    if (result == true) {
      _loadBusinessProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBFE),
      appBar: AppBar(
        title: const Text('Product Management'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1D1B20),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Color(0xFF1D1B20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductSearchScreen(businessId: widget.businessId),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadBusinessProducts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dashboard Header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF6750A4), Color(0xFF7C4DFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                                child: const Icon(
                                  Icons.inventory_2,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Product Management Dashboard',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Manage your product catalog and inventory',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Stats Overview
                    const Text(
                      'Overview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D1B20),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stats Cards Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatsCard(
                            icon: Icons.inventory,
                            title: 'Total Products',
                            count: '${_businessProducts.length}',
                            color: const Color(0xFF6750A4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatsCard(
                            icon: Icons.check_circle,
                            title: 'Available',
                            count: '${_businessProducts.where((p) => p.available).length}',
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatsCard(
                            icon: Icons.remove_circle,
                            title: 'Out of Stock',
                            count: '${_businessProducts.where((p) => !p.available).length}',
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatsCard(
                            icon: Icons.trending_up,
                            title: 'Active',
                            count: '${_businessProducts.where((p) => p.isActive).length}',
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Quick Actions
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D1B20),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionCard(
                            icon: Icons.add_box,
                            title: 'Add Product',
                            subtitle: 'Add new product to catalog',
                            color: const Color(0xFF2E7D32),
                            onTap: _navigateToAddProduct,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildQuickActionCard(
                            icon: Icons.search,
                            title: 'Search Products',
                            subtitle: 'Find and manage products',
                            color: const Color(0xFF1976D2),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ProductSearchScreen(businessId: widget.businessId),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Products Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Your Products',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1D1B20),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _loadBusinessProducts,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Refresh'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Products List/Grid
                    _businessProducts.isEmpty
                        ? _buildEmptyState()
                        : Column(
                            children: _businessProducts.map((product) {
                              final masterProduct = _masterProducts[product.masterProductId];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildProductCard(product, masterProduct),
                              );
                            }).toList(),
                          ),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddProduct,
        backgroundColor: const Color(0xFF6750A4),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
    );
  }

  Widget _buildStatsCard({
    required IconData icon,
    required String title,
    required String count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Text(
                count,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF49454F),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF49454F),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF6750A4).withOpacity(0.1),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 40,
              color: Color(0xFF6750A4),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No Products Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1D1B20),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start building your product catalog by adding your first product',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF49454F),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToAddProduct,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6750A4),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: const RoundedRectangleBorder(),
            ),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Add Your First Product'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(BusinessProduct product, MasterProduct? masterProduct) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Product Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7F2FA),
                  ),
                  child: masterProduct?.imageUrls.isNotEmpty == true
                      ? Image.network(
                          masterProduct!.imageUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                            Icons.image,
                            color: Color(0xFF6750A4),
                            size: 32,
                          ),
                        )
                      : const Icon(
                          Icons.image,
                          color: Color(0xFF6750A4),
                          size: 32,
                        ),
                ),
                
                const SizedBox(width: 16),
                
                // Product Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        masterProduct?.name ?? 'Unknown Product',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Color(0xFF1D1B20),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (masterProduct?.brand.isNotEmpty == true)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6750A4).withOpacity(0.1),
                          ),
                          child: Text(
                            masterProduct!.brand,
                            style: const TextStyle(
                              color: Color(0xFF6750A4),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: product.available 
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  product.available
                                      ? Icons.check_circle
                                      : Icons.remove_circle,
                                  color: product.available ? Colors.green : Colors.orange,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  product.available ? 'Available' : 'Out of Stock',
                                  style: TextStyle(
                                    color: product.available ? Colors.green : Colors.orange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Price
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'LKR ${product.price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    if (product.originalPrice != null && product.originalPrice! > product.price)
                      Text(
                        'LKR ${product.originalPrice!.toStringAsFixed(0)}',
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Color(0xFF79747E),
                          fontSize: 14,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Stock: ${product.stock}',
                      style: const TextStyle(
                        color: Color(0xFF49454F),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Product Actions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFFFFBFE),
            ),
            child: Row(
              children: [
                // Toggle Availability
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUpdating 
                        ? null 
                        : () => _toggleProductAvailability(product, !product.available),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: product.available ? Colors.orange : Colors.green,
                      side: BorderSide(
                        color: product.available ? Colors.orange : Colors.green,
                      ),
                      shape: const RoundedRectangleBorder(),
                    ),
                    icon: Icon(
                      product.available ? Icons.visibility_off : Icons.visibility,
                      size: 18,
                    ),
                    label: Text(
                      product.available ? 'Disable' : 'Enable',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Edit Product
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _editProduct(product, masterProduct),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6750A4),
                      foregroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(),
                    ),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text(
                      'Edit',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // More Options
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF7F2FA),
                  ),
                  child: IconButton(
                    onPressed: () => _showProductOptions(product),
                    icon: const Icon(
                      Icons.more_vert,
                      color: Color(0xFF79747E),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToAddProduct() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ProductSearchScreen(
          businessId: widget.businessId,
        ),
      ),
    );

    // Refresh the products list if a product was added
    if (result == true) {
      _loadBusinessProducts();
    }
  }

  void _showProductOptions(BusinessProduct product) {
    final masterProduct = _masterProducts[product.masterProductId];
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Product Options',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1B20),
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF6750A4)),
              title: const Text('Edit Product'),
              onTap: () {
                Navigator.pop(context);
                _editProduct(product, masterProduct);
              },
            ),
            ListTile(
              leading: Icon(
                product.available ? Icons.visibility_off : Icons.visibility,
                color: Colors.orange,
              ),
              title: Text(product.available ? 'Disable Product' : 'Enable Product'),
              onTap: () {
                Navigator.pop(context);
                _toggleProductAvailability(product, !product.available);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Product'),
              onTap: () {
                Navigator.pop(context);
                _deleteProduct(product);
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return 'Today';
    }
  }
}
