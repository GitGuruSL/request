import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:request_marketplace/src/models/request_model.dart';
import 'package:request_marketplace/src/services/response_service.dart';
import '../../theme/app_theme.dart';
import 'respond_to_delivery_request_screen.dart';

class DeliveryRequestDetailScreen extends StatefulWidget {
  final RequestModel request;

  const DeliveryRequestDetailScreen({
    super.key,
    required this.request,
  });

  @override
  State<DeliveryRequestDetailScreen> createState() => _DeliveryRequestDetailScreenState();
}

class _DeliveryRequestDetailScreenState extends State<DeliveryRequestDetailScreen> {
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
      }
    } catch (e) {
      print('Error checking if user has responded: $e');
      if (mounted) {
        setState(() {
          _isCheckingResponse = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Delivery Request Details'),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacingLarge),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.local_shipping,
                          color: Colors.blue,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.request.title,
                              style: AppTheme.headingMedium.copyWith(
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Delivery Service Request',
                              style: AppTheme.bodyMedium.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Budget
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.attach_money,
                          color: AppTheme.successColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Budget',
                              style: AppTheme.bodySmall.copyWith(
                                color: AppTheme.successColor,
                              ),
                            ),
                            Text(
                              'LKR ${widget.request.budget.toStringAsFixed(0)}',
                              style: AppTheme.headingMedium.copyWith(
                                color: AppTheme.successColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Description
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacingLarge),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Description',
                    style: AppTheme.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.request.description,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Location
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.spacingLarge),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location',
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.request.location,
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Category
            if (widget.request.category.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingLarge),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.category,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Category',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.request.category + (widget.request.subcategory.isNotEmpty ? ' > ${widget.request.subcategory}' : ''),
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Response Button
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
                          builder: (context) => RespondToDeliveryRequestScreen(request: widget.request),
                        ),
                      );
                      
                      // If user submitted/updated a response, refresh the status
                      if (result == true && mounted) {
                        _checkIfUserHasResponded();
                      }
                    },
                    icon: Icon(_hasAlreadyResponded ? Icons.edit : Icons.send),
                    label: Text(_hasAlreadyResponded ? 'Update Delivery Proposal' : 'Submit Delivery Proposal'),
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
                      'This request is no longer accepting responses',
                      style: AppTheme.bodyMedium.copyWith(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
