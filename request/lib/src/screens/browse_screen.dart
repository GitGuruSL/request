import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/request_model.dart';
import '../models/enhanced_user_model.dart';
import '../services/enhanced_request_service.dart';
import '../services/country_service.dart';
import 'unified_request_response/unified_request_view_screen.dart';
import 'requests/ride/view_ride_request_screen.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final EnhancedRequestService _requestService = EnhancedRequestService();
  String _searchQuery = '';
  RequestType? _selectedType;
  String _selectedLocation = 'All Locations';
  List<RequestModel> _requests = [];
  bool _isLoading = true;
  String? _error; // Add error state
  String? _currencySymbol;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _currencySymbol = CountryService.instance.getCurrencySymbol();
      await _loadRequests();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading data: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadRequests() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      print('📥 Attempting to fetch requests from Firestore...');
      
      // Most basic query possible - get all documents from requests collection
      final querySnapshot = await FirebaseFirestore.instance
          .collection('requests')
          .get();
          
      print('📊 Found ${querySnapshot.docs.length} documents in requests collection');
      
      if (mounted) {
        final List<RequestModel> loadedRequests = [];
        
        // Let's inspect the first document to understand the data structure
        if (querySnapshot.docs.isNotEmpty) {
          final firstDoc = querySnapshot.docs.first;
          final data = firstDoc.data();
          
          print('🔍 First document structure:');
          print('Document ID: ${firstDoc.id}');
          print('Document data keys: ${data.keys.toList()}');
          
          // Print each field and its type
          data.forEach((key, value) {
            print('Field "$key": ${value.runtimeType} = $value');
          });
        }
        
        for (var doc in querySnapshot.docs) {
          try {
            final data = doc.data();
            data['id'] = doc.id; // Add document ID
            
            // Use the fromMap constructor which handles all type conversions properly
            final request = RequestModel.fromMap(data);
            
            loadedRequests.add(request);
            print('✅ Successfully parsed document ${doc.id}');
          } catch (e) {
            print('❌ Error parsing document ${doc.id}: $e');
            // Continue with other documents even if one fails
          }
        }
        
        _requests = loadedRequests;
        print('📝 Successfully loaded ${_requests.length} requests');
        setState(() {});
      }
    } catch (e) {
      print('💥 Error loading requests: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load requests: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<RequestModel> get _filteredRequests {
    List<RequestModel> filtered = List.from(_requests);
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((request) =>
        request.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        request.description.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    // Apply type filter
    if (_selectedType != null) {
      filtered = filtered.where((request) => request.type == _selectedType).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background, // Use app theme background
      appBar: AppBar(
        title: const Text('Browse Requests'),
        backgroundColor: theme.colorScheme.background, // Match background
        elevation: 0, // No shadow
        foregroundColor: theme.textTheme.bodyLarge?.color, // Use theme text color
        titleSpacing: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Search and Filter Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextFormField(
                  decoration: InputDecoration(
                    hintText: 'Search requests...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white, // White background for the field
                    border: InputBorder.none, // No border
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                // Filter Row
                Row(
                  children: [
                    // Category Filter
                    Expanded(
                      child: DropdownButtonFormField<RequestType>(
                        value: _selectedType,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          filled: true,
                          fillColor: Colors.white, // White background
                          border: InputBorder.none, // No border
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Categories')),
                          ...RequestType.values.map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(_getRequestTypeDisplayName(type)),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Location Filter
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedLocation,
                        decoration: InputDecoration(
                          labelText: 'Location',
                          filled: true,
                          fillColor: Colors.white, // White background
                          border: InputBorder.none, // No border
                        ),
                        items: const [
                          DropdownMenuItem(value: 'All Locations', child: Text('All Locations')),
                          DropdownMenuItem(value: 'Nearby', child: Text('Nearby')),
                          DropdownMenuItem(value: 'City Center', child: Text('City Center')),
                          DropdownMenuItem(value: 'Suburbs', child: Text('Suburbs')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedLocation = value ?? 'All Locations';
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Results List
          Expanded(
            child: _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadRequests,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _filteredRequests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No requests found',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isNotEmpty || _selectedType != null
                                  ? 'Try adjusting your search or filters'
                                  : 'No requests available at the moment',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadRequests,
                              child: const Text('Refresh'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredRequests.length,
                        itemBuilder: (context, index) {
                          final request = _filteredRequests[index];
                          return _buildRequestCard(request);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestOption({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToCreateRequest(RequestType type) {
    Navigator.pop(context); // Close the bottom sheet first
    
    String routeName;
    switch (type) {
      case RequestType.item:
        routeName = '/create-item-request';
        break;
      case RequestType.service:
        routeName = '/create-service-request';
        break;
      case RequestType.ride:
        routeName = '/create-ride-request';
        break;
      case RequestType.delivery:
        routeName = '/create-delivery-request';
        break;
      case RequestType.rental:
        routeName = '/create-rental-request';
        break;
      case RequestType.price:
        routeName = '/price'; // Navigate to existing price comparison screen
        break;
    }
    
    Navigator.pushNamed(context, routeName).then((_) {
      // Refresh the requests list when returning from create screen
      _loadRequests();
    });
  }

  Widget _buildRequestCard(RequestModel request) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.grey[200],
          child: Icon(
            _getIconForRequestType(request.type),
            color: Colors.grey[600],
          ),
        ),
        title: Text(
          request.title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              request.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  _getRequestTypeName(request.type),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (request.budget != null) ...[
                  Text(
                    ' • ',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${_currencySymbol ?? '\$'}${request.budget}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
            Text(
              request.location?.city ?? 'Location',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        onTap: () {
          _showRequestDetail(request);
        },
      ),
    );
  }

  void _showRequestDetail(RequestModel request) {
    // Use specific view screen for ride requests, unified for others
    if (request.type == RequestType.ride) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ViewRideRequestScreen(requestId: request.id),
        ),
      ).then((_) => _loadRequests()); // Refresh list when returning
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UnifiedRequestViewScreen(requestId: request.id),
        ),
      ).then((_) => _loadRequests()); // Refresh list when returning
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon!'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  String _getRequestTypeName(RequestType type) {
    switch (type) {
      case RequestType.item:
        return 'Item Request';
      case RequestType.service:
        return 'Service';
      case RequestType.ride:
        return 'Ride';
      case RequestType.delivery:
        return 'Delivery';
      case RequestType.rental:
        return 'Rental';
      case RequestType.price:
        return 'Price Check';
    }
  }

  String _getRequestTypeDisplayName(RequestType type) {
    switch (type) {
      case RequestType.item:
        return 'Item Request';
      case RequestType.service:
        return 'Service';
      case RequestType.ride:
        return 'Ride';
      case RequestType.delivery:
        return 'Delivery';
      case RequestType.rental:
        return 'Rental';
      case RequestType.price:
        return 'Price Check';
    }
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  IconData _getIconForRequestType(RequestType type) {
    switch (type) {
      case RequestType.item:
        return Icons.shopping_bag;
      case RequestType.service:
        return Icons.build;
      case RequestType.ride:
        return Icons.directions_car;
      case RequestType.delivery:
        return Icons.local_shipping;
      case RequestType.rental:
        return Icons.key;
      case RequestType.price:
        return Icons.compare_arrows;
    }
  }
}
