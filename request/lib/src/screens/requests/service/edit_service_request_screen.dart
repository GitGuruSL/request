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

class EditServiceRequestScreen extends StatefulWidget {
  final RequestModel request;
  
  const EditServiceRequestScreen({
    super.key,
    required this.request,
  });

  @override
  State<EditServiceRequestScreen> createState() => _EditServiceRequestScreenState();
}

class _EditServiceRequestScreenState extends State<EditServiceRequestScreen> {
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
    
    // Initialize service-specific fields from metadata if available
    if (widget.request.metadata != null) {
      final metadata = widget.request.metadata!;
      if (metadata['preferredDate'] != null) {
        _preferredDate = metadata['preferredDate'] is DateTime 
          ? metadata['preferredDate']
          : DateTime.tryParse(metadata['preferredDate'].toString());
      }
      _timeSlot = metadata['timeSlot'] ?? 'Morning';
      _isRemote = metadata['isRemote'] ?? false;
      _requirementsController.text = metadata['requirements'] ?? '';
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
      initialDate: _preferredDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _preferredDate = picked;
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
          'preferredDate': _preferredDate,
          'timeSlot': _timeSlot,
          'isRemote': _isRemote,
          'requirements': _requirementsController.text.trim(),
        },
        'updatedAt': DateTime.now(),
      };

      await _requestService.updateRequest(widget.request.id, updatedData);

      if (mounted) {
        Navigator.of(context).pop(true); // Return true to indicate successful update
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service request updated successfully!'),
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
    _requirementsController.dispose();
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
        title: const Text('Edit Service Request'),
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
                labelText: 'Service Title',
                hintText: 'What service do you need?',
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
                        'Update Service Request',
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
