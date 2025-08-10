import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geo;
import '../../models/request_model.dart';
import '../../models/user_model.dart';
import '../../services/image_service.dart';
import '../../services/phone_number_service.dart';
import '../../profile/screens/phone_number_management_screen.dart';
import '../widgets/category_picker.dart';

enum ServiceUrgency { low, medium, high, urgent }

class EditRequestScreen extends StatefulWidget {
  final RequestModel request;

  const EditRequestScreen({super.key, required this.request});

  @override
  State<EditRequestScreen> createState() => _EditRequestScreenState();
}

class _EditRequestScreenState extends State<EditRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  final _locationController = TextEditingController();
  final _categoryController = TextEditingController();
  final _durationController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _phoneService = PhoneNumberService();
  final Location _location = Location();
  final ImageService _imageService = ImageService();

  List<File> _newImages = [];
  List<String> _existingImageUrls = [];
  List<String> _imagesToDelete = [];
  Set<String> _selectedPhoneNumbers = {};
  List<PhoneNumber> _userPhoneNumbers = [];

  String? _selectedCategory;
  String? _selectedSubcategory;
  ItemCondition _selectedCondition = ItemCondition.any;
  DateTime? _deadline;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
    _loadPhoneNumbers();
  }

  void _initializeFields() {
    // Initialize controllers with existing data
    _titleController.text = widget.request.title;
    _descriptionController.text = widget.request.description;
    _budgetController.text = widget.request.budget.toString();
    _locationController.text = widget.request.location;
    _categoryController.text = widget.request.category;
    
    // Initialize other fields
    _selectedCategory = widget.request.category.isNotEmpty ? widget.request.category : null;
    _selectedSubcategory = widget.request.subcategory.isNotEmpty ? widget.request.subcategory : null;
    _selectedCondition = widget.request.condition;
    _existingImageUrls = List.from(widget.request.imageUrls);
    _selectedPhoneNumbers = Set.from(widget.request.additionalPhones);
    
    // Initialize deadline if it exists
    if (widget.request.deadline != null) {
      _deadline = widget.request.deadline!.toDate();
    }
  }

  Future<void> _loadPhoneNumbers() async {
    try {
      final phoneNumbers = await _phoneService.getUserPhoneNumbers();
      setState(() {
        _userPhoneNumbers = phoneNumbers;
      });
    } catch (e) {
      print('Error loading phone numbers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${widget.request.type.toString().split('.').last.toUpperCase()} Request'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveRequest,
              child: const Text(
                'SAVE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4F46E5),
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information Section
              _buildSectionHeader('Basic Information'),
              const SizedBox(height: 16),
              
              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  hintText: 'What do you need?',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description *',
                  hintText: 'Provide detailed information about your request',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Category Section
              _buildSectionHeader('Category'),
              const SizedBox(height: 16),
              
              GestureDetector(
                onTap: _showCategoryPicker,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.category, color: Colors.grey),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedCategory ?? 'Select Category *',
                              style: TextStyle(
                                fontSize: 16,
                                color: _selectedCategory != null ? Colors.black : Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (_selectedSubcategory != null)
                              Text(
                                _selectedSubcategory!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Item Condition (only for item requests)
              if (widget.request.type == RequestType.item) ...[
                _buildSectionHeader('Item Condition'),
                const SizedBox(height: 16),
                _buildConditionSelector(),
                const SizedBox(height: 24),
              ],

              // Budget Section (not for ride requests)
              if (widget.request.type != RequestType.ride) ...[
                _buildSectionHeader('Budget'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _budgetController,
                  decoration: const InputDecoration(
                    labelText: 'Budget (LKR) *',
                    hintText: 'Enter your budget',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a budget';
                    }
                    final budget = double.tryParse(value);
                    if (budget == null || budget <= 0) {
                      return 'Please enter a valid budget';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Location Section
              _buildSectionHeader('Location'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(
                        labelText: 'Location *',
                        hintText: 'Enter your location',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a location';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: _getCurrentLocation,
                    icon: const Icon(Icons.my_location),
                    tooltip: 'Use current location',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Images Section
              _buildSectionHeader('Images'),
              const SizedBox(height: 16),
              _buildImageSection(),
              const SizedBox(height: 24),

              // Additional Phone Numbers Section
              _buildSectionHeader('Contact Numbers'),
              const SizedBox(height: 16),
              _buildPhoneNumbersSection(),
              const SizedBox(height: 24),

              // Deadline Section (for service and item requests)
              if (widget.request.type != RequestType.ride) ...[
                _buildSectionHeader('Deadline (Optional)'),
                const SizedBox(height: 16),
                _buildDeadlineSection(),
                const SizedBox(height: 32),
              ],

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveRequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'UPDATE REQUEST',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2D3748),
      ),
    );
  }

  Widget _buildConditionSelector() {
    return Column(
      children: ItemCondition.values.map((condition) {
        return RadioListTile<ItemCondition>(
          title: Text(condition.value.toUpperCase()),
          value: condition,
          groupValue: _selectedCondition,
          onChanged: (ItemCondition? value) {
            if (value != null) {
              setState(() {
                _selectedCondition = value;
              });
            }
          },
          dense: true,
        );
      }).toList(),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Existing Images
        if (_existingImageUrls.isNotEmpty) ...[
          const Text(
            'Current Images:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _existingImageUrls.length,
              itemBuilder: (context, index) {
                final imageUrl = _existingImageUrls[index];
                final isMarkedForDeletion = _imagesToDelete.contains(imageUrl);
                
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isMarkedForDeletion ? Colors.red : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            colorBlendMode: isMarkedForDeletion ? BlendMode.saturation : null,
                            color: isMarkedForDeletion ? Colors.grey : null,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _toggleImageDeletion(imageUrl),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isMarkedForDeletion ? Colors.red : Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isMarkedForDeletion ? Icons.undo : Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      if (isMarkedForDeletion)
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: Colors.red.withOpacity(0.3),
                          ),
                          child: const Center(
                            child: Text(
                              'WILL DELETE',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],

        // New Images
        if (_newImages.isNotEmpty) ...[
          const Text(
            'New Images:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _newImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(
                            _newImages[index],
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeNewImage(index),
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
              },
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Add Images Button
        OutlinedButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Add Images'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneNumbersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Additional contact numbers for this request:',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            TextButton.icon(
              onPressed: _managePhoneNumbers,
              icon: const Icon(Icons.settings, size: 16),
              label: const Text('Manage'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_userPhoneNumbers.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.blue),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Add phone numbers to let people contact you easily'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _managePhoneNumbers,
                      child: const Text('Add Numbers'),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            children: _userPhoneNumbers.map((phone) {
              final isSelected = _selectedPhoneNumbers.contains(phone.number);
              return CheckboxListTile(
                title: Text(
                  phone.number,
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: phone.isPrimary ? const Text('Primary') : null,
                value: isSelected,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedPhoneNumbers.add(phone.number);
                    } else {
                      _selectedPhoneNumbers.remove(phone.number);
                    }
                  });
                },
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildDeadlineSection() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _selectDeadline,
            icon: const Icon(Icons.calendar_today),
            label: Text(
              _deadline != null
                  ? 'Deadline: ${_deadline!.day}/${_deadline!.month}/${_deadline!.year}'
                  : 'Set Deadline',
            ),
          ),
        ),
        if (_deadline != null) ...[
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => setState(() => _deadline = null),
            icon: const Icon(Icons.clear),
            tooltip: 'Remove deadline',
          ),
        ],
      ],
    );
  }

  void _showCategoryPicker() async {
    String requestType = widget.request.type == RequestType.item ? 'item' : 'service';
    
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.8,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => CategoryPicker(
          requestType: requestType,
          scrollController: scrollController,
        ),
      ),
    );

    if (result != null && result.containsKey('category')) {
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

      final LocationData locationData = await _location.getLocation();
      final List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
        locationData.latitude!,
        locationData.longitude!,
      );

      if (placemarks.isNotEmpty) {
        final geo.Placemark place = placemarks[0];
        final String address = '${place.street}, ${place.locality}, ${place.country}';
        setState(() {
          _locationController.text = address;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _newImages.addAll(images.map((xfile) => File(xfile.path)));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking images: $e')),
      );
    }
  }

  void _toggleImageDeletion(String imageUrl) {
    setState(() {
      if (_imagesToDelete.contains(imageUrl)) {
        _imagesToDelete.remove(imageUrl);
      } else {
        _imagesToDelete.add(imageUrl);
      }
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  Future<void> _selectDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _deadline = picked;
      });
    }
  }

  void _managePhoneNumbers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PhoneNumberManagementScreen(),
      ),
    ).then((_) => _loadPhoneNumbers());
  }

  Future<void> _saveRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload new images
      List<String> newImageUrls = [];
      if (_newImages.isNotEmpty) {
        newImageUrls = await _imageService.uploadRequestImages(_newImages, widget.request.id);
      }

      // Combine existing images (minus deleted ones) with new images
      final finalImageUrls = [
        ..._existingImageUrls.where((url) => !_imagesToDelete.contains(url)),
        ...newImageUrls,
      ];

      // Delete images marked for deletion from storage
      if (_imagesToDelete.isNotEmpty) {
        try {
          await _imageService.deleteImages(_imagesToDelete);
        } catch (e) {
          print('Error deleting images: $e');
        }
      }

      // Prepare update data
      final updateData = <String, dynamic>{
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'category': _selectedCategory!,
        'subcategory': _selectedSubcategory ?? '',
        'imageUrls': finalImageUrls,
        'additionalPhones': _selectedPhoneNumbers.toList(),
        'updatedAt': Timestamp.now(),
      };

      // Add type-specific fields
      if (widget.request.type == RequestType.item) {
        updateData['condition'] = _selectedCondition.value;
      }

      if (widget.request.type != RequestType.ride) {
        updateData['budget'] = double.parse(_budgetController.text);
      }

      if (_deadline != null) {
        updateData['deadline'] = Timestamp.fromDate(_deadline!);
      } else {
        updateData['deadline'] = null;
      }

      // Update the request in Firestore
      await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.request.id)
          .update(updateData);

      // Create activity log
      await FirebaseFirestore.instance.collection('activities').add({
        'userId': widget.request.userId,
        'type': 'update_request',
        'description': 'Updated request: ${_titleController.text.trim()}',
        'timestamp': Timestamp.now(),
        'details': {
          'requestId': widget.request.id,
          'requestTitle': _titleController.text.trim(),
          'changes': 'Full edit including images and details',
        },
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate successful update
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
        setState(() => _isLoading = false);
      }
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
}
