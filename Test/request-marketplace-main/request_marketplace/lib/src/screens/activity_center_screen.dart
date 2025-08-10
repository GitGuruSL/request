import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/request_service.dart';
import '../services/response_service.dart';
import '../models/request_model.dart';
import '../models/response_model.dart';

class ActivityCenterScreen extends StatefulWidget {
  const ActivityCenterScreen({super.key});

  @override
  State<ActivityCenterScreen> createState() => _ActivityCenterScreenState();
}

class _ActivityCenterScreenState extends State<ActivityCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _auth = FirebaseAuth.instance;
  final _requestService = RequestService();
  final _responseService = ResponseService();
  
  List<RequestModel> _userRequests = [];
  List<ResponseModel> _userResponses = [];
  bool _isLoadingRequests = true;
  bool _isLoadingResponses = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserRequests();
    _loadUserResponses();
  }

  Future<void> _loadUserRequests() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final requests = await _requestService.getUserRequests();
        setState(() {
          _userRequests = requests;
          _isLoadingRequests = false;
        });
      } else {
        setState(() {
          _isLoadingRequests = false;
        });
      }
    } catch (e) {
      print('Error loading user requests: $e');
      setState(() {
        _isLoadingRequests = false;
      });
    }
  }

  Future<void> _loadUserResponses() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final responses = await _responseService.getUserResponses();
        setState(() {
          _userResponses = responses;
          _isLoadingResponses = false;
        });
      } else {
        setState(() {
          _isLoadingResponses = false;
        });
      }
    } catch (e) {
      print('Error loading user responses: $e');
      setState(() {
        _isLoadingResponses = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBFE),
      appBar: AppBar(
        title: const Text('Activity Center'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1D1B20),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Color(0xFF1D1B20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6750A4),
          unselectedLabelColor: const Color(0xFF49454F),
          indicatorColor: const Color(0xFF6750A4),
          tabs: const [
            Tab(text: 'My Requests', icon: Icon(Icons.send_outlined)),
            Tab(text: 'Responses', icon: Icon(Icons.reply_outlined)),
            Tab(text: 'Transactions', icon: Icon(Icons.receipt_long_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyRequestsTab(),
          _buildResponsesTab(),
          _buildTransactionsTab(),
        ],
      ),
    );
  }

  Widget _buildMyRequestsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6750A4), Color(0xFF9575CD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.send, color: Colors.white, size: 28),
                SizedBox(height: 12),
                Text(
                  'My Requests',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Track all your posted requests',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Request Cards
          if (_isLoadingRequests)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (_userRequests.isNotEmpty)
            ..._userRequests.map((request) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildRequestCard(
                title: request.title,
                category: request.category.toString().split('.').last,
                status: request.status,
                responses: 0, // TODO: Add response count to RequestModel
                timestamp: _formatTimestamp(request.createdAt.toDate()),
                statusColor: _getStatusColor(request.status),
              ),
            )).toList()
          else
            // Demo data when no real requests
            Column(
              children: [
                _buildRequestCard(
                  title: 'Need iPhone 15 Pro',
                  category: 'Electronics',
                  status: 'Active',
                  responses: 5,
                  timestamp: '2 hours ago',
                  statusColor: Colors.green,
                ),
                const SizedBox(height: 16),
                _buildRequestCard(
                  title: 'Looking for Wedding Photographer',
                  category: 'Services',
                  status: 'Pending',
                  responses: 2,
                  timestamp: '1 day ago',
                  statusColor: Colors.orange,
                ),
                const SizedBox(height: 16),
                _buildRequestCard(
                  title: 'Delivery from Colombo to Kandy',
                  category: 'Logistics',
                  status: 'Completed',
                  responses: 8,
                  timestamp: '3 days ago',
                  statusColor: Colors.blue,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildResponsesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.reply, color: Colors.white, size: 28),
                SizedBox(height: 12),
                Text(
                  'My Responses',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Responses you sent to requests',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Response Cards
          if (_isLoadingResponses)
            const Center(
              child: CircularProgressIndicator(),
            )
          else if (_userResponses.isNotEmpty)
            ..._userResponses.map((response) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildResponseCard(
                requestTitle: 'Request', // TODO: Fetch request title from requestId
                yourOffer: response.offeredPrice != null 
                    ? 'LKR ${response.offeredPrice!.toStringAsFixed(0)}'
                    : response.message,
                status: response.status,
                timestamp: _formatTimestamp(response.createdAt.toDate()),
                statusColor: _getResponseStatusColor(response.status),
              ),
            )).toList()
          else
            // Demo data when no real responses
            Column(
              children: [
                _buildResponseCard(
                  requestTitle: 'iPhone 15 Pro Max needed',
                  yourOffer: 'LKR 450,000',
                  status: 'accepted',
                  timestamp: '1 hour ago',
                  statusColor: Colors.green,
                ),
                const SizedBox(height: 16),
                _buildResponseCard(
                  requestTitle: 'Wedding Photography Service',
                  yourOffer: 'LKR 75,000 for full package',
                  status: 'pending',
                  timestamp: '4 hours ago',
                  statusColor: Colors.orange,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.receipt_long, color: Colors.white, size: 28),
                SizedBox(height: 12),
                Text(
                  'Transaction History',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'All your completed transactions',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Transaction Cards
          _buildTransactionCard(
            title: 'Samsung Galaxy S24',
            amount: 'LKR 320,000',
            type: 'Purchase',
            date: '2024-01-15',
            transactionId: 'TXN001234',
          ),
          const SizedBox(height: 16),
          _buildTransactionCard(
            title: 'Delivery Service',
            amount: 'LKR 2,500',
            type: 'Payment',
            date: '2024-01-12',
            transactionId: 'TXN001233',
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard({
    required String title,
    required String category,
    required String status,
    required int responses,
    required String timestamp,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF1D1B20),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.category, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                category,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(width: 16),
              Icon(Icons.reply, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '$responses responses',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                timestamp,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to request details
                },
                child: const Text('View Details'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResponseCard({
    required String requestTitle,
    required String yourOffer,
    required String status,
    required String timestamp,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  requestTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF1D1B20),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your Offer: $yourOffer',
            style: const TextStyle(
              color: Color(0xFF6750A4),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                timestamp,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to response details
                },
                child: const Text('View Details'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard({
    required String title,
    required String amount,
    required String type,
    required String date,
    required String transactionId,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF1D1B20),
                  ),
                ),
              ),
              Text(
                amount,
                style: const TextStyle(
                  color: Color(0xFF1976D2),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.payment, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                type,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(width: 16),
              Icon(Icons.date_range, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                date,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ID: $transactionId',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              TextButton(
                onPressed: () {
                  // Show transaction receipt
                },
                child: const Text('View Receipt'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
      case 'active':
        return Colors.green;
      case 'in_progress':
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
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
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
