import 'package:flutter/material.dart';
import '../../../models/request_model.dart';
import '../../../models/enhanced_user_model.dart';
import '../../../services/enhanced_request_service.dart';
import '../../../services/enhanced_user_service.dart';
import '../../../widgets/image_upload_widget.dart';
import '../../../widgets/accurate_location_picker_widget.dart';
import '../../../utils/currency_helper.dart';

class CreateRideResponseScreen extends StatefulWidget {
  final RequestModel request;
  
  const CreateRideResponseScreen({
    super.key,
    required this.request,
  });

  @override
  State<CreateRideResponseScreen> createState() => _CreateRideResponseScreenState();
}

class _CreateRideResponseScreenState extends State<CreateRideResponseScreen> {
  final _formKey = GlobalKey<FormState>();
  final EnhancedRequestService _requestService = EnhancedRequestService();
  final EnhancedUserService _userService = EnhancedUserService();

  // Form Controllers
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _locationController = TextEditingController();
  final _vehicleDetailsController = TextEditingController();
  final _drivingExperienceController = TextEditingController();
  
  String _vehicleType = 'Sedan';
  bool _smokingAllowed = false;
  bool _petsAllowed = true;
  DateTime? _departureTime;
  int _availableSeats = 3;
  List<String> _imageUrls = [];

  bool _isLoading = false;

  final List<String> _vehicleTypes = [
    'Sedan',
    'SUV',
    'Hatchback',
    'Van',
    'Truck',
    'Coupe',
    'Convertible',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _vehicleDetailsController.dispose();
    _drivingExperienceController.dispose();
    super.dispose();
  }

  Future<void> _selectDepartureTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      
      if (pickedTime != null) {
        setState(() {
          _departureTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _submitResponse() async {
    if (!_formKey.currentState!.validate()) return;

    if (_departureTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select departure time')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _userService.getCurrentUserModel();
      if (user == null) {
        throw Exception('User not logged in');
      }

      final responseData = {
        'description': _descriptionController.text.trim(),
        'price': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'currency': CurrencyHelper.instance.getCurrency(),
        'location': _locationController.text.trim(),
        'images': _imageUrls,
        'metadata': {
          'vehicleDetails': _vehicleDetailsController.text.trim(),
          'vehicleType': _vehicleType,
          'availableSeats': _availableSeats,
          'departureTime': _departureTime,
          'smokingAllowed': _smokingAllowed,
          'petsAllowed': _petsAllowed,
          'drivingExperience': _drivingExperienceController.text.trim(),
          'pickupLocation': widget.request.location?.address ?? '',
          'destination': widget.request.typeSpecificData['destination'] ?? '',
        },
      };

      await _requestService.createResponse(
        requestId: widget.request.id,
        message: _descriptionController.text,
        price: double.tryParse(_priceController.text.trim()),
        currency: widget.request.currency ?? 'USD',
        availableFrom: DateTime.now(),
        images: _imageUrls,
        additionalInfo: {
          'vehicleType': _vehicleType,
          'destination': widget.request.typeSpecificData['destination'] ?? '',
        },
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride offer submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting offer: $e'),
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
        title: const Text('Offer Ride'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submitResponse,
            child: _isLoading 
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Original Request Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
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
                    Text(CurrencyHelper.instance.formatPrice(widget.request.budget!),
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                  if (widget.request.location != null) ...[
                    const SizedBox(height: 4),
                    Text('Pickup: ${widget.request.location!.address}',
                      style: const TextStyle(fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Your Ride Offer'),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Ride Description',
                hintText: 'Describe your ride offer...',
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please describe your ride offer';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _drivingExperienceController,
              decoration: InputDecoration(
                labelText: 'Driving Experience',
                hintText: 'Years of driving, safety record, etc.',
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

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
                    value: _vehicleType,
                    decoration: InputDecoration(
                      labelText: 'Vehicle Type',
                      filled: true,
                      fillColor: Colors.white,
                      border: InputBorder.none,
                    ),
                    items: _vehicleTypes.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _vehicleType = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _vehicleDetailsController,
              decoration: InputDecoration(
                labelText: 'Vehicle Details',
                hintText: 'Make, model, year, color, license plate...',
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please provide vehicle details';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Trip Details'),
            const SizedBox(height: 12),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                title: Text(_departureTime == null 
                  ? 'Select Departure Time' 
                  : 'Departure: ${_departureTime!.day}/${_departureTime!.month} at ${_departureTime!.hour}:${_departureTime!.minute.toString().padLeft(2, '0')}'),
                trailing: const Icon(Icons.access_time),
                onTap: _selectDepartureTime,
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available Seats: $_availableSeats',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Slider(
                    value: _availableSeats.toDouble(),
                    min: 1,
                    max: 6,
                    divisions: 5,
                    onChanged: (value) {
                      setState(() {
                        _availableSeats = value.toInt();
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Ride Preferences'),
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
                    title: const Text('Smoking Allowed'),
                    subtitle: const Text('Passengers can smoke in the vehicle'),
                    value: _smokingAllowed,
                    onChanged: (value) {
                      setState(() {
                        _smokingAllowed = value!;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: const Text('Pets Allowed'),
                    subtitle: const Text('Passengers can bring pets'),
                    value: _petsAllowed,
                    onChanged: (value) {
                      setState(() {
                        _petsAllowed = value!;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Vehicle & Driver Images'),
            const SizedBox(height: 12),
            ImageUploadWidget(
              initialImages: _imageUrls,
              maxImages: 4,
              uploadPath: 'responses/ride',
              label: 'Upload vehicle & driver photos (up to 4)',
              onImagesChanged: (images) {
                setState(() {
                  _imageUrls = images;
                });
              },
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Your Location'),
            const SizedBox(height: 12),
            AccurateLocationPickerWidget(
              controller: _locationController,
              labelText: 'Your Current Location',
              hintText: 'Where are you located?',
              isRequired: true,
              onLocationSelected: (address, lat, lng) {
                print('Driver location: $address at $lat, $lng');
              },
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitResponse,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.orange[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Submit Ride Offer',
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
