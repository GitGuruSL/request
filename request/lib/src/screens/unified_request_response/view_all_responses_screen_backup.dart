import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../models/request_model.dart';
import '../../models/enhanced_user_model.dart';
import '../../services/enhanced_request_service.dart';
import '../../services/enhanced_user_service.dart';
import '../../services/messaging_service.dart';
import '../../utils/currency_helper.dart';
import '../messaging/conversation_screen.dart';
import 'unified_response_view_screen.dart';

class ViewAllResponsesScreen extends StatefulWidget {
  final RequestModel request;

  const ViewAllResponsesScreen({super.key, required this.request});

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
    setState(() {
      _isLoading = true;
    });

    try {
      // Load responses for the request
      final responses = await _requestService.getResponsesForRequest(widget.request.id!);
      
      // Load responder details
      Map<String, UserModel> responders = {};
      for (ResponseModel response in responses) {
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

  Widget _buildResponseCard(ResponseModel response, UserModel? responder) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Response header - clickable to go to details
          GestureDetector(
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.reply, color: Colors.blue[600], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Response to ${_getTypeDisplayName(widget.request.type)}',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Tap to view details',
                    style: TextStyle(
                      color: Colors.blue[600],
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 12, color: Colors.blue[600]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header with responder info and price
          Row(
            children: [
              // Responder avatar and name
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue[100],
                child: Text(
                  responder?.name?[0] ?? 'U',
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
                      responder != null
                          ? responder!.name
                          : 'Unknown User',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _getTimeAgo(response.createdAt),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Price badge
              if (response.price != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${response.currency ?? 'LKR'} ${_formatPrice(response.price!)}',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Response message
          Text(
            response.message,
            style: const TextStyle(fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Additional info
          if (_getAdditionalInfo(response).isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _getAdditionalInfo(response).take(2).map((info) =>
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    info,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ).toList(),
            ),
          ],

          // Images (if any)
          if (response.images.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: math.min(response.images.length, 3),
                itemBuilder: (context, index) {
                  return Container(
                    width: 60,
                    margin: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        response.images[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.grey[400],
                              size: 24,
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
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: response.isAccepted 
                    ? Colors.green[100] 
                    : response.rejectionReason != null 
                      ? Colors.red[100] 
                      : Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  response.isAccepted 
                    ? 'Accepted' 
                    : response.rejectionReason != null 
                      ? 'Rejected' 
                      : 'Pending',
                  style: TextStyle(
                    color: response.isAccepted 
                      ? Colors.green[700] 
                      : response.rejectionReason != null 
                        ? Colors.red[700] 
                        : Colors.orange[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              
              // Message button
              TextButton.icon(
                onPressed: () => _startConversation(response.responderId),
                icon: Icon(Icons.message, size: 16, color: Colors.blue[600]),
                label: Text(
                  'Message',
                  style: TextStyle(color: Colors.blue[600], fontSize: 14),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
              const SizedBox(width: 8),
              
              // Accept button (only for pending responses)
              if (!response.isAccepted && response.rejectionReason == null)
                ElevatedButton(
                  onPressed: () => _acceptResponse(response),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: const Size(0, 32),
                  ),
                  child: const Text('Accept', style: TextStyle(fontSize: 14)),
                ),
            ],
          ),
        ],
      ),
    );
  }
                      children: [
                        Text(
                          responder != null
                              ? responder!.name
                              : 'Unknown User',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _getTimeAgo(response.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Price
                  if (response.price != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Text(
                        '${response.currency ?? 'LKR'} ${_formatPrice(response.price!)}',
                        style: TextStyle(
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Response message
              Text(
                response.message,
                style: const TextStyle(fontSize: 14, height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              // Additional info based on request type
              if (_getAdditionalInfo(response).isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _getAdditionalInfo(response)
                      .map((info) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              info,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
              
              // Images if available
              if (response.images.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: response.images.length > 3 ? 3 : response.images.length,
                    itemBuilder: (context, index) {
                      if (index == 2 && response.images.length > 3) {
                        return Container(
                          width: 60,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '+${response.images.length - 2}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }
                      return Container(
                        width: 60,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(response.images[index]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
              
              // Status indicator
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    response.isAccepted ? Icons.check_circle : Icons.pending,
                    size: 16,
                    color: response.isAccepted ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    response.isAccepted ? 'Accepted' : 'Pending',
                    style: TextStyle(
                      fontSize: 12,
                      color: response.isAccepted ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Tap to view details',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.grey[500],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _getAdditionalInfo(ResponseModel response) {
    List<String> info = [];
    final additionalInfo = response.additionalInfo;
    
    switch (widget.request.type) {
      case RequestType.rental:
        if (additionalInfo['rentalPeriod'] != null) {
          info.add('Per ${additionalInfo['rentalPeriod']}');
        }
        if (additionalInfo['securityDeposit'] != null) {
          info.add('Deposit: ${response.currency ?? 'LKR'} ${_formatPrice(additionalInfo['securityDeposit'])}');
        }
        break;
      case RequestType.delivery:
        if (additionalInfo['vehicleType'] != null) {
          info.add(additionalInfo['vehicleType']);
        }
        if (additionalInfo['estimatedPickupTime'] != null) {
          info.add('Pickup: ${additionalInfo['estimatedPickupTime']}');
        }
        break;
      case RequestType.ride:
        if (additionalInfo['vehicleType'] != null) {
          info.add(additionalInfo['vehicleType']);
        }
        break;
      case RequestType.item:
        if (additionalInfo['itemCondition'] != null) {
          info.add(additionalInfo['itemCondition']);
        }
        if (additionalInfo['deliveryMethod'] != null) {
          info.add(additionalInfo['deliveryMethod']);
        }
        break;
      case RequestType.service:
        if (additionalInfo['priceType'] != null) {
          info.add(additionalInfo['priceType']);
        }
        break;
      case RequestType.price:
        // Handle price comparison requests
        break;
    }
    
    return info;
  }

  String _formatPrice(double price) {
    if (price == price.roundToDouble()) {
      return price.round().toString();
    } else {
      return price.toString();
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Responses (${_responses.length})'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
              _sortResponses();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'date',
                child: Row(
                  children: [
                    Icon(Icons.access_time, size: 18),
                    SizedBox(width: 8),
                    Text('Latest First'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'price_low',
                child: Row(
                  children: [
                    Icon(Icons.arrow_upward, size: 18),
                    SizedBox(width: 8),
                    Text('Price: Low to High'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'price_high',
                child: Row(
                  children: [
                    Icon(Icons.arrow_downward, size: 18),
                    SizedBox(width: 8),
                    Text('Price: High to Low'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _responses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No responses yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your request is waiting for responses',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Request summary header
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.request.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.request.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    
                    // Responses list
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _responses.length,
                        itemBuilder: (context, index) {
                          final response = _responses[index];
                          final responder = _responders[response.responderId];
                          return _buildResponseCard(response, responder);
                        },
                      ),
                    ),
                  ],
                ),
    );
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

  Future<void> _startConversation(String responderId) async {
    try {
      final currentUser = await _userService.getCurrentUserModel();
      if (currentUser == null) return;

      final conversationId = await MessagingService().startConversation(
        currentUser.id,
        responderId,
        'Response to: ${widget.request.title}',
      );

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConversationScreen(
              conversationId: conversationId,
              otherUserId: responderId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting conversation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _acceptResponse(ResponseModel response) async {
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Accept'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _requestService.acceptResponse(response.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Response accepted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadResponses(); // Refresh the list
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
}
