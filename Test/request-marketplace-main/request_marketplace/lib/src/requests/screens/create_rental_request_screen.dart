import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:request_marketplace/src/models/request_model.dart';
import 'package:request_marketplace/src/services/request_service.dart';
import 'package:request_marketplace/src/core/services/phone_verification_helper.dart';
import 'package:request_marketplace/src/profile/screens/phone_number_management_screen.dart';
import '../../theme/app_theme.dart';

enum RentalDuration { hourly, daily, weekly, monthly, custom }

// Predefined rental items that can be managed from admin portal
const List<String> RENTAL_ITEMS = [
  'Car/Vehicle',
  'Motorcycle',
  'Bicycle',
  'Van/Truck',
  'Construction Equipment',
  'Power Tools',
  'Garden Equipment',
  'Party Equipment',
  'Sound System',
  'Camera Equipment',
  'Laptop/Computer',
  'Projector',
  'Furniture',
  'Office Space',
  'Event Venue',
  'Storage Space',
  'Other Equipment',
];

class CreateRentalRequestScreen extends StatefulWidget {
  const CreateRentalRequestScreen({super.key});

  @override
  State<CreateRentalRequestScreen> createState() => _CreateRentalRequestScreenState();
}

class _CreateRentalRequestScreenState extends State<CreateRentalRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _locationController = TextEditingController();
  final _requestService = RequestService();
  final _imagePicker = ImagePicker();
  final Location _location = Location();
  final List<File> _selectedImages = [];
  final Set<String> _selectedPhoneNumbers = {};

  String? _selectedRentalItem;
  RentalDuration _selectedDuration = RentalDuration.daily;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = false;
  bool _needsVehicleDelivery = false;

  @override
  void initState() {
    super.initState();
  }

  void _showRentalItemPicker() async {
    final selectedItem = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'What do you want to rent?',
                      style: AppTheme.headingMedium.copyWith(color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: RENTAL_ITEMS.length,
                itemBuilder: (context, index) {
                  final item = RENTAL_ITEMS[index];
                  return ListTile(
                    title: Text(item),
                    trailing: _selectedRentalItem == item 
                        ? Icon(Icons.check, color: AppTheme.primaryColor)
                        : null,
                    onTap: () {
                      Navigator.pop(context, item);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (selectedItem != null) {
      setState(() {
        _selectedRentalItem = selectedItem;
        _titleController.text = 'Looking for $selectedItem to rent';
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

      final locationData = await _location.getLocation();
      if (locationData.latitude != null && locationData.longitude != null) {
        final placemarks = await geo.placemarkFromCoordinates(
          locationData.latitude!,
          locationData.longitude!,
        );

        if (placemarks.isNotEmpty && mounted) {
          final place = placemarks[0];
          final address = '${place.name ?? place.locality ?? 'Current Location'}, ${place.locality ?? place.administrativeArea ?? ''}';
          setState(() {
            _locationController.text = address;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  void _showLocationInputDialog() {
    final locationInputController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Location'),
          content: TextField(
            controller: locationInputController,
            decoration: const InputDecoration(
              hintText: 'Enter rental location',
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

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(limit: 5);
      setState(() {
        _selectedImages.clear();
        _selectedImages.addAll(images.map((image) => File(image.path)));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e')),
        );
      }
    }
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _submitRequest() async {
    // Check phone verification before proceeding
    final hasVerifiedPhone = await PhoneVerificationHelper.validatePhoneVerification(context);
    if (!hasVerifiedPhone) {
      return; // User cancelled or doesn't have verified phone
    }

    if (!_formKey.currentState!.validate()) return;

    if (_selectedRentalItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select what you want to rent')),
      );
      return;
    }

    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select rental period')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String description = _descriptionController.text.trim();
      description += '\n\nRental Details:';
      description += '\n- Item: $_selectedRentalItem';
      description += '\n- Duration: ${_selectedDuration.name}';
      description += '\n- Start Date: ${_startDate?.toString().split(' ')[0]}';
      description += '\n- End Date: ${_endDate?.toString().split(' ')[0]}';
      description += '\n- Vehicle Delivery Required: ${_needsVehicleDelivery ? 'Yes' : 'No'}';
      description += '\n\nNote: Responders will specify their deposit requirements in their offers.';

      await _requestService.createRequest(
        title: _titleController.text.trim(),
        description: description,
        type: RequestType.rental,
        condition: ItemCondition.any.toString(), // Default for rentals
        budget: double.tryParse(_budgetController.text.trim()) ?? 0.0,
        location: _locationController.text.trim(),
        category: _selectedRentalItem!,
        subcategory: _selectedDuration.name,
        images: _selectedImages.map((file) => XFile(file.path)).toList(),
        // additionalPhones: [], // Removed complex phone management
        deadline: _endDate != null ? Timestamp.fromDate(_endDate!) : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rental request created successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating request: $e')),
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

  String _getDurationText() {
    if (_startDate == null || _endDate == null) {
      return 'Select rental period';
    }
    
    final days = _endDate!.difference(_startDate!).inDays + 1;
    if (days == 1) {
      return '${_startDate!.toString().split(' ')[0]} (1 day)';
    } else if (days <= 7) {
      return '${_startDate!.toString().split(' ')[0]} - ${_endDate!.toString().split(' ')[0]} ($days days)';
    } else if (days <= 30) {
      final weeks = (days / 7).ceil();
      return '${_startDate!.toString().split(' ')[0]} - ${_endDate!.toString().split(' ')[0]} (~$weeks weeks)';
    } else {
      final months = (days / 30).ceil();
      return '${_startDate!.toString().split(' ')[0]} - ${_endDate!.toString().split(' ')[0]} (~$months months)';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Request Rental Service',
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
              // Title
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'What do you want to rent? *',
                  hintText: 'e.g., Car for weekend, Camera equipment, Tools',
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(AppTheme.spacingMedium),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter what you want to rent';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description *',
                  hintText: 'Describe your rental requirements, specifications, and intended use',
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(AppTheme.spacingMedium),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // What to Rent
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                child: ListTile(
                  title: Text(
                    _selectedRentalItem ?? 'What do you want to rent? *',
                    style: AppTheme.bodyMedium.copyWith(
                      color: _selectedRentalItem != null ? AppTheme.textPrimary : AppTheme.textSecondary,
                    ),
                  ),
                  trailing: Icon(Icons.keyboard_arrow_down, color: AppTheme.textSecondary),
                  onTap: _showRentalItemPicker,
                ),
              ),
              const SizedBox(height: 16),

              // Budget
              TextFormField(
                controller: _budgetController,
                decoration: InputDecoration(
                  labelText: 'Budget *',
                  hintText: 'Enter your rental budget',
                  prefixText: 'LKR ',
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(AppTheme.spacingMedium),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your budget';
                  }
                  final budget = double.tryParse(value.trim());
                  if (budget == null || budget <= 0) {
                    return 'Please enter a valid budget amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Duration Selection
              Text(
                'Rental Duration',
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                child: Column(
                  children: RentalDuration.values.map((duration) {
                    return RadioListTile<RentalDuration>(
                      title: Text(_getDurationDisplayName(duration)),
                      subtitle: Text(_getDurationDescription(duration)),
                      value: duration,
                      groupValue: _selectedDuration,
                      onChanged: (value) {
                        setState(() {
                          _selectedDuration = value!;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Date Range Selection
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                child: ListTile(
                  title: Text(
                    _getDurationText(),
                    style: AppTheme.bodyMedium.copyWith(
                      color: _startDate == null ? AppTheme.textSecondary : AppTheme.textPrimary,
                    ),
                  ),
                  trailing: Icon(Icons.calendar_today, color: AppTheme.textSecondary),
                  onTap: _selectDateRange,
                ),
              ),
              const SizedBox(height: 16),

              // Location
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                child: ListTile(
                  title: Text(
                    _locationController.text.isEmpty ? 'Select Location' : _locationController.text,
                    style: AppTheme.bodyMedium.copyWith(
                      color: _locationController.text.isNotEmpty ? AppTheme.textPrimary : AppTheme.textSecondary,
                    ),
                  ),
                  trailing: Icon(Icons.location_on, color: AppTheme.textSecondary),
                  onTap: _showLocationOptions,
                ),
              ),
              const SizedBox(height: 16),

              // Additional Options
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Additional Options',
                        style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      
                      // Vehicle Delivery Option
                      CheckboxListTile(
                        title: const Text('Vehicle Delivery Required'),
                        subtitle: const Text('Need the vehicle delivered to your location'),
                        value: _needsVehicleDelivery,
                        onChanged: (value) {
                          setState(() {
                            _needsVehicleDelivery = value ?? false;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Images
              if (_selectedImages.isEmpty) ...[
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                  ),
                  child: InkWell(
                    onTap: _pickImages,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate,
                            size: 40,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add Photos',
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Up to 5 images',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length + 1,
                    itemBuilder: (context, index) {
                      if (index < _selectedImages.length) {
                        return Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 8),
                          child: Stack(
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
                          ),
                        );
                      } else if (_selectedImages.length < 5) {
                        return Container(
                          width: 120,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: InkWell(
                            onTap: _pickImages,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add,
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
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Phone Numbers
              Text(
                'Share Contact Information',
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              if (false) // Removed complex phone management
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingMedium),
                    child: Column(
                      children: [
                        Icon(Icons.phone_disabled, size: 48, color: AppTheme.textSecondary),
                        const SizedBox(height: 8),
                        Text(
                          'No verified phone numbers',
                          style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add and verify phone numbers to share with rental providers.',
                          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PhoneNumberManagementScreen(),
                              ),
                            );
                            // Removed complex phone management
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add Phone Number'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
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
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: AppTheme.backgroundColor,
                            strokeWidth: 3,
                          ),
                        )
                      : const Text('Submit Rental Request'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  String _getDurationDisplayName(RentalDuration duration) {
    switch (duration) {
      case RentalDuration.hourly:
        return 'Hourly';
      case RentalDuration.daily:
        return 'Daily';
      case RentalDuration.weekly:
        return 'Weekly';
      case RentalDuration.monthly:
        return 'Monthly';
      case RentalDuration.custom:
        return 'Custom Duration';
    }
  }

  String _getDurationDescription(RentalDuration duration) {
    switch (duration) {
      case RentalDuration.hourly:
        return 'For short-term rentals (few hours)';
      case RentalDuration.daily:
        return 'For 1-7 days';
      case RentalDuration.weekly:
        return 'For 1-4 weeks';
      case RentalDuration.monthly:
        return 'For 1+ months';
      case RentalDuration.custom:
        return 'Specify your own duration';
    }
  }
}
