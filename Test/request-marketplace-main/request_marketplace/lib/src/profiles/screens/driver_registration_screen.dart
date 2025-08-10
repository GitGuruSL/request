import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/enhanced_user_model.dart';
import '../../services/user_profile_service.dart';
import '../../models/driver_model.dart';

class DriverRegistrationScreen extends StatefulWidget {
  final String userId;
  
  const DriverRegistrationScreen({
    super.key,
    required this.userId,
  });

  @override
  State<DriverRegistrationScreen> createState() => _DriverRegistrationScreenState();
}

class _DriverRegistrationScreenState extends State<DriverRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _licenseNumberController = TextEditingController();
  final _vehicleMakeController = TextEditingController();
  final _vehicleModelController = TextEditingController();
  final _vehicleYearController = TextEditingController();
  final _vehiclePlateController = TextEditingController();
  final _insuranceNumberController = TextEditingController();
  final _userProfileService = UserProfileService();
  final Location _location = Location();
  final _imagePicker = ImagePicker();

  final List<VehicleType> _selectedVehicleTypes = [];
  final List<File> _vehicleImages = [];
  final Map<String, String> _availability = {
    'Monday': 'Available',
    'Tuesday': 'Available',
    'Wednesday': 'Available',
    'Thursday': 'Available',
    'Friday': 'Available',
    'Saturday': 'Available',
    'Sunday': 'Available',
  };
  
  double _operatingRadius = 25.0; // km
  double _latitude = 0.0;
  double _longitude = 0.0;
  bool _isLoading = false;
  bool _hasLicense = false;
  bool _hasInsurance = false;
  bool _hasVehicleDocuments = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Registration'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE65100), Color(0xFFFF9800)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.directions_car, color: Colors.white, size: 32),
                    SizedBox(height: 16),
                    Text(
                      'Become a Driver',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Register as a driver to provide rides, deliveries, and transportation services in your area.',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Driver License Information
              const Text(
                'Driver Information',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // License Number
              TextFormField(
                controller: _licenseNumberController,
                decoration: const InputDecoration(
                  labelText: 'Driver License Number *',
                  hintText: 'Enter your license number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.credit_card),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your license number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Vehicle Types
              const Text(
                'Vehicle Types',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select the types of vehicles you can drive',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 16),
              
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: VehicleType.values.map((type) {
                  final isSelected = _selectedVehicleTypes.contains(type);
                  return ChoiceChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getVehicleTypeIcon(type),
                          size: 18,
                          color: isSelected ? Colors.white : null,
                        ),
                        const SizedBox(width: 8),
                        Text(_getVehicleTypeDisplayName(type)),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedVehicleTypes.add(type);
                        } else {
                          _selectedVehicleTypes.remove(type);
                        }
                      });
                    },
                    selectedColor: const Color(0xFFE65100),
                    backgroundColor: Colors.grey[100],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Vehicle Information
              const Text(
                'Vehicle Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Vehicle Make and Model
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _vehicleMakeController,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Make *',
                        hintText: 'Toyota',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.directions_car),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _vehicleModelController,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Model *',
                        hintText: 'Camry',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Vehicle Year and Plate
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _vehicleYearController,
                      decoration: const InputDecoration(
                        labelText: 'Year *',
                        hintText: '2020',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        final year = int.tryParse(value);
                        if (year == null || year < 1990 || year > DateTime.now().year + 1) {
                          return 'Invalid year';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _vehiclePlateController,
                      decoration: const InputDecoration(
                        labelText: 'License Plate *',
                        hintText: 'ABC-123',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.local_taxi),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Insurance Number
              TextFormField(
                controller: _insuranceNumberController,
                decoration: const InputDecoration(
                  labelText: 'Insurance Policy Number *',
                  hintText: 'Enter your insurance policy number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.security),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your insurance policy number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Vehicle Images
              const Text(
                'Vehicle Images',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add clear photos of your vehicle (exterior and interior)',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 16),
              
              if (_vehicleImages.isNotEmpty) ...[
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _vehicleImages.length + (_vehicleImages.length < 6 ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < _vehicleImages.length) {
                      return Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(_vehicleImages[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
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
                              Icon(Icons.add_photo_alternate, color: Colors.grey[600]),
                              const SizedBox(height: 4),
                              Text('Add More', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
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
                        Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey[600]),
                        const SizedBox(height: 8),
                        Text('Add Vehicle Photos', style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Operating Area
              const Text(
                'Operating Area',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Operating Radius', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text('${_operatingRadius.round()} km'),
                      Slider(
                        value: _operatingRadius,
                        min: 5.0,
                        max: 100.0,
                        divisions: 19,
                        label: '${_operatingRadius.round()} km',
                        onChanged: (value) {
                          setState(() {
                            _operatingRadius = value;
                          });
                        },
                        activeColor: const Color(0xFFE65100),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _getCurrentLocation,
                        icon: const Icon(Icons.my_location),
                        label: const Text('Set Current Location'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE65100).withOpacity(0.1),
                          foregroundColor: const Color(0xFFE65100),
                        ),
                      ),
                      if (_latitude != 0.0 && _longitude != 0.0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Location set: ${_latitude.toStringAsFixed(4)}, ${_longitude.toStringAsFixed(4)}',
                            style: const TextStyle(color: Colors.green, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Availability
              const Text(
                'Availability',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: _availability.entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text(
                              entry.key,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: entry.value,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 8),
                              ),
                              items: [
                                'Not Available',
                                'Available',
                                'Morning Only',
                                'Afternoon Only',
                                'Evening Only',
                                'Night Shift'
                              ].map((availability) => DropdownMenuItem(
                                value: availability,
                                child: Text(availability),
                              )).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _availability[entry.key] = value!;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // Document Verification
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.verified, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Document Verification',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Upload required documents to complete your driver verification.',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        title: const Text('Driver License'),
                        subtitle: const Text('Upload front and back of license'),
                        value: _hasLicense,
                        onChanged: (value) {
                          setState(() {
                            _hasLicense = value ?? false;
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('Insurance Certificate'),
                        subtitle: const Text('Upload valid insurance document'),
                        value: _hasInsurance,
                        onChanged: (value) {
                          setState(() {
                            _hasInsurance = value ?? false;
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('Vehicle Registration'),
                        subtitle: const Text('Upload vehicle registration document'),
                        value: _hasVehicleDocuments,
                        onChanged: (value) {
                          setState(() {
                            _hasVehicleDocuments = value ?? false;
                          });
                        },
                      ),
                      if (_hasLicense || _hasInsurance || _hasVehicleDocuments)
                        ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Implement document upload
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Document upload coming soon!')),
                            );
                          },
                          icon: const Icon(Icons.upload_file),
                          label: const Text('Upload Documents'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitDriverRegistration,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFFE65100),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Complete Registration'),
                ),
              ),
              const SizedBox(height: 16),

              // Skip Option
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                  child: const Text(
                    'Skip for now - I\'ll complete this later',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getVehicleTypeIcon(VehicleType type) {
    switch (type) {
      case VehicleType.car:
        return Icons.directions_car;
      case VehicleType.bike:
        return Icons.motorcycle;
      case VehicleType.threewheeler:
        return Icons.motorcycle;
      case VehicleType.van:
        return Icons.airport_shuttle;
      case VehicleType.suv:
        return Icons.local_shipping;
    }
  }

  String _getVehicleTypeDisplayName(VehicleType type) {
    switch (type) {
      case VehicleType.car:
        return 'Car';
      case VehicleType.bike:
        return 'Bike';
      case VehicleType.threewheeler:
        return 'Three Wheeler';
      case VehicleType.van:
        return 'Van';
      case VehicleType.suv:
        return 'SUV';
    }
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
      
      if (mounted) {
        setState(() {
          _latitude = locationData.latitude!;
          _longitude = locationData.longitude!;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location set successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location: $e')),
        );
      }
    }
  }

  Future<void> _pickImages() async {
    if (_vehicleImages.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 6 images allowed')),
      );
      return;
    }

    final pickedFiles = await _imagePicker.pickMultiImage(imageQuality: 80);
    if (pickedFiles.isNotEmpty) {
      setState(() {
        final remainingSlots = 6 - _vehicleImages.length;
        final imagesToAdd = pickedFiles.take(remainingSlots);
        _vehicleImages.addAll(imagesToAdd.map((xFile) => File(xFile.path)));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _vehicleImages.removeAt(index);
    });
  }

  Future<void> _submitDriverRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedVehicleTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one vehicle type')),
      );
      return;
    }

    if (_latitude == 0.0 || _longitude == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set your operating location')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create driver profile
      final driverProfile = DriverProfile(
        licenseNumber: _licenseNumberController.text.trim(),
        licenseExpiryDate: Timestamp.fromDate(DateTime.now().add(const Duration(days: 365))), // Default 1 year expiry
        vehicleIds: [], // We'll add vehicle management later
        isOnline: false,
        currentLocation: 'Set during first use',
        latitude: _latitude,
        longitude: _longitude,
        verificationStatus: VerificationStatus.pending,
      );

      // Add driver profile to user
      await _userProfileService.addDriverProfile(widget.userId, driverProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Driver registration submitted! Verification pending.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error registering driver: $e')),
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
    _licenseNumberController.dispose();
    _vehicleMakeController.dispose();
    _vehicleModelController.dispose();
    _vehicleYearController.dispose();
    _vehiclePlateController.dispose();
    _insuranceNumberController.dispose();
    super.dispose();
  }
}
