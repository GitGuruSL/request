import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/request_model.dart';
import '../../../models/enhanced_user_model.dart';
import '../../../services/enhanced_request_service.dart';
import '../../../services/enhanced_user_service.dart';
import '../../../services/messaging_service.dart';
import '../../../utils/currency_helper.dart';
import '../../messaging/conversation_screen.dart';
import '../responses/create_response_screen.dart';
import '../responses/view_response_detail_screen.dart';

class ViewRequestScreen extends StatefulWidget {
  final String requestId;
  final String requestType; // 'item', 'service', 'ride', 'delivery', 'rental'

  const ViewRequestScreen({
    super.key,
    required this.requestId,
    required this.requestType,
  });

  @override
  State<ViewRequestScreen> createState() => _ViewRequestScreenState();
}

class _ViewRequestScreenState extends State<ViewRequestScreen> {
  final EnhancedRequestService _requestService = EnhancedRequestService();
  final EnhancedUserService _userService = EnhancedUserService();
  final MessagingService _messagingService = MessagingService();
  
  RequestModel? _request;
  UserModel? _requester;
  UserModel? _currentUser;
  List<ResponseModel> _responses = [];
  ResponseModel? _userResponse;
  bool _isLoading = true;
  bool _canRespond = false;
  bool _hasUserResponded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load current user
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId != null) {
        _currentUser = await _userService.getUserById(currentUserId);
      }

      // Load request
      _request = await _requestService.getRequestById(widget.requestId);
      if (_request == null) {
        _showError('Request not found');
        return;
      }

      // Load requester info
      _requester = await _userService.getUserById(_request!.requesterId);

      // Load responses
      _responses = await _requestService.getResponsesForRequest(widget.requestId);

      // Check if current user has already responded
      if (currentUserId != null) {
        _userResponse = _responses.firstWhere(
          (response) => response.responderId == currentUserId,
          orElse: () => ResponseModel(
            id: '',
            requestId: '',
            responderId: '',
            message: '',
            createdAt: DateTime.now(),
          ),
        );
        _hasUserResponded = _userResponse?.id.isNotEmpty == true;
      }

      // Check if user can respond
      _canRespond = _checkCanRespond();

    } catch (e) {
      _showError('Error loading request: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _checkCanRespond() {
    if (_currentUser == null || _request == null) return false;
    
    // Can't respond to own request
    if (_request!.requesterId == _currentUser!.id) return false;
    
    // Check if request is still active
    if (_request!.status != RequestStatus.active) return false;
    
    // Check role-based permissions
    if (_request!.type == RequestType.delivery) {
      // Only delivery businesses can respond to delivery requests
      return _currentUser!.hasRole(UserRole.delivery) && 
             _currentUser!.isRoleVerified(UserRole.delivery);
    }
    
    if (_request!.type == RequestType.ride) {
      // Only drivers can respond to ride requests
      return _currentUser!.hasRole(UserRole.driver) && 
             _currentUser!.isRoleVerified(UserRole.driver);
    }
    
    // For other request types, general users can respond
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Request Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_request == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Request Details')),
        body: const Center(
          child: Text('Request not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_request!.title),
        actions: [
          if (_request!.requesterId == _currentUser?.id) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _editRequest,
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRequestDetails(),
            const SizedBox(height: 20),
            _buildRequesterInfo(),
            const SizedBox(height: 20),
            if (_responses.isNotEmpty) _buildResponsesSection(),
            if (_request!.requesterId != _currentUser?.id) _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getRequestTypeIcon(),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _request!.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildStatusChip(),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _request!.description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            if (_request!.budget != null) ...[
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Budget: ${CurrencyHelper.formatPrice(_request!.budget!, _request!.currency)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (_request!.location != null) ...[
              Row(
                children: [
                  const Icon(Icons.location_on, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _request!.location!.address,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (_request!.deadline != null) ...[
              Row(
                children: [
                  const Icon(Icons.schedule, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Deadline: ${_formatDate(_request!.deadline!)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                const Icon(Icons.access_time, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Posted ${_getTimeAgo(_request!.createdAt)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            _buildTypeSpecificDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSpecificDetails() {
    switch (_request!.type) {
      case RequestType.item:
        final itemData = _request!.itemData;
        if (itemData == null) return const SizedBox();
        return Column(
          children: [
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Category: ', style: TextStyle(fontWeight: FontWeight.w500)),
                Text(itemData.category),
              ],
            ),
            if (itemData.brand != null)
              Row(
                children: [
                  const Text('Brand: ', style: TextStyle(fontWeight: FontWeight.w500)),
                  Text(itemData.brand!),
                ],
              ),
            if (itemData.model != null)
              Row(
                children: [
                  const Text('Model: ', style: TextStyle(fontWeight: FontWeight.w500)),
                  Text(itemData.model!),
                ],
              ),
            Row(
              children: [
                const Text('Condition: ', style: TextStyle(fontWeight: FontWeight.w500)),
                Text(itemData.condition),
              ],
            ),
          ],
        );
        
      case RequestType.service:
        final serviceData = _request!.serviceData;
        if (serviceData == null) return const SizedBox();
        return Column(
          children: [
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Service Type: ', style: TextStyle(fontWeight: FontWeight.w500)),
                Text(serviceData.serviceType),
              ],
            ),
            if (serviceData.skillLevel != null)
              Row(
                children: [
                  const Text('Skill Level: ', style: TextStyle(fontWeight: FontWeight.w500)),
                  Text(serviceData.skillLevel!),
                ],
              ),
            Row(
              children: [
                const Text('Duration: ', style: TextStyle(fontWeight: FontWeight.w500)),
                Text('${serviceData.estimatedDuration} hours'),
              ],
            ),
          ],
        );
        
      case RequestType.ride:
        final rideData = _request!.rideData;
        if (rideData == null) return const SizedBox();
        return Column(
          children: [
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Passengers: ', style: TextStyle(fontWeight: FontWeight.w500)),
                Text('${rideData.passengers}'),
              ],
            ),
            if (rideData.vehicleType != null)
              Row(
                children: [
                  const Text('Vehicle Type: ', style: TextStyle(fontWeight: FontWeight.w500)),
                  Text(rideData.vehicleType!),
                ],
              ),
            if (_request!.destinationLocation != null)
              Row(
                children: [
                  const Icon(Icons.flag, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'To: ${_request!.destinationLocation!.address}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
          ],
        );
        
      case RequestType.delivery:
        final deliveryData = _request!.deliveryData;
        if (deliveryData == null) return const SizedBox();
        return Column(
          children: [
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Package: ', style: TextStyle(fontWeight: FontWeight.w500)),
                Expanded(child: Text(deliveryData.package.description)),
              ],
            ),
            Row(
              children: [
                const Text('Weight: ', style: TextStyle(fontWeight: FontWeight.w500)),
                Text('${deliveryData.package.weight} kg'),
              ],
            ),
            if (deliveryData.isFragile)
              const Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 16),
                  SizedBox(width: 4),
                  Text('Fragile', style: TextStyle(color: Colors.orange)),
                ],
              ),
          ],
        );
        
      case RequestType.rental:
        final rentalData = _request!.rentalData;
        if (rentalData == null) return const SizedBox();
        return Column(
          children: [
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Category: ', style: TextStyle(fontWeight: FontWeight.w500)),
                Text(rentalData.itemCategory),
              ],
            ),
            Row(
              children: [
                const Text('Period: ', style: TextStyle(fontWeight: FontWeight.w500)),
                Text('${_formatDate(rentalData.startDate)} - ${_formatDate(rentalData.endDate)}'),
              ],
            ),
          ],
        );
        
      default:
        return const SizedBox();
    }
  }

  Widget _buildRequesterInfo() {
    if (_requester == null) return const SizedBox();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Requester Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Text(
                    _requester!.name.isNotEmpty ? _requester!.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _requester!.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_requester!.isEmailVerified)
                        const Row(
                          children: [
                            Icon(Icons.verified, color: Colors.green, size: 16),
                            SizedBox(width: 4),
                            Text('Verified', style: TextStyle(color: Colors.green, fontSize: 12)),
                          ],
                        ),
                    ],
                  ),
                ),
                if (_request!.requesterId != _currentUser?.id)
                  ElevatedButton.icon(
                    onPressed: _openChat,
                    icon: const Icon(Icons.chat),
                    label: const Text('Message'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.email, size: 16),
                const SizedBox(width: 8),
                Text(_requester!.email),
              ],
            ),
            if (_requester!.phoneNumber != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone, size: 16),
                  const SizedBox(width: 8),
                  Text(_requester!.phoneNumber!),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResponsesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Responses (${_responses.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_request!.requesterId == _currentUser?.id && _responses.isNotEmpty)
                  Text(
                    'Tap to accept/reject',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ..._responses.map((response) => _buildResponseCard(response)),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseCard(ResponseModel response) {
    final isOwner = _request!.requesterId == _currentUser?.id;
    final isResponder = response.responderId == _currentUser?.id;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: response.isAccepted ? Colors.green : Colors.grey,
          child: Icon(
            response.isAccepted ? Icons.check : Icons.person,
            color: Colors.white,
          ),
        ),
        title: Text(response.message),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (response.price != null)
              Text(
                'Price: ${CurrencyHelper.formatPrice(response.price!, response.currency)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            Text('${_getTimeAgo(response.createdAt)}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isResponder) ...[
              IconButton(
                icon: const Icon(Icons.chat),
                onPressed: () => _openChatWithRequester(response.responderId),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editResponse(response),
              ),
            ],
            if (isOwner && !response.isAccepted) ...[
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: () => _acceptResponse(response),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () => _rejectResponse(response),
              ),
            ],
            if (!isOwner && !isResponder) ...[
              IconButton(
                icon: const Icon(Icons.chat),
                onPressed: () => _openChatWithResponder(response.responderId),
              ),
            ],
          ],
        ),
        onTap: () => _viewResponseDetails(response),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          if (_canRespond) ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _hasUserResponded ? _updateResponse : _createResponse,
                icon: Icon(_hasUserResponded ? Icons.edit : Icons.add),
                label: Text(_hasUserResponded ? 'Update Response' : 'Respond'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasUserResponded ? Colors.orange : Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    _getCannotRespondReason(),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getCannotRespondReason() {
    if (_currentUser == null) return 'Please login to respond';
    if (_request!.requesterId == _currentUser!.id) return 'This is your request';
    if (_request!.status != RequestStatus.active) return 'Request is not active';
    
    if (_request!.type == RequestType.delivery && !_currentUser!.hasRole(UserRole.delivery)) {
      return 'Only delivery businesses can respond';
    }
    
    if (_request!.type == RequestType.ride && !_currentUser!.hasRole(UserRole.driver)) {
      return 'Only drivers can respond';
    }
    
    return 'Cannot respond to this request';
  }

  Widget _buildStatusChip() {
    Color color;
    switch (_request!.status) {
      case RequestStatus.active:
        color = Colors.green;
        break;
      case RequestStatus.inProgress:
        color = Colors.orange;
        break;
      case RequestStatus.completed:
        color = Colors.blue;
        break;
      case RequestStatus.cancelled:
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Chip(
      label: Text(
        _request!.status.name.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color,
    );
  }

  Widget _getRequestTypeIcon() {
    IconData icon;
    switch (_request!.type) {
      case RequestType.item:
        icon = Icons.shopping_bag;
        break;
      case RequestType.service:
        icon = Icons.build;
        break;
      case RequestType.ride:
        icon = Icons.directions_car;
        break;
      case RequestType.delivery:
        icon = Icons.local_shipping;
        break;
      case RequestType.rental:
        icon = Icons.key;
        break;
      default:
        icon = Icons.help_outline;
    }
    
    return Icon(icon, color: Colors.blue);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  void _editRequest() {
    // Navigate to edit request screen
    Navigator.pushNamed(
      context,
      '/edit-${widget.requestType}-request',
      arguments: _request,
    ).then((result) {
      if (result == true) _loadData();
    });
  }

  void _createResponse() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateResponseScreen(
          request: _request!,
          requestType: widget.requestType,
        ),
      ),
    ).then((result) {
      if (result == true) _loadData();
    });
  }

  void _updateResponse() {
    if (_userResponse == null) return;
    Navigator.pushNamed(
      context,
      '/edit-${widget.requestType}-response',
      arguments: _userResponse,
    ).then((result) {
      if (result == true) _loadData();
    });
  }

  void _editResponse(ResponseModel response) {
    Navigator.pushNamed(
      context,
      '/edit-${widget.requestType}-response',
      arguments: response,
    ).then((result) {
      if (result == true) _loadData();
    });
  }

  void _viewResponseDetails(ResponseModel response) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewResponseDetailScreen(
          response: response,
          request: _request!,
        ),
      ),
    );
  }

  void _openChat() async {
    if (_requester == null || _currentUser == null) return;
    
    final conversationId = await _messagingService.getOrCreateConversation(
      requestId: _request!.id,
      requesterId: _request!.requesterId,
      responderId: _currentUser!.id,
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConversationScreen(
          conversationId: conversationId,
          otherUser: _requester!,
        ),
      ),
    );
  }

  void _openChatWithRequester(String responderId) async {
    final conversationId = await _messagingService.getOrCreateConversation(
      requestId: _request!.id,
      requesterId: _request!.requesterId,
      responderId: responderId,
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConversationScreen(
          conversationId: conversationId,
          otherUser: _requester!,
        ),
      ),
    );
  }

  void _openChatWithResponder(String responderId) async {
    final responder = await _userService.getUserById(responderId);
    if (responder == null) return;
    
    final conversationId = await _messagingService.getOrCreateConversation(
      requestId: _request!.id,
      requesterId: _request!.requesterId,
      responderId: responderId,
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConversationScreen(
          conversationId: conversationId,
          otherUser: responder,
        ),
      ),
    );
  }

  void _acceptResponse(ResponseModel response) async {
    try {
      await _requestService.acceptResponse(response.id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Response accepted!')),
      );
      _loadData();
    } catch (e) {
      _showError('Failed to accept response: $e');
    }
  }

  void _rejectResponse(ResponseModel response) async {
    // Show rejection reason dialog
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _buildRejectionDialog(),
    );
    
    if (reason != null) {
      try {
        await _requestService.rejectResponse(response.id, reason);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Response rejected')),
        );
        _loadData();
      } catch (e) {
        _showError('Failed to reject response: $e');
      }
    }
  }

  Widget _buildRejectionDialog() {
    final controller = TextEditingController();
    return AlertDialog(
      title: const Text('Reject Response'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Reason for rejection (optional)',
          hintText: 'Let them know why...',
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, controller.text),
          child: const Text('Reject'),
        ),
      ],
    );
  }
}
