import 'package:flutter/material.dart';
import '../models/request_model.dart';
import '../models/enhanced_user_model.dart';
import '../services/country_filtered_data_service.dart';
import '../services/country_service.dart';
import '../services/module_service.dart';
import 'unified_request_response/unified_request_view_screen.dart';
import 'requests/ride/view_ride_request_screen.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final CountryFilteredDataService _dataService = CountryFilteredDataService.instance;
  String _searchQuery = '';
  RequestType? _selectedType;
  String _selectedLocation = 'All Locations';
  List<RequestModel> _requests = [];
  bool _isLoading = true;
  String? _error; // Add error state
  String? _currencySymbol;
  CountryModules? _countryModules;
  List<RequestType> _enabledRequestTypes = [];
  bool _showFilters = false; // Add filter visibility state

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _currencySymbol = CountryService.instance.getCurrencySymbol();
      
      // Load country modules configuration
      final countryCode = CountryService.instance.countryCode;
      if (countryCode != null) {
        _countryModules = await ModuleService.getCountryModules(countryCode);
        _enabledRequestTypes = _getEnabledRequestTypes();
      }
      
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

  List<RequestType> _getEnabledRequestTypes() {
    if (_countryModules == null) return RequestType.values;
    
    List<RequestType> enabledTypes = [];
    _countryModules!.modules.forEach((moduleId, isEnabled) {
      if (isEnabled) {
        RequestType? type = _getRequestTypeFromModuleId(moduleId);
        if (type != null) {
          enabledTypes.add(type);
        }
      }
    });
    
    return enabledTypes;
  }

  RequestType? _getRequestTypeFromModuleId(String moduleId) {
    switch (moduleId) {
      case 'item':
        return RequestType.item;
      case 'service':
        return RequestType.service;
      case 'rent':
        return RequestType.rental;
      case 'delivery':
        return RequestType.delivery;
      case 'ride':
        return RequestType.ride;
      case 'price':
        return RequestType.price;
      default:
        return null;
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
      print('📥 Fetching country-filtered requests...');
      
      // Use centralized service which automatically filters by user's country
      final requestsStream = _dataService.getCountryRequestsStream(
        status: null, // Get all statuses
        type: _selectedType,
        limit: 50,
      );
      
      // Listen to the stream and get the first result
      final loadedRequests = await requestsStream.first;
          
      print('📊 Found ${loadedRequests.length} country-filtered requests');
      
      if (mounted) {
        _requests = loadedRequests;
        print('📝 Successfully loaded ${_requests.length} requests for country: ${CountryService.instance.countryCode}');
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

  String? _getModuleIdFromRequestType(RequestType requestType) {
    switch (requestType) {
      case RequestType.item:
        return 'item';
      case RequestType.service:
        return 'service';
      case RequestType.rental:
        return 'rent';
      case RequestType.delivery:
        return 'delivery';
      case RequestType.ride:
        return 'ride';
      case RequestType.price:
        return 'price';
      default:
        return null;
    }
  }

  List<RequestModel> get _filteredRequests {
    List<RequestModel> filtered = List.from(_requests);
    
    // Apply module-based filtering first - only show requests for enabled modules
    if (_countryModules != null) {
      filtered = filtered.where((request) {
        // Get the module ID for this request type
        String? moduleId = _getModuleIdFromRequestType(request.type);
        if (moduleId == null) return false;
        
        // Check if this module is enabled for the user's country
        return _countryModules!.isModuleEnabled(moduleId);
      }).toList();
    }
    
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
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: _showFilters ? Colors.blue : theme.textTheme.bodyLarge?.color,
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextFormField(
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
          ),

          // Collapsible filter section
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showFilters ? null : 0,
            child: _showFilters
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: theme.colorScheme.surface.withOpacity(0.5),
                    child: Column(
                      children: [
                        // Category filter
                        Row(
                          children: [
                            const Text('Category:', style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<RequestType>(
                                value: _selectedType,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                hint: const Text('All Categories'),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('All Categories')),
                                  ..._enabledRequestTypes.map((type) {
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
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Location filter
                        Row(
                          children: [
                            const Text('Location:', style: TextStyle(fontWeight: FontWeight.w500)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedLocation,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        const SizedBox(height: 8),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
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
    final iconData = _getIconForRequestType(request.type);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconData['color'].withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            iconData['icon'],
            color: iconData['color'],
            size: 22,
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
                    request.budget != null 
                      ? CountryService.instance.formatPrice(request.budget!)
                      : 'Budget not specified',
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

  Map<String, dynamic> _getIconForRequestType(RequestType type) {
    switch (type) {
      case RequestType.item:
        return {
          'icon': Icons.shopping_bag,
          'color': Colors.orange,
        };
      case RequestType.service:
        return {
          'icon': Icons.build,
          'color': Colors.teal,
        };
      case RequestType.ride:
        return {
          'icon': Icons.directions_car,
          'color': Colors.yellow.shade700,
        };
      case RequestType.delivery:
        return {
          'icon': Icons.local_shipping,
          'color': Colors.green,
        };
      case RequestType.rental:
        return {
          'icon': Icons.key,
          'color': Colors.blue,
        };
      case RequestType.price:
        return {
          'icon': Icons.trending_up,
          'color': Colors.purple,
        };
    }
  }
}
