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

class CreateServiceRequestScreen extends StatefulWidget {
  const CreateServiceRequestScreen({super.key});

  @override
  State<CreateServiceRequestScreen> createState() => _CreateServiceRequestScreenState();
}

class _CreateServiceRequestScreenState extends State<CreateServiceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final EnhancedRequestService _requestService = EnhancedRequestService();
  final EnhancedUserService _userService = EnhancedUserService();

  // Form Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController();
  
  // Service-specific fields
  String? _selectedCategoryId;
  String? _selectedSubCategoryId;
  String? _selectedCategory;
  String? _selectedSubcategory;
  DateTime? _preferredDate;
  String _timeSlot = 'Morning';
  bool _isRemote = false;
  final _requirementsController = TextEditingController();
  List<String> _imageUrls = [];

  bool _isLoading = false;

  final List<String> _timeSlots = [
    'Morning',
    'Afternoon',
    'Evening',
    'Flexible',
  ];

  @override
  void initState() {
    super.initState();
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
        _selectedSubcategory = result['subcategory']; // Can be null for main categories
        _selectedCategoryId = _selectedCategory; // Set ID same as name for now
        _selectedSubCategoryId = _selectedSubcategory; // Set ID same as name for now
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFAFF),
      appBar: AppBar(
        title: const Text('Create Service Request'),
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
                    Icon(Icons.build, color: Colors.green[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Service Request',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[600],
                            ),
                          ),
                          const Text(
                            'Need professional help? Find the right service provider!',
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
                decoration: InputDecoration(
                  labelText: 'What service do you need?',
                  hintText: 'e.g., Home Cleaning, Web Design, Tutoring',
                  filled: true,
                  fillColor: Colors.white,
                  border: InputBorder.none,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter the service you need';
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

              // Service Details
              _buildSectionTitle('Service Details'),
              const SizedBox(height: 12),
              
              // Category Selection
              TextFormField(
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Service Category',
                  hintText: 'Select a service category',
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
                    return 'Please select a service category';
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
                  title: Text(_preferredDate == null 
                    ? 'Select Preferred Date' 
                    : 'Date: ${_preferredDate!.day}/${_preferredDate!.month}/${_preferredDate!.year}'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _selectDate,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _timeSlot,
                decoration: InputDecoration(
                  labelText: 'Preferred Time',
                  filled: true,
                  fillColor: Colors.white,
                  border: InputBorder.none,
                ),
                items: _timeSlots.map((time) {
                  return DropdownMenuItem(
                    value: time,
                    child: Text(time),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _timeSlot = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _requirementsController,
                decoration: InputDecoration(
                  labelText: 'Special Requirements (Optional)',
                  hintText: 'Any specific requirements or preferences...',
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
                uploadPath: 'requests/services',
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
                  title: const Text('Remote Service'),
                  subtitle: const Text('This service can be provided remotely'),
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
                  hintText: 'Where should the service be provided?',
                  isRequired: !_isRemote,
                  onLocationSelected: (address, lat, lng) {
                    print('Service location selected: $address at $lat, $lng');
                  },
                ),
              ],
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRequest,
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
                          'Create Service Request',
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _preferredDate = picked;
      });
    }
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

      // Get category info
      String categoryName = 'Service'; // Default fallback
      
      // If we have selected categories, we'll store the IDs and let the backend handle names
      if (_selectedCategoryId != null) {
        categoryName = 'Selected Service Category'; // Placeholder - backend will resolve
      }

      // Create the service-specific data
      final serviceData = ServiceRequestData(
        serviceType: categoryName,
        preferredTime: _preferredDate,
        estimatedDuration: 1, // Default 1 hour
        isRecurring: false,
        requirements: {
          'timeSlot': _timeSlot,
          'specialRequirements': _requirementsController.text.trim(),
          'isRemote': _isRemote.toString(),
          'categoryId': _selectedCategoryId ?? '',
          'subCategoryId': _selectedSubCategoryId ?? '',
        },
      );

      final requestId = await _requestService.createRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: RequestType.service,
        budget: double.tryParse(_budgetController.text),
        currency: CurrencyHelper.instance.getCurrency(),
        typeSpecificData: serviceData.toMap(),
        tags: [
          'service',
          if (_selectedCategoryId != null) 'category_${_selectedCategoryId!}',
          if (_selectedSubCategoryId != null) 'subcategory_${_selectedSubCategoryId!}',
        ],
        location: _isRemote ? null : LocationInfo(
          latitude: 0.0,
          longitude: 0.0,
          address: _locationController.text.trim(),
        ),
        images: _imageUrls,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service request created successfully!'),
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
