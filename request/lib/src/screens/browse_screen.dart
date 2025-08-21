import 'package:flutter/material.dart';
import '../models/request_model.dart';
import '../models/enhanced_user_model.dart';
import '../services/country_filtered_data_service.dart';
import '../services/country_service.dart';
import '../services/module_service.dart';
import '../services/user_registration_service.dart';
import 'unified_request_response/unified_request_view_screen.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final CountryFilteredDataService _dataService =
      CountryFilteredDataService.instance;
  final UserRegistrationService _registrationService =
      UserRegistrationService.instance;
  String _searchQuery = '';
  RequestType? _selectedType;
  List<RequestModel> _requests = [];
  bool _isLoading = true;
  String? _error;
  String? _currencySymbol;
  CountryModules? _countryModules;
  List<RequestType> _enabledRequestTypes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      _currencySymbol = CountryService.instance.getCurrencySymbol();

      // Load user's allowed request types based on registrations
      final allowedRequestTypeStrings =
          await _registrationService.getAllowedRequestTypes();

      // Load country modules configuration
      final countryCode = CountryService.instance.countryCode;
      if (countryCode != null) {
        _countryModules = await ModuleService.getCountryModules(countryCode);
        _enabledRequestTypes =
            _getEnabledRequestTypes(allowedRequestTypeStrings);
      }

      await _loadRequests();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<RequestType> _getEnabledRequestTypes(List<String> allowedTypes) {
    if (_countryModules == null) return [];

    List<RequestType> enabledTypes = [];
    _countryModules!.modules.forEach((moduleId, isEnabled) {
      if (isEnabled) {
        // Map module ID to request type string for comparison
        String requestTypeString = _getRequestTypeStringFromModuleId(moduleId);
        if (allowedTypes.contains(requestTypeString)) {
          RequestType? type = _getRequestTypeFromModuleId(moduleId);
          if (type != null) {
            enabledTypes.add(type);
          }
        }
      }
    });

    return enabledTypes;
  }

  /// Map module ID to request type string used in backend
  String _getRequestTypeStringFromModuleId(String moduleId) {
    switch (moduleId) {
      case 'item':
        return 'item';
      case 'service':
        return 'service';
      case 'rent':
        return 'rent'; // Module uses 'rent', backend uses 'rent'
      case 'delivery':
        return 'delivery';
      case 'ride':
        return 'ride';
      case 'price':
        return 'price';
      default:
        return moduleId;
    }
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
    try {
      setState(() => _isLoading = true);

      // Use the same method as the original browse screen
      final requestsStream = _dataService.getCountryRequestsStream(
        status: null, // Get all statuses
        type: _selectedType?.name, // pass enum name as string for shim services
        limit: 50,
      );

      // Listen to the stream and get the first result
      final requests = await requestsStream.first;

      if (mounted) {
        setState(() {
          _requests = requests;
          _isLoading = false;
          _error = null;
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

  // Add color helper methods
  Color _getTypeColor(RequestType type) {
    switch (type) {
      case RequestType.item:
        return const Color(0xFFFF6B35); // Orange/red
      case RequestType.service:
        return const Color(0xFF00BCD4); // Teal
      case RequestType.rental:
        return const Color(0xFF2196F3); // Blue
      case RequestType.delivery:
        return const Color(0xFF4CAF50); // Green
      case RequestType.ride:
        return const Color(0xFFFFC107); // Yellow
      case RequestType.price:
        return const Color(0xFF9C27B0); // Purple
    }
  }

  Color _getLightTypeColor(RequestType type) {
    switch (type) {
      case RequestType.item:
        return const Color(0xFFFF6B35).withOpacity(0.1); // Light orange/red
      case RequestType.service:
        return const Color(0xFF00BCD4).withOpacity(0.1); // Light teal
      case RequestType.rental:
        return const Color(0xFF2196F3).withOpacity(0.1); // Light blue
      case RequestType.delivery:
        return const Color(0xFF4CAF50).withOpacity(0.1); // Light green
      case RequestType.ride:
        return const Color(0xFFFFC107).withOpacity(0.1); // Light yellow
      case RequestType.price:
        return const Color(0xFF9C27B0).withOpacity(0.1); // Light purple
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Light gray background
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Modern Search Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Discover Requests',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Find requests that match your skills',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Modern Search Bar
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F5F5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText:
                                  'Search by title, location, description... (use commas to separate)',
                              hintStyle: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: Colors.grey[500],
                                size: 20,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: Icon(
                                        Icons.clear,
                                        color: Colors.grey[500],
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                          ),
                        ),

                        // Quick Filter Chips
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip('All', _selectedType == null),
                              ..._enabledRequestTypes.map((type) =>
                                  _buildFilterChip(_getTypeDisplayName(type),
                                      _selectedType == type)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Results List
                  Expanded(
                    child: _error != null
                        ? _buildErrorWidget()
                        : _buildRequestsList(),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            if (label == 'All') {
              _selectedType = null;
            } else {
              _selectedType = _getRequestTypeFromName(label);
            }
          });
        },
        backgroundColor: Colors.grey[100],
        selectedColor: Colors.blue[50],
        checkmarkColor: Colors.blue[600],
        labelStyle: TextStyle(
          color: isSelected ? Colors.blue[600] : Colors.grey[700],
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? Colors.blue[200]! : Colors.grey[300]!,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Error',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRequestsList() {
    final filteredRequests = _getFilteredRequests();

    if (filteredRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No requests found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredRequests.length,
        itemBuilder: (context, index) {
          return _buildRequestCard(filteredRequests[index]);
        },
      ),
    );
  }

  Widget _buildRequestCard(RequestModel request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _getLightTypeColor(request.type),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getTypeColor(request.type).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _navigateToRequestView(request),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with type and status
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getTypeColor(request.type),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getTypeDisplayName(request.type),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      request.status.toString().split('.').last.toUpperCase(),
                      style: TextStyle(
                        color: Colors.green[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Title
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

              // Description
              Text(
                request.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Footer with budget and location
              Row(
                children: [
                  if (request.budget != null) ...[
                    Icon(
                      Icons.attach_money,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    Text(
                      '${_currencySymbol ?? ''} ${request.budget!.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _getTypeColor(request.type),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (request.location?.city != null) ...[
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        request.location!.city!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTypeDisplayName(RequestType type) {
    switch (type) {
      case RequestType.item:
        return 'Items';
      case RequestType.service:
        return 'Services';
      case RequestType.rental:
        return 'Rentals';
      case RequestType.delivery:
        return 'Delivery';
      case RequestType.ride:
        return 'Rides';
      case RequestType.price:
        return 'Quotes';
    }
  }

  RequestType? _getRequestTypeFromName(String name) {
    switch (name) {
      case 'Items':
        return RequestType.item;
      case 'Services':
        return RequestType.service;
      case 'Rentals':
        return RequestType.rental;
      case 'Delivery':
        return RequestType.delivery;
      case 'Rides':
        return RequestType.ride;
      case 'Quotes':
        return RequestType.price;
      default:
        return null;
    }
  }

  String _getModuleIdFromRequestType(RequestType requestType) {
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
    }
  }

  List<RequestModel> _getFilteredRequests() {
    var filtered = List<RequestModel>.from(_requests);

    // Apply module-based filtering first - only show requests for enabled modules
    if (_countryModules != null) {
      filtered = filtered.where((request) {
        // Get the module ID for this request type
        String moduleId = _getModuleIdFromRequestType(request.type);

        // Check if this module is enabled for the user's country
        return _countryModules!.isModuleEnabled(moduleId);
      }).toList();
    }

    // Filter by type
    if (_selectedType != null) {
      filtered =
          filtered.where((request) => request.type == _selectedType).toList();
    }

    // Filter by search query with comma support
    if (_searchQuery.isNotEmpty) {
      final searchTerms = _searchQuery
          .toLowerCase()
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty);

      filtered = filtered.where((request) {
        final title = request.title.toLowerCase();
        final description = request.description.toLowerCase();
        final location = request.location?.city?.toLowerCase() ?? '';
        final type = _getTypeDisplayName(request.type).toLowerCase();

        return searchTerms.any((term) =>
            title.contains(term) ||
            description.contains(term) ||
            location.contains(term) ||
            type.contains(term));
      }).toList();
    }

    return filtered;
  }

  void _navigateToRequestView(RequestModel request) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UnifiedRequestViewScreen(requestId: request.id),
      ),
    );
  }
}
