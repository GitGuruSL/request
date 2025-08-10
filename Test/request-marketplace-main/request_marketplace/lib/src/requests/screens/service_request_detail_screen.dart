import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/request_model.dart';
import '../../theme/app_theme.dart';
import '../../services/response_service.dart';
import 'respond_to_service_request_screen.dart';

class ServiceRequestDetailScreen extends StatefulWidget {
  final RequestModel request;
  
  const ServiceRequestDetailScreen({
    super.key,
    required this.request,
  });

  @override
  State<ServiceRequestDetailScreen> createState() => _ServiceRequestDetailScreenState();
}

class _ServiceRequestDetailScreenState extends State<ServiceRequestDetailScreen> {
  final ResponseService _responseService = ResponseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _hasAlreadyResponded = false;
  bool _isCheckingResponse = true;

  @override
  void initState() {
    super.initState();
    _checkIfUserHasResponded();
  }

  Future<void> _checkIfUserHasResponded() async {
    try {
      final hasResponded = await _responseService.hasUserAlreadyResponded(widget.request.id);
      if (mounted) {
        setState(() {
          _hasAlreadyResponded = hasResponded;
          _isCheckingResponse = false;
        });
        print('✅ ServiceRequestDetailScreen: User has already responded = $hasResponded');
      }
    } catch (e) {
      print('❌ Error checking if user has responded: $e');
      if (mounted) {
        setState(() {
          _isCheckingResponse = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy • HH:mm').format(date);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return AppTheme.successColor;
      case 'in_progress':
        return AppTheme.warningColor;
      case 'completed':
        return AppTheme.primaryColor;
      case 'cancelled':
        return AppTheme.errorColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return 'Open';
      case 'in_progress':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Service Request Details',
          style: AppTheme.headingMedium.copyWith(fontSize: 20),
        ),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.request.title,
                          style: AppTheme.headingMedium.copyWith(fontSize: 20),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(widget.request.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                        ),
                        child: Text(
                          _getStatusText(widget.request.status),
                          style: TextStyle(
                            color: _getStatusColor(widget.request.status),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  Row(
                    children: [
                      Icon(Icons.monetization_on, color: AppTheme.successColor, size: 20),
                      const SizedBox(width: AppTheme.spacingXSmall),
                      Text(
                        'Budget: LKR ${widget.request.budget.toStringAsFixed(0)}',
                        style: AppTheme.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingXSmall),
                  Row(
                    children: [
                      Icon(Icons.category, color: AppTheme.primaryColor, size: 20),
                      const SizedBox(width: AppTheme.spacingXSmall),
                      Text(
                        '${widget.request.category} • ${widget.request.subcategory}',
                        style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingXSmall),
                  Row(
                    children: [
                      Icon(Icons.access_time, color: AppTheme.warningColor, size: 20),
                      const SizedBox(width: AppTheme.spacingXSmall),
                      Text(
                        'Posted: ${_formatDate(widget.request.createdAt.toDate())}',
                        style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingMedium),

            // Description Card
            if (widget.request.description.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.description, color: AppTheme.primaryColor, size: 20),
                        const SizedBox(width: AppTheme.spacingXSmall),
                        Text(
                          'Service Description',
                          style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingSmall),
                    Text(
                      widget.request.description,
                      style: AppTheme.bodyMedium.copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingMedium),
            ],

            // Location Card
            if (widget.request.location.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: AppTheme.errorColor, size: 20),
                        const SizedBox(width: AppTheme.spacingXSmall),
                        Text(
                          'Service Location',
                          style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingSmall),
                    Text(
                      widget.request.location,
                      style: AppTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingMedium),
            ],

            // Images Card
            if (widget.request.imageUrls.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.photo_library, color: AppTheme.primaryColor, size: 20),
                        const SizedBox(width: AppTheme.spacingXSmall),
                        Text(
                          'Service Images',
                          style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingSmall),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemCount: widget.request.imageUrls.length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () => _showImageDialog(widget.request.imageUrls[index]),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppTheme.borderRadiusSmall),
                              image: DecorationImage(
                                image: NetworkImage(widget.request.imageUrls[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingMedium),
            ],

            // Deadline Card
            if (widget.request.deadline != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: AppTheme.warningColor, size: 20),
                    const SizedBox(width: AppTheme.spacingXSmall),
                    Text(
                      'Deadline: ',
                      style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      _formatDate(widget.request.deadline!.toDate()),
                      style: AppTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingMedium),
            ],

            // Additional Contact Numbers
            if (widget.request.additionalPhones.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.phone, color: AppTheme.successColor, size: 20),
                        const SizedBox(width: AppTheme.spacingXSmall),
                        Text(
                          'Contact Numbers',
                          style: AppTheme.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingSmall),
                    ...widget.request.additionalPhones.map((phone) => 
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          phone,
                          style: AppTheme.bodyMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingMedium),
            ],

            // Respond Button
            if (widget.request.status.toLowerCase() == 'open') ...[
              if (_isCheckingResponse) ...[
                // Show loading while checking response status
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: null,
                    icon: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.backgroundColor,
                      ),
                    ),
                    label: const Text('Checking...'),
                    style: AppTheme.primaryButtonStyle.copyWith(
                      padding: WidgetStateProperty.all(
                        const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingLarge,
                          vertical: AppTheme.spacingMedium,
                        ),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RespondToServiceRequestScreen(request: widget.request),
                        ),
                      );
                      
                      // If user submitted/updated a response, refresh the status
                      if (result == true && mounted) {
                        _checkIfUserHasResponded();
                      }
                    },
                    icon: Icon(_hasAlreadyResponded ? Icons.edit : Icons.send),
                    label: Text(_hasAlreadyResponded ? 'Update Service Proposal' : 'Submit Service Proposal'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: _hasAlreadyResponded
                          ? Colors.orange
                          : Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingLarge,
                        vertical: AppTheme.spacingMedium,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.info_outline, color: AppTheme.textSecondary),
                    const SizedBox(width: AppTheme.spacingXSmall),
                    Text(
                      'This service request is ${_getStatusText(widget.request.status).toLowerCase()}',
                      style: AppTheme.bodyMedium.copyWith(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppTheme.spacingXLarge),
          ],
        ),
      ),
    );
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppTheme.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(
                  'Image',
                  style: AppTheme.headingSmall,
                ),
                backgroundColor: AppTheme.backgroundColor,
                foregroundColor: AppTheme.textPrimary,
                elevation: 0,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(AppTheme.spacingMedium),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Text(
                          'Failed to load image',
                          style: AppTheme.bodyMedium,
                        ),
                      );
                    },
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
