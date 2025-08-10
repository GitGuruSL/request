import 'package:flutter/material.dart';
import '../../../models/request_model.dart';
import '../../../models/enhanced_user_model.dart';
import '../../../models/category_model.dart';
import '../../../services/enhanced_request_service.dart';
import '../../../services/enhanced_user_service.dart';
import '../../../services/category_service.dart';
import '../../../widgets/image_upload_widget.dart';
import '../../../widgets/category_selection_widget.dart';

class CreateItemRequestScreen extends StatefulWidget {
  const CreateItemRequestScreen({super.key});

  @override
  State<CreateItemRequestScreen> createState() => _CreateItemRequestScreenState();
}

class _CreateItemRequestScreenState extends State<CreateItemRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final EnhancedRequestService _requestService = EnhancedRequestService();
  final EnhancedUserService _userService = EnhancedUserService();

  // Form Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController();
  
  // Item-specific fields
  String? _selectedCategoryId;
  String? _selectedSubCategoryId;
  String _condition = 'New';
  bool _isUrgent = false;
  final _brandController = TextEditingController();
  final _specificationsController = TextEditingController();
  List<String> _imageUrls = [];

  bool _isLoading = false;

  final List<String> _conditions = [
    'New',
    'Like New',
    'Good',
    'Fair',
    'Any Condition',
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    _brandController.dispose();
    _specificationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFAFF),
      appBar: AppBar(
        title: const Text('Create Item Request'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.shopping_bag, color: Colors.blue[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Item Request',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[600],
                            ),
                          ),
                          const Text(
                            'Looking for a specific item? Tell us what you need!',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Basic Information
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'What are you looking for?',
                  hintText: 'e.g., iPhone 15 Pro, Gaming Chair',
                  filled: true,
                  fillColor: Colors.white,
                  border: InputBorder.none,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter what you\'re looking for';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Provide more details about the item...',
                  filled: true,
                  fillColor: Colors.white,
                  border: InputBorder.none,
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Item Details
              _buildSectionTitle('Item Details'),
              const SizedBox(height: 12),
              
              // Category Selection
              CategorySelectionWidget(
                categoryType: 'item',
                selectedCategoryId: _selectedCategoryId,
                selectedSubCategoryId: _selectedSubCategoryId,
                onSelectionChanged: (categoryId, subCategoryId) {
                  setState(() {
                    _selectedCategoryId = categoryId;
                    _selectedSubCategoryId = subCategoryId;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _condition,
                decoration: const InputDecoration(
                  labelText: 'Preferred Condition',
                  filled: true,
                  fillColor: Colors.white,
                  border: InputBorder.none,
                ),
                items: _conditions.map((condition) {
                  return DropdownMenuItem(
                    value: condition,
                    child: Text(condition),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _condition = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(
                  labelText: 'Brand (Optional)',
                  hintText: 'e.g., Apple, Samsung, Nike',
                  filled: true,
                  fillColor: Colors.white,
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _specificationsController,
                decoration: const InputDecoration(
                  labelText: 'Specifications (Optional)',
                  hintText: 'Size, color, model, features...',
                  filled: true,
                  fillColor: Colors.white,
                  border: InputBorder.none,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Images
              _buildSectionTitle('Images'),
              const SizedBox(height: 12),
              ImageUploadWidget(
                initialImages: _imageUrls,
                maxImages: 4,
                uploadPath: 'requests/items',
                label: 'Upload item images (up to 4)',
                onImagesChanged: (images) {
                  setState(() {
                    _imageUrls = images;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Budget & Location
              _buildSectionTitle('Budget & Location'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _budgetController,
                decoration: const InputDecoration(
                  labelText: 'Budget (USD)',
                  hintText: '0.00',
                  prefixText: '\$ ',
                  filled: true,
                  fillColor: Colors.white,
                  border: InputBorder.none,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Preferred Location',
                  hintText: 'Where would you like to pick up?',
                  filled: true,
                  fillColor: Colors.white,
                  border: InputBorder.none,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please specify your preferred location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Options
              _buildSectionTitle('Options'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CheckboxListTile(
                  title: const Text('This is urgent'),
                  subtitle: const Text('I need this item as soon as possible'),
                  value: _isUrgent,
                  onChanged: (value) {
                    setState(() {
                      _isUrgent = value!;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Create Item Request',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if user has verified phone number
      final currentUser = await _userService.getCurrentUserModel();
      if (currentUser == null || !currentUser.isPhoneVerified) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please verify your phone number to create requests'),
            ),
          );
        }
        return;
      }

      // Get category and subcategory info
      String categoryName = 'Item'; // Default fallback
      String? subCategoryName;

      // If we have selected categories, we'll store the IDs and let the backend handle names
      if (_selectedCategoryId != null) {
        // We'll use the category ID and let the backend resolve the name
        categoryName = 'Selected Item Category'; // Placeholder - backend will resolve
      }

      // Create the item-specific data
      final itemData = ItemRequestData(
        category: categoryName,
        brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
        condition: _condition,
        specifications: {
          'specifications': _specificationsController.text.trim(),
          'isUrgent': _isUrgent.toString(),
          'categoryId': _selectedCategoryId ?? '',
          'subCategoryId': _selectedSubCategoryId ?? '',
        },
        acceptAlternatives: true,
      );

      final requestId = await _requestService.createRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: RequestType.item,
        budget: double.tryParse(_budgetController.text),
        currency: 'USD',
        typeSpecificData: itemData.toMap(),
        tags: [
          'item', 
          'category_${_selectedCategoryId ?? 'other'}',
          if (_selectedSubCategoryId != null) 'subcategory_${_selectedSubCategoryId}',
        ],
        location: LocationInfo(
          latitude: 0.0,
          longitude: 0.0,
          address: _locationController.text.trim(),
        ),
        images: _imageUrls,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item request created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
