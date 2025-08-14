import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/request_model.dart';
import '../../../models/enhanced_user_model.dart';
import '../../../models/vehicle_type_model.dart';
import '../../../services/enhanced_request_service.dart';
import '../../../services/enhanced_user_service.dart';
import '../../../services/country_service.dart';
import '../../../services/vehicle_service.dart';
import '../../../widgets/image_upload_widget.dart';
import '../../../widgets/accurate_location_picker_widget.dart';
import '../../../utils/currency_helper.dart';
import '../../../utils/distance_calculator.dart';
import '../../../services/google_directions_service.dart';

class CreateRideRequestScreen extends StatefulWidget {
  const CreateRideRequestScreen({super.key});

  @override
  State<CreateRideRequestScreen> createState() => _CreateRideRequestScreenState();
}

class _CreateRideRequestScreenState extends State<CreateRideRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final EnhancedRequestService _requestService = EnhancedRequestService();
  final EnhancedUserService _userService = EnhancedUserService();
  final VehicleService _vehicleService = VehicleService();

  // Form Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pickupLocationController = TextEditingController();
  final _destinationController = TextEditingController();
  final _budgetController = TextEditingController();
  
  // Ride-specific fields
  String _selectedVehicleType = '';
  DateTime? _departureTime;
  int _passengerCount = 1;
  bool _scheduleForLater = false;
  bool _allowSharing = true;
  final _specialRequestsController = TextEditingController();
  List<String> _imageUrls = [];
  
  // Location coordinates and distance
  double? _pickupLat;
  double? _pickupLng;
  double? _destinationLat; 
  double? _destinationLng;
  double? _distance; // Distance in kilometers
  String? _estimatedTime;

  // Google Maps
  GoogleMapController? _mapController;
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(6.9271, 79.8612), // Colombo, Sri Lanka
    zoom: 14,
  );
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  bool _isLoading = false;

  // Dynamic vehicle types from database
  List<VehicleTypeModel> _vehicleTypes = [];

  @override
  void initState() {
    super.initState();
    _loadVehicleTypes();
  }

  Future<void> _loadVehicleTypes() async {
    try {
      setState(() => _isLoading = true);
      final vehicles = await _vehicleService.getAvailableVehicles();
      setState(() {
        _vehicleTypes = vehicles;
        // Set first vehicle as default selection if available
        if (vehicles.isNotEmpty && _selectedVehicleType.isEmpty) {
          _selectedVehicleType = vehicles.first.id;
        }
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading vehicle types: $e');
      setState(() => _isLoading = false);
      // Show error snackbar if needed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load vehicle types')),
        );
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

  /// Get icon from string name
  IconData _getVehicleIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'two_wheeler':
      case 'twowheeler':
        return Icons.two_wheeler;
      case 'local_taxi':
      case 'localtaxi':
        return Icons.local_taxi;
      case 'directions_car':
      case 'directionscar':
        return Icons.directions_car;
      case 'airport_shuttle':
      case 'airportshuttle':
        return Icons.airport_shuttle;
      case 'directions_bus':
      case 'directionsbus':
        return Icons.directions_bus;
      case 'people':
        return Icons.people;
      default:
        return Icons.directions_car;
    }
  }

  void _calculateDistance() async {
    if (_pickupLat != null && _pickupLng != null && 
        _destinationLat != null && _destinationLng != null) {
      
      // Always calculate fallback distance first
      final fallbackDistance = DistanceCalculator.calculateDistance(
        startLat: _pickupLat!,
        startLng: _pickupLng!,
        endLat: _destinationLat!,
        endLng: _destinationLng!,
      );
      
      final fallbackTime = DistanceCalculator.estimateTravelTime(
        fallbackDistance,
        vehicleType: _selectedVehicleType,
      );
      
      // Set fallback values first
      _distance = fallbackDistance;
      _estimatedTime = fallbackTime;
      
      setState(() {});
      
      // Try to get better estimates from Google API in the background
      try {
        Map<String, dynamic> routeInfo = await GoogleDirectionsService.getRouteInfo(
          origin: LatLng(_pickupLat!, _pickupLng!),
          destination: LatLng(_destinationLat!, _destinationLng!),
          travelMode: 'driving',
        );

        if (routeInfo.isNotEmpty) {
          // Update with API data
          _distance = (routeInfo['distance'] / 1000.0);
          _estimatedTime = routeInfo['durationText'];
          
          setState(() {});
        }
      } catch (e) {
        print('Google Directions API error: $e');
        // Keep fallback values
      }
      
      // Update map with route
      _updateMapWithRoute();
    }
  }

  Future<BitmapDescriptor> _createCustomMarker(IconData icon, Color color) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color;
    const double radius = 20.0;
    
    // Draw circle background
    canvas.drawCircle(const Offset(radius, radius), radius, paint);
    
    // Draw white circle border
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(const Offset(radius, radius), radius, borderPaint);
    
    // Draw icon
    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: 20.0,
        fontFamily: icon.fontFamily,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(10, 10));
    
    // Convert to image
    final ui.Image markerAsImage = await pictureRecorder.endRecording().toImage(
      (radius * 2).toInt(),
      (radius * 2).toInt(),
    );
    
    final ByteData? byteData = await markerAsImage.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List uint8List = byteData!.buffer.asUint8List();
    
    return BitmapDescriptor.bytes(uint8List);
  }

  void _updateMapWithRoute() async {
    if (_pickupLat != null && _pickupLng != null && 
        _destinationLat != null && _destinationLng != null) {
      
      // Create custom human icon for pickup
      final BitmapDescriptor humanIcon = await _createCustomMarker(Icons.person, Colors.blue);
      final BitmapDescriptor destinationIcon = await _createCustomMarker(Icons.location_on, Colors.red);
      
      // Add markers with human icon for pickup
      _markers = {
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(_pickupLat!, _pickupLng!),
          infoWindow: InfoWindow(title: 'Pickup', snippet: _pickupLocationController.text),
          icon: humanIcon,
        ),
        Marker(
          markerId: const MarkerId('destination'),
          position: LatLng(_destinationLat!, _destinationLng!),
          infoWindow: InfoWindow(title: 'Destination', snippet: _destinationController.text),
          icon: destinationIcon,
        ),
      };

      try {
        // Get route points from Google Directions API
        List<LatLng> routePoints = await GoogleDirectionsService.getDirections(
          origin: LatLng(_pickupLat!, _pickupLng!),
          destination: LatLng(_destinationLat!, _destinationLng!),
          travelMode: _selectedVehicleType == 'bike' ? 'driving' : 'driving',
        );

        if (routePoints.isNotEmpty) {
          // Add polyline with actual route
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              points: routePoints,
              color: Colors.blue,
              width: 4,
              patterns: [],
            ),
          };
        } else {
          // Fallback to straight line if directions API fails
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              points: [
                LatLng(_pickupLat!, _pickupLng!),
                LatLng(_destinationLat!, _destinationLng!),
              ],
              color: Colors.blue,
              width: 3,
            ),
          };
        }
      } catch (e) {
        print('Error getting directions: $e');
        // Fallback to straight line
        _polylines = {
          Polyline(
            polylineId: const PolylineId('route'),
            points: [
              LatLng(_pickupLat!, _pickupLng!),
              LatLng(_destinationLat!, _destinationLng!),
            ],
            color: Colors.blue,
            width: 3,
          ),
        };
      }

      // Adjust camera to show both points
      if (_mapController != null) {
        double minLat = _pickupLat! < _destinationLat! ? _pickupLat! : _destinationLat!;
        double maxLat = _pickupLat! > _destinationLat! ? _pickupLat! : _destinationLat!;
        double minLng = _pickupLng! < _destinationLng! ? _pickupLng! : _destinationLng!;
        double maxLng = _pickupLng! > _destinationLng! ? _pickupLng! : _destinationLng!;

        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(minLat, minLng),
              northeast: LatLng(maxLat, maxLng),
            ),
            100.0, // padding
          ),
        );
      }
      
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Google Maps View
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: _initialPosition,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              markers: _markers,
              polylines: _polylines,
              onTap: _onMapTapped,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
          ),
          
          // My Location Button (like in Uber)
          Positioned(
            right: 16,
            top: 120,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _goToCurrentLocation,
              child: const Icon(
                Icons.my_location,
                color: Colors.black,
              ),
            ),
          ),
          
          // Top App Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                bottom: 8,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Book a Ride',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.my_location),
                    onPressed: _goToCurrentLocation,
                  ),
                ],
              ),
            ),
          ),

          // Bottom Sheet with ride details
          DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
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

                    // Location inputs
                    _buildLocationInputs(),
                    const SizedBox(height: 16),

                    // Distance information card
                    if (_distance != null) _buildDistanceCard(),
                    if (_distance != null) const SizedBox(height: 16),
                    
                    // Vehicle selection
                    _buildVehicleSelection(),
                    const SizedBox(height: 24),

                    // Passengers and scheduling
                    _buildRideOptions(),
                    const SizedBox(height: 24),

                    // Request ride button
                    _buildRequestButton(),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildLocationInputs() {
    return Column(
      children: [
        // Pickup location
        Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AccurateLocationPickerWidget(
                  controller: _pickupLocationController,
                  labelText: '',
                  hintText: 'Pickup location',
                  isRequired: true,
                  prefixIcon: Icons.my_location,
                  onLocationSelected: (address, lat, lng) {
                    setState(() {
                      _pickupLat = lat;
                      _pickupLng = lng;
                    });
                    _calculateDistance();
                    // Show feedback
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Pickup location set: $address'),
                        duration: const Duration(seconds: 2),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Destination location
        Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AccurateLocationPickerWidget(
                  controller: _destinationController,
                  labelText: '',
                  hintText: 'Where to?',
                  isRequired: true,
                  prefixIcon: Icons.location_on,
                  onLocationSelected: (address, lat, lng) {
                    setState(() {
                      _destinationLat = lat;
                      _destinationLng = lng;
                    });
                    _calculateDistance(); // Add this line
                    // Show feedback
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Destination set: $address'),
                        duration: const Duration(seconds: 2),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDistanceCard() {
    if (_distance == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.route, color: Colors.blue.shade600, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Distance: ${DistanceCalculator.formatDistance(_distance!)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                if (_estimatedTime != null)
                  Text(
                    'Estimated time: $_estimatedTime',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleSelection() {
    if (_vehicleTypes.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose a ride',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 80,
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : const Center(
                  child: Text(
                    'No vehicles available in your area',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose a ride',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _vehicleTypes.length,
            itemBuilder: (context, index) {
              final vehicle = _vehicleTypes[index];
              final isSelected = _selectedVehicleType == vehicle.id;
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedVehicleType = vehicle.id;
                  });
                  // Recalculate estimated time for new vehicle type
                  if (_distance != null) {
                    _estimatedTime = DistanceCalculator.estimateTravelTime(
                      _distance!,
                      vehicleType: _selectedVehicleType,
                    );
                    setState(() {});
                  }
                },
                child: Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.transparent,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _getVehicleIcon(vehicle.icon),
                            size: 24,
                            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
                          ),
                          const Spacer(),
                          Text(
                            '${vehicle.passengerCapacity}',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        vehicle.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRideOptions() {
    return Column(
      children: [
        // Passenger count
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[50],
          ),
          child: Row(
            children: [
              const Icon(Icons.person, color: Colors.grey),
              const SizedBox(width: 12),
              const Text(
                'Passengers',
                style: TextStyle(fontSize: 16),
              ),
              const Spacer(),
              Row(
                children: [
                  IconButton(
                    onPressed: _passengerCount > 1 
                        ? () => setState(() => _passengerCount--) 
                        : null,
                    icon: Icon(
                      Icons.remove_circle_outline,
                      color: _passengerCount > 1 
                          ? Theme.of(context).primaryColor 
                          : Colors.grey,
                    ),
                  ),
                  Text(
                    '$_passengerCount',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  IconButton(
                    onPressed: _passengerCount < 6 
                        ? () => setState(() => _passengerCount++) 
                        : null,
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: _passengerCount < 6 
                          ? Theme.of(context).primaryColor 
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Schedule for later
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[50],
          ),
          child: ListTile(
            leading: Icon(
              Icons.schedule, 
              color: _scheduleForLater ? Theme.of(context).primaryColor : Colors.grey,
            ),
            title: Text(_scheduleForLater 
                ? (_departureTime != null 
                    ? 'Leave at ${_departureTime!.hour}:${_departureTime!.minute.toString().padLeft(2, '0')}'
                    : 'Select time')
                : 'Leave now'),
            trailing: Switch(
              value: _scheduleForLater,
              onChanged: (value) {
                setState(() {
                  _scheduleForLater = value;
                  if (value && _departureTime == null) {
                    _selectDateTime();
                  }
                });
              },
            ),
            onTap: _scheduleForLater ? _selectDateTime : null,
          ),
        ),
      ],
    );
  }

  Widget _buildRequestButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Request Ride',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  void _updateMapMarkers() {
    setState(() {
      _markers.clear();
      _polylines.clear();
      
      // Add pickup marker
      if (_pickupLat != null && _pickupLng != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('pickup'),
            position: LatLng(_pickupLat!, _pickupLng!),
            infoWindow: InfoWindow(
              title: 'Pickup',
              snippet: _pickupLocationController.text,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ),
        );
      }
      
      // Add destination marker
      if (_destinationLat != null && _destinationLng != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('destination'),
            position: LatLng(_destinationLat!, _destinationLng!),
            infoWindow: InfoWindow(
              title: 'Drop',
              snippet: _destinationController.text,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
      }
      
      // Add route line if both locations are set
      if (_pickupLat != null && _pickupLng != null && 
          _destinationLat != null && _destinationLng != null) {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: [
              LatLng(_pickupLat!, _pickupLng!),
              LatLng(_destinationLat!, _destinationLng!),
            ],
            color: const Color(0xFF2196F3),
            width: 5,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          ),
        );
      }
    });
    
    // Camera movement after setState
    if (_pickupLat != null && _pickupLng != null && 
        _destinationLat != null && _destinationLng != null) {
      Future.delayed(const Duration(milliseconds: 200), () {
        _fitMarkersOnMap();
      });
    } else if (_pickupLat != null && _pickupLng != null) {
      // If only pickup is set, center on pickup
      Future.delayed(const Duration(milliseconds: 200), () {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(_pickupLat!, _pickupLng!), 15),
        );
      });
    } else if (_destinationLat != null && _destinationLng != null) {
      // If only destination is set, center on destination
      Future.delayed(const Duration(milliseconds: 200), () {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(_destinationLat!, _destinationLng!), 15),
        );
      });
    }
  }

  void _fitMarkersOnMap() {
    if (_mapController == null || _pickupLat == null || _destinationLat == null) return;
    
    final bounds = LatLngBounds(
      southwest: LatLng(
        _pickupLat! < _destinationLat! ? _pickupLat! : _destinationLat!,
        _pickupLng! < _destinationLng! ? _pickupLng! : _destinationLng!,
      ),
      northeast: LatLng(
        _pickupLat! > _destinationLat! ? _pickupLat! : _destinationLat!,
        _pickupLng! > _destinationLng! ? _pickupLng! : _destinationLng!,
      ),
    );
    
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 120.0), // More padding for better view
    );
  }

  void _onMapTapped(LatLng position) {
    // For now, just show coordinates - can be enhanced to set pickup/destination
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tapped: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _goToCurrentLocation() {
    // Future: Implement current location functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Getting current location...'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
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

  Future<void> _submitRequest() async {
    // Basic validation
    if (_pickupLocationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter pickup location')),
      );
      return;
    }

    if (_destinationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter destination')),
      );
      return;
    }

    if (_scheduleForLater && _departureTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select departure time')),
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

      // Get selected vehicle details
      final selectedVehicle = _vehicleTypes.firstWhere(
        (vehicle) => vehicle.id == _selectedVehicleType,
      );

      // Create the ride-specific data
      final rideData = RideRequestData(
        passengers: _passengerCount,
        preferredTime: _scheduleForLater ? _departureTime! : DateTime.now().add(const Duration(minutes: 10)),
        isFlexibleTime: !_scheduleForLater,
        vehicleType: selectedVehicle.name,
        allowSmoking: false,
        petsAllowed: _allowSharing,
        specialRequests: _specialRequestsController.text.trim().isEmpty 
            ? null 
            : _specialRequestsController.text.trim(),
      );

      // Generate a descriptive title
      final title = 'Ride from ${_pickupLocationController.text.trim()} to ${_destinationController.text.trim()}';

      final requestId = await _requestService.createRequest(
        title: title,
        description: 'Ride request for $_passengerCount passenger(s) using ${selectedVehicle.name}',
        type: RequestType.ride,
        budget: double.tryParse(_budgetController.text),
        currency: CurrencyHelper.instance.getCurrency(),
        typeSpecificData: rideData.toMap(),
        tags: [
          'ride', 
          _selectedVehicleType,
          'passengers_$_passengerCount',
          if (_scheduleForLater) 'scheduled',
        ],
        location: LocationInfo(
          latitude: _pickupLat ?? 0.0,
          longitude: _pickupLng ?? 0.0,
          address: _pickupLocationController.text.trim(),
        ),
        destinationLocation: LocationInfo(
          latitude: _destinationLat ?? 0.0,
          longitude: _destinationLng ?? 0.0,
          address: _destinationController.text.trim(),
        ),
        images: _imageUrls,
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
          SnackBar(
            content: Text('Error creating request: $e'),
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
}
