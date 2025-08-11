import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/request_model.dart';
import '../../models/enhanced_user_model.dart';
import '../../services/enhanced_request_service.dart';
import '../../services/enhanced_user_service.dart';
import 'unified_response_create_screen.dart';
import 'unified_request_edit_screen.dart';

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
  String _requesterName = '';

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
      // Check Firebase Auth state first
      final firebaseUser = FirebaseAuth.instance.currentUser;
      print('🔍 Debug Auth - Firebase User: ${firebaseUser?.uid ?? "NULL"}');
      print('🔍 Debug Auth - Firebase User Email: ${firebaseUser?.email ?? "NULL"}');
      print('🔍 Debug Auth - Firebase User Phone: ${firebaseUser?.phoneNumber ?? "NULL"}');
      
      final request = await _requestService.getRequestById(widget.requestId);
      final responses = await _requestService.getResponsesForRequest(widget.requestId);
      final currentUser = await _userService.getCurrentUserModel();
      
      // Load requester name
      String requesterName = 'Unknown User';
      if (request != null) {
        try {
          final requesterUser = await _userService.getUserById(request.requesterId);
          if (requesterUser != null && requesterUser.name.isNotEmpty) {
            requesterName = requesterUser.name;
          }
        } catch (e) {
          print('Error loading requester name: $e');
        }
      }
      
      // More robust owner check using both current user model and Firebase Auth
      bool isOwner = false;
      String currentUserId = '';
      
      // Try Firebase Auth first
      if (firebaseUser?.uid != null) {
        currentUserId = firebaseUser!.uid;
      }
      
      // If Firebase Auth doesn't work, try user service
      if (currentUserId.isEmpty && currentUser?.id != null) {
        currentUserId = currentUser!.id;
      }
      
      // Check ownership with additional safety checks
      if (currentUserId.isNotEmpty && request?.requesterId != null) {
        isOwner = currentUserId == request!.requesterId;
      } else {
        // If we can't determine the current user, assume ownership to hide respond button
        // This is a safety measure to prevent users from responding to their own requests
        isOwner = true;
        print('⚠️ Warning: Could not determine current user, defaulting to owner=true for safety');
      }
      
      if (mounted) {
        setState(() {
          _request = request;
          _responses = responses;
          _isOwner = isOwner;
          _requesterName = requesterName;
          _isLoading = false;
        });
        
        // Enhanced debug information
        print('🔍 Debug Unified - Firebase User ID: ${firebaseUser?.uid ?? "NULL"}');
        print('🔍 Debug Unified - Current User Model ID: ${currentUser?.id ?? "NULL"}');
        print('🔍 Debug Unified - Final Current User ID: $currentUserId');
        print('🔍 Debug Unified - Request Owner ID: ${request?.requesterId ?? "NULL"}');
        print('🔍 Debug Unified - Is Owner: $isOwner');
        print('🔍 Debug Unified - Requester Name: $requesterName');
        print('🔍 Debug Unified - Will Show Respond Button: ${!isOwner && request != null}');
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

  void _navigateToEditRequest() {
    if (_request == null) return;
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UnifiedRequestEditScreen(request: _request!),
      ),
    ).then((_) => _loadRequestData()); // Reload data when coming back
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
        actions: _isOwner ? [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEditRequest,
            tooltip: 'Edit Request',
          ),
        ] : null,
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
              const SizedBox(height: 16),
              _buildRequesterInfo(),
              const SizedBox(height: 24),
              _buildTypeSpecificDetails(),
              const SizedBox(height: 24),
              _buildResponsesSection(),
            ],
          ),
        ),
      ),
      floatingActionButton: (_request != null && 
                              !_isOwner && 
                              FirebaseAuth.instance.currentUser != null &&
                              FirebaseAuth.instance.currentUser!.uid != _request!.requesterId)
          ? FloatingActionButton.extended(
              onPressed: () {
                print('🔍 Respond button pressed - IsOwner: $_isOwner');
                print('🔍 Respond button pressed - Current User: ${FirebaseAuth.instance.currentUser?.uid}');
                print('🔍 Respond button pressed - Request Owner: ${_request!.requesterId}');
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
                Icon(Icons.account_balance_wallet, color: Colors.blue, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Budget: \$${_request!.budget?.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
          // Display images if available
          if (_request!.images.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Images',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _request!.images.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _showFullScreenImage(index),
                    child: Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _request!.images[index],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey[400],
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
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

  Widget _buildRequesterInfo() {
    final String firstLetter = _requesterName.isNotEmpty ? _requesterName[0].toUpperCase() : 'U';
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              // TODO: Navigate to user profile screen
              print('Navigate to profile: ${_request!.requesterId}');
            },
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blue[100],
              child: Text(
                firstLetter,
                style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _requesterName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.verified, color: Colors.blue, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Verified',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Only show message button if viewing someone else's request
          if (!_isOwner) 
            IconButton(
              onPressed: () {
                // TODO: Implement contact functionality
              },
              icon: const Icon(Icons.message),
            ),
        ],
      ),
    );
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
    
    // Debug information
    print('🔍 Item Debug - TypeSpecificData: ${_request!.typeSpecificData}');
    print('🔍 Item Debug - ItemData: $itemData');
    
    if (itemData == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Item Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 12),
            Text(
              'No additional item details available.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Item Details',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (itemData.itemName?.isNotEmpty == true) ...[
            Row(
              children: [
                Text('Item Name: ', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                Expanded(child: Text(itemData.itemName!)),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (itemData.category.isNotEmpty) ...[
            Row(
              children: [
                Text('Category: ', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                Expanded(child: Text(itemData.subcategory?.isNotEmpty == true ? itemData.subcategory! : itemData.category)),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (itemData.quantity != null) ...[
            Row(
              children: [
                Text('Quantity: ', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                Text('${itemData.quantity}'),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Text('Condition: ', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
              Text(itemData.condition),
            ],
          ),
          if (itemData.brand?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Brand: ', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                Text(itemData.brand!),
              ],
            ),
          ],
          if (itemData.model?.isNotEmpty == true) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Model: ', style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500)),
                Text(itemData.model!),
              ],
            ),
          ],
          if (itemData.specifications.isNotEmpty) ...[
            const SizedBox(height: 12),
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
        borderRadius: BorderRadius.circular(12),
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
              Text('Service Type: ', style: TextStyle(color: Colors.grey[600])),
              Text(serviceData.serviceType),
            ],
          ),
          if (serviceData.skillLevel != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Text('Skill Level: ', style: TextStyle(color: Colors.grey[600])),
                Text(serviceData.skillLevel!.toUpperCase()),
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
        borderRadius: BorderRadius.circular(12),
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
        borderRadius: BorderRadius.circular(12),
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
              borderRadius: BorderRadius.circular(12),
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
                  borderRadius: BorderRadius.circular(12),
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

  void _showFullScreenImage(int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: _request!.images.length,
              itemBuilder: (context, index) {
                return Center(
                  child: InteractiveViewer(
                    child: Image.network(
                      _request!.images[index],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              color: Colors.grey[400],
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ],
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 50,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
            if (_request!.images.length > 1)
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _request!.images.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == initialIndex
                            ? Colors.white
                            : Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
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