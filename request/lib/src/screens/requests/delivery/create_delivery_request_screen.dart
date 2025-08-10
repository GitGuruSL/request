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

class CreateDeliveryRequestScreen extends StatefulWidget {
  const CreateDeliveryRequestScreen({super.key});

  @override
  State<CreateDeliveryRequestScreen> createState() => _CreateDeliveryRequestScreenState();
}

class _CreateDeliveryRequestScreenState extends State<CreateDeliveryRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final EnhancedRequestService _requestService = EnhancedRequestService();
  final EnhancedUserService _userService = EnhancedUserService();

  // Form Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pickupLocationController = TextEditingController();
  final _deliveryLocationController = TextEditingController();
  final _budgetController = TextEditingController();
  
  // Delivery-specific fields
  String? _selectedCategoryId;
  String? _selectedSubCategoryId;
  String? _selectedCategory;
  String? _selectedSubcategory;
  String _packageSize = 'Small';
  DateTime? _pickupTime;
  DateTime? _deliveryTime;
  bool _isFragile = false;
  bool _requiresSignature = false;
  final _specialInstructionsController = TextEditingController();
  final _itemDescriptionController = TextEditingController();
  List<String> _imageUrls = [];

  bool _isLoading = false;

  final List<String> _packageSizes = [
    'Small',
    'Medium',
    'Large',
    'Extra Large',
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
          requestType: 'delivery',
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
    _pickupLocationController.dispose();
    _deliveryLocationController.dispose();
    _budgetController.dispose();
    _specialInstructionsController.dispose();
    _itemDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFAFF),
      appBar: AppBar(
        title: const Text('Create Delivery Request'),
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
                    Icon(Icons.local_shipping, color: Colors.purple[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delivery Request',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple[600],
                            ),
                          ),
                          const Text(
                            'Need something delivered? Find reliable couriers!',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Basic Information
              _buildSectionTitle('Delivery Details'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Delivery Title',
                  hintText: 'e.g., Documents to Office, Food Delivery',
                  filled: true,
                  fillColor: Colors.white,
                  border: InputBorder.none,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a delivery title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _itemDescriptionController,
                decoration: const InputDecoration(
                  labelText: 'What needs to be delivered?',
                  hintText: 'Describe the items to be delivered...',
                  filled: true,
                  fillColor: Colors.white,
                  border: InputBorder.none,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe what needs to be delivered';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Category Selection
              TextFormField(
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: 'Delivery Category',
                  hintText: 'Select a delivery category',
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
                    return 'Please select a delivery category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Images
              _buildSectionTitle('Images'),
              const SizedBox(height: 12),
              ImageUploadWidget(
                initialImages: _imageUrls,
                maxImages: 4,
                uploadPath: 'requests/deliveries',
                label: 'Upload item images (up to 4)',
                onImagesChanged: (images) {
                  setState(() {
                    _imageUrls = images;
                  });
                },
              ),
              const SizedBox(height: 24),
              LocationPickerWidget(
                controller: _pickupLocationController,
                labelText: 'Pickup Location',
                hintText: 'Where should the courier pick up from?',
                isRequired: true,
                onLocationSelected: (address, lat, lng) {
                  print('Pickup location selected: $address at $lat, $lng');
                },
              ),
              const SizedBox(height: 16),
              LocationPickerWidget(
                controller: _deliveryLocationController,
                labelText: 'Delivery Location',
                hintText: 'Where should it be delivered?',
                isRequired: true,
                onLocationSelected: (address, lat, lng) {
                  print('Delivery location selected: $address at $lat, $lng');
                },
              ),
              const SizedBox(height: 24),

              // Package Details
              _buildSectionTitle('Package Information'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _packageSize,
                decoration: const InputDecoration(
                  labelText: 'Package Size',
                  filled: true,
                  fillColor: Colors.white,
                  border: InputBorder.none,
                ),
                items: _packageSizes.map((size) {
                  return DropdownMenuItem(
                    value: size,
                    child: Text(size),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _packageSize = value!;
                  });
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
                      title: const Text('Fragile Items'),
                      subtitle: const Text('Handle with care'),
                      value: _isFragile,
                      onChanged: (value) {
                        setState(() {
                          _isFragile = value!;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      title: const Text('Signature Required'),
                      subtitle: const Text('Recipient must sign on delivery'),
                      value: _requiresSignature,
                      onChanged: (value) {
                        setState(() {
                          _requiresSignature = value!;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Timing
              _buildSectionTitle('Timing'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  title: Text(_pickupTime == null 
                    ? 'Preferred Pickup Time' 
                    : 'Pickup: ${_pickupTime!.day}/${_pickupTime!.month} at ${_pickupTime!.hour}:${_pickupTime!.minute.toString().padLeft(2, '0')}'),
                  trailing: const Icon(Icons.access_time),
                  onTap: () => _selectDateTime(isPickup: true),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  title: Text(_deliveryTime == null 
                    ? 'Preferred Delivery Time (Optional)' 
                    : 'Deliver by: ${_deliveryTime!.day}/${_deliveryTime!.month} at ${_deliveryTime!.hour}:${_deliveryTime!.minute.toString().padLeft(2, '0')}'),
                  trailing: const Icon(Icons.schedule),
                  onTap: () => _selectDateTime(isPickup: false),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _specialInstructionsController,
                decoration: const InputDecoration(
                  labelText: 'Special Instructions (Optional)',
                  hintText: 'Any special handling or delivery instructions...',
                  filled: true,
                  fillColor: Colors.white,
                  border: InputBorder.none,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Budget
              _buildSectionTitle('Budget'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _budgetController,
                decoration: const InputDecoration(
                  labelText: 'Delivery Fee (USD)',
                  hintText: '0.00',
                  prefixText: '\$ ',
                  filled: true,
                  fillColor: Colors.white,
                  border: InputBorder.none,
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRequest,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.purple[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Create Delivery Request',
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

  Future<void> _selectDateTime({required bool isPickup}) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      
      if (pickedTime != null) {
        final selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        
        setState(() {
          if (isPickup) {
            _pickupTime = selectedDateTime;
          } else {
            _deliveryTime = selectedDateTime;
          }
        });
      }
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_pickupTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select pickup time')),
      );
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
      String categoryName = 'Delivery'; // Default fallback
      
      // If we have selected categories, we'll store the IDs and let the backend handle names
      if (_selectedCategoryId != null) {
        categoryName = 'Package Delivery'; // Placeholder - backend will resolve
      }

      // Create the delivery-specific data
      final packageInfo = PackageInfo(
        description: _itemDescriptionController.text.trim(),
        weight: 1.0, // Default weight
        dimensions: PackageDimensions(
          length: 10.0,
          width: 10.0, 
          height: 10.0,
        ),
        category: categoryName,
      );

      final deliveryData = DeliveryRequestData(
        package: packageInfo,
        preferredPickupTime: _pickupTime!,
        preferredDeliveryTime: _deliveryTime ?? _pickupTime!.add(const Duration(hours: 24)),
        isFlexibleTime: _deliveryTime == null,
        requireSignature: _requiresSignature,
        isFragile: _isFragile,
        deliveryInstructions: _specialInstructionsController.text.trim().isEmpty 
            ? null 
            : _specialInstructionsController.text.trim(),
      );

      final requestId = await _requestService.createRequest(
        title: _titleController.text.trim(),
        description: '${_itemDescriptionController.text.trim()}\n${_descriptionController.text.trim()}',
        type: RequestType.delivery,
        budget: double.tryParse(_budgetController.text),
        currency: 'USD',
        typeSpecificData: deliveryData.toMap(),
        tags: [
          'delivery',
          _packageSize.toLowerCase().replaceAll(' ', '_'),
          if (_selectedCategoryId != null) 'category_${_selectedCategoryId!}',
          if (_selectedSubCategoryId != null) 'subcategory_${_selectedSubCategoryId!}',
        ],
        location: LocationInfo(
          latitude: 0.0,
          longitude: 0.0,
          address: _pickupLocationController.text.trim(),
        ),
        destinationLocation: LocationInfo(
          latitude: 0.0,
          longitude: 0.0,
          address: _deliveryLocationController.text.trim(),
        ),
        images: _imageUrls,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery request created successfully!'),
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
