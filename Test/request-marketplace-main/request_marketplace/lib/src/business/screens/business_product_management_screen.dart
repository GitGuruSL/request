import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/category_data.dart';
import '../../services/business_service.dart';
import '../../services/image_service.dart';
import '../../services/approved_products_service.dart';
import 'add_approved_product_screen.dart';

class BusinessProductManagementScreen extends StatefulWidget {
  final String businessId;
  
  const BusinessProductManagementScreen({
    super.key,
    required this.businessId,
  });

  @override
  State<BusinessProductManagementScreen> createState() => _BusinessProductManagementScreenState();
}

class _BusinessProductManagementScreenState extends State<BusinessProductManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BusinessService _businessService = BusinessService();
  final ImageService _imageService = ImageService();
  final ApprovedProductsService _approvedProductsService = ApprovedProductsService();
  
  List<Map<String, dynamic>> _businessProducts = [];
  List<Map<String, dynamic>> _masterProducts = [];
  List<Map<String, dynamic>> _categories = [];
  String? _businessName;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // Changed to 4 tabs
    _loadData();
    _loadBusinessName();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      await Future.wait([
        _loadBusinessProducts(),
        _loadMasterProducts(),
        _loadCategories(),
      ]);
    } catch (e) {
      print('Error loading data: $e');
      _showSnackBar('Error loading data: $e', isError: true);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadBusinessName() async {
    try {
      final businessDoc = await FirebaseFirestore.instance
          .collection('businesses')
          .doc(widget.businessId)
          .get();
      
      if (businessDoc.exists) {
        setState(() {
          _businessName = businessDoc.data()?['businessName'] ?? 
                          businessDoc.data()?['name'] ?? 
                          'My Business';
        });
      }
    } catch (e) {
      print('Error loading business name: $e');
    }
  }

  Future<void> _loadBusinessProducts() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('business_products')
        .where('businessId', isEqualTo: widget.businessId)
        .get();
    
    _businessProducts = snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  Future<void> _loadMasterProducts() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('master_products')
        .get();
    
    _masterProducts = snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  Future<void> _loadCategories() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('product_categories')
        .get();
    
    _categories = snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data(),
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Management'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.green,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.inventory), text: 'My Products'),
            Tab(icon: Icon(Icons.store), text: 'Approved Products'),
            Tab(icon: Icon(Icons.add_business), text: 'Add Products'),
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMyProductsTab(),
                _buildApprovedProductsTab(),
                _buildAddProductsTab(),
                _buildAnalyticsTab(),
              ],
            ),
    );
  }

  Widget _buildMyProductsTab() {
    return RefreshIndicator(
      onRefresh: _loadBusinessProducts,
      child: _businessProducts.isEmpty
          ? _buildEmptyState(
              icon: Icons.inventory_2_outlined,
              title: 'No Products Yet',
              message: 'Add products to start selling on the marketplace',
              actionText: 'Add Products',
              onAction: () => _tabController.animateTo(1),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _businessProducts.length,
              itemBuilder: (context, index) {
                final product = _businessProducts[index];
                return _buildProductCard(product);
              },
            ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final masterProduct = _masterProducts.firstWhere(
      (mp) => mp['id'] == product['masterProductId'],
      orElse: () => {},
    );
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
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
                        masterProduct['name'] ?? 'Unknown Product',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        masterProduct['description'] ?? '',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: product['available'] == true 
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    product['available'] == true ? 'Available' : 'Unavailable',
                    style: TextStyle(
                      color: product['available'] == true ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(
                  icon: Icons.attach_money,
                  label: 'LKR ${product['price']?.toStringAsFixed(0) ?? '0'}',
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  icon: Icons.local_shipping,
                  label: product['deliveryAvailable'] == true ? 'Delivery' : 'Pickup',
                  color: Colors.blue,
                ),
                if (product['warranty'] != null && product['warranty'] > 0) ...[
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    icon: Icons.verified_user,
                    label: '${product['warranty']} months',
                    color: Colors.purple,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editProduct(product),
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _toggleAvailability(product),
                    icon: Icon(product['available'] == true ? Icons.visibility_off : Icons.visibility),
                    label: Text(product['available'] == true ? 'Hide' : 'Show'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: product['available'] == true ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
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

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovedProductsTab() {
    return Column(
      children: [
        // Header with info
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.green.withOpacity(0.1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.verified, color: Colors.green[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Admin-Approved Products',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[800],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Browse products approved by admin and add your pricing to start selling',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        ),
        
        // Browse approved products button
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.store,
                  size: 80,
                  color: Colors.green[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Browse Approved Products',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your pricing to admin-approved products and get them listed on the marketplace',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      if (_businessName != null) {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => AddApprovedProductScreen(
                              businessId: widget.businessId,
                              businessName: _businessName!,
                            ),
                          ),
                        );
                        // Refresh data when returning
                        _loadBusinessProducts();
                      } else {
                        _showSnackBar('Loading business information...', isError: false);
                      }
                    },
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: const Text('Browse Products'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Info cards
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Icon(Icons.admin_panel_settings, 
                                   color: Colors.blue[600], size: 24),
                              const SizedBox(height: 8),
                              const Text(
                                'Admin Approved',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Text(
                                'Quality products verified by admin',
                                style: TextStyle(fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Icon(Icons.trending_up, 
                                   color: Colors.orange[600], size: 24),
                              const SizedBox(height: 8),
                              const Text(
                                'Competitive',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Text(
                                'Set your own competitive pricing',
                                style: TextStyle(fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Icon(Icons.speed, 
                                   color: Colors.green[600], size: 24),
                              const SizedBox(height: 8),
                              const Text(
                                'Quick Setup',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const Text(
                                'Fast approval process',
                                style: TextStyle(fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddProductsTab() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.grey[50],
            child: const TabBar(
              labelColor: Colors.green,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.green,
              tabs: [
                Tab(text: 'From Catalog'),
                Tab(text: 'Add New'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildFromCatalogTab(),
                _buildAddNewProductTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFromCatalogTab() {
    final availableProducts = _masterProducts.where((product) {
      return !_businessProducts.any((bp) => bp['masterProductId'] == product['id']);
    }).toList();

    if (availableProducts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.category,
        title: 'All Products Added',
        message: 'You have added all available products from the catalog',
        actionText: 'Add New Product',
        onAction: () => DefaultTabController.of(context)?.animateTo(1),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: availableProducts.length,
      itemBuilder: (context, index) {
        final product = availableProducts[index];
        return _buildCatalogProductCard(product);
      },
    );
  }

  Widget _buildCatalogProductCard(Map<String, dynamic> product) {
    final category = _categories.firstWhere(
      (cat) => cat['id'] == product['categoryId'],
      orElse: () => {},
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                        product['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product['description'] ?? '',
                        style: const TextStyle(color: Colors.grey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (category.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            category['name'] ?? '',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _addProductFromCatalog(product),
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNewProductTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.add_box, color: Colors.green),
                      const SizedBox(width: 8),
                      const Text(
                        'Add New Product',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create a new product that will be added to the master catalog and your business inventory.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showAddNewProductDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Create New Product'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Text(
                        'Tips for Success',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTip('Add high-quality product images'),
                  _buildTip('Write detailed descriptions'),
                  _buildTip('Set competitive prices'),
                  _buildTip('Offer delivery when possible'),
                  _buildTip('Provide warranty information'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    final totalProducts = _businessProducts.length;
    final availableProducts = _businessProducts.where((p) => p['available'] == true).length;
    final totalValue = _businessProducts.fold<double>(
      0.0,
      (sum, product) => sum + (product['price']?.toDouble() ?? 0.0),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Analytics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  icon: Icons.inventory,
                  label: 'Total Products',
                  value: totalProducts.toString(),
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAnalyticsCard(
                  icon: Icons.visibility,
                  label: 'Available',
                  value: availableProducts.toString(),
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsCard(
                  icon: Icons.attach_money,
                  label: 'Total Value',
                  value: 'LKR ${totalValue.toStringAsFixed(0)}',
                  color: Colors.purple,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAnalyticsCard(
                  icon: Icons.trending_up,
                  label: 'Avg Price',
                  value: totalProducts > 0
                      ? 'LKR ${(totalValue / totalProducts).toStringAsFixed(0)}'
                      : 'LKR 0',
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Category Breakdown',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildCategoryBreakdown(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    final categoryBreakdown = <String, int>{};
    
    for (final product in _businessProducts) {
      final masterProduct = _masterProducts.firstWhere(
        (mp) => mp['id'] == product['masterProductId'],
        orElse: () => {},
      );
      
      final categoryName = masterProduct['categoryName'] ?? 'Uncategorized';
      categoryBreakdown[categoryName] = (categoryBreakdown[categoryName] ?? 0) + 1;
    }

    if (categoryBreakdown.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No data available'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: categoryBreakdown.entries.map((entry) {
            final percentage = (entry.value / _businessProducts.length * 100).toStringAsFixed(1);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(entry.key),
                  ),
                  Text('${entry.value} (${percentage}%)'),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionText),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _addProductFromCatalog(Map<String, dynamic> masterProduct) {
    showDialog(
      context: context,
      builder: (context) => AddProductDialog(
        masterProduct: masterProduct,
        businessId: widget.businessId,
        onProductAdded: () {
          _loadBusinessProducts();
          _showSnackBar('Product added successfully!');
        },
      ),
    );
  }

  void _editProduct(Map<String, dynamic> product) {
    final masterProduct = _masterProducts.firstWhere(
      (mp) => mp['id'] == product['masterProductId'],
      orElse: () => {},
    );
    
    showDialog(
      context: context,
      builder: (context) => AddProductDialog(
        masterProduct: masterProduct,
        businessId: widget.businessId,
        existingProduct: product,
        onProductAdded: () {
          _loadBusinessProducts();
          _showSnackBar('Product updated successfully!');
        },
      ),
    );
  }

  void _showAddNewProductDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateNewProductDialog(
        businessId: widget.businessId,
        categories: _categories,
        onProductCreated: () {
          _loadData();
          _showSnackBar('New product created and added successfully!');
        },
      ),
    );
  }

  Future<void> _toggleAvailability(Map<String, dynamic> product) async {
    try {
      final newAvailability = !(product['available'] ?? false);
      
      await FirebaseFirestore.instance
          .collection('business_products')
          .doc(product['id'])
          .update({
        'available': newAvailability,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      await _loadBusinessProducts();
      setState(() {});
      
      _showSnackBar(
        newAvailability ? 'Product is now available' : 'Product is now hidden',
      );
    } catch (e) {
      _showSnackBar('Error updating product: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}

// Dialog for adding products from catalog
class AddProductDialog extends StatefulWidget {
  final Map<String, dynamic> masterProduct;
  final String businessId;
  final Map<String, dynamic>? existingProduct;
  final VoidCallback onProductAdded;

  const AddProductDialog({
    super.key,
    required this.masterProduct,
    required this.businessId,
    this.existingProduct,
    required this.onProductAdded,
  });

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _deliveryFeeController = TextEditingController();
  final _stockController = TextEditingController();
  final _warrantyController = TextEditingController();
  
  bool _deliveryAvailable = true;
  bool _hasWarranty = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    if (widget.existingProduct != null) {
      final product = widget.existingProduct!;
      _priceController.text = product['price']?.toString() ?? '';
      _deliveryFeeController.text = product['deliveryFee']?.toString() ?? '';
      _stockController.text = product['stock']?.toString() ?? '';
      _warrantyController.text = product['warranty']?.toString() ?? '';
      _deliveryAvailable = product['deliveryAvailable'] ?? true;
      _hasWarranty = (product['warranty'] ?? 0) > 0;
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _deliveryFeeController.dispose();
    _stockController.dispose();
    _warrantyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingProduct != null ? 'Edit Product' : 'Add Product'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.masterProduct['name'] ?? '',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Price
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price (LKR) *',
                  border: OutlineInputBorder(),
                  prefixText: 'LKR ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Stock
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(
                  labelText: 'Stock Quantity',
                  border: OutlineInputBorder(),
                  hintText: 'Optional',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              
              // Delivery
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Delivery Available'),
                value: _deliveryAvailable,
                onChanged: (value) {
                  setState(() {
                    _deliveryAvailable = value ?? false;
                  });
                },
              ),
              
              if (_deliveryAvailable) ...[
                TextFormField(
                  controller: _deliveryFeeController,
                  decoration: const InputDecoration(
                    labelText: 'Delivery Fee (LKR)',
                    border: OutlineInputBorder(),
                    prefixText: 'LKR ',
                    hintText: '0 for free delivery',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
              ],
              
              // Warranty
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Warranty Available'),
                value: _hasWarranty,
                onChanged: (value) {
                  setState(() {
                    _hasWarranty = value ?? false;
                  });
                },
              ),
              
              if (_hasWarranty) ...[
                TextFormField(
                  controller: _warrantyController,
                  decoration: const InputDecoration(
                    labelText: 'Warranty Period (months)',
                    border: OutlineInputBorder(),
                    suffixText: 'months',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
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
          onPressed: _isLoading ? null : _saveProduct,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.existingProduct != null ? 'Update' : 'Add'),
        ),
      ],
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final productData = {
        'businessId': widget.businessId,
        'masterProductId': widget.masterProduct['id'],
        'price': double.parse(_priceController.text),
        'deliveryAvailable': _deliveryAvailable,
        'deliveryFee': _deliveryAvailable && _deliveryFeeController.text.isNotEmpty
            ? double.parse(_deliveryFeeController.text)
            : 0.0,
        'stock': _stockController.text.isNotEmpty ? int.parse(_stockController.text) : null,
        'warranty': _hasWarranty && _warrantyController.text.isNotEmpty
            ? int.parse(_warrantyController.text)
            : 0,
        'available': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.existingProduct != null) {
        // Update existing product
        await FirebaseFirestore.instance
            .collection('business_products')
            .doc(widget.existingProduct!['id'])
            .update(productData);
      } else {
        // Add new product
        productData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('business_products')
            .add(productData);
      }

      widget.onProductAdded();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving product: $e')),
      );
    }

    setState(() => _isLoading = false);
  }
}

// Dialog for creating new products
class CreateNewProductDialog extends StatefulWidget {
  final String businessId;
  final List<Map<String, dynamic>> categories;
  final VoidCallback onProductCreated;

  const CreateNewProductDialog({
    super.key,
    required this.businessId,
    required this.categories,
    required this.onProductCreated,
  });

  @override
  State<CreateNewProductDialog> createState() => _CreateNewProductDialogState();
}

class _CreateNewProductDialogState extends State<CreateNewProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _unitController = TextEditingController();
  
  String? _selectedCategoryId;
  String? _selectedSubcategory;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCategory = widget.categories.firstWhere(
      (cat) => cat['id'] == _selectedCategoryId,
      orElse: () => {},
    );
    
    final subcategories = selectedCategory['subcategories'] as List<dynamic>? ?? [];

    return AlertDialog(
      title: const Text('Create New Product'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Product Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              
              // Category
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  border: OutlineInputBorder(),
                ),
                items: widget.categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category['id'],
                    child: Text(category['name'] ?? ''),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategoryId = value;
                    _selectedSubcategory = null;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Subcategory
              if (subcategories.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  value: _selectedSubcategory,
                  decoration: const InputDecoration(
                    labelText: 'Subcategory',
                    border: OutlineInputBorder(),
                  ),
                  items: subcategories.map((sub) {
                    return DropdownMenuItem(
                      value: sub.toString(),
                      child: Text(sub.toString()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSubcategory = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],
              
              // Unit
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(
                  labelText: 'Unit (e.g., piece, kg, liter)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter unit';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Price
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Your Price (LKR) *',
                  border: OutlineInputBorder(),
                  prefixText: 'LKR ',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a price';
                  }
                  if (double.tryParse(value) == null || double.parse(value) <= 0) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
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
          onPressed: _isLoading ? null : _createProduct,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final selectedCategory = widget.categories.firstWhere(
        (cat) => cat['id'] == _selectedCategoryId,
      );

      // First, create the master product
      final masterProductData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'categoryId': _selectedCategoryId,
        'categoryName': selectedCategory['name'],
        'subcategory': _selectedSubcategory ?? '',
        'unit': _unitController.text.trim(),
        'keywords': _nameController.text.trim().toLowerCase().split(' '),
        'createdAt': FieldValue.serverTimestamp(),
        'source': 'business_created',
        'createdBy': FirebaseAuth.instance.currentUser?.uid,
      };

      final masterProductRef = await FirebaseFirestore.instance
          .collection('master_products')
          .add(masterProductData);

      // Then, add it to business products
      final businessProductData = {
        'businessId': widget.businessId,
        'masterProductId': masterProductRef.id,
        'price': double.parse(_priceController.text),
        'available': true,
        'deliveryAvailable': true,
        'deliveryFee': 0.0,
        'warranty': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('business_products')
          .add(businessProductData);

      widget.onProductCreated();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating product: $e')),
      );
    }

    setState(() => _isLoading = false);
  }
}
