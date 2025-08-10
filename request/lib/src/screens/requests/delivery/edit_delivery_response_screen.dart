import 'package:flutter/material.dart';
import '../../../models/request_model.dart';
import '../../../models/response_model.dart';
import '../../../models/enhanced_user_model.dart';
import '../../../services/enhanced_request_service.dart';
import '../../../services/enhanced_user_service.dart';
import '../../../widgets/image_upload_widget.dart';
import '../../../widgets/location_picker_widget.dart';
import '../../../utils/currency_helper.dart';

class EditDeliveryResponseScreen extends StatefulWidget {
  final ResponseModel response;
  final RequestModel? originalRequest;
  
  const EditDeliveryResponseScreen({
    super.key,
    required this.response,
    this.originalRequest,
  });

  @override
  State<EditDeliveryResponseScreen> createState() => _EditDeliveryResponseScreenState();
}

class _EditDeliveryResponseScreenState extends State<EditDeliveryResponseScreen> {
  final _formKey = GlobalKey<FormState>();
  final EnhancedRequestService _requestService = EnhancedRequestService();
  final EnhancedUserService _userService = EnhancedUserService();

  // Form Controllers
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _vehicleDetailsController = TextEditingController();
  final _experienceController = TextEditingController();
  
  String _deliveryType = 'Standard';
  bool _insured = true;
  DateTime? _availableDate;
  List<String> _imageUrls = [];

  bool _isLoading = false;

  final List<String> _deliveryTypes = [
    'Standard',
    'Express',
    'Same Day',
    'Scheduled',
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
      _vehicleDetailsController.text = metadata['vehicleDetails'] ?? '';
      _experienceController.text = metadata['experience'] ?? '';
      _deliveryType = metadata['deliveryType'] ?? 'Standard';
      _insured = metadata['insured'] ?? true;
      
      if (metadata['availableDate'] != null) {
        _availableDate = metadata['availableDate'] is DateTime 
          ? metadata['availableDate']
          : DateTime.tryParse(metadata['availableDate'].toString());
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _availableDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _availableDate = picked;
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
          'vehicleDetails': _vehicleDetailsController.text.trim(),
          'experience': _experienceController.text.trim(),
          'deliveryType': _deliveryType,
          'insured': _insured,
          'availableDate': _availableDate,
        },
        'updatedAt': DateTime.now(),
      };

      await _requestService.updateResponse(widget.response.id, updatedData);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery response updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating response: $e'),
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
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _vehicleDetailsController.dispose();
    _experienceController.dispose();
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
        title: const Text('Edit Delivery Response'),
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
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Original Request',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
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

            _buildSectionTitle('Your Delivery Service'),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Service Description',
                hintText: 'Describe your delivery service...',
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please describe your delivery service';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _vehicleDetailsController,
              decoration: InputDecoration(
                labelText: 'Vehicle Details',
                hintText: 'Your vehicle type, capacity, etc.',
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please provide vehicle details';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _experienceController,
              decoration: InputDecoration(
                labelText: 'Experience',
                hintText: 'Your delivery experience and qualifications...',
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Service Terms'),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: CurrencyHelper.instance.getPriceLabel(),
                      hintText: '0.00',
                      prefixText: CurrencyHelper.instance.getCurrencyPrefix(),
                      filled: true,
                      fillColor: Colors.white,
                      border: InputBorder.none,
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your price';
                      }
                      final price = double.tryParse(value.trim());
                      if (price == null || price <= 0) {
                        return 'Please enter a valid price';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _deliveryType,
                    decoration: InputDecoration(
                      labelText: 'Delivery Type',
                      filled: true,
                      fillColor: Colors.white,
                      border: InputBorder.none,
                    ),
                    items: _deliveryTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _deliveryType = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title: Text(_availableDate == null 
                  ? 'Select Available Date' 
                  : 'Available from: ${_availableDate!.day}/${_availableDate!.month}/${_availableDate!.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDate,
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: CheckboxListTile(
                title: const Text('Insured Delivery'),
                subtitle: const Text('Delivery includes insurance coverage'),
                value: _insured,
                onChanged: (value) {
                  setState(() {
                    _insured = value!;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Vehicle & License Images'),
            const SizedBox(height: 12),
            ImageUploadWidget(
              initialImages: _imageUrls,
              maxImages: 4,
              uploadPath: 'responses/delivery',
              label: 'Upload vehicle photos & license (up to 4)',
              onImagesChanged: (images) {
                setState(() {
                  _imageUrls = images;
                });
              },
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Service Location'),
            const SizedBox(height: 12),
            LocationPickerWidget(
              controller: _locationController,
              labelText: 'Your Service Area',
              hintText: 'Where do you provide delivery services?',
              isRequired: true,
              onLocationSelected: (address, lat, lng) {
                print('Delivery service location: $address at $lat, $lng');
              },
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateResponse,
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
                        'Update Delivery Response',
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
