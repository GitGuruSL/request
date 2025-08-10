import 'package:flutter/material.dart';
import '../../../src/models/category_data.dart';

class CategoryPicker extends StatefulWidget {
  final String requestType; // 'item', 'service', or 'product'
  final ScrollController scrollController;

  const CategoryPicker({
    super.key,
    required this.requestType,
    required this.scrollController,
  });

  @override
  State<CategoryPicker> createState() => _CategoryPickerState();
}

class _CategoryPickerState extends State<CategoryPicker> {
  String? _selectedMainCategory;
  Map<String, List<String>> _categories = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await CategoryData.getCategoriesForType(widget.requestType);
      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading categories: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_selectedMainCategory != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      setState(() {
                        _selectedMainCategory = null;
                      });
                    },
                  ),
                Expanded(
                  child: Text(
                    _selectedMainCategory ?? 'Select a Category',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _isLoading ? null : () {
                    CategoryData.clearCache();
                    _loadCategories();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _categories.isEmpty
                    ? _buildEmptyState()
                    : _selectedMainCategory == null
                        ? _buildMainCategoryList(_categories.keys.toList())
                        : _buildSubCategoryList(
                            _selectedMainCategory!,
                            _categories[_selectedMainCategory!] ?? [],
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No categories available',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Categories will be loaded from the admin panel',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              CategoryData.clearCache();
              _loadCategories();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildMainCategoryList(List<String> mainCategories) {
    return ListView.builder(
      controller: widget.scrollController,
      itemCount: mainCategories.length,
      itemBuilder: (context, index) {
        final category = mainCategories[index];
        final hasSubcategories = (_categories[category]?.isNotEmpty ?? false);
        
        return ListTile(
          leading: Icon(
            _getCategoryIcon(category),
            color: Theme.of(context).primaryColor,
          ),
          title: Text(category),
          subtitle: hasSubcategories 
              ? Text('${_categories[category]!.length} subcategories')
              : null,
          trailing: hasSubcategories 
              ? const Icon(Icons.chevron_right)
              : null,
          onTap: () {
            if (hasSubcategories) {
              setState(() {
                _selectedMainCategory = category;
              });
            } else {
              // No subcategories, select this category directly
              Navigator.pop(
                context,
                {'category': category, 'subcategory': null},
              );
            }
          },
        );
      },
    );
  }

  Widget _buildSubCategoryList(String mainCategory, List<String> subCategories) {
    return ListView.builder(
      controller: widget.scrollController,
      itemCount: subCategories.length + 1, // +1 for "All" option
      itemBuilder: (context, index) {
        if (index == 0) {
          // "All" option to select main category without subcategory
          return ListTile(
            leading: Icon(
              Icons.all_inclusive,
              color: Theme.of(context).primaryColor,
            ),
            title: Text('All $mainCategory'),
            subtitle: const Text('Select this main category'),
            onTap: () {
              Navigator.pop(
                context,
                {'category': mainCategory, 'subcategory': null},
              );
            },
          );
        }
        
        final subCategory = subCategories[index - 1];
        return ListTile(
          leading: Icon(
            _getSubcategoryIcon(subCategory),
            color: Colors.grey[600],
          ),
          title: Text(subCategory),
          onTap: () {
            Navigator.pop(
              context,
              {'category': mainCategory, 'subcategory': subCategory},
            );
          },
        );
      },
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
      case 'fashion':
      case 'fashion & clothing':
        return Icons.checkroom;
      case 'home services':
        return Icons.home_repair_service;
      case 'transportation':
        return Icons.local_shipping;
      case 'professional services':
        return Icons.business;
      case 'personal services':
        return Icons.person;
      case 'technical services':
        return Icons.computer;
      case 'event services':
        return Icons.event;
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
}
