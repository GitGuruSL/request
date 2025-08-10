import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import '../../models/request_model.dart';
import '../../models/response_model.dart';
import '../../services/response_service.dart';
import '../../services/chat_service.dart';
import '../../services/user_service.dart';
import '../../chat/screens/chat_screen.dart';
import '../../drivers/screens/respond_to_ride_request_screen_new.dart';
import 'request_responses_screen.dart';
import '../../services/driver_service.dart';
import '../../theme/app_theme.dart';

class RideRequestDetailScreen extends StatefulWidget {
  final RequestModel request;

  const RideRequestDetailScreen({super.key, required this.request});

  @override
  State<RideRequestDetailScreen> createState() =>
      _RideRequestDetailScreenState();
}

class _RideRequestDetailScreenState extends State<RideRequestDetailScreen> {
  final ResponseService _responseService = ResponseService();
  final DriverService _driverService = DriverService();
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<ResponseModel> _responses = [];
  bool _isLoadingResponses = false;
  bool _hasAlreadyResponded = false;
  bool _isDriver = false;

  @override
  void initState() {
    super.initState();
    _loadResponses();
    _checkExistingResponse();
    _checkDriverStatus();
  }

  Future<void> _checkDriverStatus() async {
    print('🔍 RideRequestDetailScreen: _checkDriverStatus called');
    final isDriver = await _driverService.isFullyActivatedDriver();
    print(
        '🔍 RideRequestDetailScreen: isFullyActivatedDriver returned: $isDriver');
    if (mounted) {
      setState(() {
        _isDriver = isDriver;
        print('🔍 RideRequestDetailScreen: _isDriver set to: $_isDriver');
      });
    }
  }

  Future<void> _checkExistingResponse() async {
    try {
      final hasResponded =
          await _responseService.hasUserAlreadyResponded(widget.request.id);
      if (mounted) {
        setState(() {
          _hasAlreadyResponded = hasResponded;
        });
      }
    } catch (e) {
      print('Error checking existing response: $e');
    }
  }

