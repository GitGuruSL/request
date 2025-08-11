import 'package:flutter/material.dart';
import '../../models/request_model.dart';
import '../../models/enhanced_user_model.dart';
import '../../services/enhanced_request_service.dart';
import '../../services/enhanced_user_service.dart';
import '../../utils/currency_helper.dart';
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
}
