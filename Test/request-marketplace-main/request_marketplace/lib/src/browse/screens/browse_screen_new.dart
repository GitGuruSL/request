import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/request_model.dart';
import '../../services/request_service.dart';
import '../../requests/screens/item_request_detail_screen.dart';
import '../../requests/screens/service_request_detail_screen.dart';
import '../../requests/screens/ride_request_detail_screen.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> with SingleTickerProviderStateMixin {
  final RequestService _requestService = RequestService();
  List<RequestModel> _itemRequests = [];
  List<RequestModel> _serviceRequests = [];
  List<RequestModel> _rideRequests = [];
  bool _isLoading = true;
  String? _error;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToRequestDetail(BuildContext context, RequestModel request) {
    Widget detailScreen;
    switch (request.type) {
      case RequestType.item:
        detailScreen = ItemRequestDetailScreen(request: request);
        break;
      case RequestType.service:
        detailScreen = ServiceRequestDetailScreen(request: request);
        break;
      case RequestType.ride:
        detailScreen = RideRequestDetailScreen(request: request);
        break;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => detailScreen),
    );
  }

  Future<void> _loadAllRequests() async {
    try {
      print('🔍 Loading all requests by type...');
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load requests by type
      final itemRequests = await _requestService.getAllRequests(type: RequestType.item);
      final serviceRequests = await _requestService.getAllRequests(type: RequestType.service);
      final rideRequests = await _requestService.getAllRequests(type: RequestType.ride);

      print('✅ Loaded ${itemRequests.length} items, ${serviceRequests.length} services, ${rideRequests.length} rides');
      
      setState(() {
        _itemRequests = itemRequests;
        _serviceRequests = serviceRequests;
        _rideRequests = rideRequests;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading requests: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Requests'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllRequests,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: [
            Tab(
              icon: const Icon(Icons.shopping_bag_outlined),
              text: 'Items (${_itemRequests.length})',
            ),
            Tab(
              icon: const Icon(Icons.build_outlined),
              text: 'Services (${_serviceRequests.length})',
            ),
            Tab(
              icon: const Icon(Icons.directions_car_outlined),
              text: 'Rides (${_rideRequests.length})',
            ),
          ],
        ),
      ),
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _loadAllRequests,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildRequestsList(_itemRequests, RequestType.item),
            _buildRequestsList(_serviceRequests, RequestType.service),
            _buildRequestsList(_rideRequests, RequestType.ride),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList(List<RequestModel> requests, RequestType type) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      bool isIndexError = _error!.contains('index') || 
                         _error!.contains('Index') || 
                         _error!.contains('requires an index');
      
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isIndexError ? Icons.build : Icons.error_outline,
              size: 64,
              color: isIndexError ? Colors.orange : Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              isIndexError ? 'Setting up database...' : 'Error loading requests',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isIndexError 
                ? 'The database is being optimized. This may take a few minutes. Please try again shortly.'
                : _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAllRequests,
              child: Text(isIndexError ? 'Check Again' : 'Retry'),
            ),
          ],
        ),
      );
    }

    if (requests.isEmpty) {
      String emptyMessage;
      IconData emptyIcon;
      
      switch (type) {
        case RequestType.item:
          emptyMessage = 'No item requests found';
          emptyIcon = Icons.shopping_bag_outlined;
          break;
        case RequestType.service:
          emptyMessage = 'No service requests found';
          emptyIcon = Icons.build_outlined;
          break;
        case RequestType.ride:
          emptyMessage = 'No ride requests found';
          emptyIcon = Icons.directions_car_outlined;
          break;
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              emptyIcon,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check back later for new requests',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAllRequests,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return _buildRequestCard(request);
      },
    );
  }

  Widget _buildRequestCard(RequestModel request) {
    switch (request.type) {
      case RequestType.item:
        return _buildItemCard(request);
      case RequestType.service:
        return _buildServiceCard(request);
      case RequestType.ride:
        return _buildRideCard(request);
    }
  }

  Widget _buildItemCard(RequestModel request) {
    return GestureDetector(
      onTap: () => _navigateToDetail(request),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF1976D2),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.shopping_bag, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'ITEM REQUEST',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(request.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      request.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      if (request.imageUrls.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            request.imageUrls.first,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.image, color: Colors.grey),
                            ),
                          ),
                        ),
                      if (request.imageUrls.isNotEmpty) const SizedBox(width: 16),

                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              request.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'LKR ${NumberFormat('#,##0').format(request.budget)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1976D2),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    request.location,
                                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildTag(request.category, Colors.blue),
                      if (request.subcategory.isNotEmpty)
                        _buildTag(request.subcategory, Colors.green),
                      _buildTag(request.condition.toString().split('.').last.toUpperCase(), Colors.orange),
                      if (request.deadline != null)
                        _buildTag('Has Deadline', Colors.red),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(RequestModel request) {
    return GestureDetector(
      onTap: () => _navigateToDetail(request),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF388E3C),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.build, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'SERVICE REQUEST',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(request.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      request.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  
                  if (request.description.isNotEmpty)
                    Text(
                      request.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      // Budget
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Budget',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'LKR ${NumberFormat('#,##0').format(request.budget)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF388E3C),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Urgency (stored in condition field for services)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Urgency',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getUrgencyColor(request.condition.toString().split('.').last),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                request.condition.toString().split('.').last.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Location
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          request.location,
                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildTag(request.category, Colors.green),
                      if (request.subcategory.isNotEmpty)
                        _buildTag(request.subcategory, Colors.teal),
                      if (request.deadline != null)
                        _buildTag('Has Deadline', Colors.red),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRideCard(RequestModel request) {
    return GestureDetector(
      onTap: () => _navigateToDetail(request),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFFF6F00),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.directions_car, color: Colors.white),
                  const SizedBox(width: 8),
                  const Text(
                    'RIDE REQUEST',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(request.status),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      request.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    request.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  
                  // Route Information
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'From',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              request.location.split(' to ')[0],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Dotted line
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: SizedBox(
                            width: 2,
                            height: 20,
                            child: CustomPaint(
                              painter: DottedLinePainter(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'To',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              request.location.contains(' to ') 
                                ? request.location.split(' to ')[1]
                                : request.location,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Vehicle and Category Info
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Vehicle',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              request.category.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF6F00),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      if (request.subcategory.isNotEmpty)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Passengers',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                request.subcategory,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Date/Time if available
                  if (request.deadline != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'Preferred: ${DateFormat('MMM dd, yyyy - hh:mm a').format(request.deadline!.toDate())}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Color _getUrgencyColor(String urgency) {
    switch (urgency.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.deepOrange;
      case 'urgent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _navigateToDetail(RequestModel request) {
    _navigateToRequestDetail(context, request);
  }
}

// Custom painter for dotted line
class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashHeight = 3;
    const dashSpace = 2;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, startY),
        Offset(size.width / 2, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
