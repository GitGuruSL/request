import 'package:flutter/material.dart';
import '../../../models/request_model.dart';
import '../../../models/enhanced_user_model.dart';
import '../../../services/enhanced_request_service.dart';
import '../../../services/enhanced_user_service.dart';
import '../../../widgets/image_upload_widget.dart';
import '../../../widgets/location_picker_widget.dart';
import '../../../utils/currency_helper.dart';

class EditRideRequestScreen extends StatefulWidget {
  final RequestModel request;
  
  const EditRideRequestScreen({
    super.key,
    required this.request,
  });

  @override
  State<EditRideRequestScreen> createState() => _EditRideRequestScreenState();
}

class _EditRideRequestScreenState extends State<EditRideRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final EnhancedRequestService _requestService = EnhancedRequestService();
  final EnhancedUserService _userService = EnhancedUserService();

  // Form Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pickupLocationController = TextEditingController();
  final _destinationController = TextEditingController();
  final _budgetController = TextEditingController();
  
  // Ride-specific fields
  String _rideType = 'Regular';
  DateTime? _departureTime;
  int _passengerCount = 1;
  bool _allowSharing = true;
  final _specialRequestsController = TextEditingController();
  List<String> _imageUrls = [];

  bool _isLoading = false;

  final List<String> _rideTypes = [
    'Regular',
    'Premium',
    'Shared',
    'Airport Transfer',
  ];

  @override
  void initState() {
    super.initState();
    _initializeFromRequest();
  }

  void _initializeFromRequest() {
    _titleController.text = widget.request.title;
    _descriptionController.text = widget.request.description ?? '';
    _pickupLocationController.text = widget.request.location?.address ?? '';
    _budgetController.text = widget.request.budget?.toString() ?? '';
    _imageUrls = List<String>.from(widget.request.images ?? []);
    
    if (widget.request.metadata != null) {
      final metadata = widget.request.metadata!;
      _rideType = metadata['rideType'] ?? 'Regular';
      _passengerCount = metadata['passengerCount'] ?? 1;
      _allowSharing = metadata['allowSharing'] ?? true;
      _specialRequestsController.text = metadata['specialRequests'] ?? '';
      _destinationController.text = metadata['destination'] ?? '';
      
      if (metadata['departureTime'] != null) {
        _departureTime = metadata['departureTime'] is DateTime 
          ? metadata['departureTime']
          : DateTime.tryParse(metadata['departureTime'].toString());
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _pickupLocationController.dispose();
    _destinationController.dispose();
    _budgetController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _departureTime ?? DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: _departureTime != null 
          ? TimeOfDay.fromDateTime(_departureTime!)
          : TimeOfDay.now(),
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

  Future<void> _updateRequest() async {
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
      final user = await _userService.getCurrentUser();
      if (user == null) {
        throw Exception('User not logged in');
      }

      final updatedData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'budget': double.tryParse(_budgetController.text.trim()),
        'location': {
          'address': _pickupLocationController.text.trim(),
          'latitude': 0.0, // Will be updated by LocationPicker
          'longitude': 0.0,
        },
        'images': _imageUrls,
        'metadata': {
          'rideType': _rideType,
          'departureTime': _departureTime,
          'passengerCount': _passengerCount,
          'allowSharing': _allowSharing,
          'specialRequests': _specialRequestsController.text.trim(),
          'destination': _destinationController.text.trim(),
        },
        'updatedAt': DateTime.now(),
      };

      await _requestService.updateRequest(widget.request.id, updatedData);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride request updated successfully!'),
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
        title: const Text('Edit Ride Request'),
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
            _buildSectionTitle('Trip Details'),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Trip Title',
                hintText: 'e.g., Airport to Downtown, Daily Commute',
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a trip title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            LocationPickerWidget(
              controller: _pickupLocationController,
              labelText: 'Pickup Location',
              hintText: 'Where should the driver pick you up?',
              isRequired: true,
              onLocationSelected: (address, lat, lng) {
                print('Pickup location: $address at $lat, $lng');
              },
            ),
            const SizedBox(height: 16),
            
            LocationPickerWidget(
              controller: _destinationController,
              labelText: 'Destination',
              hintText: 'Where do you want to go?',
              isRequired: true,
              onLocationSelected: (address, lat, lng) {
                print('Destination: $address at $lat, $lng');
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Additional Notes (Optional)',
                hintText: 'Any special instructions or preferences...',
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Ride Preferences'),
            const SizedBox(height: 12),
            
            DropdownButtonFormField<String>(
              value: _rideType,
              decoration: InputDecoration(
                labelText: 'Ride Type',
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
              ),
              items: _rideTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _rideType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            
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
                onTap: _selectDateTime,
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
                    'Number of Passengers: $_passengerCount',
                    style: const TextStyle(fontSize: 16),
                  ),
                  Slider(
                    value: _passengerCount.toDouble(),
                    min: 1,
                    max: 6,
                    divisions: 5,
                    onChanged: (value) {
                      setState(() {
                        _passengerCount = value.toInt();
                      });
                    },
                  ),
                ],
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
                title: const Text('Allow ride sharing'),
                subtitle: const Text('Other passengers can join this ride'),
                value: _allowSharing,
                onChanged: (value) {
                  setState(() {
                    _allowSharing = value!;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _specialRequestsController,
              decoration: InputDecoration(
                labelText: 'Special Requests (Optional)',
                hintText: 'Pet-friendly, non-smoking, etc...',
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Reference Images'),
            const SizedBox(height: 12),
            ImageUploadWidget(
              initialImages: _imageUrls,
              maxImages: 4,
              uploadPath: 'requests/ride',
              label: 'Upload reference images (optional)',
              onImagesChanged: (images) {
                setState(() {
                  _imageUrls = images;
                });
              },
            ),
            const SizedBox(height: 24),

            _buildSectionTitle('Budget'),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _budgetController,
              decoration: InputDecoration(
                labelText: CurrencyHelper.instance.getPriceLabel('Offered Price'),
                hintText: '0.00',
                prefixText: CurrencyHelper.instance.getCurrencyPrefix(),
                filled: true,
                fillColor: Colors.white,
                border: InputBorder.none,
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updateRequest,
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
                        'Update Ride Request',
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
