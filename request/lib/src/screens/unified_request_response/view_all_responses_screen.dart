import 'package:flutter/material.dart';
import '../../models/request_model.dart';
import '../../models/enhanced_user_model.dart';
import '../../services/enhanced_request_service.dart';
import '../../services/enhanced_user_service.dart';
import '../../services/messaging_service.dart';
import '../messaging/conversation_screen.dart';
import 'unified_response_view_screen.dart';

class ViewAllResponsesScreen extends StatefulWidget {
  final RequestModel request;

  const ViewAllResponsesScreen({
    super.key,
    required this.request,
  });

  @override
  State<ViewAllResponsesScreen> createState() => _ViewAllResponsesScreenState();
}

class _ViewAllResponsesScreenState extends State<ViewAllResponsesScreen> {
  final EnhancedRequestService _requestService = EnhancedRequestService();
  final EnhancedUserService _userService = EnhancedUserService();
  
  List<ResponseModel> _responses = [];
  Map<String, UserModel> _responders = {};
  bool _isLoading = true;
  String _sortBy = 'date'; // 'date', 'price_low', 'price_high'

  @override
  void initState() {
    super.initState();
    _loadResponses();
  }

  Future<void> _loadResponses() async {
    try {
      final responses = await _requestService.getResponsesForRequest(widget.request.id);
      final responders = <String, UserModel>{};
      
      // Load responder information
      for (final response in responses) {
        try {
          final user = await _userService.getUserById(response.responderId);
          if (user != null) {
            responders[response.responderId] = user;
          }
        } catch (e) {
          print('Error loading user ${response.responderId}: $e');
        }
      }

      setState(() {
        _responses = responses;
        _responders = responders;
        _isLoading = false;
      });
      
      _sortResponses();
    } catch (e) {
      print('Error loading responses: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading responses: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _sortResponses() {
    setState(() {
      switch (_sortBy) {
        case 'price_low':
          _responses.sort((a, b) {
            final priceA = a.price ?? 0.0;
            final priceB = b.price ?? 0.0;
            return priceA.compareTo(priceB);
          });
          break;
        case 'price_high':
          _responses.sort((a, b) {
            final priceA = a.price ?? 0.0;
            final priceB = b.price ?? 0.0;
            return priceB.compareTo(priceA);
          });
          break;
        case 'date':
        default:
          _responses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
      }
    });
  }

  String _getTypeDisplayName(String type) {
    switch (type.toLowerCase()) {
      case 'item':
        return 'Item';
      case 'service':
        return 'Service';
      case 'delivery':
        return 'Delivery';
      case 'ride':
        return 'Ride';
      case 'rental':
        return 'Rental';
      case 'price':
        return 'Price';
      default:
        return type;
    }
  }

  Widget _buildResponseItem(ResponseModel response, UserModel? responder) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UnifiedResponseViewScreen(
              request: widget.request,
              response: response,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with responder info and status
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    (responder != null && responder.name.isNotEmpty) ? responder.name[0] : 'U',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        responder?.name ?? 'Unknown User',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Response to ${_getTypeDisplayName(widget.request.type.toString().split('.').last)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusBadge(response),
              ],
            ),
            const SizedBox(height: 12),

            // Price
            if (response.price != null) ...[
              Text(
                '${response.currency ?? 'LKR'} ${_formatPrice(response.price!)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
            ],

            // Message preview
            Text(
              response.message,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _startConversation(response.responderId, responder?.name ?? 'User'),
                    icon: const Icon(Icons.message, size: 16),
                    label: const Text('Message'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue[600],
                      side: BorderSide(color: Colors.blue[300]!),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptResponse(response),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ResponseModel response) {
    if (response.isAccepted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Accepted',
          style: TextStyle(
            color: Colors.green[700],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (response.rejectionReason != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Rejected',
          style: TextStyle(
            color: Colors.red[700],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Pending',
          style: TextStyle(
            color: Colors.orange[700],
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '';
    double? priceValue = price is double ? price : double.tryParse(price.toString());
    if (priceValue == null) return '';
    
    if (priceValue == priceValue.roundToDouble()) {
      return priceValue.round().toString();
    } else {
      return priceValue.toString();
    }
  }

  void _startConversation(String responderId, String responderName) async {
    try {
      final conversation = await MessagingService().getOrCreateConversation(
        requestId: widget.request.id,
        requestTitle: widget.request.title,
        requesterId: widget.request.requesterId,
        responderId: responderId,
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

  void _acceptResponse(ResponseModel response) async {
    try {
      await _requestService.acceptResponse(response.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Response accepted successfully')),
        );
        
        _loadResponses(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error accepting response: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Responses (${_responses.length})'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
              _sortResponses();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'date',
                child: Text('Sort by Date'),
              ),
              const PopupMenuItem(
                value: 'price_low',
                child: Text('Price: Low to High'),
              ),
              const PopupMenuItem(
                value: 'price_high',
                child: Text('Price: High to Low'),
              ),
            ],
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.sort),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _responses.isEmpty
              ? const Center(
                  child: Text(
                    'No responses yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _responses.length,
                  itemBuilder: (context, index) {
                    final response = _responses[index];
                    final responder = _responders[response.responderId];
                    return _buildResponseItem(response, responder);
                  },
                ),
    );
  }
}
