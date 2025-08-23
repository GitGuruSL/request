import 'package:flutter/material.dart';
import 'dart:ui';
import '../../services/country_filtered_data_service.dart';
import '../../services/user_registration_service.dart';
import '../../services/country_service.dart';
import '../../models/request_model.dart' as models;
import '../../screens/unified_request_response/unified_request_view_screen.dart';
import '../../screens/requests/ride/view_ride_request_screen.dart';

class BrowseRequestsScreen extends StatefulWidget {
  const BrowseRequestsScreen({super.key});

  @override
  State<BrowseRequestsScreen> createState() => _BrowseRequestsScreenState();
}

class _BrowseRequestsScreenState extends State<BrowseRequestsScreen> {
  final List<models.RequestModel> _requests = [];
  bool _initialLoading = true;
  bool _fetchingMore = false;
  bool _hasMore = true;
  int _page = 1;
  String? _error;
  bool _needsCountrySelection = false;

  String _selectedCategory = 'All';
  List<String> _allowedRequestTypes = ['item', 'service', 'rent'];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _scrollController.addListener(_onScroll);
  }

  // Normalize model type to one of our display tabs
  String _displayTypeFor(models.RequestModel r) {
    // Prefer explicit DB origin if present in typeSpecificData/request_type
    String t = r.type.name.toLowerCase();
    final meta = r.typeSpecificData;
    final dbType = meta['request_type']?.toString() ?? meta['type']?.toString();
    if (dbType != null && dbType.isNotEmpty) {
      t = dbType.toLowerCase();
      if (t.startsWith('requesttype.')) {
        t = t.substring('requesttype.'.length);
      }
    }
    switch (t) {
      case 'item':
        return 'Items';
      case 'service':
        return 'Service';
      case 'rental':
      case 'rent':
        return 'Rent';
      case 'delivery':
        return 'Delivery';
      case 'ride':
        return 'Ride';
      default:
        // Fallback to keyword check only if type is unknown
        return _getRequestTypeFromCategory(r.type.name, r.title, r.description);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _initialLoading = true;
      _error = null;
      _page = 1;
      _hasMore = true;
      _requests.clear();
    });
    // Ensure country is set or restored; if missing, prompt selection
    if (CountryService.instance.countryCode == null) {
      await CountryService.instance.loadPersistedCountry();
    }
    if (CountryService.instance.countryCode == null) {
      setState(() {
        _needsCountrySelection = true;
        _initialLoading = false;
      });
      return;
    }
    // Load allowed request types based on user registrations (driver/delivery)
    try {
      final allowed =
          await UserRegistrationService.instance.getAllowedRequestTypes();
      _allowedRequestTypes = allowed;
    } catch (_) {}

    await _fetchPage(reset: true);
  }

  Future<void> _fetchPage({bool reset = false}) async {
    if (_fetchingMore || (!_hasMore && !reset)) return;
    setState(() => _fetchingMore = true);
    try {
      // Map selected UI category to backend request_type
      String? selectedBackendType;
      switch (_selectedCategory) {
        case 'Items':
          selectedBackendType = 'item';
          break;
        case 'Service':
          selectedBackendType = 'service';
          break;
        case 'Rent':
          selectedBackendType = 'rent';
          break;
        case 'Delivery':
          selectedBackendType = 'delivery';
          break;
        case 'Ride':
          selectedBackendType = 'ride';
          break;
        default:
          selectedBackendType = null; // All
      }

      final response = await CountryFilteredDataService.instance.getRequests(
        page: _page,
        limit: 20,
        // Do not pass UI label as categoryId; use request_type for server filtering
        requestType: selectedBackendType,
      );
      if (response != null) {
        if (reset) _requests.clear();

        // Use the stream to get properly converted RequestModel objects, with same type filter
        await for (final modelRequests in CountryFilteredDataService.instance
            .getCountryRequestsStream(limit: 20, type: selectedBackendType)) {
          _requests.addAll(modelRequests);
          break; // Only take the first emission since we're not subscribing
        }

        _hasMore = _page < response.pagination.totalPages;
        _page += 1;
      }
    } catch (e) {
      _error = 'Failed to load requests';
    } finally {
      setState(() {
        _initialLoading = false;
        _fetchingMore = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_fetchingMore &&
        _hasMore) {
      _fetchPage();
    }
  }

  List<models.RequestModel> get _filteredRequests {
    // First, enforce role-based gating
    final gated = _requests.where((r) {
      final mapped = _mapRequestModelToTypeKey(r);
      return _allowedRequestTypes.contains(mapped);
    }).toList();

    if (_selectedCategory == 'All') return gated;
    return gated.where((r) {
      final requestType = _displayTypeFor(r);
      return requestType == _selectedCategory;
    }).toList();
  }

  // Map RequestModel to a backend type key used by allowed types list
  String _mapRequestModelToTypeKey(models.RequestModel r) {
    switch (r.type.name.toLowerCase()) {
      case 'item':
        return 'item';
      case 'service':
        return 'service';
      case 'rental':
      case 'rent':
        return 'rent';
      case 'delivery':
        return 'delivery';
      case 'ride':
        return 'ride';
      case 'price':
        return 'price';
      default:
        return r.type.name.toLowerCase();
    }
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.screenBackground,
      body: _needsCountrySelection
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.flag_outlined,
                        size: 72, color: Colors.blueGrey),
                    const SizedBox(height: 16),
                    const Text(
                      'Select your country',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose your country to browse requests near you.',
                      style: TextStyle(color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/welcome'),
                      child: const Text('Select Country'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                _Header(onRefresh: _loadInitial),
                _buildCategoryChips(),
                _buildResultCount(),
                Expanded(
                  child: _initialLoading
                      ? _buildLoadingSkeleton()
                      : _error != null
                          ? _buildErrorState()
                          : _filteredRequests.isEmpty
                              ? _buildEmptyState()
                              : RefreshIndicator(
                                  onRefresh: _loadInitial,
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    itemCount: _filteredRequests.length +
                                        (_fetchingMore ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index == _filteredRequests.length) {
                                        return const Padding(
                                          padding: EdgeInsets.symmetric(
                                              vertical: 16),
                                          child: Center(
                                              child:
                                                  CircularProgressIndicator()),
                                        );
                                      }
                                      final request = _filteredRequests[index];
                                      return _buildRequestCard(request);
                                    },
                                  ),
                                ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to create request
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoryChips() {
    // Build categories dynamically from allowed types
    final base = <String>['All'];
    if (_allowedRequestTypes.contains('item')) base.add('Items');
    if (_allowedRequestTypes.contains('service')) base.add('Service');
    if (_allowedRequestTypes.contains('rent')) base.add('Rent');
    if (_allowedRequestTypes.contains('delivery')) base.add('Delivery');
    if (_allowedRequestTypes.contains('ride')) base.add('Ride');
    final categories = base;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = category == _selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (_) {
                setState(() {
                  _selectedCategory = category;
                  _page = 1;
                  _hasMore = true;
                });
                _loadInitial();
              },
              backgroundColor: _Palette.screenBackground,
              selectedColor: _Palette.primaryBlue.withOpacity(0.08),
              checkmarkColor: _Palette.primaryBlue,
              labelStyle: TextStyle(
                color:
                    isSelected ? _Palette.primaryBlue : _Palette.secondaryText,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide.none,
              ),
              elevation: 0,
              pressElevation: 0,
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultCount() {
    final count = _filteredRequests.length;
    // Handle pluralization gracefully
    final requestsFoundText =
        count == 1 ? '1 request found' : '$count requests found';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Text(
            requestsFoundText,
            style: TextStyle(
              color: _Palette.secondaryText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (_fetchingMore && !_initialLoading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 64, color: _Palette.secondaryText),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Something went wrong',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _Palette.primaryText),
            ),
            const SizedBox(height: 8),
            Text(
              'We couldn\'t load requests. Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _Palette.secondaryText),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadInitial,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: _Palette.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No requests here',
              style: TextStyle(
                fontSize: 18,
                color: _Palette.primaryText,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try selecting a different category or check back later for new opportunities.',
              style: TextStyle(
                fontSize: 15,
                color: _Palette.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(models.RequestModel request) {
    final requestType = _displayTypeFor(request);
    final style = _typeStyle(requestType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _Palette.cardBackground,
      ),
      child: InkWell(
        onTap: () => _showRequestDetails(request),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(style.icon, color: style.bg, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _Palette.primaryText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: style.bg.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$requestType Request',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: style.bg,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _relativeTime(request.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: _Palette.secondaryText,
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
              Text(
                request.description,
                style: TextStyle(
                  fontSize: 14,
                  color: _Palette.secondaryText,
                  height: 1.45,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 14),
              if (request.location?.city != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 16, color: _Palette.secondaryText),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        request.location!.city!,
                        style: TextStyle(
                            fontSize: 13, color: _Palette.secondaryText),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to map categories to request types
  String _getRequestTypeFromCategory(
      String? categoryName, String? title, String? description) {
    if (categoryName == null && title == null) return 'Items';

    // Check title and description for keywords first
    String searchText =
        (title ?? '').toLowerCase() + ' ' + (description ?? '').toLowerCase();

    // Check for delivery keywords
    if (searchText.contains('delivery') ||
        searchText.contains('deliver') ||
        searchText.contains('courier') ||
        searchText.contains('shipping')) {
      return 'Delivery';
    }

    // Check for rental keywords
    if (searchText.contains('rent') ||
        searchText.contains('rental') ||
        searchText.contains('lease') ||
        searchText.contains('hire')) {
      return 'Rent';
    }

    // Check for service keywords
    if (searchText.contains('service') ||
        searchText.contains('repair') ||
        searchText.contains('maintenance') ||
        searchText.contains('fix') ||
        searchText.contains('consultation') ||
        searchText.contains('cleaning') || // Added cleaning
        searchText.contains('support')) {
      return 'Service';
    }

    // Check for ride keywords
    if (searchText.contains('ride') ||
        searchText.contains('transport') ||
        searchText.contains('taxi') ||
        searchText.contains('driver') ||
        searchText.contains('travel') ||
        searchText.contains('trip')) {
      return 'Ride';
    }

    // Default to Items for any physical objects or general requests
    return 'Items';
  }

  void _showRequestDetails(models.RequestModel request) {
    // Use specific view screen for ride requests, unified for others
    if (request.type.name == 'ride') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ViewRideRequestScreen(requestId: request.id),
        ),
      ).then((_) => _loadInitial()); // Refresh list when returning
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UnifiedRequestViewScreen(requestId: request.id),
        ),
      ).then((_) => _loadInitial()); // Refresh list when returning
    }
  }

  // Loading skeleton shimmer-like blocks
  Widget _buildLoadingSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Container(
          height: 150, // Adjusted height
          decoration: BoxDecoration(
            color: _Palette.cardBackground,
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  _TypeStyle _typeStyle(String type) {
    switch (type) {
      case 'Delivery':
        return _TypeStyle(
            Icons.local_shipping, _Palette.vibrantTeal, Colors.white);
      case 'Ride':
        return _TypeStyle(
            Icons.directions_car, _Palette.primaryBlue, Colors.white);
      case 'Service':
        return _TypeStyle(Icons.build, _Palette.deepPurple, Colors.white);
      case 'Rent':
        return _TypeStyle(Icons.weekend, _Palette.warmOrange, Colors.white);
      case 'Items':
      default:
        return _TypeStyle(
            Icons.shopping_bag, _Palette.sunnyYellow, _Palette.primaryText);
    }
  }
}

// Gradient header with search, Android 16-inspired
class _Header extends StatelessWidget {
  final VoidCallback onRefresh;
  const _Header({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _Palette.cardBackground,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Discover',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: _Palette.primaryText,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: onRefresh,
                    tooltip: 'Refresh',
                    color: _Palette.secondaryText,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const _SearchBar(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _Palette.screenBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Find requests by skill, item, or service',
          hintStyle: TextStyle(color: _Palette.secondaryText, fontSize: 15),
          prefixIcon:
              Icon(Icons.search_outlined, color: _Palette.secondaryText),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }
}

class _TypeStyle {
  final IconData icon;
  final Color bg;
  final Color fg;
  _TypeStyle(this.icon, this.bg, this.fg);
}

// Modern, vibrant, and accessible color palette
class _Palette {
  // Primary & Accents
  static const primaryBlue = Color(0xFF007AFF);
  static const vibrantTeal = Color(0xFF30D158);
  static const warmOrange = Color(0xFFFF9500);
  static const deepPurple = Color(0xFF5856D6);
  static const sunnyYellow = Color(0xFFFFCC00);

  // Neutrals
  static const cardBackground = Color(0xFFFFFFFF);
  static const screenBackground = Color(0xFFF2F2F7);
  static const primaryText = Color(0xFF1C1C1E);
  static const secondaryText = Color(0xFF6E6E73);
}
