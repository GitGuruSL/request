import 'package:flutter/material.dart';
import '../services/rest_category_service.dart';

class CategoryPicker extends StatefulWidget {
  final String requestType; // 'item', 'service', 'delivery', or 'rent'
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
  final Map<String, String> _categoryNameToId =
      {}; // Map main category name -> category id

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

      // Fetch categories via REST service then fetch their real subcategories
      final rest = RestCategoryService.instance;
      final allCategories = await rest.getCategoriesWithCache();

      // Heuristic filter by requestType (until backend supplies explicit field)
      final t = widget.requestType.toLowerCase();
      final relevant = allCategories
          .where((c) =>
              c.name.toLowerCase().contains(t) ||
              (c.description?.toLowerCase().contains(t) ?? false))
          .toList();
      final source = relevant.isEmpty ? allCategories : relevant;

      Map<String, List<String>> categories = {};
      for (final cat in source) {
        _categoryNameToId[cat.name] = cat.id;
        // Load subcategories from API (cached)
        final subs = await rest.getSubcategoriesWithCache(categoryId: cat.id);
        if (subs.isEmpty) {
          categories.putIfAbsent(cat.name, () => []);
        } else {
          categories[cat.name] = subs.map((s) => s.name).toList();
        }
      }

      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });

        if (categories.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No categories found. Using default categories.'),
              backgroundColor: Colors.orange,
            ),
          );
        } else {
          print(
              '✅ CategoryPicker: Successfully loaded ${categories.length} categories');
        }
      }
    } catch (e) {
      print('Error loading categories: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _categories = _getFallbackCategories();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Using default categories. Error: $e')),
        );
      }
    }
  }

  Map<String, List<String>> _getFallbackCategories() {
    switch (widget.requestType) {
      case 'item':
        return {
          'Electronics': [
            'Mobile Phones',
            'Laptops & Computers',
            'Gaming Consoles',
            'TV & Audio',
            'Cameras',
            'Accessories'
          ],
          'Clothing & Fashion': [
            'Clothing',
            'Shoes',
            'Bags',
            'Jewelry',
            'Accessories'
          ],
          'Home & Garden': [
            'Furniture',
            'Appliances',
            'Garden',
            'Kitchen Items',
            'Home Decor'
          ],
          'Sports & Outdoors': [
            'Sports Equipment',
            'Fitness Gear',
            'Outdoor Equipment',
            'Exercise'
          ],
          'Books & Media': ['Books', 'Movies', 'Music', 'Games'],
          'Automotive': ['Cars', 'Motorcycles', 'Parts', 'Accessories'],
        };
      case 'service':
        return {
          'Home Services': [
            'Cleaning',
            'Plumbing',
            'Electrical',
            'Carpentry',
            'Painting',
            'Gardening'
          ],
          'Personal Services': [
            'Beauty',
            'Fitness Training',
            'Tutoring',
            'Photography',
            'Event Planning'
          ],
          'Professional Services': [
            'IT Support',
            'Legal',
            'Financial',
            'Consulting',
            'Marketing'
          ],
          'Transportation': ['Delivery', 'Moving', 'Taxi Service', 'Courier'],
        };
      case 'delivery':
        return {
          'Food & Beverages': [
            'Restaurant Food',
            'Groceries',
            'Beverages',
            'Snacks'
          ],
          'Retail Items': ['Clothing', 'Electronics', 'Books', 'General Items'],
          'Documents': [
            'Legal Documents',
            'Business Papers',
            'Personal Documents'
          ],
          'Medical': ['Prescriptions', 'Medical Supplies', 'Lab Results'],
        };
      case 'rent':
        return {
          'Vehicles': ['Cars', 'Motorcycles', 'Bicycles', 'Trucks', 'Vans'],
          'Electronics': [
            'Laptops',
            'Gaming Consoles',
            'Cameras',
            'Audio Equipment',
            'Projectors'
          ],
          'Tools & Equipment': [
            'Power Tools',
            'Garden Tools',
            'Construction Equipment',
            'Kitchen Appliances'
          ],
          'Furniture': ['Tables', 'Chairs', 'Sofas', 'Beds', 'Storage Units'],
          'Event Items': [
            'Tents',
            'Chairs',
            'Tables',
            'Sound Systems',
            'Lighting'
          ],
          'Sports Equipment': [
            'Bicycles',
            'Gym Equipment',
            'Outdoor Gear',
            'Water Sports'
          ],
        };
      default:
        return {};
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
                  onPressed: _isLoading
                      ? null
                      : () {
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
        final subcategoryCount = _categories[category]?.length ?? 0;

        return ListTile(
          leading: Icon(
            Icons.folder,
            color: Colors.blue.shade600,
          ),
          title: Text(
            category,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            '$subcategoryCount subcategories',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            if (subcategoryCount > 0) {
              setState(() {
                _selectedMainCategory = category;
              });
            } else {
              // If no subcategories, return the main category
              Navigator.pop(context, {
                'category': category,
                'subcategory': null,
                'categoryId': _categoryNameToId[category],
              });
            }
          },
        );
      },
    );
  }

  Widget _buildSubCategoryList(
      String mainCategory, List<String> subcategories) {
    return ListView.builder(
      controller: widget.scrollController,
      itemCount: subcategories.length + 1, // +1 for "All" option
      itemBuilder: (context, index) {
        if (index == 0) {
          // "All" option to select just the main category
          return ListTile(
            leading: Icon(
              Icons.select_all,
              color: Colors.green.shade600,
            ),
            title: Text(
              'All $mainCategory',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: const Text(
              'Select entire category',
              style: TextStyle(
                fontSize: 14,
              ),
            ),
            onTap: () {
              Navigator.pop(context, {
                'category': mainCategory,
                'subcategory': null,
                'categoryId': _categoryNameToId[mainCategory],
              });
            },
          );
        }

        final subcategory = subcategories[index - 1];
        return ListTile(
          leading: Icon(
            Icons.subdirectory_arrow_right,
            color: Colors.grey[600],
          ),
          title: Text(
            subcategory,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          onTap: () {
            Navigator.pop(context, {
              'category': mainCategory,
              'subcategory': subcategory,
              'categoryId': _categoryNameToId[mainCategory],
              // Subcategory ID not tracked yet (would need reverse map if required)
            });
          },
        );
      },
    );
  }
}
