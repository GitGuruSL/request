import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
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

  // Google Maps Controller
  GoogleMapController? _mapController;

  // Form Controllers
  final _priceController = TextEditingController();
  final _messageController = TextEditingController();
  
  String _vehicleType = 'Sedan';
  bool _smokingAllowed = false;
  bool _petsAllowed = true;
  DateTime? _departureTime;
  int _availableSeats = 3;
  List<String> _imageUrls = [];

  bool _isLoading = false;
  bool _isLoadingLocation = false;
  
  // Location data
  Position? _currentPosition;
  LatLng? _pickupLocation;
  LatLng? _dropoffLocation;
  String _pickupAddress = '';
  String _dropoffAddress = '';
  double _distanceKm = 0.0;
  double _distanceFromDriver = 0.0;
  double _estimatedAmount = 0.0;
  
  // Contact details
  String _requesterName = '';
  String _requesterPhone = '';

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
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await _requestLocationPermission();
    await _getCurrentLocation();
    _extractRequestData();
    _loadRequesterDetails();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isDenied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location permission is required for ride services'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      _currentPosition = await Geolocator.getCurrentPosition();
      
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _extractRequestData() {
    // Extract pickup and dropoff from request data
    final pickupLat = widget.request.location?.latitude;
    final pickupLng = widget.request.location?.longitude;
    if (pickupLat != null && pickupLng != null) {
      _pickupLocation = LatLng(pickupLat, pickupLng);
      _pickupAddress = widget.request.location?.address ?? 'Pickup Location';
    }

    final destination = widget.request.typeSpecificData['destination'];
    final destLat = widget.request.typeSpecificData['destinationLatitude'];
    final destLng = widget.request.typeSpecificData['destinationLongitude'];
    
    if (destLat != null && destLng != null) {
      _dropoffLocation = LatLng(destLat.toDouble(), destLng.toDouble());
      _dropoffAddress = destination ?? 'Destination';
    }

    _calculateDistances();
  }

  void _calculateDistances() {
    if (_pickupLocation != null && _dropoffLocation != null) {
      _distanceKm = _calculateDistance(
        _pickupLocation!.latitude,
        _pickupLocation!.longitude,
        _dropoffLocation!.latitude,
        _dropoffLocation!.longitude,
      );
    }

    if (_currentPosition != null && _pickupLocation != null) {
      _distanceFromDriver = _calculateDistance(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        _pickupLocation!.latitude,
        _pickupLocation!.longitude,
      );
    }

    _calculateEstimatedAmount();
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth's radius in kilometers
    double dLat = (lat2 - lat1) * (math.pi / 180);
    double dLon = (lon2 - lon1) * (math.pi / 180);
    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * (math.pi / 180)) *
            math.cos(lat2 * (math.pi / 180)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  void _calculateEstimatedAmount() {
    // Base fare calculation: $2 base + $1.5 per km + time factor
    double baseFare = 2.0;
    double perKmRate = 1.5;
    double timeFactor = 1.0; // Could be dynamic based on time of day
    
    _estimatedAmount = baseFare + (_distanceKm * perKmRate * timeFactor);
    
    // Update price controller with estimated amount
    if (_priceController.text.isEmpty) {
      _priceController.text = _estimatedAmount.toStringAsFixed(2);
    }
    
    setState(() {});
  }

  Future<void> _loadRequesterDetails() async {
    try {
      final requester = await _userService.getUserById(widget.request.requesterId);
      if (requester != null) {
        setState(() {
          _requesterName = requester.name ?? 'Unknown User';
          _requesterPhone = requester.phoneNumber ?? '';
        });
      }
    } catch (e) {
      print('Error loading requester details: $e');
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _priceController.dispose();
    _locationController.dispose();
    _vehicleDetailsController.dispose();
    _drivingExperienceController.dispose();
    _messageController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch phone app')),
      );
    }
  }

  void _openNavigation(LatLng location) {
    final url = 'https://www.google.com/maps/dir/?api=1&destination=${location.latitude},${location.longitude}';
    launchUrl(Uri.parse(url));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Ride Offer'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // Map Section
            Container(
              height: 300,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: _isLoadingLocation
                  ? const Center(child: CircularProgressIndicator())
                  : (_currentPosition == null)
                      ? Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFFAFAFA),
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.location_off, size: 50, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Location not available'),
                              ],
                            ),
                          ),
                        )
                      : ClipRRect(
                          borderRadius: const BorderRadius.all(Radius.circular(12)),
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _pickupLocation ?? LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                              zoom: 12,
                            ),
                            markers: {
                              if (_currentPosition != null)
                                Marker(
                                  markerId: const MarkerId('driver'),
                                  position: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                                  infoWindow: const InfoWindow(title: 'Your Location'),
                                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                                ),
                              if (_pickupLocation != null)
                                Marker(
                                  markerId: const MarkerId('pickup'),
                                  position: _pickupLocation!,
                                  infoWindow: InfoWindow(title: 'Pickup', snippet: _pickupAddress),
                                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
                                ),
                              if (_dropoffLocation != null)
                                Marker(
                                  markerId: const MarkerId('dropoff'),
                                  position: _dropoffLocation!,
                                  infoWindow: InfoWindow(title: 'Drop-off', snippet: _dropoffAddress),
                                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                                ),
                            },
                            onMapCreated: (GoogleMapController controller) {
                              _mapController = controller;
                            },
                            myLocationEnabled: true,
                            myLocationButtonEnabled: false,
                          ),
                        ),
            ),
            const SizedBox(height: 16),
            
            // Location Details Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: Column(
                children: [
                  // Pickup Location
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.my_location, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _pickupAddress.isNotEmpty ? _pickupAddress : 'Pickup Location',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (_pickupLocation != null)
                        IconButton(
                          onPressed: () => _openNavigation(_pickupLocation!),
                          icon: const Icon(Icons.navigation, color: Colors.blue),
                          tooltip: 'Navigate to pickup',
                        ),
                    ],
                  ),
                  
                  // Drop-off Location
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on, color: Colors.white, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _dropoffAddress.isNotEmpty ? _dropoffAddress : 'Drop-off Location',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (_dropoffLocation != null)
                        IconButton(
                          onPressed: () => _openNavigation(_dropoffLocation!),
                          icon: const Icon(Icons.navigation, color: Colors.blue),
                          tooltip: 'Navigate to destination',
                        ),
                    ],
                  ),
                  
                  // Distance Info
                  if (_distanceKm > 0) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFAFAFA),
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Distance: ${_distanceKm.toStringAsFixed(1)} km',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Estimated time: ${(_distanceKm * 2).toInt()} min',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_distanceFromDriver > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.my_location, size: 16, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              'Distance from your location: ${_distanceFromDriver.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Passengers and Price
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trip Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Available Seats
                  Row(
                    children: [
                      const Icon(Icons.people, color: Colors.blue),
                      const SizedBox(width: 12),
                      const Text('Available Seats: '),
                      Text(
                        '$_availableSeats',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          IconButton(
                            onPressed: _availableSeats > 1 ? () {
                              setState(() {
                                _availableSeats--;
                              });
                            } : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          IconButton(
                            onPressed: _availableSeats < 6 ? () {
                              setState(() {
                                _availableSeats++;
                              });
                            } : null,
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Price
                  TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: CurrencyHelper.instance.getPriceLabel(),
                      hintText: _estimatedAmount > 0 ? _estimatedAmount.toStringAsFixed(2) : '0.00',
                      prefixText: CurrencyHelper.instance.getCurrencyPrefix(),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
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
                  if (_estimatedAmount > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Suggested price: ${CurrencyHelper.instance.formatPrice(_estimatedAmount)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Requester Contact
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Requester',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          // TODO: Show driver profile modal
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile view coming soon'),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          backgroundColor: const Color(0xFF64B5F6),
                          child: Text(
                            _requesterName.isNotEmpty ? _requesterName[0].toUpperCase() : 'R',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _requesterName.isNotEmpty ? _requesterName : 'Requester',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            const Text(
                              'Tap profile to view details',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_requesterPhone.isNotEmpty)
                        IconButton(
                          onPressed: () => _makePhoneCall(_requesterPhone),
                          icon: const Icon(Icons.phone, color: Colors.green),
                          tooltip: 'Call Requester',
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Message to Requester (Optional)',
                      hintText: 'Add a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      filled: true,
                      fillColor: Color(0xFFFAFAFA),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitResponse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF64B5F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Submitting...'),
                        ],
                      )
                    : const Text(
                        'Submit Ride Offer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
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
