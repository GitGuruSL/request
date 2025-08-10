import 'package:flutter/material.dart';
import '../../../models/request_model.dart';
import '../../../models/enhanced_user_model.dart';
import '../../../services/enhanced_request_service.dart';
import '../../../services/enhanced_user_service.dart';
import '../../../widgets/image_upload_widget.dart';
import '../../../widgets/location_picker_widget.dart';
import '../../../utils/currency_helper.dart';

class CreateDeliveryResponseScreen extends StatefulWidget {
  final RequestModel request;
  
  const CreateDeliveryResponseScreen({
    super.key,
    required this.request,
  });

  @override
  State<CreateDeliveryResponseScreen> createState() => _CreateDeliveryResponseScreenState();
}

class _CreateDeliveryResponseScreenState extends State<CreateDeliveryResponseScreen> {
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
    // Initialize location from request if available
    if (widget.request.location != null) {
      _locationController.text = widget.request.location!;
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _availableDate = picked;
      });
    }
  }

  Future<void> _submitResponse() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _userService.getCurrentUser();
      if (user == null) {
        throw Exception('User not logged in');
      }

      // Create response data
      final responseData = {
        'requestId': widget.request.id,
        'requesterId': widget.request.userId,
        'responderId': user.uid,
        'responderName': user.businessName ?? user.displayName,
        'responderPhone': user.phoneNumber,
        'description': _descriptionController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'location': _locationController.text.trim(),
        'vehicleDetails': _vehicleDetailsController.text.trim(),
        'experience': _experienceController.text.trim(),
        'deliveryType': _deliveryType,
        'insured': _insured,
        'availableDate': _availableDate,
        'images': _imageUrls,
        'status': 'pending',
        'createdAt': DateTime.now(),
        'type': 'delivery',
      };

      await _requestService.createResponse(responseData);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery response submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting response: $e'),
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
        title: const Text('Respond to Delivery Request'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Request Summary
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
                    'Delivery Request',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(widget.request.title, 
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (widget.request.description != null) ...[
                    const SizedBox(height: 4),
                    Text(widget.request.description!),
                  ],
                  if (widget.request.budget != null) ...[
                    const SizedBox(height: 4),
                    Text('Budget: ${CurrencyHelper.instance.formatPrice(widget.request.budget!)}'),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Delivery Service Details
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

            // Service Terms
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

            // Vehicle Images
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

            // Service Location
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

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitResponse,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Submit Delivery Response',
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