  Future<void> _loadResponses() async {
    if (!mounted) return;

    setState(() {
      _isLoadingResponses = true;
    });

    try {
      final responses =
          await _responseService.getResponsesForRequest(widget.request.id);
      if (mounted) {
        setState(() {
          _responses = responses;
        });
      }
      // Also check if user has responded
      _checkExistingResponse();
    } catch (e) {
      print('Error loading responses: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading responses: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingResponses = false;
        });
      }
    }
  }

  bool get _isOwnRequest {
    final currentUser = _auth.currentUser;
    return currentUser?.uid == widget.request.userId;
  }

  // Parse coordinates from the ride request description
  // NOTE: For testing, you can use sample coordinates like:
  // "Pickup Coordinates: 6.9271, 79.8612\nDestination Coordinates: 6.9344, 79.8428"
  Map<String, LatLng>? _parseCoordinatesFromDescription() {
    try {
      final description = widget.request.description;
      print('Parsing description: $description');

      final pickupRegex =
          RegExp(r'Pickup Coordinates: (-?\d+\.?\d*), (-?\d+\.?\d*)');
      final destinationRegex =
          RegExp(r'Destination Coordinates: (-?\d+\.?\d*), (-?\d+\.?\d*)');

      final pickupMatch = pickupRegex.firstMatch(description);
      final destinationMatch = destinationRegex.firstMatch(description);

      print('Pickup match: $pickupMatch');
      print('Destination match: $destinationMatch');

      if (pickupMatch != null && destinationMatch != null) {
        final pickupLat = double.parse(pickupMatch.group(1)!);
        final pickupLng = double.parse(pickupMatch.group(2)!);
        final destLat = double.parse(destinationMatch.group(1)!);
        final destLng = double.parse(destinationMatch.group(2)!);

        print(
            'Parsed coordinates - Pickup: $pickupLat, $pickupLng | Destination: $destLat, $destLng');

        return {
          'pickup': LatLng(pickupLat, pickupLng),
          'destination': LatLng(destLat, destLng),
        };
      }
    } catch (e) {
      print('Error parsing coordinates: $e');
    }
    print('No coordinates found, using test coordinates');
    return null;
  }

  // Launch Google Maps for navigation
  Future<void> _openGoogleMaps(LatLng destination) async {
    final url = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${destination.latitude},${destination.longitude}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    // Check if current user is verified (has verified phone numbers)
    final bool isUserVerified =
        currentUser != null; // TODO: Check actual verification status

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Ride Request Details',
          style: AppTheme.headingMedium.copyWith(fontSize: 20),
        ),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMapSection(),
            const SizedBox(height: AppTheme.spacingMedium),
            _buildTitleSection(),
            const SizedBox(height: AppTheme.spacingMedium),
            _buildRouteSection(),
            const SizedBox(height: AppTheme.spacingMedium),
            _buildDescriptionSection(),
            const SizedBox(height: AppTheme.spacingMedium),
            _buildRequesterSection(isUserVerified),
            const SizedBox(height: AppTheme.spacingMedium),
            _buildResponsesSection(),
            const SizedBox(height: AppTheme.spacingXLarge),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildMapSection() {
    final coordinates = _parseCoordinatesFromDescription();

    // Always use test coordinates to ensure map displays
    final LatLng testPickup = const LatLng(6.9271, 79.8612); // Colombo
    final LatLng testDestination =
        const LatLng(6.9344, 79.8428); // Close to Colombo

    final LatLng pickupLocation = coordinates?['pickup'] ?? testPickup;
    final LatLng destinationLocation =
        coordinates?['destination'] ?? testDestination;

    print(
        'Building map with pickup: ${pickupLocation.latitude}, ${pickupLocation.longitude}');
    print(
        'Building map with destination: ${destinationLocation.latitude}, ${destinationLocation.longitude}');

    return Container(
      height: 250,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      clipBehavior: Clip.antiAlias,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: pickupLocation,
          zoom: 12.0,
        ),
        markers: {
          Marker(
            markerId: const MarkerId('pickup'),
            position: pickupLocation,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen),
            infoWindow: InfoWindow(
              title: coordinates != null
                  ? 'Pickup Location'
                  : 'Test Pickup (Tap to navigate)',
              snippet: 'Tap to navigate in Google Maps',
            ),
            onTap: () => _openGoogleMaps(pickupLocation),
          ),
          Marker(
            markerId: const MarkerId('destination'),
            position: destinationLocation,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: coordinates != null
                  ? 'Destination'
                  : 'Test Destination (Tap to navigate)',
              snippet: 'Tap to navigate in Google Maps',
            ),
            onTap: () => _openGoogleMaps(destinationLocation),
          ),
        },
        onTap: (LatLng location) {
          // Show options to navigate to pickup or destination
          _showNavigationOptions(pickupLocation, destinationLocation);
        },
        onMapCreated: (GoogleMapController controller) {
          print('Google Map created successfully!');
          // Fit both markers in view
          Future.delayed(const Duration(milliseconds: 500), () {
            try {
              controller.animateCamera(
                CameraUpdate.newLatLngBounds(
                  LatLngBounds(
                    southwest: LatLng(
                      math.min(pickupLocation.latitude,
                              destinationLocation.latitude) -
                          0.005,
                      math.min(pickupLocation.longitude,
                              destinationLocation.longitude) -
                          0.005,
                    ),
                    northeast: LatLng(
                      math.max(pickupLocation.latitude,
                              destinationLocation.latitude) +
                          0.005,
                      math.max(pickupLocation.longitude,
                              destinationLocation.longitude) +
                          0.005,
                    ),
                  ),
                  100.0,
                ),
              );
            } catch (e) {
              print('Error animating camera: $e');
            }
          });
        },
        myLocationButtonEnabled: true,
        myLocationEnabled: false, // Disable to avoid permission issues
        zoomControlsEnabled: false,
        mapToolbarEnabled: false,
        compassEnabled: true,
        trafficEnabled: false,
        buildingsEnabled: true,
        indoorViewEnabled: false,
        mapType: MapType.normal,
        minMaxZoomPreference: const MinMaxZoomPreference(10.0, 18.0),
      ),
    );
  }

  Future<void> _messageRequester() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in to send messages')),
        );
        return;
      }

      if (currentUser.uid == widget.request.userId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot message yourself')),
        );
        return;
      }

      // Check if user is a registered driver
      if (!_isDriver) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'You need to be a fully verified driver with approved documents and vehicle images to message requesters')),
        );
        return;
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get requester info
      final requesterInfo =
          await _userService.getUserById(widget.request.userId);

      // Create or get conversation
      final conversationId = await _chatService.createOrGetConversation(
        otherUserId: widget.request.userId,
        requestId: widget.request.id,
      );

      // Hide loading
      Navigator.pop(context);

      // Navigate to chat screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            conversationId: conversationId,
            otherUserId: widget.request.userId,
            otherUserName: requesterInfo?.displayName ?? 'Requester',
            otherUserPhotoURL: requesterInfo?.photoURL,
          ),
        ),
      );
    } catch (e) {
      // Hide loading if still showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error starting conversation: $e')),
      );
    }
  }

  void _showNavigationOptions(LatLng pickup, LatLng destination) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Navigate to Location',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.my_location, color: Colors.green),
              title: const Text('Navigate to Pickup'),
              subtitle: const Text('Get directions to pickup location'),
              onTap: () {
                Navigator.pop(context);
                _openGoogleMaps(pickup);
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.red),
              title: const Text('Navigate to Destination'),
              subtitle: const Text('Get directions to destination'),
              onTap: () {
                Navigator.pop(context);
                _openGoogleMaps(destination);
              },
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteSection() {
    final coordinates = _parseCoordinatesFromDescription();
    final hasCoordinates = coordinates != null;

    // Extract from and to locations from description or use fallback
    String fromLocation = widget.request.location;
    String toLocation = 'Destination not specified';

    // Try to extract from description
    final lines = widget.request.description.split('\n');
    for (final line in lines) {
      if (line.trim().startsWith('- From:')) {
        fromLocation = line.replaceAll('- From:', '').trim();
      } else if (line.trim().startsWith('- To:')) {
        toLocation = line.replaceAll('- To:', '').trim();
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.route, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: AppTheme.spacingXSmall),
              Text(
                'Trip Route',
                style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMedium),

          // From Location
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppTheme.successColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FROM',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fromLocation,
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasCoordinates)
                  Icon(Icons.navigation, color: AppTheme.successColor, size: 20),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spacingSmall),

          // To Location
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            decoration: BoxDecoration(
              color: AppTheme.errorColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
            ),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSmall),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TO',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        toLocation,
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasCoordinates)
                  Icon(Icons.navigation, color: AppTheme.errorColor, size: 20),
              ],
            ),
          ),

          // Trip details
          if (widget.request.deadline != null) ...[
            const SizedBox(height: AppTheme.spacingMedium),
            Row(
              children: [
                Icon(Icons.schedule, color: AppTheme.warningColor, size: 20),
                const SizedBox(width: AppTheme.spacingSmall),
                Text(
                  'Scheduled: ${DateFormat('MMM d, y \'at\' h:mm a').format(widget.request.deadline!.toDate())}',
                  style: AppTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.request.title,
                  style: AppTheme.headingMedium.copyWith(fontSize: 20),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(widget.request.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                child: Text(
                  _getStatusText(widget.request.status),
                  style: TextStyle(
                    color: _getStatusColor(widget.request.status),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Row(
            children: [
              Icon(Icons.monetization_on, color: AppTheme.successColor, size: 20),
              const SizedBox(width: AppTheme.spacingXSmall),
              Text(
                'Budget: LKR ${NumberFormat('#,##0').format(widget.request.budget)}',
                style: AppTheme.bodyLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXSmall),
          Row(
            children: [
              Icon(Icons.access_time, color: AppTheme.warningColor, size: 20),
              const SizedBox(width: AppTheme.spacingXSmall),
              Text(
                'Posted: ${_formatDate(widget.request.createdAt)}',
                style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return AppTheme.successColor;
      case 'in_progress':
        return AppTheme.warningColor;
      case 'completed':
        return AppTheme.primaryColor;
      case 'cancelled':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  Widget _buildDescriptionSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: AppTheme.spacingXSmall),
              Text(
                'Description',
                style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Text(
            widget.request.description.isNotEmpty
                ? widget.request.description
                : 'No description provided.',
            style: AppTheme.bodyMedium.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildRequesterSection(bool isUserVerified) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: AppTheme.spacingXSmall),
              Text(
                'Requester',
                style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: AppTheme.backgroundColor,
                ),
                child: widget.request.user?.photoURL != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.network(
                          widget.request.user!.photoURL!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(
                            Icons.person,
                            color: AppTheme.textSecondary,
                            size: 24,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.person,
                        color: AppTheme.textSecondary,
                        size: 24,
                      ),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.request.user?.displayName ?? 'Anonymous User',
                      style: AppTheme.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.request.location.isNotEmpty
                                ? widget.request.location
                                : 'Location not provided',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isUserVerified && widget.request.user != null) ...[
            const SizedBox(height: AppTheme.spacingMedium),
            Row(
              children: [
                Icon(Icons.phone, color: AppTheme.textSecondary, size: 18),
                const SizedBox(width: AppTheme.spacingXSmall),
                Text(
                  widget.request.user!.primaryPhoneNumber ??
                      widget.request.user!.phoneNumber ??
                      "Not provided",
                  style: AppTheme.bodyMedium,
                ),
              ],
            ),
            // Message button for registered drivers only
            if (_isDriver && !_isOwnRequest && _auth.currentUser != null) ...[
              const SizedBox(height: AppTheme.spacingSmall),
              InkWell(
                onTap: _messageRequester,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
                  child: Row(
                    children: [
                      Icon(Icons.message_outlined,
                          color: AppTheme.primaryColor, size: 16),
                      const SizedBox(width: AppTheme.spacingXSmall),
                      Text(
                        'Message requester',
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.primaryColor,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ] else if (!isUserVerified) ...[
            const SizedBox(height: AppTheme.spacingMedium),
            TextButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/phone-management');
              },
              icon: Icon(Icons.verified_user, size: 16, color: AppTheme.textSecondary),
              label: Text(
                'Verify your account to see contact details',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResponsesSection() {
    // Only show responses to the request owner
    if (!_isOwnRequest) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.comment, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: AppTheme.spacingXSmall),
              Text(
                'Responses',
                style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_responses.length}',
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          if (_isLoadingResponses)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_responses.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.comment_outlined,
                      size: 48,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No responses yet',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          RequestResponsesScreen(request: widget.request),
                    ),
                  ).then((_) {
                    // Refresh responses when coming back
                    _loadResponses();
                  });
                },
                icon: const Icon(Icons.visibility, size: 18),
                label: const Text('View All Responses'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    final currentUser = _auth.currentUser;

    if (widget.request.status != 'open' ||
        _isOwnRequest ||
        currentUser == null) {
      return null;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: () async {
            print('🔍 RideRequestDetailScreen: Respond button pressed');
            print('🔍 RideRequestDetailScreen: _isDriver = $_isDriver');
            print(
                '🔍 RideRequestDetailScreen: Request type = ${widget.request.type}');

            // Force re-check driver status
            print(
                '🔍 RideRequestDetailScreen: Force checking driver status...');
            final isDriver = await _driverService.isFullyActivatedDriver();
            print('🔍 RideRequestDetailScreen: Force check result: $isDriver');

            if (widget.request.type == RequestType.ride && !isDriver) {
              print(
                  '❌ RideRequestDetailScreen: Showing driver registration dialog');
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Driver Registration Required'),
                  content: const Text(
                      'You need to be a fully verified driver with approved documents and vehicle images to respond to ride requests.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/driver-registration');
                      },
                      child: const Text('Register Now'),
                    ),
                  ],
                ),
              );
              return;
            }
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    RespondToRideRequestScreenNew(request: widget.request),
              ),
            );
            if (result == true) {
              _loadResponses(); // Reload responses after submitting
              _checkExistingResponse(); // Re-check response status
            }
          },
          icon: Icon(_hasAlreadyResponded ? Icons.edit : Icons.send),
          label: Text(
            _hasAlreadyResponded ? 'Update Response' : 'Respond to Request',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: _hasAlreadyResponded
                ? Colors.orange
                : Theme.of(context).primaryColor,
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingLarge,
              vertical: AppTheme.spacingMedium,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';

    DateTime date;
    if (timestamp is DateTime) {
      date = timestamp;
    } else {
      date = timestamp.toDate();
    }

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return DateFormat('MMM dd, yyyy').format(date);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
