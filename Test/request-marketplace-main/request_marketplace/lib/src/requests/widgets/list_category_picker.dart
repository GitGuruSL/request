import 'package:flutter/material.dart';
import '../../services/category_service.dart';

class ListCategoryPicker extends StatefulWidget {
  final String requestType; // 'item', 'service'
  final Function(String category, String? subcategory) onCategorySelected;

  const ListCategoryPicker({
    super.key,
    required this.requestType,
    required this.onCategorySelected,
  });

  @override
  State<ListCategoryPicker> createState() => _ListCategoryPickerState();
}

class _ListCategoryPickerState extends State<ListCategoryPicker> {
  final CategoryService _categoryService = CategoryService();
  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      print('🔍 ListCategoryPicker: Loading categories for type: ${widget.requestType}');
      
      final categories = await _categoryService.getCategoriesForType(widget.requestType);
      
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
        
        print('✅ ListCategoryPicker: Loaded ${categories.length} categories');
        if (categories.isEmpty) {
          print('⚠️ No categories found for type ${widget.requestType}');
        }
      }
    } catch (e) {
      print('❌ ListCategoryPicker Error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _onCategoryTap(CategoryModel category) async {
    try {
      // Load subcategories for this category
      final subcategories = await _categoryService.getSubcategoriesForCategory(category.id);
      
      if (subcategories.isEmpty) {
        // No subcategories, select the main category directly
        widget.onCategorySelected(category.category, null);
        Navigator.pop(context);
      } else {
        // Show subcategories
        _showSubcategories(category, subcategories);
      }
    } catch (e) {
      print('Error loading subcategories: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading subcategories: $e')),
      );
    }
  }

  void _showSubcategories(CategoryModel category, List<SubcategoryModel> subcategories) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(category.category),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 1,
          ),
          body: Column(
            children: [
              // "All [Category]" option
              ListTile(
                leading: const Icon(Icons.all_inclusive, color: Colors.blue),
                title: Text('All ${category.category}'),
                subtitle: const Text('Select this main category'),
                onTap: () {
                  widget.onCategorySelected(category.category, null);
                  Navigator.pop(context); // Close subcategory screen
                  Navigator.pop(context); // Close main category screen
                },
              ),
              const Divider(),
              // Subcategories
              Expanded(
                child: ListView.builder(
                  itemCount: subcategories.length,
                  itemBuilder: (context, index) {
                    final subcategory = subcategories[index];
                    return ListTile(
                      leading: Icon(
                        _getSubcategoryIcon(subcategory.subcategory),
                        color: Colors.grey[600],
                      ),
                      title: Text(subcategory.subcategory),
                      subtitle: const Text('Tap to select'),
                      onTap: () {
                        widget.onCategorySelected(category.category, subcategory.subcategory);
                        Navigator.pop(context); // Close subcategory screen
                        Navigator.pop(context); // Close main category screen
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'electronics':
        return Icons.devices;
      case 'vehicles':
        return Icons.directions_car;
      case 'home & garden':
        return Icons.home;
      case 'fashion & clothing':
        return Icons.checkroom;
      case 'home services':
        return Icons.home_repair_service;
      case 'transportation':
        return Icons.local_shipping;
      case 'professional services':
        return Icons.business;
      case 'education & training':
        return Icons.school;
      default:
        return Icons.category;
    }
  }

  IconData _getSubcategoryIcon(String subcategory) {
    switch (subcategory.toLowerCase()) {
      case 'mobile phones':
        return Icons.smartphone;
      case 'laptops & computers':
        return Icons.laptop;
      case 'cars':
        return Icons.directions_car;
      case 'motorcycles':
        return Icons.motorcycle;
      case 'clothing':
        return Icons.checkroom;
      case 'shoes':
        return Icons.shopping_bag;
      case 'cleaning':
        return Icons.cleaning_services;
      case 'plumbing':
        return Icons.plumbing;
      case 'electrical':
        return Icons.electrical_services;
      case 'delivery':
        return Icons.local_shipping;
      case 'tutoring':
        return Icons.school;
      case 'photography':
        return Icons.camera_alt;
      default:
        return Icons.fiber_manual_record;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Category'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCategories,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading categories...'),
                ],
              ),
            )
          : _hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Error Loading Categories',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _errorMessage ?? 'Failed to load categories',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadCategories,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _categories.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.category_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No categories available',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Categories will be loaded from the admin panel',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadCategories,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          child: ListTile(
                            leading: Icon(
                              _getCategoryIcon(category.category),
                              color: Colors.blue,
                              size: 28,
                            ),
                            title: Text(
                              category.category,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            subtitle: Text(
                              'Tap to view ${category.category.toLowerCase()} options',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey,
                            ),
                            onTap: () => _onCategoryTap(category),
                          ),
                        );
                      },
                    ),
    );
  }
}
