import 'package:flutter/material.dart';
import '../services/rest_category_service.dart';

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
  State<CategorySelectionWidget> createState() =>
      _CategorySelectionWidgetState();
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
  final RestCategoryService _categoryService = RestCategoryService.instance;
  List<CategoryOption> _categoryOptions = [];
  bool _isLoading = true;
  String? _selectedValue;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // REST categories (filter by type in name/description)
      final all = await _categoryService.getCategoriesWithCache();
      final filter = widget.categoryType.toLowerCase();
      final categories = all
          .where((c) =>
              c.name.toLowerCase().contains(filter) ||
              (c.description?.toLowerCase().contains(filter) ?? false))
          .toList();

      List<CategoryOption> options = [];

      for (var category in categories) {
        // Add the main category
        options.add(CategoryOption(
          id: 'cat_${category.id}',
          displayName: category.name,
          categoryId: category.id,
          isCategory: true,
        ));
      }

      setState(() {
        _categoryOptions = options;
        _isLoading = false;

        // Set initial selection
        if (widget.selectedCategoryId != null) {
          if (widget.selectedSubCategoryId != null) {
            _selectedValue =
                'sub_${widget.selectedCategoryId}_${widget.selectedSubCategoryId}';
          } else {
            _selectedValue = 'cat_${widget.selectedCategoryId}';
          }
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading categories: $e')),
        );
      }
    }
  }

  void _onSelectionChanged(String? value) {
    setState(() {
      _selectedValue = value;
    });

    if (value == null) {
      widget.onSelectionChanged(null, null);
      return;
    }

    final selectedOption =
        _categoryOptions.firstWhere((opt) => opt.id == value);
    widget.onSelectionChanged(
      selectedOption.categoryId,
      selectedOption.subCategoryId,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Loading categories...'),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedValue,
      decoration: InputDecoration(
        labelText: _getCategoryTitle(),
        hintText: 'Select a category or subcategory',
        prefixIcon: Icon(
          _getCategoryIcon(),
          color: Colors.blue.shade600,
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.blue.shade600, width: 2),
        ),
      ),
      items: _categoryOptions.map((option) {
        return DropdownMenuItem<String>(
          value: option.id,
          child: Row(
            children: [
              // Icon for category vs subcategory
              Icon(
                option.isCategory
                    ? Icons.folder
                    : Icons.subdirectory_arrow_right,
                size: 16,
                color: option.isCategory
                    ? Colors.blue.shade600
                    : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  option.displayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight:
                        option.isCategory ? FontWeight.w500 : FontWeight.normal,
                    color: option.isCategory
                        ? Colors.black87
                        : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: _onSelectionChanged,
      validator: widget.isRequired
          ? (value) {
              if (value == null || value.isEmpty) {
                return 'Please select a category';
              }
              return null;
            }
          : null,
      isExpanded: true,
      menuMaxHeight: 300,
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
        return 'Item Category';
      case 'service':
        return 'Service Category';
      case 'delivery':
        return 'Delivery Category';
      default:
        return 'Category';
    }
  }
}
