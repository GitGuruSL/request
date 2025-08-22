import 'package:flutter/material.dart';
import '../../../services/rest_auth_service.dart' hide UserModel;
import 'package:google_maps_flutter/google_maps_flutter.dart';
// Removed unused firebase_shim import after migration
// REMOVED_FB_IMPORT: import 'package:cloud_firestore/cloud_firestore.dart';
// REMOVED_FB_IMPORT: import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import '../../../models/request_model.dart';
import '../../../models/enhanced_user_model.dart';
import '../../../services/enhanced_request_service.dart';
import '../../../services/enhanced_user_service.dart';
import '../../../utils/address_utils.dart';
import 'edit_ride_request_screen.dart';
import 'create_ride_response_screen.dart';

class ViewRideRequestScreen extends StatefulWidget {
  final String requestId;

  const ViewRideRequestScreen({super.key, required this.requestId});

  @override
  State<ViewRideRequestScreen> createState() => _ViewRideRequestScreenState();
}

class _ViewRideRequestScreenState extends State<ViewRideRequestScreen> {
  final EnhancedRequestService _requestService = EnhancedRequestService();
  final EnhancedUserService _userService = EnhancedUserService();

  RequestModel? _request;
  List<ResponseModel> _responses = [];
  bool _isLoading = true;
  bool _isOwner = false;
  UserModel? _requesterUser;
  UserModel? _currentUser;

