import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/request_model.dart';
import '../../services/response_service.dart';
import '../../services/image_service.dart';
import '../../core/services/phone_verification_helper.dart';
import '../../profile/screens/phone_number_management_screen.dart';
import '../../theme/app_theme.dart';

enum VehicleType { motorcycle, car, van, truck, other }
enum DeliveryExperience { beginner, intermediate, expert, professional }

class RespondToDeliveryRequestScreen extends StatefulWidget {
  final RequestModel request;

  const RespondToDeliveryRequestScreen({super.key, required this.request});

  @override
  State<RespondToDeliveryRequestScreen> createState() => _RespondToDeliveryRequestScreenState();
}

class _RespondToDeliveryRequestScreenState extends State<RespondToDeliveryRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _priceController = TextEditingController();
  final _vehicleDetailsController = TextEditingController();
  final ResponseService _responseService = ResponseService();
  final ImageService _imageService = ImageService();
  final ImagePicker _picker = ImagePicker();
  
  bool _isSubmitting = false;
  bool _hasAlreadyResponded = false;
  bool _isLoading = true;
  bool _canProvideVehicleDelivery = false;
  bool _hasInsurance = false;
  bool _hasLicense = true;
  bool _is24HourService = false;
  final List<File> _selectedImages = [];
  final List<String> _existingImageUrls = [];
  
  // Delivery-specific fields
  VehicleType _vehicleType = VehicleType.motorcycle;
  DeliveryExperience _deliveryExperience = DeliveryExperience.intermediate;
  double? _maxWeight;
  double? _maxDistance;
  String? _selectedLocation;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _checkExistingResponse();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh phone numbers when screen comes back into focus
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // Phone numbers are now handled by PhoneVerificationHelper
    // No need to load them here anymore
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _checkExistingResponse() async {
    try {
      final hasResponded = await _responseService.hasUserAlreadyResponded(widget.request.id);
      if (hasResponded) {
        // Load existing response data if needed
        // For now, we'll just set the flag since we don't have a direct method
        // The existing response data could be loaded via getResponsesForRequest if needed
      }
      if (mounted) {
        setState(() {
          _hasAlreadyResponded = hasResponded;
        });
      }
    } catch (e) {
      print('Error checking existing response: $e');
    }
  }

  Future<void> _pickImages() async {
    try {
      final pickedFiles = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages.clear();
          _selectedImages.addAll(pickedFiles.take(5).map((xFile) => File(xFile.path)));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e')),
        );
      }
    }
  }

  Future<void> _submitDeliveryProposal() async {
    // Check phone verification before proceeding
    final hasVerifiedPhone = await PhoneVerificationHelper.validatePhoneVerification(context);
    if (!hasVerifiedPhone) {
      return; // User cancelled or doesn't have verified phone
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      List<String> imageUrls = [..._existingImageUrls];
      
      if (_selectedImages.isNotEmpty) {
        final newImageUrls = await _imageService.uploadResponseImages(
          _selectedImages,
          widget.request.id,
        );
        imageUrls.addAll(newImageUrls);
      }

      // Build delivery details for warranty field
      String deliveryDetails = '';
      if (_hasLicense) {
        deliveryDetails += 'Licensed Driver';
      }
      if (_hasInsurance) {
        if (deliveryDetails.isNotEmpty) deliveryDetails += ' • ';
        deliveryDetails += 'Insured Vehicle';
      }
      if (_is24HourService) {
        if (deliveryDetails.isNotEmpty) deliveryDetails += ' • ';
        deliveryDetails += '24/7 Service';
      }
      if (_maxWeight != null) {
        if (deliveryDetails.isNotEmpty) deliveryDetails += ' • ';
        deliveryDetails += 'Max Weight: ${_maxWeight}kg';
      }
      if (_maxDistance != null) {
        if (deliveryDetails.isNotEmpty) deliveryDetails += ' • ';
        deliveryDetails += 'Max Distance: ${_maxDistance}km';
      }

      // Get verified phone numbers to share
      final verifiedPhones = await PhoneVerificationHelper.getVerifiedPhoneNumbers();
      final phoneNumbersToShare = verifiedPhones
          .where((phone) => phone.number.isNotEmpty)
          .map((phone) => phone.number)
          .toList();

      await _responseService.submitResponse(
        requestId: widget.request.id,
        message: _messageController.text.trim(),
        offeredPrice: double.tryParse(_priceController.text.trim()),
        sharedPhoneNumbers: phoneNumbersToShare,
        hasExpiry: false,
        expiryDate: null,
        deliveryAvailable: _canProvideVehicleDelivery,
        deliveryAmount: null, // Include in main price
        warranty: deliveryDetails.isNotEmpty ? deliveryDetails : null,
        images: imageUrls,
        location: _selectedLocation,
        latitude: _latitude,
        longitude: _longitude,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_hasAlreadyResponded 
                ? 'Your delivery proposal has been updated successfully!' 
                : 'Delivery proposal submitted successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        setState(() {
          _hasAlreadyResponded = true;
        });
        
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showDeliveryDetails() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            widget.request.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.attach_money, size: 20, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      'Budget: LKR ${widget.request.budget.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (widget.request.description.isNotEmpty) ...[
                  const Row(
                    children: [
                      Icon(Icons.description, size: 20, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Delivery Description',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(widget.request.description),
                  const SizedBox(height: 16),
                ],
                if (widget.request.location.isNotEmpty) ...[
                  const Row(
                    children: [
                      Icon(Icons.location_on, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Location',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(widget.request.location),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _getVehicleTypeText(VehicleType type) {
    switch (type) {
      case VehicleType.motorcycle:
        return 'Motorcycle';
      case VehicleType.car:
        return 'Car';
      case VehicleType.van:
        return 'Van';
      case VehicleType.truck:
        return 'Truck';
      case VehicleType.other:
        return 'Other Vehicle';
    }
  }

  String _getExperienceText(DeliveryExperience experience) {
    switch (experience) {
      case DeliveryExperience.beginner:
        return 'New to delivery (< 6 months)';
      case DeliveryExperience.intermediate:
        return 'Some experience (6 months - 2 years)';
      case DeliveryExperience.expert:
        return 'Experienced (2+ years)';
      case DeliveryExperience.professional:
        return 'Professional delivery service';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Submit Delivery Proposal'),
          backgroundColor: AppTheme.backgroundColor,
          foregroundColor: AppTheme.textPrimary,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          _hasAlreadyResponded ? 'Update Delivery Proposal' : 'Submit Delivery Proposal',
          style: AppTheme.headingMedium,
        ),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Existing response warning
              if (_hasAlreadyResponded) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.amber[800]),
                          const SizedBox(width: 8),
                          Text(
                            'You have already responded to this request',
                            style: TextStyle(
                              color: Colors.amber[800],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You can update your proposal below.',
                        style: TextStyle(color: Colors.amber[700]),
                      ),
                    ],
                  ),
                ),
              ],

              // Request Summary Card
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.request.title,
                            style: AppTheme.headingSmall,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.info_outline, color: AppTheme.primaryColor),
                          onPressed: () => _showDeliveryDetails(),
                          tooltip: 'More info',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingSmall),
                    Text(
                      'Budget: LKR ${widget.request.budget.toStringAsFixed(0)}',
                      style: AppTheme.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.successColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXSmall),
                    Text(
                      '${widget.request.category} • ${widget.request.subcategory}',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Delivery Proposal Details
              Text(
                'Your Delivery Proposal',
                style: AppTheme.headingSmall,
              ),
              const SizedBox(height: AppTheme.spacingSmall),

              // Vehicle Type
              Text(
                'Vehicle Type',
                style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMedium),
                  child: Column(
                    children: VehicleType.values.map((type) {
                      return RadioListTile<VehicleType>(
                        title: Text(
                          _getVehicleTypeText(type),
                          style: AppTheme.bodyMedium,
                        ),
                        value: type,
                        groupValue: _vehicleType,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (value) {
                          setState(() {
                            _vehicleType = value!;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMedium),

              // Delivery Experience
              Text(
                'Delivery Experience',
                style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMedium),
                  child: Column(
                    children: DeliveryExperience.values.map((experience) {
                      return RadioListTile<DeliveryExperience>(
                        title: Text(
                          _getExperienceText(experience),
                          style: AppTheme.bodyMedium,
                        ),
                        value: experience,
                        groupValue: _deliveryExperience,
                        activeColor: AppTheme.primaryColor,
                        onChanged: (value) {
                          setState(() {
                            _deliveryExperience = value!;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMedium),

              // Vehicle Details & Capacity
              Text(
                'Vehicle Details & Capacity',
                style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMedium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Vehicle Details
                      TextFormField(
                        controller: _vehicleDetailsController,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle Details (Optional)',
                          hintText: 'e.g., Honda Activa 125cc, Red color',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      // Max Weight
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Max Weight (kg)',
                                hintText: '5',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                _maxWeight = double.tryParse(value);
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              decoration: const InputDecoration(
                                labelText: 'Max Distance (km)',
                                hintText: '25',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                _maxDistance = double.tryParse(value);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMedium),

              // Service Options
              Text(
                'Service Options',
                style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMedium),
                  child: Column(
                    children: [
                      CheckboxListTile(
                        title: const Text('I have a valid driving license'),
                        value: _hasLicense,
                        onChanged: (value) {
                          setState(() {
                            _hasLicense = value ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      CheckboxListTile(
                        title: const Text('Vehicle has insurance coverage'),
                        value: _hasInsurance,
                        onChanged: (value) {
                          setState(() {
                            _hasInsurance = value ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      CheckboxListTile(
                        title: const Text('24/7 delivery service available'),
                        value: _is24HourService,
                        onChanged: (value) {
                          setState(() {
                            _is24HourService = value ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      CheckboxListTile(
                        title: const Text('Can provide door-to-door delivery'),
                        value: _canProvideVehicleDelivery,
                        onChanged: (value) {
                          setState(() {
                            _canProvideVehicleDelivery = value ?? false;
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMedium),

              // Your Proposal Message
              Text(
                'Your Proposal Message',
                style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Describe your delivery service, availability, and any special offers...',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your proposal message';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingMedium),

              // Your Price
              Text(
                'Your Delivery Price',
                style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  hintText: 'Enter your delivery charge',
                  prefixText: 'LKR ',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your delivery price';
                  }
                  final price = double.tryParse(value.trim());
                  if (price == null || price <= 0) {
                    return 'Please enter a valid price';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingMedium),

              // Add Images
              Text(
                'Add Images (Optional)',
                style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              
              if (_selectedImages.isEmpty && _existingImageUrls.isEmpty) ...[
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: InkWell(
                    onTap: _pickImages,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey[600]),
                        const SizedBox(height: 8),
                        Text(
                          'Add vehicle photos',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        Text(
                          'Up to 5 images',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedImages.length + _existingImageUrls.length + 1,
                    itemBuilder: (context, index) {
                      if (index < _selectedImages.length) {
                        return Container(
                          width: 100,
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
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else if (index < _selectedImages.length + _existingImageUrls.length) {
                        final urlIndex = index - _selectedImages.length;
                        return Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: NetworkImage(_existingImageUrls[urlIndex]),
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
                                      _existingImageUrls.removeAt(urlIndex);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        // Add more button
                        if (_selectedImages.length + _existingImageUrls.length < 5) {
                          return Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: InkWell(
                              onTap: _pickImages,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add, size: 30, color: Colors.grey[600]),
                                  Text(
                                    'Add More',
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                ),
              ],
              const SizedBox(height: AppTheme.spacingMedium),

              // Contact Information Note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your verified phone numbers from your profile will be shared with the requester when you submit this response.',
                        style: AppTheme.bodyMedium.copyWith(color: Colors.blue[800]),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppTheme.spacingLarge),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitDeliveryProposal,
                  style: AppTheme.primaryButtonStyle.copyWith(
                    padding: WidgetStateProperty.all(
                      const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: AppTheme.backgroundColor,
                            strokeWidth: 3,
                          ),
                        )
                      : Text(
                          _hasAlreadyResponded ? 'Update Delivery Proposal' : 'Submit Delivery Proposal',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
