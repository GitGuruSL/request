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
      final response = await CountryFilteredDataService.instance.getRequests(
        page: _page,
        limit: 20,
        categoryId: _selectedCategory != 'All'
            ? _selectedCategory
            : null, // TODO map to categoryId
      );
      if (response != null) {
        if (reset) _requests.clear();

        // Use the stream to get properly converted RequestModel objects
        await for (final modelRequests in CountryFilteredDataService.instance
            .getCountryRequestsStream(limit: 20)) {
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
            padding: const EdgeInsets.only(right: 12),
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
              backgroundColor: _Palette.lightBeige,
              selectedColor: _Palette.pastelViolet.withOpacity(0.35),
              checkmarkColor: _Palette.darkViolet,
              labelStyle: TextStyle(
                color: isSelected ? _Palette.darkViolet : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                    color: isSelected
                        ? _Palette.darkViolet.withOpacity(0.25)
                        : Colors.transparent,
                    width: 0.5),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '${_filteredRequests.length} requests found',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const Spacer(),
          if (_fetchingMore && !_initialLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(_error ?? 'Error',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _loadInitial,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  _Palette.pastelViolet.withOpacity(0.25),
                  _Palette.lightOrange.withOpacity(0.25),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 40,
              color: _Palette.saturatedOrange,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No requests found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or check back later',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(models.RequestModel request) {
    // Map request types to a richer style
    final requestType = _displayTypeFor(request);
    final style = _typeStyle(requestType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: style.bg, // Solid card color per request type
      ),
      child: InkWell(
        onTap: () => _showRequestDetails(request),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white, // white icon circle
                      shape: BoxShape.circle,
                    ),
                    child: Icon(style.icon, color: style.fg, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _onColor(style.bg),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _onColor(style.bg).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color:
                                        _onColor(style.bg).withOpacity(0.24)),
                              ),
                              child: Text(
                                '$requestType Request',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _onColor(style.bg),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _relativeTime(request.createdAt),
                              style: TextStyle(
                                  fontSize: 11,
                                  color: _onColor(style.bg).withOpacity(0.75)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                request.description,
                style: TextStyle(
                  fontSize: 14,
                  color: _onColor(style.bg).withOpacity(0.72),
                  height: 1.35,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 16, color: _onColor(style.bg).withOpacity(0.72)),
                  const SizedBox(width: 12),
                  Icon(Icons.favorite_border,
                      size: 16, color: _onColor(style.bg).withOpacity(0.72)),
                  const Spacer(),
                  if (request.location?.city != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 14,
                            color: _onColor(style.bg).withOpacity(0.72)),
                        const SizedBox(width: 4),
                        Text(
                          request.location!.city!,
                          style: TextStyle(
                              fontSize: 12,
                              color: _onColor(style.bg).withOpacity(0.72)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Container(
          height: 110,
          decoration: BoxDecoration(
            color: _Palette.lightBeige,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
    );
  }

  _TypeStyle _typeStyle(String type) {
    switch (type) {
      case 'Delivery':
        return _TypeStyle(
            Icons.local_shipping_outlined, _Palette.lightGreen, Colors.white);
      case 'Ride':
        return _TypeStyle(
            Icons.directions_car_outlined, _Palette.darkViolet, Colors.white);
      case 'Service':
        return _TypeStyle(
            Icons.build_outlined, _Palette.pastelViolet, _Palette.darkViolet);
      case 'Rent':
        return _TypeStyle(Icons.apartment_outlined, _Palette.lightOrange,
            _Palette.darkViolet);
      case 'Items':
      default:
        return _TypeStyle(Icons.shopping_bag_outlined, _Palette.saturatedOrange,
            Colors.white);
    }
  }

  // Pick readable foreground (white/black) based on background luminance
  Color _onColor(Color background) {
    return background.computeLuminance() < 0.5 ? Colors.white : Colors.black87;
  }
}

// Gradient header with search, Android 16-inspired
class _Header extends StatelessWidget {
  final VoidCallback onRefresh;
  const _Header({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _Palette.saturatedOrange.withOpacity(0.20),
            _Palette.pastelViolet.withOpacity(0.20),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Discover Requests',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: onRefresh,
                    tooltip: 'Refresh',
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Find requests that match your skills',
          hintStyle: TextStyle(color: Colors.grey[500]),
          prefixIcon: Icon(Icons.search_outlined, color: Colors.grey[500]),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

// Bright palette based on provided swatches
class _Palette {
  static const pastelViolet = Color(0xFFC4C3E3); // #C4C3E3
  static const darkViolet = Color(0xFF504E76); // #504E76
  static const lightBeige = Color(0xFFFDF8E2); // #FDF8E2
  static const lightGreen = Color(0xFFA3B565); // #A3B565
  static const lightOrange = Color(0xFFFCDD9D); // #FCDD9D
  static const saturatedOrange = Color(0xFFF1642E); // #F1642E
}
