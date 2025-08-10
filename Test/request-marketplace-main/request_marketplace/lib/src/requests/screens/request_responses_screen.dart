import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/request_model.dart';
import '../../models/response_model.dart';
import '../../models/ride_response_model.dart';
import '../../services/response_service.dart';
import '../../services/chat_service.dart';
import '../../services/ride_tracking_service.dart';
import '../../widgets/driver_profile_card.dart';
import '../../drivers/screens/enhanced_driver_profile_detail_screen.dart';
import '../../rides/screens/ride_tracking_screen.dart';
import '../../chat/screens/chat_screen.dart';
import '../../theme/app_theme.dart';

class RequestResponsesScreen extends StatefulWidget {
  final RequestModel request;

  const RequestResponsesScreen({super.key, required this.request});

  @override
  State<RequestResponsesScreen> createState() => _RequestResponsesScreenState();
}

class _RequestResponsesScreenState extends State<RequestResponsesScreen> {
  final ResponseService _responseService = ResponseService();
  final ChatService _chatService = ChatService();
  final RideTrackingService _rideTrackingService = RideTrackingService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<ResponseModel> _responses = [];
  List<RideResponseModel> _rideResponses = [];
  bool _isLoading = false;
  String _sortBy = 'newest'; // newest, oldest, price_low, price_high
  String _currentRequestStatus = 'open'; // Track current request status
  bool _isRideRequest = false;

  @override
  void initState() {
    super.initState();
    _currentRequestStatus =
        widget.request.status; // Initialize with current status
    _isRideRequest = widget.request.type == RequestType.ride;
    _loadResponses();
  }

  Future<void> _loadResponses() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      if (_isRideRequest) {
        // For ride requests, get responses with driver information
        final rideResponses = await _responseService
            .getRideResponsesWithDriverInfo(widget.request.id);

        if (mounted) {
          setState(() {
            _rideResponses = rideResponses;
            _responses = rideResponses.cast<
                ResponseModel>(); // Cast for compatibility with existing UI
          });
        }
      } else {
        // For other requests, use the regular method
        final responses =
            await _responseService.getResponsesForRequest(widget.request.id);

        if (mounted) {
          setState(() {
            _responses = responses;
            _rideResponses = [];
          });
        }
      }

      // Also fetch the latest request status
      await _updateRequestStatus();

