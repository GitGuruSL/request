import 'package:flutter/material.dart';
import '../../models/request_model.dart';
import '../../models/enhanced_user_model.dart';
import '../../services/enhanced_request_service.dart';
import '../../services/enhanced_user_service.dart';
import '../../services/messaging_service.dart';
import '../messaging/conversation_screen.dart';
import 'unified_response_edit_screen.dart';

class UnifiedResponseViewScreen extends StatefulWidget {
  final RequestModel request;
  final ResponseModel response;

  const UnifiedResponseViewScreen({
    super.key,
    required this.request,
    required this.response,
  });

  @override
  State<UnifiedResponseViewScreen> createState() =>
      _UnifiedResponseViewScreenState();
}

class _UnifiedResponseViewScreenState extends State<UnifiedResponseViewScreen> {
  final EnhancedRequestService _requestService = EnhancedRequestService();
  final EnhancedUserService _userService = EnhancedUserService();

  UserModel? _responder;
  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final currentUser = await _userService.getCurrentUserModel();
      final responder =
          await _userService.getUserById(widget.response.responderId);

      setState(() {
        _currentUser = currentUser;
        _responder = responder;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading response details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _acceptResponse() async {
    if (_isProcessing) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Response'),
        content: const Text('Are you sure you want to accept this response?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await _requestService.acceptResponse(widget.response.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Response accepted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back to previous screen
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
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _rejectResponse() async {
    if (_isProcessing) return;

    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final reasonController = TextEditingController();
        return AlertDialog(
          title: const Text('Reject Response'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please provide a reason for rejection:'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  hintText: 'Rejection reason...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, reasonController.text.trim()),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (reason == null || reason.isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      await _requestService.rejectResponse(widget.response.id, reason);

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
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _editResponse() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UnifiedResponseEditScreen(
          request: widget.request,
          response: widget.response,
        ),
      ),
    ).then((_) => _loadData()); // Refresh data when returning
  }

  String _getTypeDisplayName(RequestType type) {
    switch (type) {
      case RequestType.item:
        return 'Item Request';
      case RequestType.service:
        return 'Service Request';
      case RequestType.rental:
        return 'Rental Request';
      case RequestType.delivery:
        return 'Delivery Request';
      case RequestType.ride:
        return 'Ride Request';
      case RequestType.price:
        return 'Price Request';
    }
  }

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

  Widget _buildActionButtons() {
    final isRequester = _currentUser?.id == widget.request.requesterId;

    if (_isProcessing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (isRequester && !widget.response.isAccepted) {
      // Requester can accept or reject pending responses
      return Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _acceptResponse,
              icon: const Icon(Icons.check),
              label: const Text('Accept'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _rejectResponse,
              icon: const Icon(Icons.close),
              label: const Text('Reject'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
              ),
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildStatusBadge() {
    if (widget.response.isAccepted) {
      return const Text(
        'Accepted',
        style: TextStyle(
          color: Colors.black54,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    } else if (widget.response.rejectionReason != null) {
      return const Text(
        'Rejected',
        style: TextStyle(
          color: Colors.black54,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    } else {
      return const Text(
        'Pending',
        style: TextStyle(
          color: Colors.black54,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    }
  }

  Widget _buildTypeSpecificDetails() {
    final additionalInfo = widget.response.additionalInfo;

    switch (widget.request.type) {
      case RequestType.rental:
        return _buildRentalDetails(additionalInfo);
      case RequestType.item:
        return _buildItemDetails(additionalInfo);
      case RequestType.service:
        return _buildServiceDetails(additionalInfo);
      case RequestType.delivery:
        return _buildDeliveryDetails(additionalInfo);
      case RequestType.ride:
        return _buildRideDetails(additionalInfo);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRentalDetails(Map<String, dynamic> info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (info['rentalPeriod'] != null) ...[
          _buildDetailRow('Rental Period', info['rentalPeriod']),
          const SizedBox(height: 8),
        ],
        if (info['securityDeposit'] != null) ...[
          _buildDetailRow('Security Deposit',
              '${widget.response.currency ?? 'LKR'} ${_formatPrice(info['securityDeposit'])}'),
          const SizedBox(height: 8),
        ],
        if (info['itemCondition'] != null) ...[
          _buildDetailRow('Item Condition', info['itemCondition']),
          const SizedBox(height: 8),
        ],
        if (info['pickupDeliveryOption'] != null) ...[
          _buildDetailRow('Pickup/Delivery', info['pickupDeliveryOption']),
        ],
      ],
    );
  }

  Widget _buildItemDetails(Map<String, dynamic> info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (info['itemCondition'] != null) ...[
          _buildDetailRow('Condition', info['itemCondition']),
          const SizedBox(height: 8),
        ],
        if (info['deliveryMethod'] != null) ...[
          _buildDetailRow('Delivery Method', info['deliveryMethod']),
          const SizedBox(height: 8),
        ],
        if (info['deliveryCost'] != null) ...[
          _buildDetailRow('Delivery Cost',
              '${widget.response.currency ?? 'LKR'} ${_formatPrice(info['deliveryCost'])}'),
          const SizedBox(height: 8),
        ],
        if (info['warranty'] != null) ...[
          _buildDetailRow('Warranty', info['warranty']),
        ],
      ],
    );
  }

  Widget _buildServiceDetails(Map<String, dynamic> info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (info['priceType'] != null) ...[
          _buildDetailRow('Price Type', info['priceType']),
          const SizedBox(height: 8),
        ],
        if (info['timeframe'] != null) ...[
          _buildDetailRow('Timeframe', info['timeframe']),
        ],
      ],
    );
  }

  Widget _buildDeliveryDetails(Map<String, dynamic> info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (info['vehicleType'] != null) ...[
          _buildDetailRow('Vehicle Type', info['vehicleType']),
          const SizedBox(height: 8),
        ],
        if (info['estimatedPickupTime'] != null) ...[
          _buildDetailRow('Pickup Time', info['estimatedPickupTime']),
          const SizedBox(height: 8),
        ],
        if (info['estimatedDropoffTime'] != null) ...[
          _buildDetailRow('Drop-off Time', info['estimatedDropoffTime']),
        ],
      ],
    );
  }

  Widget _buildRideDetails(Map<String, dynamic> info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (info['vehicleType'] != null) ...[
          _buildDetailRow('Vehicle Type', info['vehicleType']),
          const SizedBox(height: 8),
        ],
        if (info['routeDescription'] != null) ...[
          _buildDetailRow('Route', info['routeDescription']),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '';
    double? priceValue =
        price is double ? price : double.tryParse(price.toString());
    if (priceValue == null) return '';

    // Remove unnecessary decimal places
    if (priceValue == priceValue.roundToDouble()) {
      return priceValue.round().toString();
    } else {
      return priceValue.toString();
    }
  }

  void _startConversation() async {
    if (_responder == null) return;

    try {
      final conversation = await MessagingService().getOrCreateConversation(
        requestId: widget.request.id,
        requestTitle: widget.request.title,
        requesterId: widget.request.requesterId,
        responderId: _responder!.id,
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationScreen(
              conversation: conversation,
              request: widget.request,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting conversation: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Response Details'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Response to ${_getTypeDisplayName(widget.request.type)}'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
        actions: [
          if (_currentUser?.id == widget.response.responderId &&
              !widget.response.isAccepted)
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Your Response',
              onPressed: _editResponse,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Response status badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Response Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                _buildStatusBadge(),
              ],
            ),
            const SizedBox(height: 24),

            // Responder information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Responder Information',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.blue[100],
                        child: Text(
                          (_responder != null && _responder!.name.isNotEmpty)
                              ? _responder!.name[0]
                              : 'U',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _responder?.name ?? 'Unknown User',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            if (_responder?.email != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _responder!.email,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                            if (widget.response
                                        .additionalInfo['location_address'] !=
                                    null ||
                                widget.response
                                        .additionalInfo['locationAddress'] !=
                                    null) ...[
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on,
                                      size: 16, color: Colors.redAccent),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      widget
                                              .response
                                              .additionalInfo[
                                                  'location_address']
                                              ?.toString() ??
                                          widget.response
                                              .additionalInfo['locationAddress']
                                              ?.toString() ??
                                          '',
                                      style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Message button
                      IconButton(
                        onPressed: () => _startConversation(),
                        icon: Icon(
                          Icons.message,
                          color: _getTypeColor(widget.request.type),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Response details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Response Details',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Price
                  if (widget.response.price != null) ...[
                    _buildDetailRow('Price',
                        '${widget.response.currency ?? 'LKR'} ${_formatPrice(widget.response.price!)}'),
                    const SizedBox(height: 12),
                  ],

                  // Message
                  _buildDetailRow('Message', widget.response.message),
                  const SizedBox(height: 12),

                  // Availability
                  if (widget.response.availableFrom != null ||
                      widget.response.availableUntil != null) ...[
                    if (widget.response.availableFrom != null)
                      _buildDetailRow('Available From',
                          '${widget.response.availableFrom!.day}/${widget.response.availableFrom!.month}/${widget.response.availableFrom!.year}'),
                    const SizedBox(height: 8),
                    if (widget.response.availableUntil != null)
                      _buildDetailRow('Available Until',
                          '${widget.response.availableUntil!.day}/${widget.response.availableUntil!.month}/${widget.response.availableUntil!.year}'),
                    const SizedBox(height: 12),
                  ],

                  // Type-specific details
                  _buildTypeSpecificDetails(),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Images (if any)
            if (widget.response.images.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Images',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.response.images.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                widget.response.images[index],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Rejection reason (if any)
            if (widget.response.rejectionReason != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rejection Reason',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.response.rejectionReason!,
                      style: TextStyle(color: Colors.red[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action buttons
            _buildActionButtons(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
