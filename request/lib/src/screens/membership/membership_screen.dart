import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/subscription_service.dart';
import '../../services/country_service.dart';
import '../../theme/glass_theme.dart';
import '../../theme/app_theme.dart';

class MembershipScreen extends StatefulWidget {
  final bool promptOnboarding;
  final String?
      requiredSubscriptionType; // 'driver', 'business', 'product_seller'
  final bool isProductSellerRequired; // Force product seller subscription

  const MembershipScreen({
    super.key,
    this.promptOnboarding = false,
    this.requiredSubscriptionType,
    this.isProductSellerRequired = false,
  });

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  final _api = SubscriptionServiceApi.instance;
  final _promoController = TextEditingController();
  bool _loading = true;
  List<SubscriptionPlan> _userResponsePlans = [];
  List<SubscriptionPlan> _productSellerPlans = [];
  Map<String, dynamic>? _current;
  String _planType = 'user_response'; // 'user_response' | 'product_seller'
  bool _checkingOut = false;
  String? _selectedRole; // general | driver | delivery | professional

  @override
  void initState() {
    super.initState();
    _initializePlanType();
    _load();
  }

  void _initializePlanType() {
    // Set initial plan type based on requirements
    if (widget.isProductSellerRequired ||
        widget.requiredSubscriptionType == 'product_seller') {
      _planType = 'product_seller';
    } else {
      _planType = 'user_response';
    }
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final userPlans = await _api.fetchUserResponsePlans(activeOnly: true);
      final productPlans = await _api.fetchProductSellerPlans(activeOnly: true);
      final cur = await _api.getMySubscription();

      // Filter plans based on user type requirements
      List<SubscriptionPlan> filteredUserPlans =
          _filterUserResponsePlans(userPlans);

      if (mounted) {
        setState(() {
          _userResponsePlans = filteredUserPlans;
          _productSellerPlans = productPlans;
          _current = cur;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<SubscriptionPlan> _filterUserResponsePlans(
      List<SubscriptionPlan> plans) {
  final requiredType = widget.requiredSubscriptionType ??
    ((_selectedRole == 'driver')
      ? 'driver'
      : (_selectedRole == 'delivery' || _selectedRole == 'professional')
        ? 'business'
        : null);

  if (requiredType == 'driver') {
      // For drivers: show free plan + ride-specific plans
      return plans
          .where((plan) =>
              plan.planType == 'free' ||
              plan.planType.toLowerCase().contains('ride'))
          .toList();
  } else if (requiredType == 'business') {
      // For regular business: show free plan + all response plans
      return plans.where((plan) {
        final t = plan.planType.toLowerCase();
        return plan.planType == 'free' ||
            t.contains('all') ||
            t.contains('other') ||
            t.contains('general');
      }).toList();
  } else if (widget.isProductSellerRequired) {
      // For product sellers: only show free plan (3 responses) unless they get product subscription
      return plans.where((plan) => plan.planType == 'free').toList();
    }
    // Default: show all plans
    return plans;
  }

  String _getContextSpecificTitle() {
    if (widget.isProductSellerRequired) {
      return 'Choose your marketplace plan';
    }
    if (widget.requiredSubscriptionType == 'driver') {
      return 'Choose your driver plan';
    }
    if (widget.requiredSubscriptionType == 'business') {
      return 'Choose your business plan';
    }
    return _planType == 'user_response'
        ? 'Choose your response plan'
        : 'Choose your marketplace plan';
  }

  String _getContextSpecificDescription() {
    if (widget.isProductSellerRequired) {
      return 'Choose how you want to pay for your product listings in our marketplace.';
    }
    if (widget.requiredSubscriptionType == 'driver') {
      return 'Free plan gives 3 ride responses with contact details. Paid plans unlock unlimited responses, contact visibility, and instant notifications.';
    }
    if (widget.requiredSubscriptionType == 'business') {
      return 'Free plan gives 3 responses with contact details. Paid plans unlock unlimited responses, contact visibility, and instant notifications.';
    }
    return _planType == 'user_response'
        ? 'Free plan gives limited responses. Paid plans unlock unlimited responses, contact visibility, and instant notifications.'
        : 'Choose how you want to pay for your product listings in our marketplace.';
  }

  List<SubscriptionPlan> get _currentPlans {
    return _planType == 'user_response'
        ? _userResponsePlans
        : _productSellerPlans;
  }

  Future<void> _choosePlan(SubscriptionPlan plan) async {
    final promo = _promoController.text.trim();
    final country = CountryService.instance.getCurrentCountryCode();
    setState(() => _checkingOut = true);
    try {
      final created = await _api.createSubscription(
        planId: plan.id,
        countryCode: country,
        promoCode: promo.isEmpty ? null : promo,
      );
      if (created == null) {
        _toast('Failed to start subscription');
        return;
      }

      // Mark membership onboarding complete locally (role chosen + plan picked)
      await _markMembershipCompleted();

      final status = (created['status'] ?? created['state'] ?? '').toString();
      final subId =
          (created['id'] ?? created['subscription_id'] ?? '').toString();

      if (status == 'active' ||
          status == 'trialing' ||
          (created['active'] == true)) {
        _toast('Subscription activated');
        await _load();
        if (widget.promptOnboarding && mounted) {
          await _maybeNavigateRoleRegistration();
          Navigator.pushNamedAndRemoveUntil(context, '/home', (r) => false);
        }
        return;
      }

      // For paid plans -> payment checkout flow
      await _presentGatewaySheet(subId);
    } catch (e) {
      _toast('Error: $e');
    } finally {
      if (mounted) setState(() => _checkingOut = false);
    }
  }

  Future<void> _presentGatewaySheet(String subscriptionId) async {
    final country = CountryService.instance.getCurrentCountryCode();
    final gateways = await _api.getCountryGateways(country);
    if (!mounted) return;
    if (gateways.isEmpty) {
      _toast('No payment methods available for your country');
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: GlassTheme.colors.glassBackground.first,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select a payment method',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: GlassTheme.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...gateways.map((g) {
                  final name = (g['display_name'] ??
                          g['name'] ??
                          g['provider'] ??
                          'Payment')
                      .toString();
                  final provider =
                      (g['provider'] ?? g['code'] ?? '').toString();
                  return ListTile(
                    leading: const Icon(Icons.payment),
                    title: Text(name,
                        style: TextStyle(color: GlassTheme.colors.textPrimary)),
                    onTap: () async {
                      Navigator.pop(ctx);
                      await _startCheckout(subscriptionId, provider);
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _startCheckout(String subscriptionId, String provider) async {
    setState(() => _checkingOut = true);
    try {
      final data = await _api.checkoutSubscription(
        subscriptionId: subscriptionId,
        provider: provider.isEmpty ? null : provider,
      );
      if (data == null) {
        _toast('Unable to start payment');
        return;
      }
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor:
              GlassTheme.isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
          title: const Text('Continue to Pay'),
          content: SingleChildScrollView(
            child: Text(
              'Follow the payment instructions in the next step.\n\nDetails: ${data.toString()}',
              style: TextStyle(color: GlassTheme.colors.textSecondary),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      _toast('Checkout error: $e');
    } finally {
      if (mounted) setState(() => _checkingOut = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _markMembershipCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('membership_completed', true);
    } catch (_) {}
  }

  Future<void> _maybeNavigateRoleRegistration() async {
    // After selecting a plan during onboarding, take user to role-specific registration if applicable
    if (_selectedRole == 'driver') {
      Navigator.pushNamed(context, '/driver-registration');
    } else if (_selectedRole == 'delivery' || _selectedRole == 'professional' || _selectedRole == 'business') {
      // Use business registration for delivery/professional/business
      Navigator.pushNamed(context, '/business-registration');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFmt = CountryService.instance.getCurrencySymbol();
    return GlassTheme.backgroundContainer(
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('Membership'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppTheme.textPrimary,
          actions: [
            if (widget.promptOnboarding)
              TextButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context, '/home', (r) => false),
                child: const Text('Skip'),
              ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_current != null) _buildCurrentCard(),

                    if (widget.promptOnboarding) _buildRoleOnboarding(),

                    // Show tabs or context-specific header
                    _buildPlanTypeSelector(),

                    Container(
                      decoration: GlassTheme.glassContainer,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_getContextSpecificTitle(),
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: GlassTheme.colors.textPrimary)),
                          const SizedBox(height: 8),
                          Text(_getContextSpecificDescription(),
                              style: TextStyle(
                                  color: GlassTheme.colors.textSecondary)),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _promoController,
                            decoration: const InputDecoration(
                              labelText: 'Promo code (optional)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...(_currentPlans)
                        .map((p) => _buildPlanCard(p, currencyFmt))
                        .toList(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPlanTypeSelector() {
    // If user must choose product seller subscription, only show product seller options
    if (widget.isProductSellerRequired) {
      return Container(
        decoration: GlassTheme.glassContainer,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.store, color: GlassTheme.colors.primaryBlue),
                const SizedBox(width: 8),
                Text(
                  'Product Seller Subscription Required',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: GlassTheme.colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'To list products in our marketplace, you need to subscribe to a product seller plan.',
              style: TextStyle(color: GlassTheme.colors.textSecondary),
            ),
          ],
        ),
      );
    }

    // Context-specific headers for different user types
  final requiredType = widget.requiredSubscriptionType ??
    ((_selectedRole == 'driver') ? 'driver' : null);
  if (requiredType == 'driver') {
      return Container(
        decoration: GlassTheme.glassContainer,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.drive_eta, color: GlassTheme.colors.primaryBlue),
                const SizedBox(width: 8),
                Text(
                  'Driver Response Plans',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: GlassTheme.colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Special plans for drivers to respond to ride requests. Free plan gives 3 responses, then upgrade for unlimited responses and contact visibility.',
              style: TextStyle(color: GlassTheme.colors.textSecondary),
            ),
          ],
        ),
      );
    }

  if ((widget.requiredSubscriptionType == 'business') ||
    (_selectedRole == 'delivery') ||
    (_selectedRole == 'professional') ||
    (_selectedRole == 'business')) {
      return Container(
        decoration: GlassTheme.glassContainer,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, color: GlassTheme.colors.primaryBlue),
                const SizedBox(width: 8),
                Text(
                  'Business Response Plans',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: GlassTheme.colors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Plans for responding to various requests. Free plan gives 3 responses, then upgrade for unlimited responses and contact visibility.',
              style: TextStyle(color: GlassTheme.colors.textSecondary),
            ),
          ],
        ),
      );
    }

    // For regular users without specific context, show plan type tabs
    return Container(
      decoration: GlassTheme.glassContainer,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Plan Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: GlassTheme.colors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPlanTypeButton(
                  'Response Plans',
                  'For responding to requests',
                  Icons.chat_bubble_outline,
                  'user_response',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPlanTypeButton(
                  'Product Seller',
                  'For listing products',
                  Icons.store,
                  'product_seller',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleOnboarding() {
    // Simple role chooser shown during onboarding
    return Container(
      decoration: GlassTheme.glassContainer,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose how you will use Request',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: GlassTheme.colors.textPrimary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _roleChip('General Responder', 'general', Icons.handshake),
              _roleChip('Driver', 'driver', Icons.drive_eta),
              _roleChip('Delivery Service', 'delivery', Icons.local_shipping),
              _roleChip('Professional', 'professional', Icons.badge),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _selectedRole == 'driver'
                ? '3 free ride responses per month. Upgrade for unlimited and contact visibility.'
                : '3 free responses per month. Upgrade for unlimited and contact visibility.',
            style: TextStyle(color: GlassTheme.colors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _roleChip(String title, String value, IconData icon) {
    final selected = _selectedRole == value;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 6), Text(title)],
      ),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _selectedRole = value;
        });
      },
    );
  }

  Widget _buildPlanTypeButton(
      String title, String subtitle, IconData icon, String type) {
    final isSelected = _planType == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _planType = type;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? GlassTheme.colors.primaryBlue
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? GlassTheme.colors.primaryBlue.withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? GlassTheme.colors.primaryBlue : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? GlassTheme.colors.primaryBlue
                    : GlassTheme.colors.textPrimary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: GlassTheme.colors.textSecondary,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentCard() {
    final p = _current!;
    final planName = p['name'] ?? p['plan']?['name'] ?? 'Current Plan';
    final until = p['current_period_end'] ?? p['expires_at'];
    return Container(
      decoration: GlassTheme.glassContainer,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(planName.toString(),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: GlassTheme.colors.textPrimary,
              )),
          const SizedBox(height: 6),
          Text('Valid until: ${until ?? '-'}',
              style: TextStyle(color: GlassTheme.colors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionPlan plan, String currencySymbol) {
    return Container(
      decoration: GlassTheme.glassContainer,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(plan.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: GlassTheme.colors.textPrimary,
                    )),
              ),
              Text(plan.displayPrice,
                  style: TextStyle(color: GlassTheme.colors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          if ((plan.description ?? '').isNotEmpty)
            Text(plan.description!,
                style: TextStyle(color: GlassTheme.colors.textSecondary)),
          const SizedBox(height: 8),

          // Show plan-specific details
          if (plan.type == 'user_response') ...[
            if (plan.responseLimit != null)
              Text('${plan.responseLimit} responses per month',
                  style: TextStyle(
                      color: GlassTheme.colors.textSecondary, fontSize: 12))
            else
              Text('Unlimited responses',
                  style: TextStyle(
                      color: GlassTheme.colors.textSecondary, fontSize: 12)),
            if (plan.features != null && plan.features!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                children: plan.features!
                    .map((feature) => Chip(
                          label: Text(feature,
                              style: const TextStyle(fontSize: 10)),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ))
                    .toList(),
              ),
            ],
          ] else if (plan.type == 'product_seller') ...[
            Text(
                plan.planType == 'per_click'
                    ? 'Pay only when customers click on your products'
                    : 'Fixed monthly fee for unlimited product listings',
                style: TextStyle(
                    color: GlassTheme.colors.textSecondary, fontSize: 12)),
          ],

          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _checkingOut ? null : () => _choosePlan(plan),
              style: ElevatedButton.styleFrom(
                backgroundColor: GlassTheme.colors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: Text(plan.isFree ? 'Continue Free' : 'Subscribe'),
            ),
          ),
        ],
      ),
    );
  }
}
