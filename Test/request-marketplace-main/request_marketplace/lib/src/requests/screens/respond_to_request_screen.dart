import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'dart:io';
import '../../models/request_model.dart';
import '../../services/response_service.dart';
import '../../services/image_service.dart';
import '../../core/services/phone_verification_helper.dart';
import '../../profile/screens/phone_number_management_screen.dart';

class RespondToRequestScreen extends StatefulWidget {
  final RequestModel request;

  const RespondToRequestScreen({super.key, required this.request});

  @override
  State<RespondToRequestScreen> createState() => _RespondToRequestScreenState();
}

class _RespondToRequestScreenState extends State<RespondToRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _priceController = TextEditingController();
  final _warrantyMonthsController = TextEditingController();
  final _deliveryAmountController = TextEditingController();
  final ResponseService _responseService = ResponseService();
  final ImageService _imageService = ImageService();
  final ImagePicker _picker = ImagePicker();
  final Location _location = Location();
  
  bool _isSubmitting = false;
  final List<File> _selectedImages = [];
  final List<String> _existingImageUrls = [];
  final Set<String> _selectedPhoneNumbers = {};
  List<dynamic> _userPhoneNumbers = [];
  
  // Enhanced response fields
  bool _hasExpiry = false;
  DateTime? _expiryDate;
  bool _deliveryAvailable = false;
  bool _hasWarranty = false;
  String? _selectedLocation;
  double? _latitude;
  double? _longitude;
  
  // Check if user has already responded
  bool _hasAlreadyResponded = false;
  bool _isLoadingExistingResponse = true;

  @override
  void initState() {
    super.initState();
    _checkExistingResponse();
  }

  Future<void> _checkExistingResponse() async {
    try {
      print('🔍 Checking existing response for request: ${widget.request.id}');
      final hasResponded = await _responseService.hasUserAlreadyResponded(widget.request.id);
      print('📊 Has already responded: $hasResponded');
      
      final existingResponse = await _responseService.getUserExistingResponse(widget.request.id);
      print('📄 Existing response found: ${existingResponse != null}');
      
      if (existingResponse != null) {
        print('✅ Existing response data:');
        print('   Message: "${existingResponse.message}"');
        print('   Price: ${existingResponse.offeredPrice}');
        print('   Phone numbers: ${existingResponse.sharedPhoneNumbers}');
      }
      
      if (mounted) {
        setState(() {
          _hasAlreadyResponded = hasResponded;
          _isLoadingExistingResponse = false;
        });
        
        if (existingResponse != null) {
          print('🔧 Pre-filling form with existing response data...');
          
          // Use a small delay to ensure the UI is ready
          await Future.delayed(const Duration(milliseconds: 100));
          
          if (mounted) {
            setState(() {
              // Pre-fill form with existing response data
              _messageController.text = existingResponse.message;
              _priceController.text = existingResponse.offeredPrice?.toString() ?? '';
              _selectedPhoneNumbers.clear(); // Clear existing selections first
              _selectedPhoneNumbers.addAll(existingResponse.sharedPhoneNumbers);
              _hasExpiry = existingResponse.hasExpiry;
              _expiryDate = existingResponse.expiryDate;
              _deliveryAvailable = existingResponse.deliveryAvailable;
              _deliveryAmountController.text = existingResponse.deliveryAmount?.toString() ?? '';
              _hasWarranty = existingResponse.warranty?.isNotEmpty ?? false;
              if (_hasWarranty && existingResponse.warranty != null) {
                // Extract months from warranty text
                final monthsMatch = RegExp(r'(\d+)').firstMatch(existingResponse.warranty!);
                if (monthsMatch != null) {
                  _warrantyMonthsController.text = monthsMatch.group(1)!;
                }
              }
              _selectedLocation = existingResponse.location;
              _latitude = existingResponse.latitude;
              _longitude = existingResponse.longitude;
              
              // Load existing images
              if (existingResponse.images.isNotEmpty) {
                _existingImageUrls.clear();
                _existingImageUrls.addAll(existingResponse.images);
              }
            });
            
            print('✅ Form fields updated:');
            print('   Message controller: "${_messageController.text}"');
            print('   Price controller: "${_priceController.text}"');
            print('   Selected phones: $_selectedPhoneNumbers');
          }
        }
      }
    } catch (e) {
      print('❌ Error checking existing response: $e');
      if (mounted) {
        setState(() {
          _isLoadingExistingResponse = false;
        });
      }
      print('Error checking existing response: $e');
    }
  }

  Future<void> _loadUserPhoneNumbers() async {
    try {
      final phoneNumbers = await PhoneVerificationHelper.getAllPhoneNumbers();
      if (mounted) {
        setState(() {
          _userPhoneNumbers = phoneNumbers.map((phone) => {
            'number': phone.number,
            'isVerified': phone.isVerified,
            'isPrimary': false, // Default to false, can be enhanced later
          }).toList();
        });
      }
    } catch (e) {
      print('Error loading user phone numbers: $e');
      if (mounted) {
        setState(() {
          _userPhoneNumbers = [];
        });
      }
    }
  }

  Future<void> _submitResponse() async {
    // Check phone verification before proceeding
    final hasVerifiedPhone = await PhoneVerificationHelper.validatePhoneVerification(context);
    if (!hasVerifiedPhone) {
      return; // User cancelled or doesn't have verified phone
    }

    if (!_formKey.currentState!.validate()) return;

    // Show confirmation dialog for updates
    if (_hasAlreadyResponded) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Update Response'),
            content: const Text(
              'Are you sure you want to update your existing response? This will replace your previous response to this request.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Update'),
              ),
            ],
          );
        },
      );
      
      if (confirmed != true) return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final offeredPrice = _priceController.text.isEmpty 
          ? null 
          : double.tryParse(_priceController.text);

      // Upload images to Firebase Storage
      List<String> imageUrls = [..._existingImageUrls]; // Start with existing images
      if (_selectedImages.isNotEmpty) {
        print('📤 Uploading ${_selectedImages.length} new images...');
        final newImageUrls = await _imageService.uploadResponseImages(_selectedImages, widget.request.id);
        imageUrls.addAll(newImageUrls);
        print('✅ Uploaded ${newImageUrls.length} new images successfully');
      }

      // Get verified phone numbers to share automatically
      final verifiedPhones = await PhoneVerificationHelper.getVerifiedPhoneNumbers();
      final phoneNumbersToShare = verifiedPhones.map((phone) => phone.number).toList();

      await _responseService.submitResponse(
        requestId: widget.request.id,
        message: _messageController.text.trim(),
        sharedPhoneNumbers: phoneNumbersToShare,
        offeredPrice: offeredPrice,
        hasExpiry: _hasExpiry,
        expiryDate: _expiryDate,
        deliveryAvailable: _deliveryAvailable,
        deliveryAmount: _deliveryAvailable && _deliveryAmountController.text.isNotEmpty 
            ? double.tryParse(_deliveryAmountController.text) 
            : null,
        warranty: _hasWarranty && _warrantyMonthsController.text.isNotEmpty 
            ? '${_warrantyMonthsController.text} months warranty'
            : null,
        images: imageUrls, // Use uploaded image URLs
        location: _selectedLocation,
        latitude: _latitude,
        longitude: _longitude,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_hasAlreadyResponded 
                ? 'Your response has been updated successfully!' 
                : 'Response submitted successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
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

  Future<void> _pickImages() async {
    if (_totalImageCount >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 4 images allowed')),
      );
      return;
    }

    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          for (var image in images) {
            if (_totalImageCount < 4) {
              _selectedImages.add(File(image.path));
            }
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          return;
        }
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          return;
        }
      }

      final LocationData locationData = await _location.getLocation();
      
      if (locationData.latitude != null && locationData.longitude != null) {
        setState(() {
          _latitude = locationData.latitude;
          _longitude = locationData.longitude;
        });

        // Get address from coordinates
        try {
          List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
            locationData.latitude!,
            locationData.longitude!,
          );
          
          if (placemarks.isNotEmpty) {
            final placemark = placemarks.first;
            setState(() {
              _selectedLocation = '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}';
            });
          }
        } catch (e) {
          print('Error getting address: $e');
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  void _showLocationPicker() {
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

  void _showLocationInputDialog() {
    final locationController = TextEditingController(text: _selectedLocation ?? '');
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Location'),
          content: TextField(
            controller: locationController,
            decoration: const InputDecoration(
              hintText: 'Enter your location',
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
                  _selectedLocation = locationController.text;
                  _latitude = null;
                  _longitude = null;
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

  // Helper functions for image management
  int get _totalImageCount => _existingImageUrls.length + _selectedImages.length;
  
  bool get _canAddMoreImages => _totalImageCount < 4;
  
  void _removeExistingImage(int index) {
    setState(() {
      _existingImageUrls.removeAt(index);
    });
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _showRequestDetails() {
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
                        'Description',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.request.description,
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                ],
                if (widget.request.location.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 20, color: Colors.red),
                      const SizedBox(width: 8),
                      const Text(
                        'Location',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.request.location,
                    style: const TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 20, color: Colors.orange),
                    const SizedBox(width: 8),
                    const Text(
                      'Posted',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDate(widget.request.createdAt.toDate()),
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _priceController.dispose();
    _warrantyMonthsController.dispose();
    _deliveryAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Check if request is fulfilled
    if (widget.request.status == 'fulfilled') {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Request Fulfilled'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 80,
                  color: Colors.blue[600],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Request Already Fulfilled',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This request has already been fulfilled and is no longer accepting responses.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isLoadingExistingResponse 
            ? 'Respond to Request' 
            : (_hasAlreadyResponded ? 'Update Response' : 'Respond to Request')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: _isLoadingExistingResponse 
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading existing response...'),
                ],
              ),
            )
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Existing response notification
              if (_hasAlreadyResponded) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  margin: const EdgeInsets.only(bottom: 20.0),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    border: Border.all(color: Colors.amber[300]!, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.edit_note,
                              color: Colors.amber[800],
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Updating Existing Response',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.amber[900],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'You already responded to this request. The form is pre-filled with your previous response.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.amber[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.amber[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.amber[800],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Make your changes and click "Update Response" to save',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.amber[800],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              // Request Summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.request.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.info_outline, color: Colors.blue),
                            onPressed: () => _showRequestDetails(),
                            tooltip: 'More info',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Budget: LKR ${widget.request.budget.toStringAsFixed(0)}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      if (widget.request.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.request.description,
                          style: const TextStyle(color: Colors.black87),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.request.description.length > 100)
                          TextButton(
                            onPressed: () => _showRequestDetails(),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              alignment: Alignment.centerLeft,
                            ),
                            child: const Text('Read more'),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Response Message
              Row(
                children: [
                  Text(
                    _hasAlreadyResponded ? 'Update Your Response' : 'Your Response',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  if (_hasAlreadyResponded) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'EDITING',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[800],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Write your response message...',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a response message';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Offered Price (Optional)
              const Text(
                'Offered Price (Optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  hintText: 'Enter your offered price',
                  prefixText: 'LKR ',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'Please enter a valid price';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Product Expiry Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Product Expiry',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          Switch(
                            value: _hasExpiry,
                            onChanged: (value) {
                              setState(() {
                                _hasExpiry = value;
                                if (!value) {
                                  _expiryDate = null;
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      if (_hasExpiry) ...[
                        const SizedBox(height: 12),
                        ListTile(
                          title: Text(
                            _expiryDate != null 
                                ? 'Expires: ${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'
                                : 'Select expiry date',
                          ),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                            );
                            if (date != null) {
                              setState(() {
                                _expiryDate = date;
                              });
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Delivery Available Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Delivery Available',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          Switch(
                            value: _deliveryAvailable,
                            onChanged: (value) {
                              setState(() {
                                _deliveryAvailable = value;
                                if (!value) {
                                  _deliveryAmountController.clear();
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      if (_deliveryAvailable) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _deliveryAmountController,
                          decoration: const InputDecoration(
                            labelText: 'Delivery Amount',
                            prefixText: 'LKR ',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (_deliveryAvailable && (value == null || value.isEmpty)) {
                              return 'Please enter delivery amount';
                            }
                            if (value != null && value.isNotEmpty) {
                              final amount = double.tryParse(value);
                              if (amount == null || amount <= 0) {
                                return 'Please enter a valid amount';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Warranty Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Warranty',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          Switch(
                            value: _hasWarranty,
                            onChanged: (value) {
                              setState(() {
                                _hasWarranty = value;
                                if (!value) {
                                  _warrantyMonthsController.clear();
                                }
                              });
                            },
                          ),
                        ],
                      ),
                      if (_hasWarranty) ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _warrantyMonthsController,
                          decoration: const InputDecoration(
                            labelText: 'Warranty Period (Months)',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (_hasWarranty && (value == null || value.isEmpty)) {
                              return 'Please enter warranty period';
                            }
                            if (value != null && value.isNotEmpty) {
                              final months = int.tryParse(value);
                              if (months == null || months <= 0) {
                                return 'Please enter a valid number of months';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Images Section
              const Text(
                'Images (Optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_totalImageCount == 0) ...[
                        Container(
                          height: 120,
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
                                    Icons.add_photo_alternate,
                                    size: 40,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Add Photos',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Up to 4 images',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                          itemCount: _totalImageCount + (_totalImageCount < 4 ? 1 : 0),
                          itemBuilder: (context, index) {
                            // Handle existing images first
                            if (index < _existingImageUrls.length) {
                              return Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: NetworkImage(_existingImageUrls[index]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeExistingImage(index),
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
                            }
                            // Handle new selected images
                            else if (index < _totalImageCount) {
                              final fileIndex = index - _existingImageUrls.length;
                              return Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      image: DecorationImage(
                                        image: FileImage(_selectedImages[fileIndex]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => _removeImage(fileIndex),
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
                              return Container(
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
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Location
              const Text(
                'Location (Optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  title: Text(
                    _selectedLocation ?? 'Select Location',
                    style: TextStyle(
                      color: _selectedLocation != null ? Colors.black : Colors.grey[600],
                    ),
                  ),
                  subtitle: _selectedLocation != null 
                      ? Text(
                          'Tap to change location',
                          style: TextStyle(color: Colors.grey[500]),
                        )
                      : null,
                  trailing: const Icon(Icons.location_on),
                  onTap: _showLocationPicker,
                ),
              ),
              const SizedBox(height: 24),

              // Phone Number Sharing
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Share Contact Information',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PhoneNumberManagementScreen(),
                        ),
                      );
                      _loadUserPhoneNumbers(); // Reload after returning
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Manage'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Select which phone numbers to share (optional):',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              
              if (_userPhoneNumbers.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Icon(Icons.phone_disabled, size: 48, color: Colors.grey),
                        const SizedBox(height: 8),
                        const Text(
                          'No verified phone numbers',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Add and verify phone numbers to share with requesters.',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
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
                        ),
                      ],
                    ),
                  ),
                )
              else
                Column(
                  children: _userPhoneNumbers.map((phone) {
                    return Card(
                      child: CheckboxListTile(
                        title: Row(
                          children: [
                            Expanded(child: Text(phone.number)),
                            if (phone.isVerified) ...[
                              const Icon(Icons.verified, color: Colors.green, size: 16),
                              const SizedBox(width: 4),
                              const Text(
                                'Verified',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: phone.isPrimary 
                            ? const Text('Primary', style: TextStyle(color: Colors.blue))
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
                        } : null, // Disable checkbox if not verified
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    );
                  }).toList(),
                ),
              
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitResponse,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    backgroundColor: _hasAlreadyResponded ? Colors.orange : null,
                    foregroundColor: _hasAlreadyResponded ? Colors.white : null,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _hasAlreadyResponded ? Icons.update : Icons.send,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(_hasAlreadyResponded ? 'Update Response' : 'Submit Response'),
                          ],
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
