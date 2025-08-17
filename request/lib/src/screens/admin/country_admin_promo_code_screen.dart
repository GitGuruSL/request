import 'package:flutter/material.dart';
import 'src/utils/firebase_shim.dart'; // Added by migration script
// REMOVED_FB_IMPORT: import 'package:firebase_auth/firebase_auth.dart';
import '../../models/promo_code_model.dart';
import '../../services/promo_code_service.dart';

class CountryAdminPromoCodeScreen extends StatefulWidget {
  final String adminCountryCode;
  
  const CountryAdminPromoCodeScreen({
    Key? key,
    required this.adminCountryCode,
  }) : super(key: key);

  @override
  _CountryAdminPromoCodeScreenState createState() => _CountryAdminPromoCodeScreenState();
}

class _CountryAdminPromoCodeScreenState extends State<CountryAdminPromoCodeScreen>
    with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  List<PromoCodeModel> myPromoCodes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMyPromoCodes();
  }

  Future<void> _loadMyPromoCodes() async {
    setState(() {
      isLoading = true;
    });

    try {
      final adminId = RestAuthService.instance.currentUser?.uid;
      if (adminId != null) {
        final codes = await PromoCodeService.getPromoCodesByCountryAdmin(
          adminId,
          widget.adminCountryCode,
        );
        setState(() {
          myPromoCodes = codes;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading promo codes: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Promo Codes - ${widget.adminCountryCode}'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'My Promo Codes'),
            Tab(text: 'Create New'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMyPromoCodesTab(),
          _buildCreatePromoCodeTab(),
        ],
      ),
    );
  }

  Widget _buildMyPromoCodesTab() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (myPromoCodes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_offer_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No promo codes created yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first promo code using the Create New tab',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyPromoCodes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: myPromoCodes.length,
        itemBuilder: (context, index) {
          final promoCode = myPromoCodes[index];
          return _buildPromoCodeCard(promoCode);
        },
      ),
    );
  }

  Widget _buildPromoCodeCard(PromoCodeModel promoCode) {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (promoCode.status) {
      case PromoCodeStatus.pendingApproval:
        statusColor = Colors.orange;
        statusText = 'PENDING APPROVAL';
        statusIcon = Icons.pending;
        break;
      case PromoCodeStatus.active:
        statusColor = Colors.green;
        statusText = 'ACTIVE';
        statusIcon = Icons.check_circle;
        break;
      case PromoCodeStatus.rejected:
        statusColor = Colors.red;
        statusText = 'REJECTED';
        statusIcon = Icons.cancel;
        break;
      case PromoCodeStatus.disabled:
        statusColor = Colors.grey;
        statusText = 'DISABLED';
        statusIcon = Icons.pause_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusText = promoCode.status.toString().split('.').last.toUpperCase();
        statusIcon = Icons.help;
    }

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
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              promoCode.displayValue,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.orange.shade700,
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        statusIcon,
                        color: statusColor,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Usage progress and dates
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Usage: ${promoCode.currentUses}/${promoCode.maxUses}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: promoCode.maxUses > 0 
                            ? promoCode.currentUses / promoCode.maxUses 
                            : 0.0,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          promoCode.currentUses / promoCode.maxUses > 0.8 
                              ? Colors.red 
                              : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Valid until',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      _formatDate(promoCode.validTo),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Rejection reason if applicable
            if (promoCode.isRejected && promoCode.rejectionReason != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade600,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Rejection Reason:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      promoCode.rejectionReason!,
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Approval info if approved
            if (promoCode.isApproved) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified,
                      color: Colors.green.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Approved on ${_formatDate(promoCode.approvedAt!)}',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildCreatePromoCodeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: _CreatePromoCodeForm(
        adminCountryCode: widget.adminCountryCode,
        onPromoCodeCreated: () {
          _loadMyPromoCodes();
          _tabController.animateTo(0); // Switch to first tab
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Promo code submitted for approval!'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class _CreatePromoCodeForm extends StatefulWidget {
  final String adminCountryCode;
  final VoidCallback onPromoCodeCreated;

  const _CreatePromoCodeForm({
    Key? key,
    required this.adminCountryCode,
    required this.onPromoCodeCreated,
  }) : super(key: key);

  @override
  _CreatePromoCodeFormState createState() => _CreatePromoCodeFormState();
}

class _CreatePromoCodeFormState extends State<_CreatePromoCodeForm> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _valueController = TextEditingController();
  final _maxUsesController = TextEditingController();

  PromoCodeType _selectedType = PromoCodeType.percentageDiscount;
  DateTime _validFrom = DateTime.now();
  DateTime _validTo = DateTime.now().add(const Duration(days: 30));
  List<String> _selectedUserTypes = ['rider'];
  bool _applyToAllCountries = false;
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade600, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Promo Code Approval Process',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'All promo codes require super admin approval before becoming active. You will be notified once your promo code is reviewed.',
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Promo code basic info
          TextFormField(
            controller: _codeController,
            decoration: const InputDecoration(
              labelText: 'Promo Code *',
              hintText: 'e.g., SUMMER2025',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.local_offer),
            ),
            textCapitalization: TextCapitalization.characters,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a promo code';
              }
              if (value.length < 3) {
                return 'Promo code must be at least 3 characters';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title *',
              hintText: 'e.g., Summer Special Offer',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a title';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description *',
              hintText: 'Brief description of the offer',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a description';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Discount type and value
          Text(
            'Discount Type',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          DropdownButtonFormField<PromoCodeType>(
            value: _selectedType,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
            items: PromoCodeType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(_getPromoTypeDisplayName(type)),
              );
            }).toList(),
            onChanged: (PromoCodeType? value) {
              setState(() {
                _selectedType = value!;
              });
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _valueController,
            decoration: InputDecoration(
              labelText: _getValueLabel(),
              hintText: _getValueHint(),
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.monetization_on),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a value';
              }
              final doubleValue = double.tryParse(value);
              if (doubleValue == null || doubleValue <= 0) {
                return 'Please enter a valid positive number';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          TextFormField(
            controller: _maxUsesController,
            decoration: const InputDecoration(
              labelText: 'Maximum Uses *',
              hintText: 'e.g., 100',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.people),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter maximum uses';
              }
              final intValue = int.tryParse(value);
              if (intValue == null || intValue <= 0) {
                return 'Please enter a valid positive number';
              }
              return null;
            },
          ),

          const SizedBox(height: 24),

          // Valid dates
          Text(
            'Validity Period',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: const Text('Valid From'),
                  subtitle: Text(_formatDate(_validFrom)),
                  leading: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _validFrom,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        _validFrom = date;
                      });
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ListTile(
                  title: const Text('Valid To'),
                  subtitle: Text(_formatDate(_validTo)),
                  leading: const Icon(Icons.event),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: _validTo,
                      firstDate: _validFrom,
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        _validTo = date;
                      });
                    }
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // User types
          Text(
            'Applicable User Types',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            children: ['rider', 'business', 'driver'].map((userType) {
              return FilterChip(
                label: Text(userType[0].toUpperCase() + userType.substring(1)),
                selected: _selectedUserTypes.contains(userType),
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedUserTypes.add(userType);
                    } else {
                      _selectedUserTypes.remove(userType);
                    }
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Country applicability
          SwitchListTile(
            title: const Text('Apply to all countries'),
            subtitle: Text(_applyToAllCountries 
                ? 'This promo code will be available globally'
                : 'This promo code will only be available in ${widget.adminCountryCode}'),
            value: _applyToAllCountries,
            onChanged: (value) {
              setState(() {
                _applyToAllCountries = value;
              });
            },
          ),

          const SizedBox(height: 32),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitPromoCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Submit for Approval',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitPromoCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedUserTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one user type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final adminId = RestAuthService.instance.currentUser?.uid;
      if (adminId == null) {
        throw Exception('Admin not authenticated');
      }

      final promoCode = PromoCodeModel(
        id: '',
        code: _codeController.text.trim().toUpperCase(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        status: PromoCodeStatus.pendingApproval,
        value: double.parse(_valueController.text.trim()),
        validFrom: _validFrom,
        validTo: _validTo,
        maxUses: int.parse(_maxUsesController.text.trim()),
        currentUses: 0,
        applicableUserTypes: _selectedUserTypes,
        applicableCountries: _applyToAllCountries ? [] : [widget.adminCountryCode],
        conditions: {},
        createdBy: adminId,
        approvedBy: null,
        approvedAt: null,
        rejectionReason: null,
        createdByCountry: widget.adminCountryCode,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await PromoCodeService.createPromoCodeForApproval(
        promoCode,
        adminId,
        widget.adminCountryCode,
      );

      // Reset form
      _formKey.currentState!.reset();
      _codeController.clear();
      _titleController.clear();
      _descriptionController.clear();
      _valueController.clear();
      _maxUsesController.clear();
      setState(() {
        _selectedType = PromoCodeType.percentageDiscount;
        _validFrom = DateTime.now();
        _validTo = DateTime.now().add(const Duration(days: 30));
        _selectedUserTypes = ['rider'];
        _applyToAllCountries = false;
      });

      widget.onPromoCodeCreated();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating promo code: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
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

  String _getValueLabel() {
    switch (_selectedType) {
      case PromoCodeType.percentageDiscount:
        return 'Discount Percentage (%)';
      case PromoCodeType.fixedDiscount:
        return 'Discount Amount';
      case PromoCodeType.freeTrialExtension:
        return 'Extra Days';
      case PromoCodeType.unlimitedResponses:
        return 'Valid for (Days)';
      case PromoCodeType.businessFreeClicks:
        return 'Number of Free Clicks';
      default:
        return 'Value';
    }
  }

  String _getValueHint() {
    switch (_selectedType) {
      case PromoCodeType.percentageDiscount:
        return 'e.g., 50 (for 50% off)';
      case PromoCodeType.fixedDiscount:
        return 'e.g., 200 (discount amount in local currency)';
      case PromoCodeType.freeTrialExtension:
        return 'e.g., 30 (extra 30 days)';
      case PromoCodeType.unlimitedResponses:
        return 'e.g., 30 (unlimited for 30 days)';
      case PromoCodeType.businessFreeClicks:
        return 'e.g., 100 (100 free clicks)';
      default:
        return 'Enter value';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _codeController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _valueController.dispose();
    _maxUsesController.dispose();
    super.dispose();
  }
}
