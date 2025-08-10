import 'package:flutter/material.dart';
import '../../../models/request_model.dart';
import '../../../models/enhanced_user_model.dart';
import '../../../models/category_model.dart';
import '../../../services/enhanced_request_service.dart';
import '../../../services/enhanced_user_service.dart';
import '../../../services/category_service.dart';
import '../../../widgets/image_upload_widget.dart';
import '../../../widgets/category_picker.dart';
import '../../../widgets/location_picker_widget.dart';
import '../../../utils/currency_helper.dart';

class EditItemRequestScreen extends StatefulWidget {
  final RequestModel request;
  
  const EditItemRequestScreen({
    super.key,
    required this.request,
  });

  @override
  State<EditItemRequestScreen> createState() => _EditItemRequestScreenState();
}

class _EditItemRequestScreenState extends State<EditItemRequestScreen> {
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
  String? _selectedCategory;
  String? _selectedSubcategory;
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
    _initializeFromRequest();
  }

  void _initializeFromRequest() {
    // Pre-populate form with existing request data
    _titleController.text = widget.request.title;
    _descriptionController.text = widget.request.description ?? '';
    _locationController.text = widget.request.location ?? '';
    _budgetController.text = widget.request.budget?.toString() ?? '';
    
    _selectedCategory = widget.request.category;
    _selectedCategoryId = widget.request.categoryId;
    _selectedSubcategory = widget.request.subcategory;
    _selectedSubCategoryId = widget.request.subcategoryId;
    
    _imageUrls = List<String>.from(widget.request.images ?? []);
    
    // Initialize item-specific fields from metadata if available
    if (widget.request.metadata != null) {
      final metadata = widget.request.metadata!;
      _condition = metadata['condition'] ?? 'New';
      _isUrgent = metadata['isUrgent'] ?? false;
      _brandController.text = metadata['brand'] ?? '';
      _specificationsController.text = metadata['specifications'] ?? '';
    }
  }

  Future<void> _showCategoryPicker() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => CategoryPicker(
          requestType: 'item',
          scrollController: scrollController,
        ),
      ),
    );

    if (result != null && result.containsKey('category')) {
      setState(() {
        _selectedCategory = result['category'];
        _selectedSubcategory = result['subcategory'];
        _selectedCategoryId = _selectedCategory;
        _selectedSubCategoryId = _selectedSubcategory;
      });
    }
  }

  Future<void> _updateRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _userService.getCurrentUser();
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Create updated request data
      final updatedData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'budget': double.tryParse(_budgetController.text.trim()),
        'category': _selectedCategory,
        'categoryId': _selectedCategoryId,
        'subcategory': _selectedSubcategory,
        'subcategoryId': _selectedSubCategoryId,
        'images': _imageUrls,
        'metadata': {
          'condition': _condition,
          'isUrgent': _isUrgent,
          'brand': _brandController.text.trim(),
          'specifications': _specificationsController.text.trim(),
        },
        'updatedAt': DateTime.now(),
      };

      await _requestService.updateRequest(widget.request.id, updatedData);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item request updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating request: $e'),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFAFF),
      appBar: AppBar(
        title: const Text('Edit Item Request'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updateRequest,
            child: _isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Information
            _buildSectionTitle('Basic Information'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Item Title',
                hintText: 'What item do you need?',
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter the item you need';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Describe what you need in detail...',
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
            TextFormField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Item Category',
                hintText: 'Select an item category',
                suffixIcon: Icon(Icons.arrow_drop_down),
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
              ),
              controller: TextEditingController(
                text: _selectedSubcategory != null 
                  ? '$_selectedCategory > $_selectedSubcategory'
                  : _selectedCategory ?? '',
              ),
              onTap: _showCategoryPicker,
              validator: (value) {
                if (_selectedCategory == null) {
                  return 'Please select an item category';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _brandController,
                    decoration: InputDecoration(
                      labelText: 'Preferred Brand (Optional)',
                      hintText: 'Any specific brand?',
                      filled: true,
                      fillColor: Colors.white,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _condition,
                    decoration: InputDecoration(
                      labelText: 'Condition',
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
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _specificationsController,
              decoration: InputDecoration(
                labelText: 'Specifications (Optional)',
                hintText: 'Any specific requirements, features, size, etc...',
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Images
            _buildSectionTitle('Reference Images'),
            const SizedBox(height: 12),
            ImageUploadWidget(
              initialImages: _imageUrls,
              maxImages: 4,
              uploadPath: 'requests/items',
              label: 'Upload reference images (up to 4)',
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
              decoration: InputDecoration(
                labelText: CurrencyHelper.instance.getBudgetLabel(),
                hintText: '0.00',
                prefixText: CurrencyHelper.instance.getCurrencyPrefix(),
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: CheckboxListTile(
                title: const Text('Urgent Request'),
                subtitle: const Text('I need this item urgently'),
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
            const SizedBox(height: 16),
            LocationPickerWidget(
              controller: _locationController,
              labelText: 'Preferred Location',
              hintText: 'Where would you like to find this item?',
              isRequired: true,
              onLocationSelected: (address, lat, lng) {
                print('Item location selected: $address at $lat, $lng');
              },
            ),
            const SizedBox(height: 32),

            // Update Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateRequest,
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
                        'Update Item Request',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
