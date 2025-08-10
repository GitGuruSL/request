import 'package:flutter/material.dart';
import '../models/category_model.dart';
import '../services/category_service.dart';

class CategorySelectionWidget extends StatefulWidget {
  final String categoryType;
  final String? selectedCategoryId;
  final String? selectedSubCategoryId;
  final Function(String? categoryId, String? subCategoryId) onSelectionChanged;
  final bool isRequired;

  const CategorySelectionWidget({
    super.key,
    required this.categoryType,
    this.selectedCategoryId,
    this.selectedSubCategoryId,
    required this.onSelectionChanged,
    this.isRequired = true,
  });

  @override
  State<CategorySelectionWidget> createState() => _CategorySelectionWidgetState();
}

class CategoryOption {
  final String id;
  final String displayName;
  final String categoryId;
  final String? subCategoryId;
  final bool isCategory;

  CategoryOption({
    required this.id,
    required this.displayName,
    required this.categoryId,
    this.subCategoryId,
    required this.isCategory,
  });
}

class _CategorySelectionWidgetState extends State<CategorySelectionWidget> {
  final CategoryService _categoryService = CategoryService();
  List<Category> _categories = [];
  List<SubCategory> _subCategories = [];
  bool _isLoading = true;
  String? _selectedCategoryId;
  String? _selectedSubCategoryId;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.selectedCategoryId;
    _selectedSubCategoryId = widget.selectedSubCategoryId;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      setState(() {
        _isLoading = true;
      });

      List<Category> categories;
      switch (widget.categoryType) {
        case 'item':
          categories = await _categoryService.getItemCategories();
          break;
        case 'service':
          categories = await _categoryService.getServiceCategories();
          break;
        case 'delivery':
          categories = await _categoryService.getDeliveryCategories();
          break;
        default:
          categories = await _categoryService.getCategoriesByType(widget.categoryType);
      }
      
      setState(() {
        _categories = categories;
        _isLoading = false;
        
        // Load subcategories if category is already selected
        if (_selectedCategoryId != null) {
          _updateSubCategories(_selectedCategoryId!);
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading categories: $e')),
      );
    }
  }

  void _updateSubCategories(String categoryId) {
    final category = _categories.firstWhere((cat) => cat.id == categoryId);
    setState(() {
      _subCategories = category.subCategories;
      // Reset subcategory selection if it doesn't exist in new category
      if (_selectedSubCategoryId != null && 
          !_subCategories.any((sub) => sub.id == _selectedSubCategoryId)) {
        _selectedSubCategoryId = null;
      }
    });
  }

  void _onCategorySelected(String? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
      _selectedSubCategoryId = null;
      
      if (categoryId != null) {
        _updateSubCategories(categoryId);
      } else {
        _subCategories = [];
      }
    });
    
    widget.onSelectionChanged(_selectedCategoryId, _selectedSubCategoryId);
  }

  void _onSubCategorySelected(String? subCategoryId) {
    setState(() {
      _selectedSubCategoryId = subCategoryId;
    });
    
    widget.onSelectionChanged(_selectedCategoryId, _selectedSubCategoryId);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Card(
        color: Colors.white,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: const Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Loading categories...'),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Categories
        Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              // Category Selection Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getCategoryIcon(),
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getCategoryTitle(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (widget.isRequired)
                      const Text(
                        ' *',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                        ),
                      ),
                  ],
                ),
              ),
              
              // Categories List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _categories.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: Colors.grey.shade200,
                ),
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategoryId == category.id;
                  final hasSubCategories = category.subCategories.isNotEmpty;
                  
                  return InkWell(
                    onTap: () => _onCategorySelected(category.id),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: isSelected ? Colors.blue.shade50 : Colors.white,
                      child: Row(
                        children: [
                          // Selection indicator
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.blue.shade600 : Colors.grey.shade400,
                                width: 2,
                              ),
                              color: isSelected ? Colors.blue.shade600 : Colors.transparent,
                            ),
                            child: isSelected 
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 14,
                                )
                              : null,
                          ),
                          const SizedBox(width: 12),
                          
                          // Category icon (if available)
                          if (category.iconUrl != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Image.network(
                                category.iconUrl!,
                                width: 24,
                                height: 24,
                                errorBuilder: (context, error, stackTrace) => 
                                  const Icon(Icons.category, size: 24),
                              ),
                            )
                          else
                            const Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Icon(Icons.category, size: 24, color: Colors.grey),
                            ),
                          
                          // Category name
                          Expanded(
                            child: Text(
                              category.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                color: isSelected ? Colors.blue.shade800 : Colors.black87,
                              ),
                            ),
                          ),
                          
                          // Arrow indicator for subcategories
                          if (hasSubCategories)
                            Icon(
                              isSelected ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                              color: Colors.grey.shade600,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        
        // Subcategories (shown when a category is selected)
        if (_selectedCategoryId != null && _subCategories.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Column(
              children: [
                // Subcategory Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.subdirectory_arrow_right,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Select Subcategory',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Subcategories List
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _subCategories.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Colors.grey.shade200,
                  ),
                  itemBuilder: (context, index) {
                    final subCategory = _subCategories[index];
                    final isSelected = _selectedSubCategoryId == subCategory.id;
                    
                    return InkWell(
                      onTap: () => _onSubCategorySelected(subCategory.id),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        color: isSelected ? Colors.blue.shade50 : Colors.white,
                        child: Row(
                          children: [
                            // Selection indicator
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? Colors.blue.shade600 : Colors.grey.shade400,
                                  width: 1.5,
                                ),
                                color: isSelected ? Colors.blue.shade600 : Colors.transparent,
                              ),
                              child: isSelected 
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 12,
                                  )
                                : null,
                            ),
                            const SizedBox(width: 16),
                            
                            // Subcategory name
                            Expanded(
                              child: Text(
                                subCategory.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                  color: isSelected ? Colors.blue.shade800 : Colors.black87,
                                ),
                              ),
                            ),
                            
                            // Optional delivery indicator (like in your image)
                            if (subCategory.name.toLowerCase().contains('delivery') || 
                                subCategory.name.toLowerCase().contains('available'))
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Available',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  IconData _getCategoryIcon() {
    switch (widget.categoryType) {
      case 'item':
        return Icons.shopping_bag;
      case 'service':
        return Icons.build;
      case 'delivery':
        return Icons.local_shipping;
      default:
        return Icons.category;
    }
  }

  String _getCategoryTitle() {
    switch (widget.categoryType) {
      case 'item':
        return 'Select Item Category';
      case 'service':
        return 'Select Service Category';
      case 'delivery':
        return 'Select Delivery Category';
      default:
        return 'Select Category';
    }
  }
}
