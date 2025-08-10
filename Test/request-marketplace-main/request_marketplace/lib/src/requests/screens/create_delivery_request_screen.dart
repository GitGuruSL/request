import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:request_marketplace/src/models/request_model.dart';
import 'package:request_marketplace/src/models/user_model.dart';
import 'package:request_marketplace/src/services/request_service.dart';
import 'package:request_marketplace/src/services/phone_number_service.dart';
import 'package:request_marketplace/src/core/services/phone_verification_helper.dart' as phone_helper;
import 'package:request_marketplace/src/profile/screens/phone_number_management_screen.dart';
import '../../theme/app_theme.dart';

enum DeliveryType { pickup, delivery, both }
enum DeliveryUrgency { standard, express, sameDay, scheduled }
enum PackageSize { small, medium, large, extraLarge }

class CreateDeliveryRequestScreen extends StatefulWidget {
  const CreateDeliveryRequestScreen({super.key});

  @override
  State<CreateDeliveryRequestScreen> createState() => _CreateDeliveryRequestScreenState();
}

class _CreateDeliveryRequestScreenState extends State<CreateDeliveryRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _pickupLocationController = TextEditingController();
  final _deliveryLocationController = TextEditingController();
  final _packageDetailsController = TextEditingController();
  final _requestService = RequestService();
  final _imagePicker = ImagePicker();
  final _phoneService = PhoneNumberService();
  final Location _location = Location();
  final List<File> _selectedImages = [];
  final Set<String> _selectedPhoneNumbers = {};
  final List<PhoneNumber> _userPhoneNumbers = [];

  DeliveryType _deliveryType = DeliveryType.both;
  DeliveryUrgency _selectedUrgency = DeliveryUrgency.standard;
  PackageSize _selectedPackageSize = PackageSize.medium;
  DateTime? _scheduledTime;
  bool _isLoading = false;
  bool _requiresSpecialHandling = false;
  bool _isFragile = false;
  double? _estimatedWeight;

  @override
  void initState() {
    super.initState();
    _loadUserPhoneNumbers();
  }

  Future<void> _loadUserPhoneNumbers() async {
    try {
      final phoneNumbers = await _phoneService.getUserPhoneNumbers();
      if (mounted) {
        setState(() {
          _userPhoneNumbers.clear();
          _userPhoneNumbers.addAll(phoneNumbers);
        });
      }
    } catch (e) {
      debugPrint('Error loading phone numbers: $e');
    }
  }

  void _showLocationOptions(bool isPickup) {
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
                  _getCurrentLocation(isPickup);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit_location),
                title: const Text('Enter Location Manually'),
                onTap: () {
                  Navigator.pop(context);
                  _showLocationInputDialog(isPickup);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getCurrentLocation(bool isPickup) async {
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
            if (isPickup) {
              _pickupLocationController.text = address;
            } else {
              _deliveryLocationController.text = address;
            }
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

  void _showLocationInputDialog(bool isPickup) {
    final locationInputController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isPickup ? 'Enter Pickup Location' : 'Enter Delivery Location'),
          content: TextField(
            controller: locationInputController,
            decoration: InputDecoration(
              hintText: isPickup ? 'Enter pickup address' : 'Enter delivery address',
              border: const OutlineInputBorder(),
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
                  if (isPickup) {
                    _pickupLocationController.text = locationInputController.text;
                  } else {
                    _deliveryLocationController.text = locationInputController.text;
                  }
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

  Future<void> _selectScheduledTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _scheduledTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _submitRequest() async {
    // Check phone verification before proceeding
    final hasVerifiedPhone = await phone_helper.PhoneVerificationHelper.validatePhoneVerification(context);
    if (!hasVerifiedPhone) {
      return; // User cancelled or doesn't have verified phone
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String description = _descriptionController.text.trim();
      description += '\n\nDelivery Details:';
      description += '\n- Type: ${_deliveryType.name}';
      description += '\n- Urgency: ${_selectedUrgency.name}';
      description += '\n- Package Size: ${_selectedPackageSize.name}';
      if (_estimatedWeight != null) {
        description += '\n- Estimated Weight: ${_estimatedWeight!.toStringAsFixed(1)} kg';
      }
      description += '\n- Requires Special Handling: ${_requiresSpecialHandling ? 'Yes' : 'No'}';
      description += '\n- Fragile Item: ${_isFragile ? 'Yes' : 'No'}';
      
      if (_scheduledTime != null && _selectedUrgency == DeliveryUrgency.scheduled) {
        description += '\n- Scheduled Time: ${_scheduledTime.toString()}';
      }
      
      description += '\n\nLocations:';
      if (_pickupLocationController.text.isNotEmpty) {
        description += '\n- Pickup: ${_pickupLocationController.text}';
      }
      if (_deliveryLocationController.text.isNotEmpty) {
        description += '\n- Delivery: ${_deliveryLocationController.text}';
      }

      // For delivery requests, we'll use the pickup location as the main location
      final mainLocation = _pickupLocationController.text.isNotEmpty 
          ? _pickupLocationController.text 
          : _deliveryLocationController.text;

      await _requestService.createRequest(
        title: _titleController.text.trim(),
        description: description,
        type: RequestType.delivery,
        condition: ItemCondition.any.toString(), // Default for deliveries
        budget: double.tryParse(_budgetController.text.trim()) ?? 0.0,
        location: mainLocation,
        category: 'Delivery Service',
        subcategory: '',
        images: _selectedImages.map((file) => XFile(file.path)).toList(),
        additionalPhones: _selectedPhoneNumbers.toList(),
        deadline: _scheduledTime != null ? Timestamp.fromDate(_scheduledTime!) : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delivery request created successfully!')),
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    _pickupLocationController.dispose();
    _deliveryLocationController.dispose();
    _packageDetailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Request Delivery Service',
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
                  labelText: 'What needs to be delivered? *',
                  hintText: 'e.g., Documents, Food, Package, Furniture',
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(AppTheme.spacingMedium),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter what needs to be delivered';
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
                  hintText: 'Describe the items, special instructions, and requirements',
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(AppTheme.spacingMedium),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Delivery Type
              Text(
                'Delivery Type',
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
                  children: DeliveryType.values.map((type) {
                    return RadioListTile<DeliveryType>(
                      title: Text(_getDeliveryTypeDisplayName(type)),
                      subtitle: Text(_getDeliveryTypeDescription(type)),
                      value: type,
                      groupValue: _deliveryType,
                      onChanged: (value) {
                        setState(() {
                          _deliveryType = value!;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Pickup Location (if needed)
              if (_deliveryType == DeliveryType.pickup || _deliveryType == DeliveryType.both) ...[
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.my_location, color: Colors.green),
                    title: Text(
                      _pickupLocationController.text.isEmpty 
                          ? 'Set Pickup Location *' 
                          : _pickupLocationController.text,
                      style: AppTheme.bodyMedium.copyWith(
                        color: _pickupLocationController.text.isNotEmpty 
                            ? AppTheme.textPrimary 
                            : AppTheme.textSecondary,
                      ),
                    ),
                    trailing: Icon(Icons.edit_location, color: AppTheme.textSecondary),
                    onTap: () => _showLocationOptions(true),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Delivery Location (if needed)
              if (_deliveryType == DeliveryType.delivery || _deliveryType == DeliveryType.both) ...[
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.red),
                    title: Text(
                      _deliveryLocationController.text.isEmpty 
                          ? 'Set Delivery Location *' 
                          : _deliveryLocationController.text,
                      style: AppTheme.bodyMedium.copyWith(
                        color: _deliveryLocationController.text.isNotEmpty 
                            ? AppTheme.textPrimary 
                            : AppTheme.textSecondary,
                      ),
                    ),
                    trailing: Icon(Icons.edit_location, color: AppTheme.textSecondary),
                    onTap: () => _showLocationOptions(false),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Package Details
              Text(
                'Package Details',
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Package Size
                    Text(
                      'Package Size',
                      style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: PackageSize.values.map((size) {
                        final isSelected = _selectedPackageSize == size;
                        return FilterChip(
                          label: Text(_getPackageSizeDisplayName(size)),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _selectedPackageSize = size;
                              });
                            }
                          },
                          selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                          checkmarkColor: AppTheme.primaryColor,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Estimated Weight
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Estimated Weight (kg)',
                        hintText: 'Enter approximate weight',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          _estimatedWeight = double.tryParse(value);
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Special Handling Options
                    CheckboxListTile(
                      title: const Text('Fragile Item'),
                      subtitle: const Text('Item requires careful handling'),
                      value: _isFragile,
                      onChanged: (value) {
                        setState(() {
                          _isFragile = value ?? false;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                    CheckboxListTile(
                      title: const Text('Special Handling Required'),
                      subtitle: const Text('Item needs extra care or specific handling'),
                      value: _requiresSpecialHandling,
                      onChanged: (value) {
                        setState(() {
                          _requiresSpecialHandling = value ?? false;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Delivery Urgency
              Text(
                'Delivery Urgency',
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
                  children: DeliveryUrgency.values.map((urgency) {
                    return RadioListTile<DeliveryUrgency>(
                      title: Text(_getUrgencyDisplayName(urgency)),
                      subtitle: Text(_getUrgencyDescription(urgency)),
                      value: urgency,
                      groupValue: _selectedUrgency,
                      onChanged: (value) {
                        setState(() {
                          _selectedUrgency = value!;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Scheduled Time (if scheduled delivery)
              if (_selectedUrgency == DeliveryUrgency.scheduled) ...[
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  ),
                  child: ListTile(
                    title: Text(
                      _scheduledTime == null
                          ? 'Select Scheduled Time *'
                          : 'Scheduled: ${_scheduledTime.toString().split('.')[0]}',
                      style: AppTheme.bodyMedium.copyWith(
                        color: _scheduledTime == null ? AppTheme.textSecondary : AppTheme.textPrimary,
                      ),
                    ),
                    trailing: Icon(Icons.schedule, color: AppTheme.textSecondary),
                    onTap: _selectScheduledTime,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Budget
              TextFormField(
                controller: _budgetController,
                decoration: InputDecoration(
                  labelText: 'Budget *',
                  hintText: 'Enter your delivery budget',
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
                            'Add Package Photos',
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
              if (_userPhoneNumbers.isEmpty)
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
                          'Add and verify phone numbers to share with delivery providers.',
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
                            _loadUserPhoneNumbers();
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
                )
              else
                Column(
                  children: _userPhoneNumbers.map<Widget>((phone) {
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                      ),
                      child: CheckboxListTile(
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                phone.number,
                                style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
                              ),
                            ),
                            if (phone.isVerified) ...[
                              Icon(Icons.verified, color: AppTheme.successColor, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                'Verified',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.successColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: phone.isPrimary 
                            ? Text(
                                'Primary', 
                                style: AppTheme.bodySmall.copyWith(color: AppTheme.primaryColor),
                              )
                            : null,
                        value: _selectedPhoneNumbers.contains(phone.number),
                        onChanged: phone.isVerified ? (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedPhoneNumbers.add(phone.number);
                            } else {
                              _selectedPhoneNumbers.remove(phone.number);
                            }
                          });
                        } : null,
                      ),
                    );
                  }).toList(),
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
                      : const Text('Submit Delivery Request'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  String _getDeliveryTypeDisplayName(DeliveryType type) {
    switch (type) {
      case DeliveryType.pickup:
        return 'Pickup Only';
      case DeliveryType.delivery:
        return 'Delivery Only';
      case DeliveryType.both:
        return 'Pickup & Delivery';
    }
  }

  String _getDeliveryTypeDescription(DeliveryType type) {
    switch (type) {
      case DeliveryType.pickup:
        return 'I need someone to collect items from a location';
      case DeliveryType.delivery:
        return 'I need something delivered to a location';
      case DeliveryType.both:
        return 'I need items picked up and delivered';
    }
  }

  String _getPackageSizeDisplayName(PackageSize size) {
    switch (size) {
      case PackageSize.small:
        return 'Small';
      case PackageSize.medium:
        return 'Medium';
      case PackageSize.large:
        return 'Large';
      case PackageSize.extraLarge:
        return 'Extra Large';
    }
  }

  String _getUrgencyDisplayName(DeliveryUrgency urgency) {
    switch (urgency) {
      case DeliveryUrgency.standard:
        return 'Standard (24-48 hours)';
      case DeliveryUrgency.express:
        return 'Express (2-6 hours)';
      case DeliveryUrgency.sameDay:
        return 'Same Day (Within today)';
      case DeliveryUrgency.scheduled:
        return 'Scheduled Time';
    }
  }

  String _getUrgencyDescription(DeliveryUrgency urgency) {
    switch (urgency) {
      case DeliveryUrgency.standard:
        return 'Regular delivery within 1-2 days';
      case DeliveryUrgency.express:
        return 'Fast delivery within a few hours';
      case DeliveryUrgency.sameDay:
        return 'Must be delivered today';
      case DeliveryUrgency.scheduled:
        return 'Specific date and time required';
    }
  }
}
