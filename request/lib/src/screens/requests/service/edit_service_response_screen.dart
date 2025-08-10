import 'package:flutter/material.dart';
import '../../../models/request_model.dart';
import '../../../models/response_model.dart';
import '../../../models/enhanced_user_model.dart';
import '../../../services/enhanced_request_service.dart';
import '../../../services/enhanced_user_service.dart';
import '../../../widgets/image_upload_widget.dart';
import '../../../widgets/category_picker.dart';
import '../../../widgets/location_picker_widget.dart';
import '../../../utils/currency_helper.dart';

class EditServiceResponseScreen extends StatefulWidget {
  final ResponseModel response;
  final RequestModel? originalRequest;
  
  const EditServiceResponseScreen({
    super.key,
    required this.response,
    this.originalRequest,
  });

  @override
  State<EditServiceResponseScreen> createState() => _EditServiceResponseScreenState();
}

class _EditServiceResponseScreenState extends State<EditServiceResponseScreen> {
  final _formKey = GlobalKey<FormState>();
  final EnhancedRequestService _requestService = EnhancedRequestService();
  final EnhancedUserService _userService = EnhancedUserService();

  // Form Controllers
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _availabilityController = TextEditingController();
  
  // Service-specific fields
  String? _selectedCategoryId;
  String? _selectedSubCategoryId;
  String? _selectedCategory;
  String? _selectedSubcategory;
  String _serviceType = 'One-time';
  bool _isRemote = false;
  DateTime? _availableDate;
  List<String> _imageUrls = [];

  bool _isLoading = false;

  final List<String> _serviceTypes = [
    'One-time',
    'Recurring',
    'Project-based',
    'Hourly',
  ];

  @override
  void initState() {
    super.initState();
    _initializeFromResponse();
  }

  void _initializeFromResponse() {
    // Pre-populate form with existing response data
    _descriptionController.text = widget.response.description ?? '';
    _priceController.text = widget.response.price?.toString() ?? '';
    _locationController.text = widget.response.location ?? '';
    
    _selectedCategory = widget.response.category;
    _selectedCategoryId = widget.response.categoryId;
    _selectedSubcategory = widget.response.subcategory;
    _selectedSubCategoryId = widget.response.subcategoryId;
    
    _imageUrls = List<String>.from(widget.response.images ?? []);
    
    // Initialize service-specific fields from metadata if available
    if (widget.response.metadata != null) {
      final metadata = widget.response.metadata!;
      _experienceController.text = metadata['experience'] ?? '';
      _availabilityController.text = metadata['availability'] ?? '';
      _serviceType = metadata['serviceType'] ?? 'One-time';
      _isRemote = metadata['isRemote'] ?? false;
      
      if (metadata['availableDate'] != null) {
        _availableDate = metadata['availableDate'] is DateTime 
          ? metadata['availableDate']
          : DateTime.tryParse(metadata['availableDate'].toString());
      }
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
          requestType: 'service',
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _availableDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _availableDate = picked;
      });
    }
  }

  Future<void> _updateResponse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _userService.getCurrentUser();
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Create updated response data
      final updatedData = {
        'description': _descriptionController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'location': _locationController.text.trim(),
        'category': _selectedCategory,
        'categoryId': _selectedCategoryId,
        'subcategory': _selectedSubcategory,
        'subcategoryId': _selectedSubCategoryId,
        'images': _imageUrls,
        'metadata': {
          'experience': _experienceController.text.trim(),
          'availability': _availabilityController.text.trim(),
          'availableDate': _availableDate,
          'serviceType': _serviceType,
          'isRemote': _isRemote,
        },
        'updatedAt': DateTime.now(),
      };

      await _requestService.updateResponse(widget.response.id, updatedData);

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate successful update
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service response updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating response: $e'),
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
    _experienceController.dispose();
    _availabilityController.dispose();
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
        title: const Text('Edit Service Response'),
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
            // Original Request Summary (if available)
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

            // Service Details
            _buildSectionTitle('Your Service Offer'),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Service Description',
                hintText: 'Describe how you will provide this service...',
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please describe your service';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _experienceController,
              decoration: InputDecoration(
                labelText: 'Experience & Qualifications',
                hintText: 'Your relevant experience for this service...',
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please describe your experience';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Category Selection
            TextFormField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Service Category',
                hintText: 'Select service category (optional)',
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
            ),
            const SizedBox(height: 24),

            // Service Terms
            _buildSectionTitle('Service Terms'),
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

            DropdownButtonFormField<String>(
              value: _serviceType,
              decoration: InputDecoration(
                labelText: 'Service Type',
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
              ),
              items: _serviceTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _serviceType = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _availabilityController,
              decoration: InputDecoration(
                labelText: 'Availability',
                hintText: 'When are you available to provide this service?',
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please specify your availability';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title: Text(_availableDate == null 
                  ? 'Select Available Date' 
                  : 'Available from: ${_availableDate!.day}/${_availableDate!.month}/${_availableDate!.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDate,
              ),
            ),
            const SizedBox(height: 24),

            // Images
            _buildSectionTitle('Portfolio Images'),
            const SizedBox(height: 12),
            ImageUploadWidget(
              initialImages: _imageUrls,
              maxImages: 4,
              uploadPath: 'responses/services',
              label: 'Upload portfolio/work samples (up to 4)',
              onImagesChanged: (images) {
                setState(() {
                  _imageUrls = images;
                });
              },
            ),
            const SizedBox(height: 24),

            // Location
            _buildSectionTitle('Service Location'),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: CheckboxListTile(
                title: const Text('Remote Service'),
                subtitle: const Text('I can provide this service remotely'),
                value: _isRemote,
                onChanged: (value) {
                  setState(() {
                    _isRemote = value!;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (!_isRemote) ...[
              const SizedBox(height: 16),
              LocationPickerWidget(
                controller: _locationController,
                labelText: 'Service Location',
                hintText: 'Where can you provide this service?',
                isRequired: !_isRemote,
                onLocationSelected: (address, lat, lng) {
                  print('Service response location: $address at $lat, $lng');
                },
              ),
            ],
            const SizedBox(height: 32),

            // Update Button
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
                        'Update Service Response',
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
