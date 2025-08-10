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

class CreateServiceResponseScreen extends StatefulWidget {
  final RequestModel request;
  
  const CreateServiceResponseScreen({
    super.key,
    required this.request,
  });

  @override
  State<CreateServiceResponseScreen> createState() => _CreateServiceResponseScreenState();
}

class _CreateServiceResponseScreenState extends State<CreateServiceResponseScreen> {
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
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _availableDate = picked;
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
        'experience': _experienceController.text.trim(),
        'availability': _availabilityController.text.trim(),
        'availableDate': _availableDate,
        'serviceType': _serviceType,
        'isRemote': _isRemote,
        'category': _selectedCategory ?? widget.request.category,
        'categoryId': _selectedCategoryId ?? widget.request.categoryId,
        'subcategory': _selectedSubcategory ?? widget.request.subcategory,
        'subcategoryId': _selectedSubCategoryId ?? widget.request.subcategoryId,
        'images': _imageUrls,
        'status': 'pending',
        'createdAt': DateTime.now(),
        'type': 'service',
      };

      await _requestService.createResponse(responseData);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service response submitted successfully!'),
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
        title: const Text('Respond to Service Request'),
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

            // Category Selection (if different from request)
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
                  : _selectedCategory ?? (widget.request.category ?? ''),
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
                        'Submit Service Response',
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