  // Map related
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _loadRequestData();
  }

  Future<void> _loadRequestData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check Firebase Auth state first
      final firebaseUser = RestAuthService.instance.currentUser;
      print(
          '🔍 Debug Ride Auth - Firebase User: ${firebaseUser?.uid ?? "NULL"}');
      print(
          '🔍 Debug Ride Auth - Firebase User Email: ${firebaseUser?.email ?? "NULL"}');
      print(
          '🔍 Debug Ride Auth - Firebase User Phone: ${firebaseUser?.phoneNumber ?? "NULL"}');

      final request = await _requestService.getRequestById(widget.requestId);
      final responses =
          await _requestService.getResponsesForRequest(widget.requestId);
      final currentUser = await _userService.getCurrentUserModel();

      if (request != null) {
        final requesterUser =
            await _userService.getUserById(request.requesterId);

        // More robust owner check using both current user model and Firebase Auth
        bool isOwner = false;
        String currentUserId = '';

        // Try Firebase Auth first
        if (firebaseUser?.uid != null) {
          currentUserId = firebaseUser!.uid;
        }

        // If Firebase Auth doesn't work, try user service
        if (currentUserId.isEmpty && currentUser?.id != null) {
          currentUserId = currentUser!.id;
        }

        // Check ownership with additional safety checks
        if (currentUserId.isNotEmpty && request.requesterId.isNotEmpty) {
          isOwner = currentUserId == request.requesterId;
        } else {
          // If we can't determine the current user, assume ownership to hide respond button
          // This is a safety measure to prevent users from responding to their own requests
          isOwner = true;
          print(
              '⚠️ Warning: Could not determine current user, defaulting to owner=true for safety');
        }

        if (mounted) {
          setState(() {
            _request = request;
            _responses = responses.cast<ResponseModel>();
            _isOwner = isOwner;
            _requesterUser = requesterUser;
            _currentUser = currentUser;
            _isLoading = false;
          });

          // Enhanced debug information
          print(
              '🔍 Debug Ride - Firebase User ID: ${firebaseUser?.uid ?? "NULL"}');
          print(
              '🔍 Debug Ride - Current User Model ID: ${currentUser?.id ?? "NULL"}');
          print('🔍 Debug Ride - Final Current User ID: $currentUserId');
          print('🔍 Debug Ride - Request Owner ID: ${request.requesterId}');
          print('🔍 Debug Ride - Is Owner: $isOwner');
          print('🔍 Debug Ride - Will Show Respond Button: ${!isOwner}');

          _setupMapMarkers();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading ride request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Role-based validation methods
  bool _canUserRespond() {
    if (_currentUser == null || _request == null) return false;
    if (_isOwner) return false;

    // For ride requests, user must have driver role and be approved
    return _currentUser!.hasRole(UserRole.driver) &&
        _currentUser!.isRoleVerified(UserRole.driver);
  }

  bool _hasUserResponded() {
    final currentUser = RestAuthService.instance.currentUser;
    if (currentUser == null) return false;

    return _responses
        .any((response) => response.responderId == currentUser.uid);
  }

  ResponseModel? _getUserResponse() {
    final currentUser = RestAuthService.instance.currentUser;
    if (currentUser == null) return null;

    try {
      return _responses
          .firstWhere((response) => response.responderId == currentUser.uid);
    } catch (e) {
      return null;
    }
  }

  void _navigateToEditRideRequest() {
    if (_request == null) return;

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => EditRideRequestScreen(request: _request!),
          ),
        )
        .then((_) => _loadRequestData()); // Reload data when coming back
  }

  void _setupMapMarkers() {
    if (_request?.location == null) return;

    setState(() {
      _markers.clear();
      _polylines.clear();

      // Add pickup marker
      _markers.add(
        Marker(
          markerId: const MarkerId('pickup'),
          position: LatLng(
              _request!.location!.latitude, _request!.location!.longitude),
          infoWindow: InfoWindow(
            title: 'Pickup Location',
            snippet: AddressUtils.cleanAddress(_request!.location!.address),
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );

      // Add destination marker if available
      if (_request!.destinationLocation != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('destination'),
            position: LatLng(
              _request!.destinationLocation!.latitude,
              _request!.destinationLocation!.longitude,
            ),
            infoWindow: InfoWindow(
              title: 'Destination',
              snippet: AddressUtils.cleanAddress(
                  _request!.destinationLocation!.address),
            ),
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );

        // Add route line
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: [
              LatLng(
                  _request!.location!.latitude, _request!.location!.longitude),
              LatLng(_request!.destinationLocation!.latitude,
                  _request!.destinationLocation!.longitude),
            ],
            color: const Color(0xFF2196F3),
            width: 5,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          ),
        );
      }
    });

    // Fit markers on map after setting them up
    if (_mapController != null) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _fitMarkersOnMap();
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_markers.isNotEmpty) {
      _fitMarkersOnMap();
    } else if (_request?.location != null) {
      // If request data is loaded but markers aren't set yet, set them up
      _setupMapMarkers();
    }
  }

  void _fitMarkersOnMap() {
    if (_mapController == null || _markers.isEmpty) return;

    if (_markers.length == 1) {
      // Center on single marker
      final marker = _markers.first;
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(marker.position, 15),
      );
    } else if (_markers.length > 1) {
      // Fit all markers
      final positions = _markers.map((m) => m.position).toList();
      final bounds = _calculateBounds(positions);

      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
    }
  }

  LatLngBounds _calculateBounds(List<LatLng> positions) {
    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (final pos in positions) {
      minLat = minLat < pos.latitude ? minLat : pos.latitude;
      maxLat = maxLat > pos.latitude ? maxLat : pos.latitude;
      minLng = minLng < pos.longitude ? minLng : pos.longitude;
      maxLng = maxLng > pos.longitude ? maxLng : pos.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_request == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Ride Request'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Ride request not found or has been removed.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Map View
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(6.9271, 79.8612), // Colombo, Sri Lanka
              zoom: 14,
            ),
            onMapCreated: _onMapCreated,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Top App Bar - Clean design without shadows
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    Expanded(
                      child: Text(
                        _buildAppBarTitle(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_isOwner) ...[
                      IconButton(
                        onPressed: _navigateToEditRideRequest,
                        icon: const Icon(Icons.edit),
                        tooltip: 'Edit Request',
                      ),
                    ],
                    if (!_isOwner) ...[
                      // Show edit response icon for drivers who have already responded
                      if (_getUserResponse() != null)
                        IconButton(
                          onPressed: () => _showResponseDialog(),
                          icon: const Icon(Icons.edit),
                          tooltip: 'Edit Response',
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Bottom Sheet - Clean design without shadows
          DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.3,
            maxChildSize: 0.85,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 20),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      _buildRideDetails(),
                      const SizedBox(height: 24),
                      _buildRequesterInfo(),
                      const SizedBox(height: 24),
                      _buildResponsesSection(),

                      // Respond Button for non-owners
                      if (!_isOwner) ...[
                        const SizedBox(height: 24),
                        _buildRespondButton(),
                      ],

                      const SizedBox(height: 80), // Space for FAB
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRideDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Enhanced Title with Route Information
        _buildRouteTitle(),
        const SizedBox(height: 24),

        // Location Details with Enhanced Design
        _buildLocationInfo(),

        const SizedBox(height: 20),

        // Distance and Route Info
        if (_request!.location != null &&
            _request!.destinationLocation != null) ...[
          _buildDistanceInfo(),
          const SizedBox(height: 20),
        ],

        // Enhanced Ride Details Section
        _buildRideDetailsSection(),

        const SizedBox(height: 16),

        // Status and Date
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(_request!.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _request!.status.name.toUpperCase(),
                style: TextStyle(
                  color: _getStatusColor(_request!.status),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const Spacer(),
            Text(
              'Posted ${_formatDate(_request!.createdAt)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openGoogleMaps(
      double latitude, double longitude, String address) async {
    final googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    final googleMapsAppUrl =
        'geo:$latitude,$longitude?q=$latitude,$longitude($address)';

    try {
      // Try to open Google Maps app first
      if (await canLaunchUrl(Uri.parse(googleMapsAppUrl))) {
        await launchUrl(Uri.parse(googleMapsAppUrl));
      } else if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        // Fallback to web version
        await launchUrl(Uri.parse(googleMapsUrl),
            mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not open maps';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    }
  }

  Widget _buildRouteTitle() {
    final pickupAddress =
        _request!.location?.address ?? 'Pickup location not specified';
    final dropoffAddress =
        _request!.destinationLocation?.address ?? 'Destination not specified';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ride Request',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ride from ${AddressUtils.cleanAddress(pickupAddress)} to ${AddressUtils.cleanAddress(dropoffAddress)}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildRideDetailsSection() {
    final rideData = _request!.rideData;

    return Column(
      children: [
        // Passengers, Vehicle Type, and Timing - Row Layout like in your screenshot
        Row(
          children: [
            // Passengers
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.person, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      '${rideData?.passengers ?? 1} passenger(s)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Vehicle Type Row
        if (rideData?.vehicleType != null)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.directions_car,
                          size: 20, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        rideData!.vehicleType!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

        if (rideData?.vehicleType != null) const SizedBox(height: 12),

        // Timing Row
        if (rideData != null)
          Row(
            children: [
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, size: 20, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        rideData.isFlexibleTime
                            ? 'Flexible timing'
                            : 'Scheduled timing',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildLocationInfo() {
    return Column(
      children: [
        // Pickup Location - Enhanced with more prominence like in screenshot
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              // Green dot for pickup
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AddressUtils.cleanAddress(_request!.location?.address ??
                          'Pickup location not specified'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              // Navigation arrow
              InkWell(
                onTap: () {
                  if (_request!.location != null) {
                    _openGoogleMaps(
                      _request!.location!.latitude,
                      _request!.location!.longitude,
                      _request!.location!.address,
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      Icon(Icons.navigation, color: Colors.grey[600], size: 20),
                ),
              ),
            ],
          ),
        ),

        if (_request!.destinationLocation != null) ...[
          // Destination Location - Red dot design
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                // Red dot for destination
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AddressUtils.cleanAddress(
                            _request!.destinationLocation!.address),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                // Navigation arrow
                InkWell(
                  onTap: () {
                    _openGoogleMaps(
                      _request!.destinationLocation!.latitude,
                      _request!.destinationLocation!.longitude,
                      _request!.destinationLocation!.address,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.navigation,
                        color: Colors.grey[600], size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDistanceInfo() {
    if (_request!.location == null || _request!.destinationLocation == null) {
      return const SizedBox.shrink();
    }

    final distance = _calculateDistance(
      _request!.location!.latitude,
      _request!.location!.longitude,
      _request!.destinationLocation!.latitude,
      _request!.destinationLocation!.longitude,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.straighten, color: Colors.blue[700], size: 20),
          const SizedBox(width: 8),
          Text(
            '${distance.toStringAsFixed(1)} km distance',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double radiusOfEarth = 6371; // Earth's radius in kilometers

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) *
            math.cos(_degreesToRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    double c = 2 * math.asin(math.sqrt(a));

    return radiusOfEarth * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  Widget _buildRequesterInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Requester Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.blue[100],
              child: Text(
                _requesterUser?.name.isNotEmpty == true
                    ? _requesterUser!.name[0].toUpperCase()
                    : 'U',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _requesterUser?.name ?? 'Anonymous User',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (_requesterUser?.phoneNumber != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          _requesterUser!.phoneNumber!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (_requesterUser?.isPhoneVerified == true)
                    Row(
                      children: [
                        Icon(Icons.verified, color: Colors.green, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Phone Verified',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            if (!_isOwner) // Hide contact options from requester/owner
              Row(
                children: [
                  IconButton(
                    onPressed: () async {
                      // Call functionality
                      if (_requesterUser?.phoneNumber != null) {
                        final phone = _requesterUser!.phoneNumber!;
                        final uri = Uri.parse('tel:$phone');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      }
                    },
                    icon: const Icon(Icons.phone, color: Colors.green),
                    tooltip: 'Call',
                  ),
                  IconButton(
                    onPressed: () {
                      // TODO: Implement message functionality
                    },
                    icon: const Icon(Icons.message, color: Colors.blue),
                    tooltip: 'Message',
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildResponsesSection() {
    // For responders (drivers): Show minimal count only
    if (!_isOwner) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Responses',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_responses.length}',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Show simple message for non-owners
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_responses.length} Responses Received',
                        style: TextStyle(
                          color: Colors.green[800],
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Thank you for your interest in this ride request',
                        style: TextStyle(
                          color: Colors.green[600],
                          fontSize: 14,
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

    // For requesters (owners): Show full responses with "View All" option
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Responses',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_responses.length}',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            if (_responses.isNotEmpty)
              Row(
                children: [
                  Icon(Icons.visibility, size: 16, color: Colors.blue[600]),
                  const SizedBox(width: 4),
                  Text(
                    'View All',
                    style: TextStyle(
                      color: Colors.blue[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_responses.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.inbox, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'No responses yet',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  Text(
                    'Drivers will respond to your ride request',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          // Show summary for requesters instead of full list
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_responses.length} Responses Received',
                        style: TextStyle(
                          color: Colors.green[800],
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap "View All" to see response details',
                        style: TextStyle(
                          color: Colors.green[600],
                          fontSize: 14,
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

  Color _getStatusColor(RequestStatus status) {
    switch (status) {
      case RequestStatus.draft:
        return Colors.grey;
      case RequestStatus.active:
        return Colors.orange;
      case RequestStatus.open:
        return Colors.green;
      case RequestStatus.inProgress:
        return Colors.orange;
      case RequestStatus.completed:
        return Colors.blue;
      case RequestStatus.cancelled:
        return Colors.red;
      case RequestStatus.expired:
        return Colors.brown;
    }
  }

  void _showResponseDialog() {
    // Navigate to the comprehensive ride response screen
    final existingResponse = _getUserResponse();

    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => CreateRideResponseScreen(
          request: _request!,
          existingResponse: existingResponse,
        ),
      ),
    )
        .then((_) {
      // Refresh the responses when returning from the response screen
      _loadRequestData(); // Reload data when coming back
    });
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  String _buildAppBarTitle() {
    if (_request == null) return 'Ride Request';

    final vehicleType = _request!.rideData?.vehicleType ?? 'Vehicle';
    String pickup = 'Pickup';
    String destination = 'Destination';

    if (_request!.location?.address != null) {
      pickup = _request!.location!.address.split(',').first;
    }

    if (_request!.destinationLocation?.address != null) {
      destination = _request!.destinationLocation!.address.split(',').first;
    }

    return '$vehicleType: $pickup to $destination';
  }

  Widget _buildRespondButton() {
    if (_isOwner) return const SizedBox.shrink();

    final hasResponded = _hasUserResponded();
    final canRespond = _canUserRespond();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ElevatedButton(
        onPressed: canRespond ? _showResponseDialog : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: hasResponded ? Colors.orange : Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          hasResponded ? 'Edit Response' : 'Respond to Request',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
