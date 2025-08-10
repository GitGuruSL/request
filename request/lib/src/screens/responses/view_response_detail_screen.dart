import 'package:flutter/material.dart';
import '../../../models/request_model.dart';
import '../../../models/enhanced_user_model.dart';
import '../../../services/enhanced_user_service.dart';
import '../../../utils/currency_helper.dart';
import '../messaging/conversation_screen.dart';

class ViewResponseDetailScreen extends StatefulWidget {
  final ResponseModel response;
  final RequestModel request;

  const ViewResponseDetailScreen({
    super.key,
    required this.response,
    required this.request,
  });

  @override
  State<ViewResponseDetailScreen> createState() => _ViewResponseDetailScreenState();
}

class _ViewResponseDetailScreenState extends State<ViewResponseDetailScreen> {
  final EnhancedUserService _userService = EnhancedUserService();
  UserModel? _responder;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResponder();
  }

  Future<void> _loadResponder() async {
    try {
      _responder = await _userService.getUserById(widget.response.responderId);
    } catch (e) {
      print('Error loading responder: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Response Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Response Details'),
        actions: [
          if (_responder != null)
            IconButton(
              icon: const Icon(Icons.chat),
              onPressed: _openChat,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildResponseStatus(),
            const SizedBox(height: 20),
            _buildResponseDetails(),
            const SizedBox(height: 20),
            if (_responder != null) _buildResponderInfo(),
            const SizedBox(height: 20),
            _buildTypeSpecificDetails(),
            const SizedBox(height: 20),
            _buildRequestSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseStatus() {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (widget.response.isAccepted) {
      statusColor = Colors.green;
      statusText = 'ACCEPTED';
      statusIcon = Icons.check_circle;
    } else if (widget.response.rejectionReason != null) {
      statusColor = Colors.red;
      statusText = 'REJECTED';
      statusIcon = Icons.cancel;
    } else {
      statusColor = Colors.orange;
      statusText = 'PENDING';
      statusIcon = Icons.pending;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                statusIcon,
                color: statusColor,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  if (widget.response.rejectionReason != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Reason: ${widget.response.rejectionReason}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                  Text(
                    'Submitted ${_getTimeAgo(widget.response.createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponseDetails() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Response Message',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.response.message,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            if (widget.response.price != null) ...[
              Row(
                children: [
                  const Icon(Icons.attach_money, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Offered Price: ${CurrencyHelper.formatPrice(widget.response.price!, widget.response.currency)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            if (widget.response.availableFrom != null) ...[
              Row(
                children: [
                  const Icon(Icons.calendar_today),
                  const SizedBox(width: 8),
                  Text(
                    'Available from: ${_formatDate(widget.response.availableFrom!)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            if (widget.response.availableUntil != null) ...[
              Row(
                children: [
                  const Icon(Icons.event),
                  const SizedBox(width: 8),
                  Text(
                    'Available until: ${_formatDate(widget.response.availableUntil!)}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResponderInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Responder Information',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.blue,
                  child: Text(
                    _responder!.name.isNotEmpty 
                        ? _responder!.name[0].toUpperCase() 
                        : '?',
                    style: const TextStyle(
                      color: Colors.white,
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
                        _responder!.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_responder!.isEmailVerified)
                        const Row(
                          children: [
                            Icon(Icons.verified, color: Colors.green, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Verified',
                              style: TextStyle(color: Colors.green, fontSize: 12),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.email, size: 16),
                const SizedBox(width: 8),
                Text(_responder!.email),
              ],
            ),
            if (_responder!.phoneNumber != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.phone, size: 16),
                  const SizedBox(width: 8),
                  Text(_responder!.phoneNumber!),
                ],
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openChat,
                icon: const Icon(Icons.chat),
                label: const Text('Send Message'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSpecificDetails() {
    final additionalInfo = widget.response.additionalInfo;
    if (additionalInfo.isEmpty) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.request.type.name.toUpperCase()} Details',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...additionalInfo.entries.map((entry) => _buildDetailRow(entry.key, entry.value)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String key, dynamic value) {
    String displayKey = _formatKey(key);
    String displayValue = _formatValue(value);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$displayKey:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(displayValue),
          ),
        ],
      ),
    );
  }

  String _formatKey(String key) {
    // Convert camelCase to readable format
    return key.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    ).trim();
  }

  String _formatValue(dynamic value) {
    if (value is bool) {
      return value ? 'Yes' : 'No';
    } else if (value is List) {
      return value.join(', ');
    } else {
      return value.toString();
    }
  }

  Widget _buildRequestSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Original Request',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.request.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.request.description,
              style: TextStyle(color: Colors.grey[600]),
            ),
            if (widget.request.budget != null) ...[
              const SizedBox(height: 8),
              Text(
                'Budget: ${CurrencyHelper.formatPrice(widget.request.budget!, widget.request.currency)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openChat() {
    if (_responder == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConversationScreen(
          conversationId: '${widget.request.id}_${widget.response.responderId}',
          otherUser: _responder!,
        ),
      ),
    );
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
}
