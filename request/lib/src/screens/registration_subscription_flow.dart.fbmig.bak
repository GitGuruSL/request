import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/subscription_model.dart';
import '../models/promo_code_model.dart';
import '../services/subscription_service.dart';
import '../services/promo_code_service.dart';
import '../services/user_service.dart';

class RegistrationSubscriptionFlow extends StatefulWidget {
  final String userType; // 'rider', 'business', 'driver'
  final String countryCode;
  final Map<String, dynamic> registrationData;
  final VoidCallback onComplete;

  const RegistrationSubscriptionFlow({
    Key? key,
    required this.userType,
    required this.countryCode,
    required this.registrationData,
    required this.onComplete,
  }) : super(key: key);

  @override
  _RegistrationSubscriptionFlowState createState() => _RegistrationSubscriptionFlowState();
}

class _RegistrationSubscriptionFlowState extends State<RegistrationSubscriptionFlow> {
  List<SubscriptionPlan> availablePlans = [];
  SubscriptionPlan? selectedPlan;
  List<PromoCodeModel> availablePromoCodes = [];
  PromoCodeModel? appliedPromoCode;
  
  final TextEditingController promoCodeController = TextEditingController();
  bool isLoadingPlans = false;
  bool isApplyingPromoCode = false;
  bool isProcessingRegistration = false;
  String? errorMessage;
  String? promoMessage;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionPlans();
    _loadPromoCodes();
  }

  Future<void> _loadSubscriptionPlans() async {
    setState(() {
      isLoadingPlans = true;
      errorMessage = null;
    });

    try {
      final plans = await SubscriptionService.getAvailablePlans(
        SubscriptionType.values.firstWhere(
          (type) => type.toString().split('.').last == widget.userType,
          orElse: () => SubscriptionType.rider,
        ),
        widget.countryCode,
      );

      setState(() {
        availablePlans = plans;
        isLoadingPlans = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading subscription plans: $e';
        isLoadingPlans = false;
      });
    }
  }

  Future<void> _loadPromoCodes() async {
    try {
      final promoCodes = await PromoCodeService.getActivePromoCodes(
        widget.userType,
        widget.countryCode,
      );

      setState(() {
        availablePromoCodes = promoCodes;
      });
    } catch (e) {
      print('Error loading promo codes: $e');
    }
  }

  Future<void> _applyPromoCode() async {
    if (promoCodeController.text.trim().isEmpty) {
      _showMessage('Please enter a promo code', isError: true);
      return;
    }

    setState(() {
      isApplyingPromoCode = true;
      promoMessage = null;
    });

    try {
      final result = await PromoCodeService.validateAndApplyPromoCode(
        promoCodeController.text.trim(),
        widget.userType,
        widget.countryCode,
      );

      if (result['success']) {
        setState(() {
          appliedPromoCode = result['promoCode'];
          promoMessage = 'Promo code applied successfully! ${appliedPromoCode!.displayValue}';
        });
      } else {
        _showMessage(result['message'], isError: true);
      }
    } catch (e) {
      _showMessage('Error applying promo code: $e', isError: true);
    } finally {
      setState(() {
        isApplyingPromoCode = false;
      });
    }
  }

  Future<void> _completeRegistration() async {
    if (widget.userType == 'business' && selectedPlan == null) {
      _showMessage('Businesses must select a subscription plan', isError: true);
      return;
    }

    setState(() {
      isProcessingRegistration = true;
      errorMessage = null;
    });

    try {
      // Complete user registration
      final user = await UserService.completeRegistration(widget.registrationData);
      
      // Create subscription
      if (selectedPlan != null || widget.userType == 'rider') {
        await SubscriptionService.createUserSubscription(
          user.uid,
          selectedPlan?.id ?? 'free_rider_plan',
          SubscriptionType.values.firstWhere(
            (type) => type.toString().split('.').last == widget.userType,
            orElse: () => SubscriptionType.rider,
          ),
          widget.countryCode,
          appliedPromoCode: appliedPromoCode,
        );
      }

      widget.onComplete();
    } catch (e) {
      setState(() {
        errorMessage = 'Registration failed: $e';
        isProcessingRegistration = false;
      });
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Registration'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: isLoadingPlans
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeSection(),
                  const SizedBox(height: 24),
                  if (availablePromoCodes.isNotEmpty) _buildPromoCodeSection(),
                  const SizedBox(height: 24),
                  _buildSubscriptionPlansSection(),
                  const SizedBox(height: 32),
                  _buildCompleteRegistrationButton(),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Text(
                        errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildWelcomeSection() {
    String userTypeDisplay = widget.userType[0].toUpperCase() + widget.userType.substring(1);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome, $userTypeDisplay!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _getWelcomeMessage(),
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  String _getWelcomeMessage() {
    switch (widget.userType) {
      case 'rider':
        return 'Get started with a 3-month free trial. After that, choose a plan that works for you!';
      case 'business':
        return 'Start with a 3-month free trial, then choose from our flexible business plans.';
      case 'driver':
        return 'Welcome to our driver community! Enjoy your 3-month free trial period.';
      default:
        return 'Complete your registration to get started!';
    }
  }

  Widget _buildPromoCodeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Have a Promo Code?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: promoCodeController,
                    decoration: InputDecoration(
                      hintText: 'Enter promo code',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.local_offer),
                      enabled: !isApplyingPromoCode && appliedPromoCode == null,
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: appliedPromoCode == null && !isApplyingPromoCode
                      ? _applyPromoCode
                      : null,
                  child: isApplyingPromoCode
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Apply'),
                ),
              ],
            ),
            if (promoMessage != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        promoMessage!,
                        style: TextStyle(color: Colors.green.shade700, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (availablePromoCodes.isNotEmpty && appliedPromoCode == null) ...[
              const SizedBox(height: 12),
              const Text(
                'Available Offers:',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: availablePromoCodes.take(3).map((promo) => 
                  GestureDetector(
                    onTap: () {
                      promoCodeController.text = promo.code;
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade300),
                      ),
                      child: Text(
                        '${promo.code} - ${promo.displayValue}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionPlansSection() {
    if (widget.userType == 'rider') {
      return _buildRiderSubscriptionInfo();
    } else if (widget.userType == 'business') {
      return _buildBusinessSubscriptionPlans();
    }
    return Container();
  }

  Widget _buildRiderSubscriptionInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Subscription Plan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPlanTile(
              title: '3 Months Free Trial',
              subtitle: 'Full access to all features',
              features: [
                'Unlimited ride responses',
                'Real-time notifications',
                'Priority customer support',
                'All app features included',
              ],
              price: 'FREE',
              isSelected: true,
              onTap: () {},
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'After Trial Period:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Subscribe for unlimited access\n• Or continue with 3 responses per month (no notifications)',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessSubscriptionPlans() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Choose Your Business Plan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (widget.userType == 'business')
                  Text(
                    ' (Required)',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Trial Period Info
            _buildPlanTile(
              title: '3 Months Free Trial',
              subtitle: 'Full access to all features',
              features: [
                'Unlimited customer inquiries',
                'Real-time notifications',
                'Business analytics dashboard',
                'Priority support',
              ],
              price: 'FREE',
              isSelected: false,
              onTap: () {},
            ),
            
            const SizedBox(height: 16),
            
            // Business Plans
            if (availablePlans.isNotEmpty)
              ...availablePlans.map((plan) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildPlanTile(
                  title: plan.name,
                  subtitle: plan.description,
                  features: plan.features,
                  price: '${plan.getCurrencySymbolForCountry(widget.countryCode)}${plan.getPriceForCountry(widget.countryCode).toStringAsFixed(2)}',
                  priceSubtitle: plan.paymentModel == PaymentModel.payPerClick ? 'per click' : 'per month',
                  isSelected: selectedPlan?.id == plan.id,
                  onTap: () {
                    setState(() {
                      selectedPlan = plan;
                    });
                  },
                ),
              )).toList(),
              
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Business Plan Benefits:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• You only pay for actual customer interactions\n• Detailed analytics and reporting\n• Dedicated business support',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanTile({
    required String title,
    required String subtitle,
    required List<String> features,
    required String price,
    String? priceSubtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? Colors.blue.shade50 : Colors.white,
        ),
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
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    if (priceSubtitle != null)
                      Text(
                        priceSubtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.green.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompleteRegistrationButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isProcessingRegistration ? null : _completeRegistration,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isProcessingRegistration
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Complete Registration',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  @override
  void dispose() {
    promoCodeController.dispose();
    super.dispose();
  }
}
