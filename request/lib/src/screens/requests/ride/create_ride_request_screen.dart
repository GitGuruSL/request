import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../models/request_model.dart';
import '../../../models/enhanced_user_model.dart';
import '../../../services/enhanced_request_service.dart';
import '../../../services/enhanced_user_service.dart';
import '../../../widgets/image_upload_widget.dart';
import '../../../widgets/location_picker_widget.dart';
import '../../../utils/currency_helper.dart';

class CreateRideRequestScreen extends StatefulWidget {
  const CreateRideRequestScreen({super.key});

  @override
  State<CreateRideRequestScreen> createState() => _CreateRideRequestScreenState();
}

class _CreateRideRequestScreenState extends State<CreateRideRequestScreen> {
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
  String _selectedVehicleType = 'economy';
  DateTime? _departureTime;
  int _passengerCount = 1;
  bool _scheduleForLater = false;
  bool _allowSharing = true;
  final _specialRequestsController = TextEditingController();
  List<String> _imageUrls = [];
  
  // Location coordinates (for future map integration)
  double? _pickupLat;
  double? _pickupLng;
  double? _destinationLat; 
  double? _destinationLng;

  // Google Maps
  GoogleMapController? _mapController;
  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(6.9271, 79.8612), // Colombo, Sri Lanka
    zoom: 14,
  );
  Set<Marker> _markers = {};

  bool _isLoading = false;

  final List<Map<String, dynamic>> _vehicleTypes = [
    {
      'id': 'economy',
      'name': 'Economy',
      'description': 'Affordable rides',
      'icon': Icons.directions_car,
      'passengers': '1-4',
    },
    {
      'id': 'premium',
      'name': 'Premium',
      'description': 'Comfortable rides',
      'icon': Icons.local_taxi,
      'passengers': '1-4', 
    },
    {
      'id': 'suv',
      'name': 'SUV',
      'description': 'Extra space',
      'icon': Icons.airport_shuttle,
      'passengers': '1-6',
    },
    {
      'id': 'shared',
      'name': 'Shared',
      'description': 'Share & save',
      'icon': Icons.people,
      'passengers': '1-2',
      'price': '${CurrencyHelper.instance.getCurrencySymbol()}100-150',
    },
  ];

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
              onTap: _onMapTapped,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
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
                    const SizedBox(height: 24),

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
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey[50],
          ),
          child: Column(
            children: [
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
                      child: LocationPickerWidget(
                        controller: _pickupLocationController,
                        labelText: '',
                        hintText: 'Pickup location',
                        isRequired: true,
                        onLocationSelected: (address, lat, lng) {
                          setState(() {
                            _pickupLat = lat;
                            _pickupLng = lng;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: Colors.grey[300]),
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
                      child: LocationPickerWidget(
                        controller: _destinationController,
                        labelText: '',
                        hintText: 'Where to?',
                        isRequired: true,
                        onLocationSelected: (address, lat, lng) {
                          setState(() {
                            _destinationLat = lat;
                            _destinationLng = lng;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVehicleSelection() {
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
              final isSelected = _selectedVehicleType == vehicle['id'];
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedVehicleType = vehicle['id'];
                  });
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
                            vehicle['icon'],
                            size: 24,
                            color: isSelected ? Theme.of(context).primaryColor : Colors.grey[600],
                          ),
                          const Spacer(),
                          Text(
                            vehicle['passengers'],
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        vehicle['name'],
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

  void _onMapTapped() {
    // Future: Handle map tapping for setting pickup/destination
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Map interaction will be available soon!'),
        duration: Duration(seconds: 1),
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
        (vehicle) => vehicle['id'] == _selectedVehicleType,
      );

      // Create the ride-specific data
      final rideData = RideRequestData(
        passengers: _passengerCount,
        preferredTime: _scheduleForLater ? _departureTime! : DateTime.now().add(const Duration(minutes: 10)),
        isFlexibleTime: !_scheduleForLater,
        vehicleType: selectedVehicle['name'],
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
        description: 'Ride request for $_passengerCount passenger(s) using ${selectedVehicle['name']}',
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
