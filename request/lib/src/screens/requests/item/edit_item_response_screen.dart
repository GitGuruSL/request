import 'package:flutter/material.dart';
import '../../../models/request_model.dart';
import '../../../models/response_model.dart';
import '../../../models/enhanced_user_model.dart';
import '../../../services/enhanced_request_service.dart';
import '../../../services/enhanced_user_service.dart';
import '../../../widgets/image_upload_widget.dart';
import '../../../widgets/location_picker_widget.dart';
import '../../../utils/currency_helper.dart';
import '../../../widgets/category_picker.dart';

class EditItemResponseScreen extends StatefulWidget {
  final ResponseModel response;
  final RequestModel? originalRequest;
  
  const EditItemResponseScreen({
    super.key,
    required this.response,
    this.originalRequest,
  });

  @override
  State<EditItemResponseScreen> createState() => _EditItemResponseScreenState();
}

class _EditItemResponseScreenState extends State<EditItemResponseScreen> {
  final _formKey = GlobalKey<FormState>();
  final EnhancedRequestService _requestService = EnhancedRequestService();
  final EnhancedUserService _userService = EnhancedUserService();

  // Form Controllers
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  
  String? _selectedCategory;
  String? _selectedSubcategory;
  String _condition = 'Excellent';
  String _availability = 'Available Now';
  bool _negotiable = true;
  bool _deliveryAvailable = false;
  List<String> _imageUrls = [];

  bool _isLoading = false;

  final List<String> _conditions = [
    'New',
    'Excellent',
    'Good',
    'Fair',
    'Poor',
  ];

  final List<String> _availabilities = [
    'Available Now',
    'Available Soon',
    'By Appointment',
    'Sold/Reserved',
  ];

  @override
  void initState() {
    super.initState();
    _initializeFromResponse();
  }

  void _initializeFromResponse() {
    _descriptionController.text = widget.response.description ?? '';
    _priceController.text = widget.response.price?.toString() ?? '';
    _locationController.text = widget.response.location ?? '';
    _imageUrls = List<String>.from(widget.response.images ?? []);
    
    if (widget.response.metadata != null) {
      final metadata = widget.response.metadata!;
      _selectedCategory = metadata['category'];
      _selectedSubcategory = metadata['subcategory'];
      _brandController.text = metadata['brand'] ?? '';
      _modelController.text = metadata['model'] ?? '';
      _condition = metadata['condition'] ?? 'Excellent';
      _availability = metadata['availability'] ?? 'Available Now';
      _negotiable = metadata['negotiable'] ?? true;
      _deliveryAvailable = metadata['deliveryAvailable'] ?? false;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _updateResponse() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _userService.getCurrentUser();
      if (user == null) {
        throw Exception('User not logged in');
      }

      final updatedData = {
        'description': _descriptionController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'location': _locationController.text.trim(),
        'images': _imageUrls,
        'metadata': {
          'category': _selectedCategory,
          'subcategory': _selectedSubcategory,
          'brand': _brandController.text.trim(),
          'model': _modelController.text.trim(),
          'condition': _condition,
          'availability': _availability,
          'negotiable': _negotiable,
          'deliveryAvailable': _deliveryAvailable,
        },
        'updatedAt': DateTime.now(),
      };

      await _requestService.updateResponse(widget.response.id, updatedData);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item offer updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating offer: $e'),
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
        title: const Text('Edit Item Offer'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updateResponse,
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
            if (widget.originalRequest != null) ...[
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
                    Text(widget.originalRequest!.title, 
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (widget.originalRequest!.description != null) ...[
                      const SizedBox(height: 4),
                      Text(widget.originalRequest!.description!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            _buildSectionTitle('Item Category'),
            const SizedBox(height: 12),
            CategoryPicker(
              selectedCategory: _selectedCategory,
              selectedSubcategory: _selectedSubcategory,
              onCategorySelected: (category, subcategory) {
                setState(() {
                  _selectedCategory = category;
                  _selectedSubcategory = subcategory;
                });
              },
              isRequired: true,
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Item Details'),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Item Description',
                hintText: 'Describe the item you\'re offering...',
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
              ),
              maxLines: 3,
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
                      labelText: 'Brand (Optional)',
                      hintText: 'Apple, Samsung, etc.',
                      filled: true,
                      fillColor: Colors.white,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _modelController,
                    decoration: InputDecoration(
                      labelText: 'Model (Optional)',
                      hintText: 'iPhone 13, Galaxy S21',
                      filled: true,
                      fillColor: Colors.white,
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
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
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _availability,
                    decoration: InputDecoration(
                      labelText: 'Availability',
                      filled: true,
                      fillColor: Colors.white,
                      border: InputBorder.none,
                    ),
                    items: _availabilities.map((availability) {
                      return DropdownMenuItem(
                        value: availability,
                        child: Text(availability),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _availability = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Pricing & Terms'),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: CurrencyHelper.instance.getPriceLabel(),
                hintText: '0.00',
                prefixText: CurrencyHelper.instance.getCurrencyPrefix(),
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your asking price';
                }
                final price = double.tryParse(value.trim());
                if (price == null || price <= 0) {
                  return 'Please enter a valid price';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  CheckboxListTile(
                    title: const Text('Price Negotiable'),
                    subtitle: const Text('Open to reasonable offers'),
                    value: _negotiable,
                    onChanged: (value) {
                      setState(() {
                        _negotiable = value!;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: const Text('Delivery Available'),
                    subtitle: const Text('Can deliver to buyer'),
                    value: _deliveryAvailable,
                    onChanged: (value) {
                      setState(() {
                        _deliveryAvailable = value!;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Item Images'),
            const SizedBox(height: 12),
            ImageUploadWidget(
              initialImages: _imageUrls,
              maxImages: 4,
              uploadPath: 'responses/item',
              label: 'Upload item photos (up to 4)',
              onImagesChanged: (images) {
                setState(() {
                  _imageUrls = images;
                });
              },
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Item Location'),
            const SizedBox(height: 12),
            LocationPickerWidget(
              controller: _locationController,
              labelText: 'Item Location',
              hintText: 'Where is the item located?',
              isRequired: true,
              onLocationSelected: (address, lat, lng) {
                print('Item location: $address at $lat, $lng');
              },
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateResponse,
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
                        'Update Item Offer',
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
