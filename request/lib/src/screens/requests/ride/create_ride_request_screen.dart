import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:geocoding/geocoding.dart' as geo;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;
import 'dart:async';
import '../../../models/request_model.dart';
import '../../../services/enhanced_request_service.dart';
import '../../../services/enhanced_user_service.dart';
import '../../../models/enhanced_user_model.dart';
import '../../../utils/currency_helper.dart';

enum VehicleType { bike, threewheeler, car, van }

class CreateRideRequestScreen extends StatefulWidget {
  const CreateRideRequestScreen({super.key});

  @override
  State<CreateRideRequestScreen> createState() => _CreateRideRequestScreenState();
}

class _CreateRideRequestScreenState extends State<CreateRideRequestScreen> {
  final EnhancedRequestService _requestService = EnhancedRequestService();
  final EnhancedUserService _userService = EnhancedUserService();
  final Location _location = Location();
  
  // Controllers
  final _pickupController = TextEditingController();
  final _destinationController = TextEditingController();
  final _searchController = TextEditingController();
  
  // Map and Location
  GoogleMapController? _mapController;
  Map<String, double>? _pickupCoordinates;
  Map<String, double>? _destinationCoordinates;
  
  // UI State
  bool _showLocationSearch = false;
  bool _isPickingPickup = true;
  bool _isLoading = false;
  bool _isOneWay = true;
  
  // Trip details
  VehicleType _selectedVehicleType = VehicleType.car;
  int _passengerCount = 1;
  double _estimatedDistance = 0.0;
  DateTime? _scheduledTime;
  bool _isScheduled = false;

