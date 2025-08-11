import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/request_model.dart';
import '../../models/enhanced_user_model.dart';
import '../../services/enhanced_request_service.dart';
import '../../services/enhanced_user_service.dart';

class UnifiedResponseViewScreen extends StatefulWidget {
  final String responseId;
  final RequestModel request;

  const UnifiedResponseViewScreen({
    super.key, 
    required this.responseId,
    required this.request,
  });

  @override
  State<UnifiedResponseViewScreen> createState() => _UnifiedResponseViewScreenState();
}

class _UnifiedResponseViewScreenState extends State<UnifiedResponseViewScreen> {
  final EnhancedRequestService _requestService = EnhancedRequestService();
  final EnhancedUserService _userService = EnhancedUserService();
  
  ResponseModel? _response;
  EnhancedUserModel? _responder;
  bool _isLoading = true;
  bool _isRequestOwner = false;

  @override
  void initState() {
    super.initState();
    _loadResponseData();
  }

  Future<void> _loadResponseData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _requestService.getResponse(widget.responseId);
      final responder = response != null 
          ? await _userService.getUserModel(response.responderId)
          : null;
      final currentUser = await _userService.getCurrentUserModel();
      
      if (mounted) {
        setState(() {
          _response = response;
          _responder = responder;
          _isRequestOwner = currentUser?.uid == widget.request.requesterId;
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
            content: Text('Error loading response: $e'),
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

    if (_response == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Response Not Found'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(
          child: Text('Response not found or has been removed.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Response to ${_getTypeDisplayName(widget.request.type)}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRequestSummary(),
            const SizedBox(height: 16),
            _buildResponderInfo(),
            const SizedBox(height: 16),
            _buildResponseDetails(),
            const SizedBox(height: 16),
            _buildTypeSpecificResponse(),
            if (_isRequestOwner) ...[
              const SizedBox(height: 24),
              _buildActionButtons(),
            ],
          ],
        ),
      ),
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
        return 'Ride Request';
      case RequestType.price:
        return 'Price Request';
    }
  }

