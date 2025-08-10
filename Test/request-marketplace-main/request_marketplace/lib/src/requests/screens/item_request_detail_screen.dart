import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/request_model.dart';
import '../../models/response_model.dart';
import '../../services/response_service.dart';
import '../../theme/app_theme.dart';
import 'respond_to_request_screen.dart';
import 'request_responses_screen.dart';

class ItemRequestDetailScreen extends StatefulWidget {
  final RequestModel request;

  const ItemRequestDetailScreen({super.key, required this.request});

  @override
  State<ItemRequestDetailScreen> createState() => _ItemRequestDetailScreenState();
}

class _ItemRequestDetailScreenState extends State<ItemRequestDetailScreen> {
  final ResponseService _responseService = ResponseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<ResponseModel> _responses = [];
  bool _isLoadingResponses = false;
  bool _hasAlreadyResponded = false;

  @override
  void initState() {
    super.initState();
    _loadResponses();
    _checkExistingResponse();
  }

  Future<void> _checkExistingResponse() async {
    try {
      final hasResponded = await _responseService.hasUserAlreadyResponded(widget.request.id);
      if (mounted) {
        setState(() {
          _hasAlreadyResponded = hasResponded;
        });
      }
    } catch (e) {
      print('Error checking existing response: $e');
    }
  }

  Future<void> _loadResponses() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingResponses = true;
    });

    try {
      final responses = await _responseService.getResponsesForRequest(widget.request.id);
      if (mounted) {
        setState(() {
          _responses = responses;
        });
      }
      // Also check if user has responded
      _checkExistingResponse();
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
          _isLoadingResponses = false;
        });
      }
    }
  }

  bool get _isOwnRequest {
    final currentUser = _auth.currentUser;
    return currentUser?.uid == widget.request.userId;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;
    // Check if current user is verified (has verified phone numbers)
    final bool isUserVerified = currentUser != null; // TODO: Check actual verification status

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Add share functionality
            },
            icon: Icon(Icons.share, color: AppTheme.textPrimary),
          ),
          const SizedBox(width: AppTheme.spacingMedium),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroSection(),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitleSection(),
                  const SizedBox(height: AppTheme.spacingLarge),
                  _buildDescriptionSection(),
                  const Divider(height: AppTheme.spacingXLarge),
                  _buildRequesterSection(isUserVerified),
                  const Divider(height: AppTheme.spacingXLarge),
                  _buildResponsesSection(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildHeroSection() {
    return SizedBox(
      height: 300,
      width: double.infinity,
      child: widget.request.imageUrls.isNotEmpty
          ? PageView.builder(
              itemCount: widget.request.imageUrls.length,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(widget.request.imageUrls[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withOpacity(0.8),
                  ],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.image_outlined,
                  size: 64,
                  color: Colors.white,
                ),
              ),
            ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium, vertical: AppTheme.spacingXSmall),
              decoration: BoxDecoration(
                color: _getStatusColor(widget.request.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              ),
              child: Text(
                widget.request.status.toUpperCase(),
                style: TextStyle(
                  color: _getStatusColor(widget.request.status),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const Spacer(),
            Text(
              _formatDate(widget.request.createdAt),
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        Text(
          widget.request.title,
          style: AppTheme.headingLarge.copyWith(
            fontSize: 28,
            height: 1.2,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              ),
              child: Icon(
                Icons.account_balance_wallet,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Budget',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                Text(
                  'LKR ${NumberFormat('#,##0').format(widget.request.budget)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: [
            _buildModernChip(widget.request.category, Icons.category),
            _buildModernChip(widget.request.subcategory, Icons.label_outline),
            _buildModernChip(widget.request.condition.name, Icons.info_outline),
            _buildModernChip(widget.request.type.name, Icons.type_specimen),
          ],
        ),
      ],
    );
  }

  Widget _buildModernChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.request.description.isNotEmpty ? widget.request.description : 'No description provided.',
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black87,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequesterSection(bool isUserVerified) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Requester',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                ),
                child: widget.request.user?.photoURL != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          widget.request.user!.photoURL!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.person,
                            color: Theme.of(context).primaryColor,
                            size: 24,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.person,
                        color: Theme.of(context).primaryColor,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.request.user?.displayName ?? 'Anonymous User',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.request.location.isNotEmpty ? widget.request.location : 'Location not provided',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isUserVerified && widget.request.user != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.phone, color: Colors.green[600], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.request.user!.primaryPhoneNumber ?? 
                      widget.request.user!.phoneNumber ?? 
                      "Not provided",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (!isUserVerified) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lock, color: Colors.orange[600], size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Verify your account to see contact details',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/phone-management');
                    },
                    icon: Icon(Icons.verified_user, size: 16, color: Colors.orange[600]),
                    label: Text(
                      'Verify Now',
                      style: TextStyle(color: Colors.orange[600]),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

  Widget _buildResponsesSection() {
    // Only show responses to the request owner
    if (!_isOwnRequest) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.comment, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Responses',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_responses.length}',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingResponses)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_responses.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.comment_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No responses yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Be the first to respond to this request',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            )
          else
            Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.comment_bank_outlined,
                        size: 40,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_responses.length} ${_responses.length == 1 ? 'Response' : 'Responses'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'View all responses to make your choice',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RequestResponsesScreen(request: widget.request),
                        ),
                      ).then((_) {
                        // Refresh responses when coming back
                        _loadResponses();
                      });
                    },
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View All Responses'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Theme.of(context).primaryColor,
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
      ),
    );
  }
  Widget? _buildFloatingActionButton() {
    final currentUser = _auth.currentUser;
    
    if (widget.request.status != 'open' || _isOwnRequest || currentUser == null) {
      return null;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: FloatingActionButton.extended(
          heroTag: "item_request_detail_fab", // Unique hero tag
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RespondToRequestScreen(request: widget.request),
              ),
            );
            if (result == true) {
              _loadResponses(); // Reload responses after submitting
              _checkExistingResponse(); // Re-check response status
            }
          },
          backgroundColor: _hasAlreadyResponded
              ? Colors.orange
              : Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          elevation: 8,
          icon: Icon(_hasAlreadyResponded ? Icons.edit : Icons.send),
          label: Text(
            _hasAlreadyResponded ? 'Update Response' : 'Respond to Request',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.green;
      case 'closed':
        return Colors.red;
      case 'fulfilled':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    
    DateTime date;
    if (timestamp is DateTime) {
      date = timestamp;
    } else {
      date = timestamp.toDate();
    }
    
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 7) {
      return DateFormat('MMM dd, yyyy').format(date);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
