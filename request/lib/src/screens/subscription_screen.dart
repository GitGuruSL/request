import 'package:flutter/material.dart';
import 'src/utils/firebase_shim.dart'; // Added by migration script
// REMOVED_FB_IMPORT: import 'package:firebase_auth/firebase_auth.dart';
import '../models/subscription_model.dart';
import '../services/subscription_service.dart';
import '../services/country_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  Map<String, dynamic>? subscriptionStatus;
  List<SubscriptionPlan> availablePlans = [];
  bool isLoading = true;
  String? errorMessage;
  SubscriptionType userType = SubscriptionType.rider; // Default

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final user = RestAuthService.instance.currentUser;
      if (user == null) {
        setState(() {
          errorMessage = 'Please log in to view subscription details';
          isLoading = false;
        });
        return;
      }

      // Load subscription status
      final status = await SubscriptionService.getSubscriptionStatus(user.uid);
      
      // Determine user type (you might want to get this from user profile)
      final currentCountry = await CountryService.getCurrentCountryCode();
      
      // Load available plans
      final plans = await SubscriptionService.getSubscriptionPlans(userType, currentCountry ?? 'LK');

      setState(() {
        subscriptionStatus = status;
        availablePlans = plans;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error loading subscription data: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? _buildErrorWidget()
              : _buildSubscriptionContent(),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            errorMessage!,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadSubscriptionData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionContent() {
    if (subscriptionStatus == null) return const SizedBox();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentStatusCard(),
          const SizedBox(height: 24),
          if (!subscriptionStatus!['hasActiveAccess']) ...[
            _buildTrialExpiredWarning(),
            const SizedBox(height: 24),
          ],
          _buildAvailablePlans(),
          const SizedBox(height: 24),
          _buildUsageStats(),
        ],
      ),
    );
  }

  Widget _buildCurrentStatusCard() {
    final status = subscriptionStatus!;
    final hasActiveAccess = status['hasActiveAccess'] ?? false;
    final isTrialActive = status['isTrialActive'] ?? false;
    final remainingTrialDays = status['remainingTrialDays'] ?? 0;
    final remainingSubscriptionDays = status['remainingSubscriptionDays'] ?? 0;

    Color statusColor;
    String statusText;
    String subtitleText;

    if (isTrialActive) {
      statusColor = Colors.blue;
      statusText = 'Free Trial Active';
      subtitleText = '$remainingTrialDays days remaining';
    } else if (hasActiveAccess) {
      statusColor = Colors.green;
      statusText = 'Premium Subscription Active';
      subtitleText = '$remainingSubscriptionDays days remaining';
    } else {
      statusColor = Colors.orange;
      statusText = 'Limited Access';
      subtitleText = 'Upgrade to unlock full features';
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    hasActiveAccess ? Icons.check_circle : Icons.warning_outlined,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitleText,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (!hasActiveAccess && !isTrialActive) ...[
              const SizedBox(height: 16),
              _buildLimitationsInfo(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLimitationsInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Limitations:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (userType == SubscriptionType.rider) ...[
            const Text('• Only 3 ride responses per month'),
            const Text('• No ride notifications'),
          ] else ...[
            const Text('• Pay per customer click'),
            const Text('• Limited analytics'),
          ],
        ],
      ),
    );
  }

  Widget _buildTrialExpiredWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_off, color: Colors.red[700], size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trial Period Ended',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your 3-month free trial has ended. Upgrade now to continue enjoying full features!',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailablePlans() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Available Plans',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...availablePlans.map((plan) => _buildPlanCard(plan)).toList(),
      ],
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan) {
    final countryCode = subscriptionStatus?['countryCode'] ?? 'LK';
    final price = plan.getPriceForCountry(countryCode);
    final currencySymbol = plan.getCurrencySymbolForCountry(countryCode);
    final isCurrentPlan = subscriptionStatus?['planId'] == plan.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: isCurrentPlan ? 8 : 2,
      child: Container(
        decoration: isCurrentPlan
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue, width: 2),
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      plan.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isCurrentPlan)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'CURRENT',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                plan.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _getPriceDisplay(plan, price, currencySymbol),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 16),
              ...plan.features.map((feature) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(feature, style: const TextStyle(fontSize: 14))),
                  ],
                ),
              )),
              const SizedBox(height: 16),
              if (!isCurrentPlan)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _selectPlan(plan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(_getButtonText(plan)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPriceDisplay(SubscriptionPlan plan, double price, String currencySymbol) {
    switch (plan.paymentModel) {
      case PaymentModel.monthly:
        return '$currencySymbol${price.toStringAsFixed(2)}/month';
      case PaymentModel.yearly:
        return '$currencySymbol${price.toStringAsFixed(2)}/year';
      case PaymentModel.payPerClick:
        return '$currencySymbol${price.toStringAsFixed(2)}/click';
    }
  }

  String _getButtonText(SubscriptionPlan plan) {
    switch (plan.paymentModel) {
      case PaymentModel.payPerClick:
        return 'Switch to Pay-Per-Click';
      default:
        return 'Subscribe Now';
    }
  }

  Widget _buildUsageStats() {
    final usageStats = subscriptionStatus?['usageStats'] as Map<String, dynamic>? ?? {};
    
    if (usageStats.isEmpty) return const SizedBox();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Usage Statistics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (userType == SubscriptionType.rider) ...[
              _buildUsageStat('Rides Responded', usageStats['ridesResponded']?.toString() ?? '0'),
              _buildUsageStat('Notifications Received', usageStats['notificationsReceived']?.toString() ?? '0'),
            ] else ...[
              _buildUsageStat('Clicks Received', usageStats['clicksReceived']?.toString() ?? '0'),
              _buildUsageStat('Total Spent', '${subscriptionStatus?['currency'] ?? 'Rs'}${usageStats['totalSpent']?.toStringAsFixed(2) ?? '0.00'}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUsageStat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _selectPlan(SubscriptionPlan plan) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Subscribe to ${plan.name}'),
          content: Text('Are you sure you want to subscribe to ${plan.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _processPlanUpgrade(plan);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Subscribe'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processPlanUpgrade(SubscriptionPlan plan) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Processing subscription...'),
              ],
            ),
          );
        },
      );

      final user = RestAuthService.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      await SubscriptionService.upgradeSubscription(
        user.uid,
        plan.id,
        'card', // This would be selected by user in real app
      );

      // Close loading dialog
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subscription updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Reload data
      _loadSubscriptionData();
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Subscription failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
