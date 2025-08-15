import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/promo_code_model.dart';
import '../services/promo_code_service.dart';

class PromoCodeAdminScreen extends StatefulWidget {
  const PromoCodeAdminScreen({Key? key}) : super(key: key);

  @override
  _PromoCodeAdminScreenState createState() => _PromoCodeAdminScreenState();
}

class _PromoCodeAdminScreenState extends State<PromoCodeAdminScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<PromoCodeModel> promoCodes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPromoCodes();
  }

  Future<void> _loadPromoCodes() async {
    setState(() {
      isLoading = true;
    });

    try {
      final snapshot = await _firestore
          .collection('promoCodes')
          .orderBy('createdAt', descending: true)
          .get();

      setState(() {
        promoCodes = snapshot.docs
            .map((doc) => PromoCodeModel.fromFirestore(doc))
            .toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading promo codes: $e')),
      );
    }
  }

  Future<void> _togglePromoCodeStatus(PromoCodeModel promoCode) async {
    try {
      final newStatus = promoCode.status == PromoCodeStatus.active
          ? PromoCodeStatus.disabled
          : PromoCodeStatus.active;

      await PromoCodeService.updatePromoCodeStatus(promoCode.id, newStatus);
      await _loadPromoCodes();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Promo code ${promoCode.code} ${newStatus == PromoCodeStatus.active ? 'activated' : 'disabled'}',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating promo code: $e')),
      );
    }
  }

  Future<void> _showPromoCodeStats(PromoCodeModel promoCode) async {
    try {
      final stats = await PromoCodeService.getPromoCodeStats(promoCode.id);
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('${promoCode.code} Statistics'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Total Uses: ${stats['totalUses'] ?? 0}'),
                Text('Remaining Uses: ${promoCode.maxUses - promoCode.currentUses}'),
                const SizedBox(height: 16),
                
                if (stats['userTypeBreakdown'] != null) ...[
                  const Text('User Type Breakdown:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...(stats['userTypeBreakdown'] as Map<String, int>).entries.map(
                    (entry) => Text('${entry.key}: ${entry.value}'),
                  ),
                  const SizedBox(height: 16),
                ],
                
                if (stats['countryBreakdown'] != null) ...[
                  const Text('Country Breakdown:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...(stats['countryBreakdown'] as Map<String, int>).entries.map(
                    (entry) => Text('${entry.key}: ${entry.value}'),
                  ),
                  const SizedBox(height: 16),
                ],
                
                Text('Total Discount Given: \$${stats['totalDiscountGiven']?.toStringAsFixed(2) ?? '0.00'}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading stats: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promo Code Management'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPromoCodes,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : promoCodes.isEmpty
              ? const Center(
                  child: Text(
                    'No promo codes found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPromoCodes,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: promoCodes.length,
                    itemBuilder: (context, index) {
                      final promoCode = promoCodes[index];
                      return _buildPromoCodeCard(promoCode);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePromoCodeDialog(),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPromoCodeCard(PromoCodeModel promoCode) {
    final isActive = promoCode.status == PromoCodeStatus.active;
    final isExpired = DateTime.now().isAfter(promoCode.validTo);
    final usagePercentage = promoCode.maxUses > 0 
        ? (promoCode.currentUses / promoCode.maxUses) 
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
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
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: promoCode.displayValue.contains('FREE')
                                  ? Colors.green.shade100
                                  : Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              promoCode.displayValue,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: promoCode.displayValue.contains('FREE')
                                    ? Colors.green.shade700
                                    : Colors.orange.shade700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        promoCode.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        promoCode.description,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isActive && !isExpired
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isExpired
                            ? 'EXPIRED'
                            : isActive
                                ? 'ACTIVE'
                                : 'DISABLED',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isActive && !isExpired
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    PopupMenuButton(
                      icon: const Icon(Icons.more_vert),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(
                            isActive ? 'Disable' : 'Enable',
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'stats',
                          child: Text('View Stats'),
                        ),
                      ],
                      onSelected: (value) {
                        switch (value) {
                          case 'toggle':
                            _togglePromoCodeStatus(promoCode);
                            break;
                          case 'stats':
                            _showPromoCodeStats(promoCode);
                            break;
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Usage progress bar
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: usagePercentage,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      usagePercentage > 0.8 ? Colors.red : Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${promoCode.currentUses}/${promoCode.maxUses}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Valid dates and applicable info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Valid: ${_formatDate(promoCode.validFrom)} - ${_formatDate(promoCode.validTo)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'For: ${promoCode.applicableUserTypes.join(', ')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                if (promoCode.applicableCountries.isNotEmpty)
                  Wrap(
                    spacing: 4,
                    children: promoCode.applicableCountries.take(3).map(
                      (country) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          country,
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ).toList(),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showCreatePromoCodeDialog() {
    // This would open a dialog to create new promo codes
    // Implementation would include form fields for all promo code properties
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Create promo code feature - implement form dialog here'),
      ),
    );
  }
}