  Widget _buildRequestSummary() {
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
            'Original Request',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Text(
            widget.request.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            widget.request.description,
            style: TextStyle(color: Colors.grey[700]),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (widget.request.budget != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.account_balance_wallet, color: Colors.green[600], size: 16),
                const SizedBox(width: 4),
                Text(
                  'Budget: \$${widget.request.budget?.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.green[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResponderInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.blue[100],
            backgroundImage: _responder?.profileImageUrl != null 
                ? NetworkImage(_responder!.profileImageUrl!)
                : null,
            child: _responder?.profileImageUrl == null
                ? Text(
                    _responder?.name?.isNotEmpty == true 
                        ? _responder!.name![0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                      fontSize: 18,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _responder?.name ?? 'Anonymous User',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${_responder?.rating?.toStringAsFixed(1) ?? '0.0'} (${_responder?.reviewCount ?? 0} reviews)',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                if (_responder?.location?.address != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey[600], size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          _responder!.location!.address!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () {
              // TODO: Navigate to user profile
            },
            child: const Text('View Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseDetails() {
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
              const Text(
                'Response Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (_response!.price != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '\$${_response!.price?.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _response!.message,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.grey[600], size: 16),
              const SizedBox(width: 4),
              Text(
                'Responded ${_formatDate(_response!.createdAt)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(_response!.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _response!.status.name.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(_response!.status),
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

  Color _getStatusColor(ResponseStatus status) {
    switch (status) {
      case ResponseStatus.pending:
        return Colors.orange;
      case ResponseStatus.accepted:
        return Colors.green;
      case ResponseStatus.rejected:
        return Colors.red;
      case ResponseStatus.completed:
        return Colors.blue;
    }
  }

  Widget _buildTypeSpecificResponse() {
    switch (widget.request.type) {
      case RequestType.item:
        return _buildItemResponse();
      case RequestType.service:
        return _buildServiceResponse();
      case RequestType.delivery:
        return _buildDeliveryResponse();
      case RequestType.rental:
        return _buildRentalResponse();
      case RequestType.ride:
        return const SizedBox();
      case RequestType.price:
        return const SizedBox();
    }
  }

  Widget _buildItemResponse() {
    final itemResponse = _response!.itemResponseData;
    if (itemResponse == null) return const SizedBox();

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
            'Item Offer Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (itemResponse.condition != null) ...[
            Row(
              children: [
                Text('Condition: ', style: TextStyle(color: Colors.grey[600])),
                Text(itemResponse.condition!),
              ],
            ),
            const SizedBox(height: 6),
          ],
          if (itemResponse.deliveryMethod != null) ...[
            Row(
              children: [
                Text('Delivery: ', style: TextStyle(color: Colors.grey[600])),
                Text(itemResponse.deliveryMethod!),
              ],
            ),
            const SizedBox(height: 6),
          ],
          if (itemResponse.estimatedDelivery != null) ...[
            Row(
              children: [
                Text('Estimated Delivery: ', style: TextStyle(color: Colors.grey[600])),
                Text('${itemResponse.estimatedDelivery!} days'),
              ],
            ),
            const SizedBox(height: 6),
          ],
          if (itemResponse.warranty != null) ...[
            Row(
              children: [
                Text('Warranty: ', style: TextStyle(color: Colors.grey[600])),
                Text(itemResponse.warranty!),
              ],
            ),
            const SizedBox(height: 6),
          ],
          if (itemResponse.photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Photos:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: itemResponse.photos.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        itemResponse.photos[index],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[300],
                            child: const Icon(Icons.error),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceResponse() {
    final serviceResponse = _response!.serviceResponseData;
    if (serviceResponse == null) return const SizedBox();

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
            'Service Offer Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (serviceResponse.estimatedDuration != null) ...[
            Row(
              children: [
                Text('Duration: ', style: TextStyle(color: Colors.grey[600])),
                Text('${serviceResponse.estimatedDuration} hours'),
              ],
            ),
            const SizedBox(height: 6),
          ],
          if (serviceResponse.availableStartDate != null) ...[
            Row(
              children: [
                Text('Available From: ', style: TextStyle(color: Colors.grey[600])),
                Text(serviceResponse.availableStartDate.toString().split(' ')[0]),
              ],
            ),
            const SizedBox(height: 6),
          ],
          if (serviceResponse.qualifications.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Qualifications:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            ...serviceResponse.qualifications.map((qual) => 
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 2),
                child: Text('• $qual'),
              ),
            ),
          ],
          if (serviceResponse.portfolioLinks.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Portfolio:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            ...serviceResponse.portfolioLinks.map((link) => 
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 2),
                child: Text('• $link', style: const TextStyle(color: Colors.blue)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDeliveryResponse() {
    final deliveryResponse = _response!.deliveryResponseData;
    if (deliveryResponse == null) return const SizedBox();

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
            'Delivery Offer Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (deliveryResponse.vehicleType != null) ...[
            Row(
              children: [
                Text('Vehicle: ', style: TextStyle(color: Colors.grey[600])),
                Text(deliveryResponse.vehicleType!),
              ],
            ),
            const SizedBox(height: 6),
          ],
          if (deliveryResponse.estimatedTime != null) ...[
            Row(
              children: [
                Text('Estimated Time: ', style: TextStyle(color: Colors.grey[600])),
                Text('${deliveryResponse.estimatedTime} minutes'),
              ],
            ),
            const SizedBox(height: 6),
          ],
          if (deliveryResponse.canHandleFragile) ...[
            const Row(
              children: [
                Icon(Icons.security, color: Colors.green, size: 16),
                SizedBox(width: 4),
                Text('Can handle fragile items'),
              ],
            ),
            const SizedBox(height: 6),
          ],
          if (deliveryResponse.insuranceCoverage != null) ...[
            Row(
              children: [
                Text('Insurance: ', style: TextStyle(color: Colors.grey[600])),
                Text('\$${deliveryResponse.insuranceCoverage?.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  Widget _buildRentalResponse() {
    final rentalResponse = _response!.rentalResponseData;
    if (rentalResponse == null) return const SizedBox();

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
            'Rental Offer Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text('Daily Rate: ', style: TextStyle(color: Colors.grey[600])),
              Text('\$${rentalResponse.dailyRate.toStringAsFixed(2)}/day'),
            ],
          ),
          const SizedBox(height: 6),
          if (rentalResponse.deposit > 0) ...[
            Row(
              children: [
                Text('Security Deposit: ', style: TextStyle(color: Colors.grey[600])),
                Text('\$${rentalResponse.deposit.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 6),
          ],
          if (rentalResponse.availableFrom != null && rentalResponse.availableUntil != null) ...[
            Row(
              children: [
                Text('Available: ', style: TextStyle(color: Colors.grey[600])),
                Text('${rentalResponse.availableFrom.toString().split(' ')[0]} - ${rentalResponse.availableUntil.toString().split(' ')[0]}'),
              ],
            ),
            const SizedBox(height: 6),
          ],
          if (rentalResponse.itemCondition != null) ...[
            Row(
              children: [
                Text('Condition: ', style: TextStyle(color: Colors.grey[600])),
                Text(rentalResponse.itemCondition!),
              ],
            ),
            const SizedBox(height: 6),
          ],
          if (rentalResponse.photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Photos:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: rentalResponse.photos.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        rentalResponse.photos[index],
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[300],
                            child: const Icon(Icons.error),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_response!.status != ResponseStatus.pending) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              _response!.status == ResponseStatus.accepted 
                  ? Icons.check_circle 
                  : Icons.cancel,
              color: _response!.status == ResponseStatus.accepted 
                  ? Colors.green 
                  : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              _response!.status == ResponseStatus.accepted 
                  ? 'You have accepted this response'
                  : 'You have rejected this response',
              style: TextStyle(
                color: _response!.status == ResponseStatus.accepted 
                    ? Colors.green[700] 
                    : Colors.red[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showRejectDialog(),
            icon: const Icon(Icons.close),
            label: const Text('Reject'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showAcceptDialog(),
            icon: const Icon(Icons.check),
            label: const Text('Accept'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  void _showAcceptDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Response'),
        content: const Text('Are you sure you want to accept this response? This will close your request and start the transaction.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _acceptResponse();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Accept'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Response'),
        content: const Text('Are you sure you want to reject this response? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _rejectResponse();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptResponse() async {
    try {
      await _requestService.acceptResponse(widget.responseId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Response accepted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting response: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectResponse() async {
    try {
      await _requestService.rejectResponse(widget.responseId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Response rejected successfully!'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting response: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
