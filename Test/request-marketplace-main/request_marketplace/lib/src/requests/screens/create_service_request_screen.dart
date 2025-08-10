import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:request_marketplace/src/models/category_data.dart';
import 'package:request_marketplace/src/models/request_model.dart';
import 'package:request_marketplace/src/services/request_service.dart';
import 'package:request_marketplace/src/core/services/phone_verification_helper.dart';
import 'package:request_marketplace/src/profile/screens/phone_number_management_screen.dart';
import 'package:request_marketplace/src/requests/widgets/category_picker.dart';
import '../../theme/app_theme.dart';

enum ServiceUrgency { low, medium, high, urgent }

class CreateServiceRequestScreen extends StatefulWidget {
  const CreateServiceRequestScreen({super.key});

  @override
  State<CreateServiceRequestScreen> createState() => _CreateServiceRequestScreenState();
}

class _CreateServiceRequestScreenState extends State<CreateServiceRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _locationController = TextEditingController();
  final _categoryController = TextEditingController();
  final _durationController = TextEditingController();
  final _requestService = RequestService();
  final _imagePicker = ImagePicker();
  final Location _location = Location();
  final List<File> _selectedImages = [];

  String? _selectedCategory;
  String? _selectedSubcategory;
  ServiceUrgency _selectedUrgency = ServiceUrgency.medium;
  DateTime? _preferredDate;
  TimeOfDay? _preferredTime;
  DateTime? _deadline;
  bool _isLoading = false;
  bool _isFlexibleTiming = false;
  bool _isRemoteService = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickImages() async {
    if (_selectedImages.length >= 4) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 4 images allowed')),
      );
      return;
    }

    final pickedFiles = await _imagePicker.pickMultiImage(imageQuality: 80);
    if (pickedFiles.isNotEmpty) {
      setState(() {
        final remainingSlots = 4 - _selectedImages.length;
        final imagesToAdd = pickedFiles.take(remainingSlots);
        _selectedImages.addAll(imagesToAdd.map((xFile) => File(xFile.path)));
      });
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

    if (result != null &&
        result.containsKey('category')) {
      setState(() {
        _selectedCategory = result['category'];
        _selectedSubcategory = result['subcategory']; // Can be null for main categories
        if (_selectedCategory != null) {
          if (_selectedSubcategory != null) {
            _categoryController.text = '$_selectedCategory > $_selectedSubcategory';
          } else {
            _categoryController.text = _selectedCategory!;
          }
        }
      });
    }
  }

  void _showLocationOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.my_location),
                title: const Text('Use Current Location'),
                onTap: () {
                  Navigator.pop(context);
                  _getCurrentLocation();
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_location),
                title: const Text('Enter Location Manually'),
                onTap: () {
                  Navigator.pop(context);
                  _showLocationInputDialog();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) return;
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) return;
      }

      LocationData locationData = await _location.getLocation();
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
        locationData.latitude!,
        locationData.longitude!,
      );

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks[0];
        final locationText = '${place.name}, ${place.locality}, ${place.administrativeArea}';
        setState(() {
          _locationController.text = locationText;
        });
      }
    } catch (e) {
      print('Error getting location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location: $e')),
        );
      }
    }
  }

  void _showLocationInputDialog() {
    final locationInputController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Location'),
          content: TextField(
            controller: locationInputController,
            decoration: const InputDecoration(
              hintText: 'Enter service location',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _locationController.text = locationInputController.text;
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectPreferredDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _preferredDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      setState(() {
        _preferredDate = selectedDate;
      });
    }
  }

  Future<void> _selectPreferredTime() async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: _preferredTime ?? TimeOfDay.now(),
    );

    if (selectedTime != null) {
      setState(() {
        _preferredTime = selectedTime;
      });
    }
  }

  Future<void> _selectDeadline() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (selectedDate != null) {
      final selectedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (selectedTime != null) {
        setState(() {
          _deadline = DateTime(
            selectedDate.year,
            selectedDate.month,
            selectedDate.day,
            selectedTime.hour,
            selectedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _submitRequest() async {
    // Check phone verification before proceeding
    final hasVerifiedPhone = await PhoneVerificationHelper.validatePhoneVerification(context);
    if (!hasVerifiedPhone) {
      return; // User cancelled or doesn't have verified phone
    }

    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedCategory == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service category')),
      );
      return;
    }

    if (_selectedSubcategory == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service subcategory')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _requestService.createRequest(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: RequestType.service,
        condition: _selectedUrgency.name, // Using urgency as condition for services
        budget: double.tryParse(_budgetController.text.trim()) ?? 0.0,
        location: _locationController.text.trim(),
        category: _selectedCategory!,
        subcategory: _selectedSubcategory!,
        deadline: _deadline != null ? Timestamp.fromDate(_deadline!) : null,
        images: _selectedImages.map((file) => XFile(file.path)).toList(),
      ).timeout(const Duration(seconds: 30));
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Service request created successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating request: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getUrgencyText(ServiceUrgency urgency) {
    switch (urgency) {
      case ServiceUrgency.low:
        return 'Low - No rush';
      case ServiceUrgency.medium:
        return 'Medium - Within a week';
      case ServiceUrgency.high:
        return 'High - Within 2-3 days';
      case ServiceUrgency.urgent:
        return 'Urgent - ASAP';
    }
  }

  Color _getUrgencyColor(ServiceUrgency urgency) {
    switch (urgency) {
      case ServiceUrgency.low:
        return Colors.green;
      case ServiceUrgency.medium:
        return Colors.orange;
      case ServiceUrgency.high:
        return Colors.deepOrange;
      case ServiceUrgency.urgent:
        return Colors.red;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _locationController.dispose();
    _categoryController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Create Service Request',
          style: AppTheme.headingMedium.copyWith(
            color: AppTheme.textPrimary,
          ),
        ),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Request Details Header
              Text(
                'Service Details',
                style: AppTheme.headingSmall.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              
              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Service Title *',
                  hintText: 'What service do you need?',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(AppTheme.spacingMedium),
                  labelStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                  hintStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.textTertiary),
                ),
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a service title';
                  }
                  if (value.trim().length < 3) {
                    return 'Title must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category
              TextFormField(
                controller: _categoryController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: 'Service Category *',
                  hintText: 'Select a service category',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(AppTheme.spacingMedium),
                  labelStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                  hintStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.textTertiary),
                  suffixIcon: Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                ),
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
                onTap: _showCategoryPicker,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a service category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Service Urgency
              Text(
                'Service Urgency',
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMedium),
                  child: Column(
                    children: ServiceUrgency.values.map((urgency) {
                      return RadioListTile<ServiceUrgency>(
                        contentPadding: EdgeInsets.zero,
                        title: Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: _getUrgencyColor(urgency),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _getUrgencyText(urgency),
                                style: AppTheme.bodyMedium.copyWith(
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        value: urgency,
                        groupValue: _selectedUrgency,
                        onChanged: (value) {
                          setState(() {
                            _selectedUrgency = value!;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Service Description *',
                  hintText: 'Describe the service you need in detail...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(AppTheme.spacingMedium),
                  labelStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                  hintStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.textTertiary),
                ),
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a service description';
                  }
                  if (value.trim().length < 10) {
                    return 'Description must be at least 10 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Budget
              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Budget',
                  hintText: 'Maximum amount you\'re willing to pay',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(AppTheme.spacingMedium),
                  labelStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                  hintStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.textTertiary),
                  prefixText: 'LKR ',
                  prefixStyle: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
                ),
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a budget';
                  }
                  final budget = double.tryParse(value.trim());
                  if (budget == null || budget <= 0) {
                    return 'Please enter a valid budget amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Location
              Text(
                'Service Location',
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              
              // Remote Service Toggle
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMedium),
                  child: Row(
                    children: [
                      Icon(Icons.computer, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Remote Service',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Switch(
                        value: _isRemoteService,
                        onChanged: (value) {
                          setState(() {
                            _isRemoteService = value;
                            if (value) {
                              _locationController.text = 'Remote/Online Service';
                            } else {
                              _locationController.clear();
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              if (!_isRemoteService) ...[
                Card(
                  child: ListTile(
                    title: Text(
                      _locationController.text.isEmpty ? 'Select Service Location' : _locationController.text,
                      style: TextStyle(
                        color: _locationController.text.isNotEmpty ? Colors.black : Colors.grey[600],
                      ),
                    ),
                    subtitle: _locationController.text.isNotEmpty 
                        ? Text(
                            'Tap to change location',
                            style: TextStyle(color: Colors.grey[500]),
                          )
                        : null,
                    trailing: const Icon(Icons.location_on),
                    onTap: _showLocationOptions,
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                const SizedBox(height: 16),
              ],

              // Service Duration (Optional)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextFormField(
                    controller: _durationController,
                    decoration: const InputDecoration(
                      labelText: 'Expected Duration (Optional)',
                      hintText: 'e.g., 2 hours, Half day, 3 days',
                      border: InputBorder.none,
                      filled: false,
                      prefixIcon: Icon(Icons.schedule),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Timing Preferences
              Text(
                'Timing Preferences',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              
              // Flexible Timing Toggle
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.schedule_outlined, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Flexible Timing',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Switch(
                        value: _isFlexibleTiming,
                        onChanged: (value) {
                          setState(() {
                            _isFlexibleTiming = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              if (!_isFlexibleTiming) ...[
                // Preferred Date and Time
                Row(
                  children: [
                    Expanded(
                      child: Card(
                        child: ListTile(
                          title: Text(
                            _preferredDate == null
                                ? 'Preferred Date'
                                : '${_preferredDate!.toLocal()}'.split(' ')[0],
                          ),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: _selectPreferredDate,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Card(
                        child: ListTile(
                          title: Text(
                            _preferredTime == null
                                ? 'Preferred Time'
                                : _preferredTime!.format(context),
                          ),
                          trailing: const Icon(Icons.access_time),
                          onTap: _selectPreferredTime,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),

              // Images Section
              Text(
                'Reference Images (Optional)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add images to help explain what you need',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      if (_selectedImages.isNotEmpty) ...[
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                          itemCount: _selectedImages.length + (_selectedImages.length < 4 ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index < _selectedImages.length) {
                              return Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: FileImage(_selectedImages[index]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedImages.removeAt(index);
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                              return GestureDetector(
                                onTap: _pickImages,
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate_outlined,
                                        size: 30,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Add More',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ] else ...[
                        GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            width: double.infinity,
                            height: 120,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 48,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add Reference Images',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Max 4 images',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Contact Information
              Text(
                'Contact Information',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              // Phone Verification Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Phone Number Sharing',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your verified phone numbers from your profile will be automatically shared with service providers. Go to Settings > Profile to manage your phone numbers.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Deadline
              Text(
                'Deadline (Optional)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  title: Text(
                    _deadline == null
                        ? 'Set Service Deadline'
                        : '${'${_deadline!.toLocal()}'.split(' ')[0]} at ${TimeOfDay.fromDateTime(_deadline!).format(context)}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _selectDeadline,
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRequest,
                  style: AppTheme.primaryButtonStyle,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Submit Service Request'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
