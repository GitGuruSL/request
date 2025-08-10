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

class CreateItemResponseScreen extends StatefulWidget {
  final RequestModel request;
  
  const CreateItemResponseScreen({
    super.key,
    required this.request,
  });

  @override
  State<CreateItemResponseScreen> createState() => _CreateItemResponseScreenState();
}

class _CreateItemResponseScreenState extends State<CreateItemResponseScreen> {
  final _formKey = GlobalKey<FormState>();
  final EnhancedRequestService _requestService = EnhancedRequestService();
  final EnhancedUserService _userService = EnhancedUserService();

  // Form Controllers
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _brandController = TextEditingController();
  final _specificationsController = TextEditingController();
  final _warrantyController = TextEditingController();
  
  // Item-specific fields
  String? _selectedCategoryId;
  String? _selectedSubCategoryId;
  String? _selectedCategory;
  String? _selectedSubcategory;
  String _condition = 'New';
  String _deliveryType = 'Pickup';
  bool _isNegotiable = true;
  List<String> _imageUrls = [];

  bool _isLoading = false;

  final List<String> _conditions = [
    'New',
    'Like New',
    'Good',
    'Fair',
  ];

  final List<String> _deliveryTypes = [
    'Pickup',
    'Delivery',
    'Both',
  ];

  @override
  void initState() {
    super.initState();
    _initializeFromRequest();
  }

  void _initializeFromRequest() {
    // Initialize category from request if available
    if (widget.request.category != null) {
      _selectedCategory = widget.request.category;
      _selectedCategoryId = widget.request.categoryId;
      _selectedSubcategory = widget.request.subcategory;
      _selectedSubCategoryId = widget.request.subcategoryId;
    }
    
    // Initialize location from request if available
    if (widget.request.location != null) {
      _locationController.text = widget.request.location!;
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

  Future<void> _submitResponse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _userService.getCurrentUser();
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Create response data
      final responseData = {
        'requestId': widget.request.id,
        'requesterId': widget.request.userId,
        'responderId': user.uid,
        'responderName': user.businessName ?? user.displayName,
        'responderPhone': user.phoneNumber,
        'description': _descriptionController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'location': _locationController.text.trim(),
        'brand': _brandController.text.trim(),
        'specifications': _specificationsController.text.trim(),
        'warranty': _warrantyController.text.trim(),
        'condition': _condition,
        'deliveryType': _deliveryType,
        'isNegotiable': _isNegotiable,
        'category': _selectedCategory ?? widget.request.category,
        'categoryId': _selectedCategoryId ?? widget.request.categoryId,
        'subcategory': _selectedSubcategory ?? widget.request.subcategory,
        'subcategoryId': _selectedSubCategoryId ?? widget.request.subcategoryId,
        'images': _imageUrls,
        'status': 'pending',
        'createdAt': DateTime.now(),
        'type': 'item',
      };

      await _requestService.createResponse(responseData);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item response submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting response: $e'),
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
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _brandController.dispose();
    _specificationsController.dispose();
    _warrantyController.dispose();
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
        title: const Text('Respond to Item Request'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Request Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Original Request',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(widget.request.title, 
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (widget.request.description != null) ...[
                    const SizedBox(height: 4),
                    Text(widget.request.description!),
                  ],
                  if (widget.request.budget != null) ...[
                    const SizedBox(height: 4),
                    Text('Budget: ${CurrencyHelper.instance.formatPrice(widget.request.budget!)}'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Item Details
            _buildSectionTitle('Your Item Offer'),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Item Description',
                hintText: 'Describe the item you are offering...',
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please describe your item';
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
                      labelText: 'Brand',
                      hintText: 'Item brand/manufacturer',
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
                labelText: 'Specifications',
                hintText: 'Technical details, features, etc...',
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Category Selection (if different from request)
            TextFormField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Item Category',
                hintText: 'Select item category (optional)',
                suffixIcon: Icon(Icons.arrow_drop_down),
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
              ),
              controller: TextEditingController(
                text: _selectedSubcategory != null 
                  ? '$_selectedCategory > $_selectedSubcategory'
                  : _selectedCategory ?? (widget.request.category ?? ''),
              ),
              onTap: _showCategoryPicker,
            ),
            const SizedBox(height: 24),

            // Pricing & Terms
            _buildSectionTitle('Pricing & Terms'),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'Your Price (USD)',
                hintText: '0.00',
                prefixText: CurrencyHelper.instance.getCurrencyPrefix(),
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your price';
                }
                final price = double.tryParse(value.trim());
                if (price == null || price <= 0) {
                  return 'Please enter a valid price';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _deliveryType,
                    decoration: InputDecoration(
                      labelText: 'Delivery',
                      filled: true,
                      fillColor: Colors.white,
                      border: InputBorder.none,
                    ),
                    items: _deliveryTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _deliveryType = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _warrantyController,
                    decoration: InputDecoration(
                      labelText: 'Warranty',
                      hintText: 'e.g. 6 months',
                      filled: true,
                      fillColor: Colors.white,
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: CheckboxListTile(
                title: const Text('Price Negotiable'),
                subtitle: const Text('Allow price negotiations'),
                value: _isNegotiable,
                onChanged: (value) {
                  setState(() {
                    _isNegotiable = value!;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 24),

            // Images
            _buildSectionTitle('Item Images'),
            const SizedBox(height: 12),
            ImageUploadWidget(
              initialImages: _imageUrls,
              maxImages: 4,
              uploadPath: 'responses/items',
              label: 'Upload item photos (up to 4)',
              onImagesChanged: (images) {
                setState(() {
                  _imageUrls = images;
                });
              },
            ),
            const SizedBox(height: 24),

            // Location
            _buildSectionTitle('Item Location'),
            const SizedBox(height: 12),
            LocationPickerWidget(
              controller: _locationController,
              labelText: 'Item Location',
              hintText: 'Where is this item located?',
              isRequired: true,
              onLocationSelected: (address, lat, lng) {
                print('Item response location: $address at $lat, $lng');
              },
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitResponse,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Submit Item Response',
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
