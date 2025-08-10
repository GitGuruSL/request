import 'package:flutter/material.dart';
import '../../../models/request_model.dart';
import '../../../models/enhanced_user_model.dart';
import '../../../services/enhanced_request_service.dart';
import '../../../services/enhanced_user_service.dart';
import '../../../widgets/image_upload_widget.dart';
import '../../../widgets/location_picker_widget.dart';
import '../../../utils/currency_helper.dart';

class EditDeliveryRequestScreen extends StatefulWidget {
  final RequestModel request;
  
  const EditDeliveryRequestScreen({
    super.key,
    required this.request,
  });

  @override
  State<EditDeliveryRequestScreen> createState() => _EditDeliveryRequestScreenState();
}

class _EditDeliveryRequestScreenState extends State<EditDeliveryRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final EnhancedRequestService _requestService = EnhancedRequestService();
  final EnhancedUserService _userService = EnhancedUserService();

  // Form Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pickupLocationController = TextEditingController();
  final _deliveryLocationController = TextEditingController();
  final _budgetController = TextEditingController();
  final _specialInstructionsController = TextEditingController();
  final _itemDescriptionController = TextEditingController();
  
  String _packageSize = 'Small';
  DateTime? _pickupTime;
  DateTime? _deliveryTime;
  bool _isFragile = false;
  bool _requiresSignature = false;
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
    _initializeFromRequest();
  }

  void _initializeFromRequest() {
    _titleController.text = widget.request.title;
    _descriptionController.text = widget.request.description ?? '';
    _budgetController.text = widget.request.budget?.toString() ?? '';
    _imageUrls = List<String>.from(widget.request.images ?? []);
    
    if (widget.request.metadata != null) {
      final metadata = widget.request.metadata!;
      _pickupLocationController.text = metadata['pickupLocation'] ?? widget.request.location ?? '';
      _deliveryLocationController.text = metadata['deliveryLocation'] ?? '';
      _packageSize = metadata['packageSize'] ?? 'Small';
      _isFragile = metadata['isFragile'] ?? false;
      _requiresSignature = metadata['requiresSignature'] ?? false;
      _specialInstructionsController.text = metadata['specialInstructions'] ?? '';
      _itemDescriptionController.text = metadata['itemDescription'] ?? '';
      
      if (metadata['pickupTime'] != null) {
        _pickupTime = metadata['pickupTime'] is DateTime 
          ? metadata['pickupTime']
          : DateTime.tryParse(metadata['pickupTime'].toString());
      }
      if (metadata['deliveryTime'] != null) {
        _deliveryTime = metadata['deliveryTime'] is DateTime 
          ? metadata['deliveryTime']
          : DateTime.tryParse(metadata['deliveryTime'].toString());
      }
    }
  }

  Future<void> _selectPickupTime() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _pickupTime ?? DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _pickupTime = picked;
      });
    }
  }

  Future<void> _selectDeliveryTime() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deliveryTime ?? _pickupTime?.add(const Duration(hours: 2)) ?? DateTime.now().add(const Duration(hours: 3)),
      firstDate: _pickupTime ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _deliveryTime = picked;
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

      final updatedData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _pickupLocationController.text.trim(),
        'budget': double.tryParse(_budgetController.text.trim()),
        'images': _imageUrls,
        'metadata': {
          'pickupLocation': _pickupLocationController.text.trim(),
          'deliveryLocation': _deliveryLocationController.text.trim(),
          'packageSize': _packageSize,
          'pickupTime': _pickupTime,
          'deliveryTime': _deliveryTime,
          'isFragile': _isFragile,
          'requiresSignature': _requiresSignature,
          'specialInstructions': _specialInstructionsController.text.trim(),
          'itemDescription': _itemDescriptionController.text.trim(),
        },
        'updatedAt': DateTime.now(),
      };

      await _requestService.updateRequest(widget.request.id, updatedData);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery request updated successfully!'),
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
    _pickupLocationController.dispose();
    _deliveryLocationController.dispose();
    _budgetController.dispose();
    _specialInstructionsController.dispose();
    _itemDescriptionController.dispose();
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
        title: const Text('Edit Delivery Request'),
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
            _buildSectionTitle('Basic Information'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Delivery Title',
                hintText: 'What needs to be delivered?',
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter delivery title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                hintText: 'Describe the delivery requirements...',
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

            _buildSectionTitle('Package Details'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _itemDescriptionController,
              decoration: InputDecoration(
                labelText: 'Item Description',
                hintText: 'What is being delivered?',
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please describe the item';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _packageSize,
                    decoration: InputDecoration(
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
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
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
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CheckboxListTile(
                      title: const Text('Fragile'),
                      value: _isFragile,
                      onChanged: (value) {
                        setState(() {
                          _isFragile = value!;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: CheckboxListTile(
                      title: const Text('Signature'),
                      value: _requiresSignature,
                      onChanged: (value) {
                        setState(() {
                          _requiresSignature = value!;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Item Images'),
            const SizedBox(height: 12),
            ImageUploadWidget(
              initialImages: _imageUrls,
              maxImages: 4,
              uploadPath: 'requests/delivery',
              label: 'Upload item photos (up to 4)',
              onImagesChanged: (images) {
                setState(() {
                  _imageUrls = images;
                });
              },
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Pickup & Delivery'),
            const SizedBox(height: 12),
            LocationPickerWidget(
              controller: _pickupLocationController,
              labelText: 'Pickup Location',
              hintText: 'Where should we pick up?',
              isRequired: true,
              onLocationSelected: (address, lat, lng) {
                print('Pickup location: $address at $lat, $lng');
              },
            ),
            const SizedBox(height: 16),
            LocationPickerWidget(
              controller: _deliveryLocationController,
              labelText: 'Delivery Location',
              hintText: 'Where should we deliver?',
              isRequired: true,
              onLocationSelected: (address, lat, lng) {
                print('Delivery location: $address at $lat, $lng');
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      title: Text(_pickupTime == null 
                        ? 'Pickup Time' 
                        : 'Pickup: ${_pickupTime!.day}/${_pickupTime!.month}'),
                      trailing: const Icon(Icons.access_time),
                      onTap: _selectPickupTime,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      title: Text(_deliveryTime == null 
                        ? 'Delivery Time' 
                        : 'Deliver: ${_deliveryTime!.day}/${_deliveryTime!.month}'),
                      trailing: const Icon(Icons.access_time),
                      onTap: _selectDeliveryTime,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _specialInstructionsController,
              decoration: InputDecoration(
                labelText: 'Special Instructions (Optional)',
                hintText: 'Any special handling or delivery instructions...',
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 32),

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
                        'Update Delivery Request',
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
