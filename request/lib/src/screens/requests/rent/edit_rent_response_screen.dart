import 'package:flutter/material.dart';
import '../../../models/request_model.dart';
import '../../../models/response_model.dart';
import '../../../models/enhanced_user_model.dart';
import '../../../services/enhanced_request_service.dart';
import '../../../services/enhanced_user_service.dart';
import '../../../widgets/image_upload_widget.dart';
import '../../../widgets/location_picker_widget.dart';
import '../../../utils/currency_helper.dart';

class EditRentResponseScreen extends StatefulWidget {
  final ResponseModel response;
  final RequestModel? originalRequest;
  
  const EditRentResponseScreen({
    super.key,
    required this.response,
    this.originalRequest,
  });

  @override
  State<EditRentResponseScreen> createState() => _EditRentResponseScreenState();
}

class _EditRentResponseScreenState extends State<EditRentResponseScreen> {
  final _formKey = GlobalKey<FormState>();
  final EnhancedRequestService _requestService = EnhancedRequestService();
  final EnhancedUserService _userService = EnhancedUserService();

  // Form Controllers
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _itemDetailsController = TextEditingController();
  final _termsController = TextEditingController();
  
  String _condition = 'Excellent';
  String _availabilityType = 'Available Now';
  bool _deliveryAvailable = true;
  bool _pickupRequired = false;
  DateTime? _availableFrom;
  DateTime? _availableUntil;
  List<String> _imageUrls = [];

  bool _isLoading = false;

  final List<String> _conditions = [
    'New',
    'Excellent',
    'Good',
    'Fair',
    'Used',
  ];

  final List<String> _availabilityTypes = [
    'Available Now',
    'Available Soon',
    'By Appointment',
    'Custom Schedule',
  ];

  @override
  void initState() {
    super.initState();
    _initializeFromResponse();
  }

