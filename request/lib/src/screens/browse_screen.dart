import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/request_model.dart';
import '../models/enhanced_user_model.dart';
import '../services/enhanced_request_service.dart';
import '../services/country_service.dart';

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
            
            // Create a simple display model instead of using RequestModel
            final simpleRequest = {
              'id': doc.id,
              'title': data['title']?.toString() ?? 'No Title',
              'description': data['description']?.toString() ?? 'No Description',
              'type': data['type']?.toString() ?? 'item',
              'status': data['status']?.toString() ?? 'active',
            };
            
            // For now, create a minimal RequestModel with fallback values
            final request = RequestModel(
              id: doc.id,
              requesterId: data['requesterId']?.toString() ?? '',
              title: data['title']?.toString() ?? 'No Title',
              description: data['description']?.toString() ?? 'No Description',
              type: _parseRequestType(data['type']?.toString()),
              status: _parseRequestStatus(data['status']?.toString()),
              createdAt: DateTime.now(), // Use current time as fallback
              updatedAt: DateTime.now(), // Use current time as fallback
            );
            
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

  RequestType _parseRequestType(String? type) {
    switch (type?.toLowerCase()) {
      case 'service':
        return RequestType.service;
      case 'ride':
        return RequestType.ride;
      case 'delivery':
        return RequestType.delivery;
      case 'rental':
        return RequestType.rental;
      case 'price':
        return RequestType.price;
      default:
        return RequestType.item;
    }
  }

  RequestStatus _parseRequestStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
      case 'open':
        return RequestStatus.active;
      case 'inprogress':
        return RequestStatus.inProgress;
      case 'completed':
        return RequestStatus.completed;
      case 'cancelled':
        return RequestStatus.cancelled;
      case 'expired':
        return RequestStatus.expired;
      default:
        return RequestStatus.draft;
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(request.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${_getRequestTypeName(request.type)}'),
            const SizedBox(height: 8),
            Text('Description: ${request.description}'),
            const SizedBox(height: 8),
            if (request.budget != null)
              Text('Budget: ${_currencySymbol ?? '\$'}${request.budget}'),
            const SizedBox(height: 8),
            Text('Location: ${request.location?.city ?? 'Not specified'}'),
            const SizedBox(height: 8),
            Text('Status: ${request.status}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showComingSoon('Respond to Request');
            },
            child: const Text('Respond'),
          ),
        ],
      ),
    );
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