      if (mounted) {
        _applySorting();
      }
    } catch (e) {
      print('Error loading responses: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading responses: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateRequestStatus() async {
    try {
      final requestDoc = await FirebaseFirestore.instance
          .collection('requests')
          .doc(widget.request.id)
          .get();

      if (requestDoc.exists) {
        final requestData = requestDoc.data()!;
        setState(() {
          _currentRequestStatus = requestData['status'] ?? 'open';
        });
      }
    } catch (e) {
      print('Error updating request status: $e');
    }
  }

  void _applySorting() {
    switch (_sortBy) {
      case 'newest':
        _responses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'oldest':
        _responses.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'price_low':
        _responses.sort((a, b) {
          final aPrice = a.offeredPrice ?? double.infinity;
          final bPrice = b.offeredPrice ?? double.infinity;
          return aPrice.compareTo(bPrice);
        });
        break;
      case 'price_high':
        _responses.sort((a, b) {
          final aPrice = a.offeredPrice ?? 0.0;
          final bPrice = b.offeredPrice ?? 0.0;
          return bPrice.compareTo(aPrice);
        });
        break;
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sort Responses',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildSortOption('newest', 'Newest First', Icons.schedule),
            _buildSortOption('oldest', 'Oldest First', Icons.history),
            _buildSortOption('price_low', 'Lowest Price', Icons.arrow_upward),
            _buildSortOption(
                'price_high', 'Highest Price', Icons.arrow_downward),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String value, String label, IconData icon) {
    final isSelected = _sortBy == value;
    return ListTile(
      leading:
          Icon(icon, color: isSelected ? Theme.of(context).primaryColor : null),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : null,
          color: isSelected ? Theme.of(context).primaryColor : null,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check) : null,
      onTap: () {
        setState(() {
          _sortBy = value;
          _applySorting();
        });
        Navigator.pop(context);
      },
    );
  }

  Future<void> _acceptResponse(ResponseModel response) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accept Response'),
        content: Text(
          'Are you sure you want to accept ${response.responder?.displayName ?? "this user's"} response?\\n\\n'
          'This will mark your request as fulfilled and notify the responder.',
        ),
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

    if (confirmed == true) {
      try {
        await _responseService.acceptResponse(response.id);
        await _responseService.markRequestAsFulfilled(widget.request.id);

        // For ride requests, create ride tracking
        if (_isRideRequest) {
          final rideTrackingId = await _rideTrackingService.createRideTracking(
            requestId: widget.request.id,
            responseId: response.id,
            requesterId: widget.request.userId,
            driverId: response.responderId,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ride accepted! Track your ride in real-time.'),
                backgroundColor: Colors.green,
              ),
            );

            // Navigate to ride tracking screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RideTrackingScreen(
                  rideTrackingId: rideTrackingId,
                  isDriver: false, // Requester view
                ),
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Response accepted successfully!')),
            );
          }
        }

        if (mounted) {
          _loadResponses(); // Refresh responses and request status
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error accepting response: $e')),
          );
        }
      }
    }
  }

  Future<void> _startChat(ResponseModel response) async {
    try {
      print('🗨️ Starting chat with ${response.responderId}');
      print('   Request ID: ${widget.request.id}');
      print('   Response ID: ${response.id}');

      // Create or get conversation first
      final conversationId = await _chatService.createOrGetConversation(
        otherUserId: response.responderId,
        requestId: widget.request.id,
        responseId: response.id,
      );

      print('✅ Conversation created/found: $conversationId');

      // Navigate to chat screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              conversationId: conversationId,
              otherUserId: response.responderId,
              otherUserName: response.responder?.displayName ?? 'User',
              otherUserPhotoURL: response.responder?.photoURL,
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error starting chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting chat: $e')),
        );
      }
    }
  }

  Future<void> _callResponder(ResponseModel response) async {
    if (response.sharedPhoneNumbers.isEmpty) return;

    try {
      // Show phone number selection dialog if multiple numbers
      if (response.sharedPhoneNumbers.length > 1) {
        final selectedNumber = await showDialog<String>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Select Phone Number'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: response.sharedPhoneNumbers.map((phone) {
                  return ListTile(
                    leading: const Icon(Icons.phone),
                    title: Text(phone),
                    onTap: () => Navigator.pop(context, phone),
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );

        if (selectedNumber != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Calling $selectedNumber...')),
          );
          // Here you would use url_launcher to open the phone app
          // final Uri phoneUri = Uri(scheme: 'tel', path: selectedNumber);
          // await launchUrl(phoneUri);
        }
      } else {
        // Single phone number - show confirmation then call
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Calling ${response.sharedPhoneNumbers.first}...')),
        );
        // Here you would use url_launcher to open the phone app
        // final Uri phoneUri = Uri(scheme: 'tel', path: response.sharedPhoneNumbers.first);
        // await launchUrl(phoneUri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error making call: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Responses (${_responses.length})',
          style: AppTheme.headingMedium.copyWith(fontSize: 20),
        ),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          if (_responses.isNotEmpty)
            IconButton(
              icon: Icon(Icons.sort, color: AppTheme.textPrimary),
              onPressed: _showSortOptions,
              tooltip: 'Sort responses',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _responses.isEmpty
              ? _buildEmptyState()
              : _buildResponsesList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXLarge),
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.comment_outlined,
                size: 80,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              Text(
                'No Responses Yet',
                style: AppTheme.headingMedium.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              Text(
                'Your request "${widget.request.title}" has not received any responses yet.',
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingMedium),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Request'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: BorderSide(color: AppTheme.primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsesList() {
    return RefreshIndicator(
      onRefresh: _loadResponses,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        itemCount: _responses.length,
        itemBuilder: (context, index) {
          final response = _responses[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
            child: _buildResponseCard(response, index),
          );
        },
      ),
    );
  }

  Widget _buildResponseCard(ResponseModel response, int index) {
    final isCurrentUser = _auth.currentUser?.uid == widget.request.userId;
    final isAccepted = response.status == 'accepted';
    final isRequestFulfilled = _currentRequestStatus == 'fulfilled';
    final rideResponse = _isRideRequest && index < _rideResponses.length
        ? _rideResponses[index]
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: isAccepted ? Border.all(color: AppTheme.successColor.withOpacity(0.3), width: 2) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // For ride requests, show driver profile card
          if (rideResponse?.driverProfile != null) ...[
            DriverProfileCard(
              driver: rideResponse!.driverProfile!,
              showSensitiveInfo: isAccepted,
              onViewProfile: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DriverProfileDetailScreen(
                      driver: rideResponse.driverProfile!,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppTheme.spacingMedium),
          ] else ...[
            // Header with user info and status (for non-ride requests or when driver profile is not available)
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: AppTheme.primaryColor.withOpacity(0.1),
                  ),
                  child: response.responder?.photoURL != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: Image.network(
                            response.responder!.photoURL!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(
                              Icons.person,
                              color: AppTheme.primaryColor,
                              size: 25,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.person,
                          color: AppTheme.primaryColor,
                          size: 25,
                        ),
                ),
                const SizedBox(width: AppTheme.spacingMedium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        response.responder?.displayName ?? 'Anonymous User',
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, yyyy • h:mm a')
                            .format(response.createdAt.toDate()),
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isAccepted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'ACCEPTED',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMedium),
          ],

          // Response message
          Text(
            response.message,
            style: AppTheme.bodyMedium.copyWith(height: 1.4),
          ),

          // Response images
          if (response.images.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingMedium),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: response.images.length,
                itemBuilder: (context, imageIndex) {
                  return Container(
                    width: 120,
                    margin: EdgeInsets.only(
                        right:
                            imageIndex < response.images.length - 1 ? 12 : 0),
                    child: GestureDetector(
                      onTap: () => _showImageViewer(
                          context, response.images, imageIndex),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                        child: Image.network(
                          response.images[imageIndex],
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: AppTheme.backgroundColor,
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes !=
                                          null
                                      ? loadingProgress
                                              .cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppTheme.backgroundColor,
                              child: Icon(Icons.error, color: AppTheme.textSecondary),
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

          const SizedBox(height: AppTheme.spacingMedium),

          // Response details
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              if (response.offeredPrice != null)
                _buildDetailChip(
                  Icons.attach_money,
                  'LKR ${response.offeredPrice!.toStringAsFixed(0)}',
                  AppTheme.successColor,
                ),
              if (response.deliveryAvailable == true)
                _buildDetailChip(
                  Icons.local_shipping,
                  response.deliveryAmount != null
                      ? 'Delivery: LKR ${response.deliveryAmount!.toStringAsFixed(0)}'
                      : 'Delivery Available',
                  AppTheme.primaryColor,
                ),
              if (response.warranty != null && response.warranty!.isNotEmpty)
                _buildDetailChip(
                  Icons.verified_user,
                  response.warranty!,
                  AppTheme.warningColor,
                ),
              if (response.expiryDate != null)
                _buildDetailChip(
                  Icons.schedule,
                  'Valid until ${DateFormat('MMM dd').format(response.expiryDate!)}',
                  AppTheme.errorColor,
                ),
            ],
          ),

          if (response.sharedPhoneNumbers.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingMedium),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingSmall),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
              ),
              child: Row(
                children: [
                  Icon(Icons.phone, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: AppTheme.spacingXSmall),
                  Expanded(
                    child: Text(
                      response.sharedPhoneNumbers.join(', '),
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Show contact options when response is accepted
          if (isCurrentUser && isAccepted) ...[
            const SizedBox(height: AppTheme.spacingMedium),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                border: Border.all(color: AppTheme.successColor.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle,
                          color: AppTheme.successColor, size: 20),
                      const SizedBox(width: AppTheme.spacingXSmall),
                      Text(
                        'Response Accepted - Contact Information',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.successColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMedium),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _startChat(response),
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          label: const Text('Message'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: AppTheme.successColor),
                            foregroundColor: AppTheme.successColor,
                          ),
                        ),
                      ),
                      if (response.sharedPhoneNumbers.isNotEmpty) ...[
                        const SizedBox(width: AppTheme.spacingSmall),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _callResponder(response),
                            icon: const Icon(Icons.phone, size: 18),
                            label: const Text('Call'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (response.sharedPhoneNumbers.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spacingSmall),
                    Text(
                      'Phone: ${response.sharedPhoneNumbers.join(', ')}',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],

          if (isCurrentUser && !isAccepted && !isRequestFulfilled) ...[
            const SizedBox(height: AppTheme.spacingMedium),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _startChat(response),
                    icon: const Icon(Icons.chat_bubble_outline, size: 18),
                    label: const Text('Message'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      foregroundColor: AppTheme.primaryColor,
                      side: BorderSide(color: AppTheme.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSmall),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _acceptResponse(response),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (isRequestFulfilled && !isAccepted) ...[
            const SizedBox(height: AppTheme.spacingMedium),
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: AppTheme.spacingXSmall),
                  Expanded(
                    child: Text(
                      'This request has been fulfilled. No more responses can be accepted.',
                      style: AppTheme.bodySmall.copyWith(
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showImageViewer(
      BuildContext context, List<String> images, int initialIndex) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              PageView.builder(
                controller: PageController(initialPage: initialIndex),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Center(
                    child: InteractiveViewer(
                      panEnabled: true,
                      boundaryMargin: const EdgeInsets.all(20),
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Image.network(
                        images[index],
                        fit: BoxFit.contain,
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
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.error,
                                    color: Colors.white, size: 48),
                                SizedBox(height: 16),
                                Text(
                                  'Failed to load image',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                ),
              ),
              if (images.length > 1)
                Positioned(
                  bottom: 50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${initialIndex + 1} of ${images.length}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