  void _initializeFromResponse() {
    _descriptionController.text = widget.response.description ?? '';
    _priceController.text = widget.response.price?.toString() ?? '';
    _locationController.text = widget.response.location ?? '';
    _imageUrls = List<String>.from(widget.response.images ?? []);
    
    if (widget.response.metadata != null) {
      final metadata = widget.response.metadata!;
      _itemDetailsController.text = metadata['itemDetails'] ?? '';
      _termsController.text = metadata['terms'] ?? '';
      _condition = metadata['condition'] ?? 'Excellent';
      _availabilityType = metadata['availabilityType'] ?? 'Available Now';
      _deliveryAvailable = metadata['deliveryAvailable'] ?? true;
      _pickupRequired = metadata['pickupRequired'] ?? false;
      
      if (metadata['availableFrom'] != null) {
        _availableFrom = metadata['availableFrom'] is DateTime 
          ? metadata['availableFrom']
          : DateTime.tryParse(metadata['availableFrom'].toString());
      }
      
      if (metadata['availableUntil'] != null) {
        _availableUntil = metadata['availableUntil'] is DateTime 
          ? metadata['availableUntil']
          : DateTime.tryParse(metadata['availableUntil'].toString());
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _itemDetailsController.dispose();
    _termsController.dispose();
    super.dispose();
  }

  Future<void> _selectAvailabilityDate({required bool isFromDate}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate 
        ? (_availableFrom ?? DateTime.now())
        : (_availableUntil ?? (_availableFrom ?? DateTime.now()).add(const Duration(days: 1))),
      firstDate: isFromDate 
        ? DateTime.now()
        : (_availableFrom ?? DateTime.now()),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _availableFrom = picked;
          // Reset end date if it's before the new start date
          if (_availableUntil != null && _availableUntil!.isBefore(picked)) {
            _availableUntil = null;
          }
        } else {
          _availableUntil = picked;
        }
      });
    }
  }

  Future<void> _updateResponse() async {
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
        'description': _descriptionController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'location': _locationController.text.trim(),
        'images': _imageUrls,
        'metadata': {
          'itemDetails': _itemDetailsController.text.trim(),
          'condition': _condition,
          'availabilityType': _availabilityType,
          'deliveryAvailable': _deliveryAvailable,
          'pickupRequired': _pickupRequired,
          'availableFrom': _availableFrom,
          'availableUntil': _availableUntil,
          'terms': _termsController.text.trim(),
        },
        'updatedAt': DateTime.now(),
      };

      await _requestService.updateResponse(widget.response.id, updatedData);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rental offer updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating offer: $e'),
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
        title: const Text('Edit Rental Offer'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updateResponse,
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
            if (widget.originalRequest != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.indigo[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.indigo[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Original Request',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.originalRequest!.title, 
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (widget.originalRequest!.description != null) ...[
                      const SizedBox(height: 4),
                      Text(widget.originalRequest!.description!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            _buildSectionTitle('Your Rental Offer'),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Rental Description',
                hintText: 'Describe what you\'re offering to rent...',
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please describe your rental offer';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _itemDetailsController,
              decoration: InputDecoration(
                labelText: 'Item Details',
                hintText: 'Brand, model, specifications, etc.',
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please provide item details';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _condition,
                    decoration: InputDecoration(
                      labelText: 'Condition',
                      filled: true,
                      fillColor: Colors.white,
                      border: InputBorder.none,
                    ),
                    items: _conditions.map((condition) {
                      return DropdownMenuItem(
                        value: condition,
                        child: Text(condition),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _condition = value!;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _availabilityType,
                    decoration: InputDecoration(
                      labelText: 'Availability',
                      filled: true,
                      fillColor: Colors.white,
                      border: InputBorder.none,
                    ),
                    items: _availabilityTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _availabilityType = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Pricing & Terms'),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: CurrencyHelper.instance.getPriceLabel('Rental Price'),
                hintText: '0.00',
                prefixText: CurrencyHelper.instance.getCurrencyPrefix(),
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter your rental price';
                }
                final price = double.tryParse(value.trim());
                if (price == null || price <= 0) {
                  return 'Please enter a valid price';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _termsController,
              decoration: InputDecoration(
                labelText: 'Rental Terms & Conditions',
                hintText: 'Security deposit, usage rules, etc.',
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Availability Period'),
            const SizedBox(height: 12),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title: Text(_availableFrom == null 
                  ? 'Available From' 
                  : 'From: ${_availableFrom!.day}/${_availableFrom!.month}/${_availableFrom!.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () => _selectAvailabilityDate(isFromDate: true),
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title: Text(_availableUntil == null 
                  ? 'Available Until' 
                  : 'Until: ${_availableUntil!.day}/${_availableUntil!.month}/${_availableUntil!.year}'),
                trailing: const Icon(Icons.event),
                onTap: () => _selectAvailabilityDate(isFromDate: false),
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Delivery Options'),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  CheckboxListTile(
                    title: const Text('Delivery Available'),
                    subtitle: const Text('I can deliver to the renter'),
                    value: _deliveryAvailable,
                    onChanged: (value) {
                      setState(() {
                        _deliveryAvailable = value!;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: const Text('Pickup Required'),
                    subtitle: const Text('Renter must pick up from my location'),
                    value: _pickupRequired,
                    onChanged: (value) {
                      setState(() {
                        _pickupRequired = value!;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Item Images'),
            const SizedBox(height: 12),
            ImageUploadWidget(
              initialImages: _imageUrls,
              maxImages: 4,
              uploadPath: 'responses/rent',
              label: 'Upload item photos (up to 4)',
              onImagesChanged: (images) {
                setState(() {
                  _imageUrls = images;
                });
              },
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Pickup/Delivery Location'),
            const SizedBox(height: 12),
            LocationPickerWidget(
              controller: _locationController,
              labelText: 'Item Location',
              hintText: 'Where is the item located?',
              isRequired: true,
              onLocationSelected: (address, lat, lng) {
                print('Rent item location: $address at $lat, $lng');
              },
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateResponse,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.indigo[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Update Rental Offer',
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
