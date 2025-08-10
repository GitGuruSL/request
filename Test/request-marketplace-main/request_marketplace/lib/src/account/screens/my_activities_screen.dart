import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/request_model.dart';
import '../../models/response_model.dart';
import '../../models/user_model.dart';
import '../../services/request_service.dart';
import '../../services/response_service.dart';
import '../../services/user_service.dart';
import '../../requests/screens/item_request_detail_screen.dart';
import '../../requests/screens/service_request_detail_screen.dart';
import '../../requests/screens/ride_request_detail_screen.dart';


class MyActivitiesScreen extends StatefulWidget {
  const MyActivitiesScreen({super.key});

  @override
  State<MyActivitiesScreen> createState() => _MyActivitiesScreenState();
}

class _MyActivitiesScreenState extends State<MyActivitiesScreen>
    with SingleTickerProviderStateMixin {
  final RequestService _requestService = RequestService();
  final ResponseService _responseService = ResponseService();
  final UserService _userService = UserService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  late TabController _tabController;
  
  List<RequestModel> _myRequests = [];
  List<ResponseModel> _myResponses = [];
  final Map<String, UserModel> _usersCache = {};
  final Map<String, RequestModel> _requestsCache = {};
  
  bool _isLoadingRequests = true;
  bool _isLoadingResponses = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
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

  Future<void> _loadData() async {
    await Future.wait([
      _loadMyRequests(),
      _loadMyResponses(),
    ]);
  }

  Future<void> _loadMyRequests() async {
    setState(() {
      _isLoadingRequests = true;
      _error = null;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final requests = await _requestService.getUserRequests();
        setState(() {
          _myRequests = requests;
          _isLoadingRequests = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingRequests = false;
      });
    }
  }

  Future<void> _loadMyResponses() async {
    setState(() {
      _isLoadingResponses = true;
      _error = null;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final responses = await _responseService.getUserResponses();
        
        // Load request details and user data for each response
        for (final response in responses) {
          if (!_requestsCache.containsKey(response.requestId)) {
            try {
              final request = await _requestService.getRequestById(response.requestId);
              if (request != null) {
                _requestsCache[response.requestId] = request;
                
                // Load request owner user data
                if (!_usersCache.containsKey(request.userId)) {
                  final requestOwner = await _userService.getUserById(request.userId);
                  if (requestOwner != null) {
                    _usersCache[request.userId] = requestOwner;
                  }
                }
              }
            } catch (e) {
              print('Error loading request ${response.requestId}: $e');
            }
          }
        }
        
        setState(() {
          _myResponses = responses;
          _isLoadingResponses = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoadingResponses = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Activities'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).primaryColor,
          tabs: [
            Tab(
              text: 'My Requests',
              icon: Badge(
                label: Text('${_myRequests.length}'),
                child: const Icon(Icons.post_add),
              ),
            ),
            Tab(
              text: 'My Responses',
              icon: Badge(
                label: Text('${_myResponses.length}'),
                child: const Icon(Icons.reply),
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildRequestsTab(),
            _buildResponsesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsTab() {
    if (_isLoadingRequests) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMyRequests,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_myRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No requests yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first request to get started',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myRequests.length,
      itemBuilder: (context, index) {
        final request = _myRequests[index];
        return _buildRequestCard(request);
      },
    );
  }

  Widget _buildResponsesTab() {
    if (_isLoadingResponses) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMyResponses,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_myResponses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.reply_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'No responses yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Start responding to requests to help others',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myResponses.length,
      itemBuilder: (context, index) {
        final response = _myResponses[index];
        return _buildResponseCard(response);
      },
    );
  }

  Widget _buildRequestCard(RequestModel request) {
    final statusColor = _getRequestStatusColor(request.status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          _navigateToRequestDetail(context, request);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      request.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                request.description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(request.createdAt.toDate()),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.category, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    request.category,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
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

  Widget _buildResponseCard(ResponseModel response) {
    final request = _requestsCache[response.requestId];
    final requestOwner = request != null ? _usersCache[request.userId] : null;
    final statusColor = _getResponseStatusColor(response.status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: request != null ? () {
          _navigateToRequestDetail(context, request);
        } : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Response to: ${request?.title ?? 'Unknown Request'}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (requestOwner != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'By: ${requestOwner.displayName}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      response.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                response.message,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (response.offeredPrice != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Offered: \$${response.offeredPrice!.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(response.createdAt.toDate()),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  const Spacer(),
                  if (response.status == 'accepted') ...[
                    Icon(Icons.check_circle, size: 16, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      'Accepted',
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else if (response.status == 'rejected') ...[
                    Icon(Icons.cancel, size: 16, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      'Not selected',
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ] else ...[
                    Icon(Icons.hourglass_empty, size: 16, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      'Pending',
                      style: TextStyle(
                        fontSize: 12,
                        color: statusColor,
                        fontWeight: FontWeight.w600,
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

  Color _getRequestStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'fulfilled':
        return Colors.blue;
      case 'expired':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getResponseStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