  // Search debouncing
  Timer? _searchTimer;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Getting your location...'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location service is disabled. Please enable GPS.')),
            );
          }
          return;
        }
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied. Please grant permission.')),
            );
          }
          return;
        }
      }

      LocationData locationData = await _location.getLocation();
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(
        locationData.latitude!,
        locationData.longitude!,
      );

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks[0];
        final address = '${place.name ?? place.locality ?? 'Current Location'}, ${place.locality ?? place.administrativeArea ?? ''}';
        setState(() {
          _pickupController.text = address;
          _pickupCoordinates = {
            'latitude': locationData.latitude!,
            'longitude': locationData.longitude!,
          };
        });
        
        if (_mapController != null) {
          _mapController!.animateCamera(
            CameraUpdate.newLatLng(
              LatLng(locationData.latitude!, locationData.longitude!),
            ),
          );
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Current location set as pickup'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error getting current location: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: ${e.toString()}')),
        );
      }
    }
  }

  void _debouncedSearch(String query) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isNotEmpty && query.length > 2) {
        _geocodeAddress(query);
      }
    });
  }

  Future<void> _geocodeAddress(String address) async {
    if (address.trim().isEmpty) return;
    try {
      final locations = await geo.locationFromAddress(address);
      if (!mounted) return;
      if (locations.isNotEmpty) {
        final location = locations.first;
        _selectLocation(address, location.latitude, location.longitude);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No results for "$address"')),
        );
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not find location: $address')),
      );
    }
  }

  void _selectLocation(String address, double lat, double lng) {
    setState(() {
      if (_isPickingPickup) {
        _pickupController.text = address;
        _pickupCoordinates = {'latitude': lat, 'longitude': lng};
      } else {
        _destinationController.text = address;
        _destinationCoordinates = {'latitude': lat, 'longitude': lng};
      }
      _showLocationSearch = false;
      _updateEstimatedDistance();
    });
    
    // Update map camera
    if (_mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(LatLng(lat, lng)),
      );
    }
  }

  void _updateEstimatedDistance() {
    if (_pickupCoordinates != null && _destinationCoordinates != null) {
      final distance = _calculateDistance(_pickupCoordinates!, _destinationCoordinates!);
      setState(() {
        _estimatedDistance = distance;
      });
    }
  }

  double _calculateDistance(Map<String, double> from, Map<String, double> to) {
    const double earthRadius = 6371;
    
    double lat1Rad = from['latitude']! * (math.pi / 180);
    double lat2Rad = to['latitude']! * (math.pi / 180);
    double deltaLatRad = (to['latitude']! - from['latitude']!) * (math.pi / 180);
    double deltaLngRad = (to['longitude']! - from['longitude']!) * (math.pi / 180);

    double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  Future<void> _submitRequest() async {
    if (_pickupCoordinates == null || _destinationCoordinates == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select pickup and destination locations')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if user has verified phone number
      final currentUser = await _userService.getCurrentUserModel();
      if (currentUser == null || !currentUser.isPhoneVerified) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please verify your phone number to create requests'),
            ),
          );
        }
        return;
      }

      final description = '''
Ride Request Details:
- From: ${_pickupController.text}
- To: ${_destinationController.text}
- Distance: ${_estimatedDistance.toStringAsFixed(1)} km
- Vehicle: ${_selectedVehicleType.name}
- Passengers: $_passengerCount
- Trip Type: ${_isOneWay ? 'One way' : 'Return trip'}
- ${_isScheduled ? 'Scheduled for: ${_scheduledTime.toString()}' : 'Needed: Now'}

Pickup Coordinates: ${_pickupCoordinates!['latitude']}, ${_pickupCoordinates!['longitude']}
Destination Coordinates: ${_destinationCoordinates!['latitude']}, ${_destinationCoordinates!['longitude']}
''';

      // Create ride-specific data with pickup and destination info in specialRequests
      final rideData = RideRequestData(
        passengers: _passengerCount,
        preferredTime: _scheduledTime ?? DateTime.now().add(const Duration(minutes: 15)),
        isFlexibleTime: !_isScheduled,
        vehicleType: _selectedVehicleType.name,
        needsWheelchairAccess: false,
        allowSmoking: false,
        petsAllowed: false,
        specialRequests: '''
Trip Details:
- Trip Type: ${_isOneWay ? 'One way' : 'Return trip'}
- Distance: ${_estimatedDistance.toStringAsFixed(1)} km
- Pickup: ${_pickupController.text}
- Destination: ${_destinationController.text}
- Pickup Coords: ${_pickupCoordinates!['latitude']}, ${_pickupCoordinates!['longitude']}
- Destination Coords: ${_destinationCoordinates!['latitude']}, ${_destinationCoordinates!['longitude']}
''',
      );

      await _requestService.createRequest(
        title: 'Ride from ${_pickupController.text.split(',')[0]} to ${_destinationController.text.split(',')[0]}',
        description: description,
        type: RequestType.ride,
        budget: null,
        currency: CurrencyHelper.instance.getCurrency(),
        typeSpecificData: rideData.toMap(),
        tags: ['ride', _selectedVehicleType.name],
        location: LocationInfo(
          latitude: _pickupCoordinates!['latitude']!,
          longitude: _pickupCoordinates!['longitude']!,
          address: _pickupController.text,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ride request created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating ride request: $e')),
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
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          // Google Map
          _buildMap(),
          
          // Top App Bar
          _buildTopBar(),
          
          // Bottom Sheet with Location Inputs
          if (!_showLocationSearch) _buildBottomSheet(),
          
          // Location Search Overlay
          if (_showLocationSearch) _buildLocationSearch(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _pickupCoordinates != null 
            ? LatLng(_pickupCoordinates!['latitude']!, _pickupCoordinates!['longitude']!)
            : const LatLng(6.9271, 79.8612), // Colombo default
        zoom: 14.0,
      ),
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
      },
      markers: _buildMarkers(),
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
    );
  }

  Set<Marker> _buildMarkers() {
    Set<Marker> markers = {};
    
    if (_pickupCoordinates != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(_pickupCoordinates!['latitude']!, _pickupCoordinates!['longitude']!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Pickup Location'),
        ),
      );
    }
    
    if (_destinationCoordinates != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(_destinationCoordinates!['latitude']!, _destinationCoordinates!['longitude']!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: 'Destination'),
        ),
      );
    }
    
    return markers;
  }

  Widget _buildTopBar() {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Text(
              'Book a ride',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.my_location, size: 20, color: Colors.blue),
              onPressed: _getCurrentLocation,
              padding: EdgeInsets.zero,
              tooltip: 'Get current location',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, -5),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Trip type toggle
                  _buildTripTypeToggle(),
                  const SizedBox(height: 20),
                  
                  // Location inputs
                  _buildLocationInputs(),
                  const SizedBox(height: 20),
                  
                  // Distance info
                  if (_estimatedDistance > 0) _buildDistanceInfo(),
                  
                  // Vehicle selection
                  if (_estimatedDistance > 0) _buildVehicleSelection(),
                  
                  // Passenger count
                  if (_estimatedDistance > 0) _buildPassengerCount(),
                  
                  // Schedule option
                  if (_estimatedDistance > 0) _buildScheduleOption(),
                  
                  const SizedBox(height: 20),
                  
                  // Book ride button
                  if (_estimatedDistance > 0) _buildBookButton(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTripTypeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isOneWay = true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isOneWay ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: _isOneWay ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Text(
                  'One way',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isOneWay ? Colors.black : Colors.grey[600],
                    fontWeight: _isOneWay ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isOneWay = false),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isOneWay ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: !_isOneWay ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Text(
                  'Return trip',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: !_isOneWay ? Colors.black : Colors.grey[600],
                    fontWeight: !_isOneWay ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationInputs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Pickup
          ListTile(
            leading: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            title: Text(
              'PICKUP',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              _pickupController.text.isEmpty ? 'Your Location' : _pickupController.text,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
            trailing: const Icon(Icons.favorite_border, size: 20),
            onTap: () {
              setState(() {
                _isPickingPickup = true;
                _showLocationSearch = true;
                _searchController.clear();
              });
            },
          ),
          Divider(height: 1, color: Colors.grey[300]),
          // Destination
          ListTile(
            leading: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            title: Text(
              'DROP',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: Text(
              _destinationController.text.isEmpty ? 'Where are you going?' : _destinationController.text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: _destinationController.text.isEmpty ? Colors.grey[400] : Colors.black,
              ),
            ),
            trailing: const Icon(Icons.add, size: 20),
            onTap: () {
              setState(() {
                _isPickingPickup = false;
                _showLocationSearch = true;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDistanceInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_estimatedDistance.toStringAsFixed(1)} km',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Distance',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(_estimatedDistance * 3).round()} min',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Estimated time',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSelection() {
    final vehicles = [
      {'type': VehicleType.bike, 'name': 'Bike', 'icon': Icons.motorcycle, 'seats': 1},
      {'type': VehicleType.threewheeler, 'name': 'Three Wheeler', 'icon': Icons.local_taxi, 'seats': 3},
      {'type': VehicleType.car, 'name': 'Car', 'icon': Icons.directions_car, 'seats': 4},
      {'type': VehicleType.van, 'name': 'Van', 'icon': Icons.airport_shuttle, 'seats': 8},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Choose a vehicle',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...vehicles.map((vehicle) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: _selectedVehicleType == vehicle['type'] ? Colors.blue[50] : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Icon(
              vehicle['icon'] as IconData,
              color: _selectedVehicleType == vehicle['type'] ? Colors.blue : Colors.grey[600],
            ),
            title: Text(
              vehicle['name'] as String,
              style: TextStyle(
                color: _selectedVehicleType == vehicle['type'] ? Colors.blue : Colors.black,
                fontWeight: _selectedVehicleType == vehicle['type'] ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              '${vehicle['seats']} seats',
              style: TextStyle(
                color: Colors.grey[600],
              ),
            ),
            trailing: _selectedVehicleType == vehicle['type'] 
                ? const Icon(Icons.check_circle, color: Colors.blue)
                : null,
            onTap: () => setState(() => _selectedVehicleType = vehicle['type'] as VehicleType),
          ),
        )),
      ],
    );
  }

  Widget _buildPassengerCount() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Passengers',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text(
              'Number of passengers:',
              style: TextStyle(fontSize: 16),
            ),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _passengerCount > 1 ? () => setState(() => _passengerCount--) : null,
                    icon: const Icon(Icons.remove),
                    color: Colors.grey[600],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      '$_passengerCount',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _passengerCount < 6 ? () => setState(() => _passengerCount++) : null,
                    icon: const Icon(Icons.add),
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScheduleOption() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            const Text(
              'Schedule for later',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Switch(
              value: _isScheduled,
              onChanged: (value) => setState(() => _isScheduled = value),
              activeColor: Colors.blue,
            ),
          ],
        ),
        if (_isScheduled) ...[
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(hours: 1)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 7)),
              );
              if (date != null) {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) {
                  setState(() {
                    _scheduledTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                  });
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              _scheduledTime != null 
                  ? 'Scheduled: ${_scheduledTime.toString().split('.')[0]}'
                  : 'Select Date & Time',
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBookButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Book ride',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildLocationSearch() {
    return Container(
      color: Colors.grey[50],
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => setState(() => _showLocationSearch = false),
                    color: Colors.black,
                  ),
                  Expanded(
                    child: Text(
                      _isPickingPickup ? 'Set pickup location' : 'Set destination',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Search bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search for a location',
                  prefixIcon: Icon(Icons.search),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: _geocodeAddress,
                onChanged: _debouncedSearch,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Current Location Button (only for pickup)
            if (_isPickingPickup) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: ListTile(
                  leading: const Icon(Icons.my_location, color: Colors.blue),
                  title: const Text(
                    'Use Current Location',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.blue,
                    ),
                  ),
                  subtitle: const Text('Automatically detect your location'),
                  onTap: () async {
                    setState(() => _showLocationSearch = false);
                    await _getCurrentLocation();
                  },
                ),
              ),
              const Divider(indent: 16, endIndent: 16),
            ],
            
            // Popular locations
            Expanded(
              child: ListView(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      'Popular Locations',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  _buildLocationOption('Colombo Fort Railway Station', '6.9344, 79.8428'),
                  _buildLocationOption('Bandaranaike International Airport', '7.1797, 79.8840'),
                  _buildLocationOption('University of Colombo', '6.9022, 79.8607'),
                  _buildLocationOption('Galle Face Green', '6.9218, 79.8450'),
                  _buildLocationOption('Independence Square', '6.9034, 79.8683'),
                  _buildLocationOption('Pettah Market', '6.9388, 79.8542'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationOption(String name, String coordinates) {
    final coords = coordinates.split(', ');
    final lat = double.parse(coords[0]);
    final lng = double.parse(coords[1]);
    
    return ListTile(
      leading: const Icon(Icons.location_on, color: Colors.grey),
      title: Text(name),
      subtitle: Text(coordinates),
      onTap: () => _selectLocation(name, lat, lng),
    );
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _searchController.dispose();
    _searchTimer?.cancel();
    super.dispose();
  }
}
