import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/request_model.dart';
import '../../models/enhanced_user_model.dart';
import '../../services/enhanced_request_service.dart';
import '../../services/enhanced_user_service.dart';
import 'unified_response_create_screen.dart';

class UnifiedRequestViewScreen extends StatefulWidget {
  final String requestId;

  const UnifiedRequestViewScreen({super.key, required this.requestId});

  @override
  State<UnifiedRequestViewScreen> createState() => _UnifiedRequestViewScreenState();
}

class _UnifiedRequestViewScreenState extends State<UnifiedRequestViewScreen> {
  final EnhancedRequestService _requestService = EnhancedRequestService();
  final EnhancedUserService _userService = EnhancedUserService();
  
  RequestModel? _request;
  List<ResponseModel> _responses = [];
  bool _isLoading = true;
  bool _isOwner = false;

  @override
  void initState() {
    super.initState();
    _loadRequestData();
  }

  Future<void> _loadRequestData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final request = await _requestService.getRequest(widget.requestId);
      final responses = await _requestService.getRequestResponses(widget.requestId);
      final currentUser = await _userService.getCurrentUserModel();
      
      if (mounted) {
        setState(() {
          _request = request;
          _responses = responses;
          _isOwner = currentUser?.uid == request?.requesterId;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading...'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_request == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Request Not Found'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Request not found or has been removed.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTypeDisplayName(_request!.type)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _loadRequestData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRequestDetails(),
              const SizedBox(height: 24),
              _buildTypeSpecificDetails(),
              const SizedBox(height: 24),
              _buildResponsesSection(),
            ],
          ),
        ),
      ),
      floatingActionButton: !_isOwner
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UnifiedResponseCreateScreen(request: _request!),
                  ),
                ).then((_) => _loadRequestData());
              },
              icon: const Icon(Icons.reply),
              label: const Text('Respond'),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  String _getTypeDisplayName(RequestType type) {
    switch (type) {
      case RequestType.item:
        return 'Item Request';
      case RequestType.service:
        return 'Service Request';
      case RequestType.delivery:
        return 'Delivery Request';
      case RequestType.rental:
        return 'Rental Request';
      case RequestType.ride:
        return 'Ride Request'; // Should not reach here due to redirect above
      case RequestType.price:
        return 'Price Request'; // Should not reach here due to redirect above
    }
  }

  Widget _buildRequestDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getTypeIcon(_request!.type),
                color: Colors.blue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _request!.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _request!.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.grey[600], size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _request!.location?.address ?? 'Location not specified',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ),
            ],
          ),
          if (_request!.budget != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: Colors.green[600], size: 16),
                const SizedBox(width: 4),
                Text(
                  'Budget: \$${_request!.budget?.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.green[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.grey[600], size: 16),
              const SizedBox(width: 4),
              Text(
                'Posted ${_formatDate(_request!.createdAt)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _request!.status == RequestStatus.open ? Colors.green[50] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _request!.status.name.toUpperCase(),
                  style: TextStyle(
                    color: _request!.status == RequestStatus.open ? Colors.green[700] : Colors.grey[700],
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(RequestType type) {
    switch (type) {
      case RequestType.item:
        return Icons.shopping_bag;
      case RequestType.service:
        return Icons.build;
      case RequestType.delivery:
        return Icons.local_shipping;
      case RequestType.rental:
        return Icons.access_time;
      case RequestType.ride:
        return Icons.directions_car;
      case RequestType.price:
        return Icons.compare_arrows;
    }
  }

  Widget _buildTypeSpecificDetails() {
    switch (_request!.type) {
      case RequestType.item:
        return _buildItemFields();
      case RequestType.service:
        return _buildServiceFields();
      case RequestType.delivery:
        return _buildDeliveryFields();
      case RequestType.rental:
        return _buildRentalFields();
      case RequestType.ride:
        return const SizedBox(); // Should not reach here
      case RequestType.price:
        return const SizedBox(); // Should not reach here
    }
  }

  Widget _buildItemFields() {
    final itemData = _request!.itemData;
    if (itemData == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Item Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (itemData.specifications.isNotEmpty) ...[
            const Text(
              'Specifications:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            ...itemData.specifications.entries.map((entry) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text('• ${entry.key}: ${entry.value}'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceFields() {
    final serviceData = _request!.serviceData;
    if (serviceData == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Service Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Category: ', style: TextStyle(color: Colors.grey[600])),
              Text(serviceData.category),
            ],
          ),
          if (serviceData.urgencyLevel != UrgencyLevel.flexible) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Text('Urgency: ', style: TextStyle(color: Colors.grey[600])),
                Text(serviceData.urgencyLevel.name.toUpperCase()),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliveryFields() {
    final deliveryData = _request!.deliveryData;
    if (deliveryData == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Pickup: ', style: TextStyle(color: Colors.grey[600])),
              Expanded(child: Text(_request!.location?.address ?? 'Pickup location not specified')),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('Drop-off: ', style: TextStyle(color: Colors.grey[600])),
              Expanded(child: Text(_request!.destinationLocation?.address ?? 'Dropoff location not specified')),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('Item Type: ', style: TextStyle(color: Colors.grey[600])),
              Text(deliveryData.package.category ?? 'Not specified'),
            ],
          ),
          if (deliveryData.package.weight > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Text('Weight: ', style: TextStyle(color: Colors.grey[600])),
                Text('${deliveryData.package.weight} kg'),
              ],
            ),
          ],
          if (deliveryData.isFragile || deliveryData.requireSignature) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Text('Special: ', style: TextStyle(color: Colors.grey[600])),
                Text(deliveryData.isFragile ? 'Fragile' : 'Signature Required'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRentalFields() {
    final rentData = _request!.rentalData;
    if (rentData == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rental Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Item Type: ', style: TextStyle(color: Colors.grey[600])),
              Text(rentData.itemCategory),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('Start Date: ', style: TextStyle(color: Colors.grey[600])),
              Text(rentData.startDate.toString().split(' ')[0]),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('End Date: ', style: TextStyle(color: Colors.grey[600])),
              Text(rentData.endDate.toString().split(' ')[0]),
            ],
          ),
          if (rentData.specifications.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Text('Specifications: ', style: TextStyle(color: Colors.grey[600])),
                Text(rentData.specifications.entries.map((e) => '${e.key}: ${e.value}').join(', ')),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResponsesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Responses',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_responses.length}',
                style: TextStyle(
                  color: Colors.blue[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_responses.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Center(
              child: Column(
                children: [
                  Icon(Icons.inbox, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text(
                    'No responses yet',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  Text(
                    'Be the first to respond to this request!',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _responses.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final response = _responses[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.blue[100],
                          child: Text(
                            'U',
                            style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'User ${response.responderId}', // TODO: Get actual user name
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                _formatDate(response.createdAt),
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '\$${response.price?.toStringAsFixed(2) ?? 'Not specified'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(response.message),
                    if (_isOwner) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                // TODO: Implement reject response
                              },
                              child: const Text('Decline'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                // TODO: Implement accept response
                              },
                              child: const Text('Accept'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}