import 'package:flutter/material.dart';
import '../../services/country_filtered_data_service.dart';
import '../../models/request_model.dart' as models;
import '../../screens/unified_request_response/unified_request_view_screen.dart';

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

  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Items',
    'Service',
    'Rental',
    'Delivery',
    'Ride',
  ];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadInitial();
    _scrollController.addListener(_onScroll);
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
        // Convert REST requests to models
        final modelRequests = response.requests.map((restRequest) {
          return RequestModel(
            id: restRequest.id,
            title: restRequest.title ?? '',
            description: restRequest.description ?? '',
            categoryName: restRequest.categoryName ?? '',
            budgetMin: restRequest.budgetMin,
            budgetMax: restRequest.budgetMax,
            location: restRequest.location ?? '',
            status: restRequest.status ?? '',
            userId: restRequest.userId ?? '',
            createdAt: restRequest.createdAt,
            updatedAt: restRequest.updatedAt,
          );
        }).toList();
        _requests.addAll(modelRequests);
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

  List<RequestModel> get _filteredRequests {
    if (_selectedCategory == 'All') return _requests;
    return _requests.where((r) {
      String requestType =
          _getRequestTypeFromCategory(r.categoryName, r.title, r.description);
      return requestType == _selectedCategory;
    }).toList();
  }

  String _formatBudget(RequestModel r) {
    if (r.budget == null) return 'No budget';
    final cur = r.currency ?? '';
    return '$cur${r.budget!.toStringAsFixed(0)}';
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
      body: Column(
        children: [
          // Modern header without AppBar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
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
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _loadInitial,
                          tooltip: 'Refresh',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Search bar (moved up to replace subtitle)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Find requests that match your skills',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          prefixIcon: Icon(Icons.search_outlined,
                              color: Colors.grey[500]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        onChanged: (value) {
                          // Add search functionality here
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _buildCategoryChips(),
          _buildResultCount(),
          Expanded(
            child: _initialLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorState()
                    : _filteredRequests.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadInitial,
                            child: ListView.builder(
                              controller: _scrollController,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _filteredRequests.length +
                                  (_fetchingMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index == _filteredRequests.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                        child: CircularProgressIndicator()),
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
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
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
              backgroundColor: Colors.grey[100],
              selectedColor: Colors.blue[50],
              checkmarkColor: Colors.blue[600],
              labelStyle: TextStyle(
                color: isSelected ? Colors.blue[600] : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.transparent, width: 0),
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
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
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

  Widget _buildRequestCard(RequestModel request) {
    // Map request types to colors based on content
    String requestType = _getRequestTypeFromCategory(
        request.categoryName, request.title, request.description);

    // Request TYPE colors
    final typeColors = {
      'Items': const Color(0xFFFF6B35).withOpacity(0.1), // Orange
      'Service': const Color(0xFF00BCD4).withOpacity(0.1), // Teal
      'Rent': const Color(0xFF2196F3).withOpacity(0.1), // Blue
      'Delivery': const Color(0xFF4CAF50).withOpacity(0.1), // Green
      'Ride': const Color(0xFFFFC107).withOpacity(0.1), // Yellow
    };

    final typeTagColors = {
      'Items': const Color(0xFFFF6B35), // Orange
      'Service': const Color(0xFF00BCD4), // Teal
      'Rent': const Color(0xFF2196F3), // Blue
      'Delivery': const Color(0xFF4CAF50), // Green
      'Ride': const Color(0xFFFFC107), // Yellow
    };

    final cardColor = typeColors[requestType] ?? Colors.grey[50]!;
    final tagColor = typeTagColors[requestType] ?? Colors.grey[400]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showRequestDetails(request),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category chip with modern design
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${request.categoryName ?? 'General'}${request.subcategoryName != null ? ' • ${request.subcategoryName}' : ''}',
                      style: TextStyle(
                        color: tagColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _relativeTime(request.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Title
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

              const SizedBox(height: 6),

              // Description
              Text(
                request.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Bottom row with responses/likes on left and location on right
              Row(
                children: [
                  // Left side - responses and likes icons
                  Row(
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.favorite_border,
                        size: 16,
                        color: Colors.grey[500],
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Right side - location
                  if (request.cityName != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          request.cityName!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          maxLines: 1,
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

  void _showRequestDetails(RequestModel request) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UnifiedRequestViewScreen(requestId: request.id),
      ),
    ).then((_) => _loadInitial()); // Refresh list when returning
  }
}
