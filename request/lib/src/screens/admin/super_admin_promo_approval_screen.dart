import 'package:flutter/material.dart';
import 'src/utils/firebase_shim.dart'; // Added by migration script
// REMOVED_FB_IMPORT: import 'package:firebase_auth/firebase_auth.dart';
import '../../models/promo_code_model.dart';
import '../../services/promo_code_service.dart';

class SuperAdminPromoApprovalScreen extends StatefulWidget {
  const SuperAdminPromoApprovalScreen({Key? key}) : super(key: key);

  @override
  _SuperAdminPromoApprovalScreenState createState() => _SuperAdminPromoApprovalScreenState();
}

class _SuperAdminPromoApprovalScreenState extends State<SuperAdminPromoApprovalScreen> {
  List<PromoCodeModel> pendingPromoCodes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingPromoCodes();
  }

  Future<void> _loadPendingPromoCodes() async {
    setState(() {
      isLoading = true;
    });

    try {
      final codes = await PromoCodeService.getPendingPromoCodesForApproval();
      setState(() {
        pendingPromoCodes = codes;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading pending promo codes: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promo Code Approvals'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingPromoCodes,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : pendingPromoCodes.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadPendingPromoCodes,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: pendingPromoCodes.length,
                    itemBuilder: (context, index) {
                      final promoCode = pendingPromoCodes[index];
                      return _buildPromoCodeApprovalCard(promoCode);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No pending approvals',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All promo codes have been reviewed',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCodeApprovalCard(PromoCodeModel promoCode) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with code and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        promoCode.code,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Created: ${_formatDate(promoCode.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.pending,
                        color: Colors.orange.shade700,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'PENDING APPROVAL',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Title and description
            Text(
              promoCode.title,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              promoCode.description,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 16),

            // Promo code details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          'Type',
                          _getPromoTypeDisplayName(promoCode.type),
                        ),
                      ),
                      Expanded(
                        child: _buildDetailItem(
                          'Value',
                          promoCode.displayValue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          'Max Uses',
                          promoCode.maxUses.toString(),
                        ),
                      ),
                      Expanded(
                        child: _buildDetailItem(
                          'Valid Until',
                          _formatDate(promoCode.validTo),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDetailItem(
                    'User Types',
                    promoCode.applicableUserTypes.join(', '),
                  ),
                  const SizedBox(height: 8),
                  _buildDetailItem(
                    'Countries',
                    promoCode.applicableCountries.isEmpty 
                        ? 'All countries'
                        : promoCode.applicableCountries.join(', '),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Creator info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Created by Country Admin',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.blue.shade700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Country: ${promoCode.createdByCountry}',
                          style: TextStyle(
                            color: Colors.blue.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(promoCode),
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showApproveDialog(promoCode),
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _showApproveDialog(PromoCodeModel promoCode) async {
    final titleController = TextEditingController(text: promoCode.title);
    final descriptionController = TextEditingController(text: promoCode.description);
    final valueController = TextEditingController(text: promoCode.value.toString());
    final maxUsesController = TextEditingController(text: promoCode.maxUses.toString());

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Approve Promo Code: ${promoCode.code}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'You can modify the promo code details before approval:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              
              TextField(
                controller: valueController,
                decoration: const InputDecoration(
                  labelText: 'Value',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              
              TextField(
                controller: maxUsesController,
                decoration: const InputDecoration(
                  labelText: 'Max Uses',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop({
                'approved': true,
                'title': titleController.text,
                'description': descriptionController.text,
                'value': double.tryParse(valueController.text),
                'maxUses': int.tryParse(maxUsesController.text),
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null && result['approved'] == true) {
      await _approvePromoCode(promoCode, result);
    }
  }

  Future<void> _showRejectDialog(PromoCodeModel promoCode) async {
    final reasonController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Promo Code: ${promoCode.code}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please provide a reason for rejection:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                hintText: 'Reason for rejection...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a rejection reason')),
                );
                return;
              }
              Navigator.of(context).pop(reasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _rejectPromoCode(promoCode, result);
    }
  }

  Future<void> _approvePromoCode(PromoCodeModel promoCode, Map<String, dynamic> modifications) async {
    try {
      final superAdminId = RestAuthService.instance.currentUser?.uid;
      if (superAdminId == null) {
        throw Exception('Super admin not authenticated');
      }

      final success = await PromoCodeService.approvePromoCode(
        promoCode.id,
        superAdminId,
        modifiedTitle: modifications['title'] != promoCode.title ? modifications['title'] : null,
        modifiedDescription: modifications['description'] != promoCode.description ? modifications['description'] : null,
        modifiedValue: modifications['value'] != promoCode.value ? modifications['value'] : null,
        modifiedMaxUses: modifications['maxUses'] != promoCode.maxUses ? modifications['maxUses'] : null,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Promo code ${promoCode.code} approved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _loadPendingPromoCodes();
      } else {
        throw Exception('Approval failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error approving promo code: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectPromoCode(PromoCodeModel promoCode, String reason) async {
    try {
      final superAdminId = RestAuthService.instance.currentUser?.uid;
      if (superAdminId == null) {
        throw Exception('Super admin not authenticated');
      }

      final success = await PromoCodeService.rejectPromoCode(
        promoCode.id,
        superAdminId,
        reason,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Promo code ${promoCode.code} rejected'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadPendingPromoCodes();
      } else {
        throw Exception('Rejection failed');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error rejecting promo code: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getPromoTypeDisplayName(PromoCodeType type) {
    switch (type) {
      case PromoCodeType.percentageDiscount:
        return 'Percentage Discount';
      case PromoCodeType.fixedDiscount:
        return 'Fixed Amount Discount';
      case PromoCodeType.freeTrialExtension:
        return 'Free Trial Extension';
      case PromoCodeType.unlimitedResponses:
        return 'Unlimited Responses';
      case PromoCodeType.businessFreeClicks:
        return 'Business Free Clicks';
      default:
        return type.toString().split('.').last;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
