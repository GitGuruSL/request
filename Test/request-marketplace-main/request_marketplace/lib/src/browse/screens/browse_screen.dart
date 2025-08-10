import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/request_model.dart';
import '../../services/request_service.dart';
import '../../requests/screens/item_request_detail_screen.dart';
import '../../requests/screens/service_request_detail_screen.dart';
import '../../requests/screens/ride_request_detail_screen.dart';
import '../../requests/screens/rental_request_detail_screen.dart';
import '../../requests/screens/delivery_request_detail_screen.dart';

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
  List<RequestModel> _rentalRequests = [];
  List<RequestModel> _deliveryRequests = [];
  List<RequestModel> _allRequests = [];
  List<RequestModel> _filteredRequests = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  RequestType? _selectedFilter;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllRequests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllRequests() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load requests by type
      final itemRequests = await _requestService.getAllRequests(type: RequestType.item);
      final serviceRequests = await _requestService.getAllRequests(type: RequestType.service);
      final rideRequests = await _requestService.getAllRequests(type: RequestType.ride);
      final rentalRequests = await _requestService.getAllRequests(type: RequestType.rental);
      final deliveryRequests = await _requestService.getAllRequests(type: RequestType.delivery);

      if (mounted) {
        setState(() {
          _itemRequests = itemRequests;
          _serviceRequests = serviceRequests;
          _rideRequests = rideRequests;
          _rentalRequests = rentalRequests;
          _deliveryRequests = deliveryRequests;
          
          // Combine all requests for the "All" tab
          _allRequests = [
            ...itemRequests,
            ...serviceRequests,
            ...rideRequests,
            ...rentalRequests,
            ...deliveryRequests,
          ];
          
          // Sort all requests by creation date (newest first)
          _allRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          // Initialize filtered requests with all requests
          _filteredRequests = List.from(_allRequests);
          
          _isLoading = false;
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

  void _filterRequests() {
    setState(() {
      _filteredRequests = _allRequests.where((request) {
        // Apply search filter
        bool matchesSearch = _searchQuery.isEmpty ||
            request.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            request.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            request.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            request.location.toLowerCase().contains(_searchQuery.toLowerCase());

        // Apply type filter
        bool matchesType = _selectedFilter == null || request.type == _selectedFilter;

        return matchesSearch && matchesType;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Requests'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllRequests,
          ),
        ],
      ),
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search requests...',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () {
                              _searchController.clear();
                              _searchQuery = '';
                              _filterRequests();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    _searchQuery = value;
                    _filterRequests();
                  },
                ),
                const SizedBox(height: 12),
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', null),
                      const SizedBox(width: 8),
                      _buildFilterChip('Items', RequestType.item),
                      const SizedBox(width: 8),
                      _buildFilterChip('Services', RequestType.service),
                      const SizedBox(width: 8),
                      _buildFilterChip('Rides', RequestType.ride),
                      const SizedBox(width: 8),
                      _buildFilterChip('Rentals', RequestType.rental),
                      const SizedBox(width: 8),
                      _buildFilterChip('Delivery', RequestType.delivery),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Content Area
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadAllRequests,
              child: _buildRequestsList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, RequestType? type) {
    bool isSelected = _selectedFilter == type;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSelected)
            Icon(
              Icons.check_circle,
              size: 16,
              color: Colors.white,
            ),
          if (isSelected) const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? type : null;
          _filterRequests();
        });
      },
      backgroundColor: Colors.grey[200],
      selectedColor: _getRequestTypeColor(type ?? RequestType.item),
      showCheckmark: false,
      elevation: isSelected ? 3 : 0,
      pressElevation: 6,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      side: BorderSide.none,
    );
  }

  Widget _buildRequestsList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'Error loading requests',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAllRequests,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredRequests.isEmpty && _allRequests.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No matching requests found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Try adjusting your search or filter',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                _searchQuery = '';
                _selectedFilter = null;
                _filterRequests();
              },
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      );
    }

    if (_allRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No requests found',
              style: TextStyle(
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
      itemCount: _filteredRequests.length + 1, // +1 for summary header
      itemBuilder: (context, index) {
        // First item is the summary
        if (index == 0) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
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
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.dashboard,
                      color: Colors.grey[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Request Overview',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Showing ${_filteredRequests.length}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem('Items', _itemRequests.length, Colors.blue),
                    _buildSummaryItem('Services', _serviceRequests.length, Colors.green),
                    _buildSummaryItem('Rides', _rideRequests.length, Colors.orange),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryItem('Rentals', _rentalRequests.length, Colors.purple),
                    _buildSummaryItem('Delivery', _deliveryRequests.length, Colors.teal),
                    _buildSummaryItem('Total', _allRequests.length, Colors.grey),
                  ],
                ),
              ],
            ),
          );
        }
        
        // Remaining items are requests (adjust index)
        final request = _filteredRequests[index - 1];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Stack(
            children: [
              _buildRequestCard(request),
              // Add type badge in top-right corner
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getRequestTypeColor(request.type),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getRequestTypeLabel(request.type),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 32, // Fixed height for consistent layout
              alignment: Alignment.center,
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: count >= 1000 ? 16 : count >= 100 ? 18 : 20, // Dynamic sizing
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              height: 16, // Fixed height for label
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRequestTypeColor(RequestType type) {
    switch (type) {
      case RequestType.item:
        return Colors.blue;
      case RequestType.service:
        return Colors.green;
      case RequestType.ride:
        return Colors.orange;
      case RequestType.rental:
        return Colors.purple;
      case RequestType.delivery:
        return Colors.teal;
    }
  }

  String _getRequestTypeLabel(RequestType type) {
    switch (type) {
      case RequestType.item:
        return 'ITEM';
      case RequestType.service:
        return 'SERVICE';
      case RequestType.ride:
        return 'RIDE';
      case RequestType.rental:
        return 'RENTAL';
      case RequestType.delivery:
        return 'DELIVERY';
    }
  }

  Widget _buildRequestCard(RequestModel request) {
    switch (request.type) {
      case RequestType.item:
        return _buildItemCard(request);
      case RequestType.service:
        return _buildServiceCard(request);
      case RequestType.ride:
        return _buildRideCard(request);
      case RequestType.rental:
        return _buildRentalCard(request);
      case RequestType.delivery:
        return _buildDeliveryCard(request);
    }
  }

  Widget _buildItemCard(RequestModel request) {
    return GestureDetector(
      onTap: () => _navigateToDetail(request),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Image or placeholder
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: request.imageUrls.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            request.imageUrls.first,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.shopping_bag,
                              color: Colors.grey[400],
                              size: 24,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.shopping_bag,
                          color: Colors.grey[400],
                          size: 24,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        request.category,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'LKR ${request.budget.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.condition.toString().split('.').last.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Location and date row
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    request.location,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  DateFormat('MMM dd').format(request.createdAt.toDate()),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceCard(RequestModel request) {
    return GestureDetector(
      onTap: () => _navigateToDetail(request),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.build,
                    color: Colors.black54,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _getServiceUrgencyText(request.condition.toString()),
                        style: TextStyle(
                          fontSize: 14,
                          color: _getServiceUrgencyColor(request.condition.toString()),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'LKR ${request.budget.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      request.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Description
            Text(
              request.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            
            // Bottom info row
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    request.location,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (request.deadline != null) ...[
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd').format(request.deadline!.toDate()),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for service urgency
  String _getServiceUrgencyText(String condition) {
    switch (condition.toLowerCase()) {
      case 'low':
        return 'Low Priority';
      case 'medium':
        return 'Medium Priority';
      case 'high':
        return 'High Priority';
      case 'urgent':
        return 'Urgent';
      default:
        return 'Standard';
    }
  }

  Color _getServiceUrgencyColor(String condition) {
    switch (condition.toLowerCase()) {
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

  Widget _buildRideCard(RequestModel request) {
    // Extract pickup and destination from description
    String pickup = request.location; // Fallback to location field
    String destination = 'Destination not specified';
    
    // Parse description to extract FROM and TO
    if (request.description.contains('- From:') && request.description.contains('- To:')) {
      final lines = request.description.split('\n');
      for (String line in lines) {
        if (line.trim().startsWith('- From:')) {
          pickup = line.replaceFirst('- From:', '').trim();
        } else if (line.trim().startsWith('- To:')) {
          destination = line.replaceFirst('- To:', '').trim();
        }
      }
    }
    
    return GestureDetector(
      onTap: () => _navigateToDetail(request),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMapPlaceholder(request),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRouteInfo(pickup, Colors.green),
                  const SizedBox(height: 8),
                  _buildRouteInfo(destination, Colors.red),
                  const Divider(height: 24),
                  _buildTripDetails(request),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPlaceholder(RequestModel request) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        color: Colors.grey[200],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: MapPatternPainter(),
              ),
            ),
            Positioned.fill(
              child: CustomPaint(
                painter: RoutePainter(),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                    )
                  ],
                ),
                child: Icon(
                  _getVehicleIcon(request.category),
                  size: 24,
                  color: Colors.black87,
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getRideUrgencyColor(request.condition.toString()).withOpacity(0.8),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRentalCard(RequestModel request) {
    return GestureDetector(
      onTap: () => _navigateToDetail(request),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.access_time,
                    color: Colors.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Rental Service',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'LKR ${request.budget.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              request.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    request.location,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (request.deadline != null) ...[
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd').format(request.deadline!.toDate()),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryCard(RequestModel request) {
    return GestureDetector(
      onTap: () => _navigateToDetail(request),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.local_shipping,
                    color: Colors.blue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Delivery Service',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'LKR ${request.budget.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              request.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    request.location,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (request.deadline != null) ...[
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM dd').format(request.deadline!.toDate()),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteInfo(String location, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            location,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTripDetails(RequestModel request) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.person_outline, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              _extractPassengers(request),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        Row(
          children: [
            Icon(Icons.social_distance, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Text(
              '${_extractDistance(request)} km',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        Text(
          DateFormat('h:mm a').format(request.createdAt.toDate()),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  IconData _getVehicleIcon(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'car':
        return Icons.directions_car;
      case 'bike':
        return Icons.two_wheeler;
      case 'threewheeler':
        return Icons.directions_car;
      case 'van':
        return Icons.airport_shuttle;
      case 'suv':
        return Icons.directions_car;
      default:
        return Icons.directions_car;
    }
  }

  String _extractPassengers(RequestModel request) {
    if (request.description.contains('Passengers:')) {
      final match = RegExp(r'Passengers:\s*(\d+)').firstMatch(request.description);
      if (match != null) {
        return match.group(1) ?? '1';
      }
    }
    return '1';
  }

  String _extractDistance(RequestModel request) {
    if (request.description.contains('Distance:')) {
      final match = RegExp(r'Distance:\s*([\d.]+)\s*km').firstMatch(request.description);
      if (match != null) {
        return match.group(1) ?? '0';
      }
    }
    return '0';
  }

  Color _getRideUrgencyColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'standard':
        return Colors.green;
      case 'priority':
        return Colors.orange;
      case 'express':
        return Colors.red;
      default:
        return Colors.green;
    }
  }

  void _navigateToDetail(RequestModel request) {
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
      case RequestType.rental:
        detailScreen = RentalRequestDetailScreen(request: request);
        break;
      case RequestType.delivery:
        detailScreen = DeliveryRequestDetailScreen(request: request);
        break;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => detailScreen,
      ),
    );
  }
}

class MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 15) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 15) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.8)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(30, size.height * 0.8);
    path.cubicTo(
      size.width * 0.3, size.height * 0.2,
      size.width * 0.7, size.height * 1.1,
      size.width - 30, size.height * 0.4,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
