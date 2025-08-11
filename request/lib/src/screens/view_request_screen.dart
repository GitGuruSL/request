import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/request_model.dart';
import '../models/enhanced_user_model.dart';
import '../services/enhanced_request_service.dart';
import '../utils/currency_helper.dart';

class ViewRequestScreen extends StatefulWidget {
  final String requestId;

  const ViewRequestScreen({
    super.key,
    required this.requestId,
  });

  @override
  State<ViewRequestScreen> createState() => _ViewRequestScreenState();
}

class _ViewRequestScreenState extends State<ViewRequestScreen> {
  final EnhancedRequestService _requestService = EnhancedRequestService();
  RequestModel? _request;
  bool _isLoading = true;
  String? _error;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  Future<void> _loadRequest() async {
    try {
      final request = await _requestService.getRequestById(widget.requestId);
      if (mounted) {
        setState(() {
          _request = request;
          _isLoading = false;
          _setupMapData();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _setupMapData() {
    if (_request == null) return;

    _markers.clear();
    _polylines.clear();

    // Add main location marker
    if (_request!.location != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('location'),
          position: LatLng(_request!.location!.latitude, _request!.location!.longitude),
          infoWindow: InfoWindow(
            title: _getLocationTitle(),
            snippet: _request!.location!.address,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(_getMarkerColor()),
        ),
      );
    }

    // Add destination marker for ride/delivery requests
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
          width: 4,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      );
    }
  }

  String _getLocationTitle() {
    switch (_request!.type) {
      case RequestType.ride:
        return 'Pickup Location';
      case RequestType.delivery:
        return 'Pickup Location';
      case RequestType.service:
        return 'Service Location';
      case RequestType.rental:
        return 'Item Location';
      case RequestType.item:
        return 'Item Location';
    }
  }

  double _getMarkerColor() {
    switch (_request!.type) {
      case RequestType.ride:
        return BitmapDescriptor.hueGreen;
      case RequestType.delivery:
        return BitmapDescriptor.hueOrange;
      case RequestType.service:
        return BitmapDescriptor.hueBlue;
      case RequestType.rental:
        return BitmapDescriptor.hueMagenta;
      case RequestType.item:
        return BitmapDescriptor.hueYellow;
      case RequestType.price:
        return BitmapDescriptor.hueRed;
    }
  }

  Color _getMarkerUIColor() {
    switch (_request!.type) {
      case RequestType.ride:
        return Colors.green;
      case RequestType.delivery:
        return Colors.orange;
      case RequestType.service:
        return Colors.blue;
      case RequestType.rental:
        return Colors.purple;
      case RequestType.item:
        return Colors.yellow[700]!;
      case RequestType.price:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Request Details',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Request Details',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _loadRequest();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_request == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Request Details',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
          ),
        ),
        body: const Center(
          child: Text('Request not found'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Map View
          if (_request!.location != null)
            Positioned.fill(
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: LatLng(_request!.location!.latitude, _request!.location!.longitude),
                  zoom: 14,
                ),
                onMapCreated: (GoogleMapController controller) {
                  _mapController = controller;
                  _fitMarkersOnMap();
                },
                markers: _markers,
                polylines: _polylines,
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
                top: MediaQuery.of(context).padding.top,
                left: 16,
                right: 16,
                bottom: 16,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _request!.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _request!.status.toString().split('.').last.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Sheet with Request Details
          DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Drag Handle
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

                    // Request Type Badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getTypeColor().withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getTypeIcon(),
                                size: 16,
                                color: _getTypeColor(),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _request!.type.toString().split('.').last.toUpperCase(),
                                style: TextStyle(
                                  color: _getTypeColor(),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${CurrencyHelper.instance.getCurrencySymbol()}${_request!.budget?.toStringAsFixed(0) ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Title and Description
                    Text(
                      _request!.title,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _request!.description,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Location Information
                    _buildLocationSection(),

                    const SizedBox(height: 24),

                    // Type-specific Information
                    _buildTypeSpecificSection(),

                    const SizedBox(height: 24),

                    // Images
                    if (_request!.images != null && _request!.images!.isNotEmpty)
                      _buildImagesSection(),

                    const SizedBox(height: 24),

                    // Tags
                    if (_request!.tags != null && _request!.tags!.isNotEmpty)
                      _buildTagsSection(),

                    const SizedBox(height: 24),

                    // Action Buttons
                    _buildActionButtons(),

                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _getMarkerColor(),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _request!.location?.address ?? 'No location specified',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              if (_request!.destinationLocation != null) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                Row(
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
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTypeSpecificSection() {
    switch (_request!.type) {
      case RequestType.ride:
        return _buildRideSection();
      case RequestType.delivery:
        return _buildDeliverySection();
      case RequestType.service:
        return _buildServiceSection();
      case RequestType.rental:
        return _buildRentalSection();
      case RequestType.item:
        return _buildItemSection();
    }
  }

  Widget _buildRideSection() {
    final rideData = _request!.typeSpecificData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ride Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildInfoRow('Passengers', '${rideData?['passengers'] ?? 1}'),
              _buildInfoRow('Vehicle Type', rideData?['vehicleType'] ?? 'Economy'),
              if (rideData?['preferredTime'] != null)
                _buildInfoRow('Preferred Time', 
                  DateTime.parse(rideData!['preferredTime']).toString().substring(0, 16)),
              if (rideData?['specialRequests'] != null)
                _buildInfoRow('Special Requests', rideData!['specialRequests']),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeliverySection() {
    final deliveryData = _request!.typeSpecificData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Delivery Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              if (deliveryData?['itemType'] != null)
                _buildInfoRow('Item Type', deliveryData!['itemType']),
              if (deliveryData?['weight'] != null)
                _buildInfoRow('Weight', '${deliveryData!['weight']} kg'),
              if (deliveryData?['dimensions'] != null)
                _buildInfoRow('Dimensions', deliveryData!['dimensions']),
              if (deliveryData?['deliveryTime'] != null)
                _buildInfoRow('Delivery Time', deliveryData!['deliveryTime']),
              if (deliveryData?['specialInstructions'] != null)
                _buildInfoRow('Special Instructions', deliveryData!['specialInstructions']),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServiceSection() {
    final serviceData = _request!.typeSpecificData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Service Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              if (serviceData?['serviceType'] != null)
                _buildInfoRow('Service Type', serviceData!['serviceType']),
              if (serviceData?['duration'] != null)
                _buildInfoRow('Duration', serviceData!['duration']),
              if (serviceData?['preferredTime'] != null)
                _buildInfoRow('Preferred Time', 
                  DateTime.parse(serviceData!['preferredTime']).toString().substring(0, 16)),
              if (serviceData?['requirements'] != null)
                _buildInfoRow('Requirements', serviceData!['requirements']),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRentalSection() {
    final rentalData = _request!.typeSpecificData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Rental Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              if (rentalData?['itemType'] != null)
                _buildInfoRow('Item Type', rentalData!['itemType']),
              if (rentalData?['duration'] != null)
                _buildInfoRow('Rental Duration', rentalData!['duration']),
              if (rentalData?['startDate'] != null)
                _buildInfoRow('Start Date', 
                  DateTime.parse(rentalData!['startDate']).toString().substring(0, 10)),
              if (rentalData?['condition'] != null)
                _buildInfoRow('Condition', rentalData!['condition']),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildItemSection() {
    final itemData = _request!.typeSpecificData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Item Details',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              if (itemData?['category'] != null)
                _buildInfoRow('Category', itemData!['category']),
              if (itemData?['condition'] != null)
                _buildInfoRow('Condition', itemData!['condition']),
              if (itemData?['quantity'] != null)
                _buildInfoRow('Quantity', '${itemData!['quantity']}'),
              if (itemData?['brand'] != null)
                _buildInfoRow('Brand', itemData!['brand']),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Images',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _request!.images!.length,
            itemBuilder: (context, index) {
              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: NetworkImage(_request!.images![index]),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _request!.tags!.map((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () {
              // TODO: Implement accept/respond to request
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Response feature coming soon!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              'Respond to Request',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implement contact user
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Contact feature coming soon!')),
                  );
                },
                icon: const Icon(Icons.message),
                label: const Text('Message'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implement save/bookmark request
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bookmark feature coming soon!')),
                  );
                },
                icon: const Icon(Icons.bookmark_outline),
                label: const Text('Save'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (_request!.status) {
      case RequestStatus.draft:
        return Colors.grey;
      case RequestStatus.active:
        return Colors.orange;
      case RequestStatus.open:
        return Colors.blue;
      case RequestStatus.inProgress:
        return Colors.purple;
      case RequestStatus.completed:
        return Colors.green;
      case RequestStatus.cancelled:
        return Colors.red;
      case RequestStatus.expired:
        return Colors.brown;
    }
  }

  Color _getTypeColor() {
    switch (_request!.type) {
      case RequestType.ride:
        return Colors.green;
      case RequestType.delivery:
        return Colors.orange;
      case RequestType.service:
        return Colors.blue;
      case RequestType.rental:
        return Colors.purple;
      case RequestType.item:
        return Colors.teal;
    }
  }

  IconData _getTypeIcon() {
    switch (_request!.type) {
      case RequestType.ride:
        return Icons.directions_car;
      case RequestType.delivery:
        return Icons.delivery_dining;
      case RequestType.service:
        return Icons.build;
      case RequestType.rental:
        return Icons.calendar_today;
      case RequestType.item:
        return Icons.shopping_bag;
    }
  }

  void _fitMarkersOnMap() {
    if (_mapController == null || _markers.isEmpty) return;

    if (_markers.length == 1) {
      final marker = _markers.first;
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(marker.position, 15),
      );
    } else {
      final positions = _markers.map((m) => m.position).toList();
      final bounds = _getBounds(positions);
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 100.0),
      );
    }
  }

  LatLngBounds _getBounds(List<LatLng> positions) {
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
}
