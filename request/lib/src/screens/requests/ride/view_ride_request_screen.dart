import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import '../../../models/request_model.dart';
import '../../../models/enhanced_user_model.dart';
import '../../../services/enhanced_request_service.dart';
import '../../../services/enhanced_user_service.dart';
import '../../../utils/currency_helper.dart';
import 'edit_ride_request_screen.dart';

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
      final firebaseUser = FirebaseAuth.instance.currentUser;
      print('🔍 Debug Ride Auth - Firebase User: ${firebaseUser?.uid ?? "NULL"}');
      print('🔍 Debug Ride Auth - Firebase User Email: ${firebaseUser?.email ?? "NULL"}');
      print('🔍 Debug Ride Auth - Firebase User Phone: ${firebaseUser?.phoneNumber ?? "NULL"}');
      
      final request = await _requestService.getRequestById(widget.requestId);
      final responses = await _requestService.getResponsesForRequest(widget.requestId);
      final currentUser = await _userService.getCurrentUserModel();
      
      if (request != null) {
        final requesterUser = await _userService.getUserById(request.requesterId);
        
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
          print('⚠️ Warning: Could not determine current user, defaulting to owner=true for safety');
        }
        
        if (mounted) {
          setState(() {
            _request = request;
            _responses = responses;
            _isOwner = isOwner;
            _requesterUser = requesterUser;
            _isLoading = false;
          });
          
          // Enhanced debug information
          print('🔍 Debug Ride - Firebase User ID: ${firebaseUser?.uid ?? "NULL"}');
          print('🔍 Debug Ride - Current User Model ID: ${currentUser?.id ?? "NULL"}');
          print('🔍 Debug Ride - Final Current User ID: $currentUserId');
          print('🔍 Debug Ride - Request Owner ID: ${request.requesterId}');
          print('🔍 Debug Ride - Is Owner: $isOwner');
          print('🔍 Debug Ride - Will Show Respond Button: ${!isOwner && request != null}');
          
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

  void _navigateToEditRideRequest() {
    if (_request == null) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditRideRequestScreen(request: _request!),
      ),
    ).then((_) => _loadRequestData()); // Reload data when coming back
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
          position: LatLng(_request!.location!.latitude, _request!.location!.longitude),
          infoWindow: InfoWindow(
            title: 'Pickup Location',
            snippet: _request!.location!.address,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
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
              snippet: _request!.destinationLocation!.address,
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ),
        );
        
        // Add route line
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: [
              LatLng(_request!.location!.latitude, _request!.location!.longitude),
              LatLng(_request!.destinationLocation!.latitude, _request!.destinationLocation!.longitude),
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
          
          // Top App Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const Expanded(
                      child: Text(
                        'Ride Request',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (_isOwner) ...[
                      IconButton(
                        onPressed: _navigateToEditRideRequest,
                        icon: const Icon(Icons.edit),
                        tooltip: 'Edit Request',
                      ),
                    ],
                    IconButton(
                      onPressed: () {}, // TODO: Add share functionality
                      icon: const Icon(Icons.share),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Bottom Sheet
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
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
                      const SizedBox(height: 80), // Space for FAB
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: (_request != null && 
                              !_isOwner && 
                              FirebaseAuth.instance.currentUser != null &&
                              FirebaseAuth.instance.currentUser!.uid != _request!.requesterId)
          ? FloatingActionButton.extended(
              onPressed: () {
                print('🔍 Ride Respond button pressed - IsOwner: $_isOwner');
                print('🔍 Ride Respond button pressed - Current User: ${FirebaseAuth.instance.currentUser?.uid}');
                print('🔍 Ride Respond button pressed - Request Owner: ${_request!.requesterId}');
                _showResponseDialog();
              },
              icon: const Icon(Icons.reply),
              label: const Text('Respond'),
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildRideDetails() {
    final rideData = _request!.rideData;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _request!.title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Location Details
        _buildLocationInfo(),
        
        const SizedBox(height: 16),
        
        // Ride Specific Details
        if (rideData != null) ...[
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text('${rideData.passengers} passenger(s)'),
              const SizedBox(width: 24),
              const Icon(Icons.directions_car, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(rideData.vehicleType ?? 'Not specified'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.schedule, size: 16, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                rideData.isFlexibleTime 
                    ? 'Flexible timing' 
                    : 'Scheduled: ${_formatDateTime(rideData.preferredTime)}',
              ),
            ],
          ),
        ],
        
        if (_request!.budget != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_balance_wallet, 
                     color: Colors.green[600], size: 16),
                const SizedBox(width: 8),
                Text(
                  'Budget: ${CurrencyHelper.instance.getCurrencySymbol()}${_request!.budget?.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.green[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: 12),
        
        // Status and Date
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(_request!.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _request!.status.name.toUpperCase(),
                style: TextStyle(
                  color: _getStatusColor(_request!.status),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const Spacer(),
            Text(
              'Posted ${_formatDate(_request!.createdAt)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _openGoogleMaps(double latitude, double longitude, String address) async {
    final googleMapsUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    final googleMapsAppUrl = 'geo:$latitude,$longitude?q=$latitude,$longitude($address)';
    
    try {
      // Try to open Google Maps app first
      if (await canLaunchUrl(Uri.parse(googleMapsAppUrl))) {
        await launchUrl(Uri.parse(googleMapsAppUrl));
      } else if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        // Fallback to web version
        await launchUrl(Uri.parse(googleMapsUrl), mode: LaunchMode.externalApplication);
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

  Future<void> _openDirectionsInGoogleMaps() async {
    if (_request?.location == null || _request?.destinationLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Route information not available')),
      );
      return;
    }

    final pickup = _request!.location!;
    final destination = _request!.destinationLocation!;
    
    // Google Maps directions URL
    final directionsUrl = 'https://www.google.com/maps/dir/?api=1'
        '&origin=${pickup.latitude},${pickup.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&travelmode=driving';
    
    // Google Maps app directions URL
    final mapsAppUrl = 'google.navigation:q=${destination.latitude},${destination.longitude}';
    
    try {
      if (await canLaunchUrl(Uri.parse(mapsAppUrl))) {
        await launchUrl(Uri.parse(mapsAppUrl));
      } else if (await canLaunchUrl(Uri.parse(directionsUrl))) {
        await launchUrl(Uri.parse(directionsUrl), mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not open maps';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps directions')),
        );
      }
    }
  }

  Widget _buildLocationInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              if (_request!.location != null) {
                _openGoogleMaps(
                  _request!.location!.latitude,
                  _request!.location!.longitude,
                  _request!.location!.address,
                );
              }
            },
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
                  child: Text(
                    _request!.location?.address ?? 'Pickup location not specified',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1C1C1E), // Same color as title
                    ),
                  ),
                ),
                if (_request!.location != null)
                  const Icon(Icons.navigation, size: 20, color: Colors.grey),
              ],
            ),
          ),
          if (_request!.destinationLocation != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                _openGoogleMaps(
                  _request!.destinationLocation!.latitude,
                  _request!.destinationLocation!.longitude,
                  _request!.destinationLocation!.address,
                );
              },
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
                    child: Text(
                      _request!.destinationLocation!.address,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1C1C1E), // Same color as title
                      ),
                    ),
                  ),
                  const Icon(Icons.navigation, size: 20, color: Colors.grey),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRequesterInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              // TODO: Navigate to user profile screen
              print('Navigate to profile: ${_requesterUser?.id}');
            },
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blue[100],
              child: Text(
                _requesterUser?.name?.isNotEmpty == true 
                    ? _requesterUser!.name[0].toUpperCase()
                    : 'U',
                style: TextStyle(
                  color: Colors.blue[700],
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
                  _requesterUser?.name ?? 'Anonymous User',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                if (_requesterUser?.isPhoneVerified == true)
                  Row(
                    children: [
                      Icon(Icons.verified, color: Colors.blue, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Verified',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          if (!_isOwner) // Hide message icon from requester/owner
            IconButton(
              onPressed: () {
                // TODO: Implement contact functionality
              },
              icon: const Icon(Icons.message),
            ),
        ],
      ),
    );
  }

  Widget _buildResponsesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Offers',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                    'No offers yet',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  Text(
                    'Be the first to offer a ride!',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _responses.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final response = _responses[index];
              return _buildResponseCard(response);
            },
          ),
      ],
    );
  }

  Widget _buildResponseCard(ResponseModel response) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue[100],
                child: Text(
                  'D', // TODO: Get actual driver name
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Driver ${response.responderId.substring(0, 8)}...', // TODO: Get actual driver name
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber[600], size: 14),
                        const SizedBox(width: 2),
                        Text(
                          '4.8', // TODO: Get actual rating
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(response.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                '${CurrencyHelper.instance.getCurrencySymbol()}${response.price?.toStringAsFixed(2) ?? 'Free'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(response.message),
          if (_isOwner) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: Implement decline response
                    },
                    child: const Text('Decline'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Implement accept response
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
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
    // TODO: Implement response creation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Offer Ride'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Your offer price',
                prefixText: 'LKR ',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Message to requester',
                hintText: 'Tell them about your vehicle, experience, etc.',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Submit response
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Your offer has been submitted!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Send Offer'),
          ),
        ],
      ),
    );
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
