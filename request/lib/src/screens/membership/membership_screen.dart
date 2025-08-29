import 'package:flutter/material.dart';
import '../../services/subscription_service.dart';
import '../../services/country_service.dart';
import '../../theme/glass_theme.dart';
import '../../theme/app_theme.dart';

class MembershipScreen extends StatefulWidget {
  final bool promptOnboarding;
  const MembershipScreen({super.key, this.promptOnboarding = false});

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  final _api = SubscriptionServiceApi.instance;
  final _promoController = TextEditingController();
  bool _loading = true;
  List<SubscriptionPlan> _plans = [];
  Map<String, dynamic>? _current;
  String _type = 'rider';
  bool _checkingOut = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final plans = await _api.fetchPlans(type: _type, activeOnly: true);
      final cur = await _api.getMySubscription();
      if (mounted) {
        setState(() {
          _plans = plans;
          _current = cur;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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

      final status = (created['status'] ?? created['state'] ?? '').toString();
      final subId =
          (created['id'] ?? created['subscription_id'] ?? '').toString();

      if (status == 'active' ||
          status == 'trialing' ||
          (created['active'] == true)) {
        _toast('Subscription activated');
        await _load();
        if (widget.promptOnboarding && mounted) {
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
                    Container(
                      decoration: GlassTheme.glassContainer,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Choose your plan',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: GlassTheme.colors.textPrimary)),
                          const SizedBox(height: 8),
                          Text(
                              'Free plan gives limited responses. Paid plans unlock unlimited responses, contact visibility, and instant notifications.',
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
                    ..._plans
                        .map((p) => _buildPlanCard(p, currencyFmt))
                        .toList(),
                  ],
                ),
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
    final isFree = (plan.price == null || plan.price == 0);
    final priceStr = isFree
        ? 'Free'
        : '${CountryService.instance.formatPrice(plan.price ?? 0)} / ${plan.durationDays ?? 30}d';
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
              Text(priceStr,
                  style: TextStyle(color: GlassTheme.colors.textSecondary)),
            ],
          ),
          const SizedBox(height: 8),
          if ((plan.description ?? '').isNotEmpty)
            Text(plan.description!,
                style: TextStyle(color: GlassTheme.colors.textSecondary)),
          const SizedBox(height: 8),
          if (plan.planType == 'monthly' && plan.type == 'rider')
            _benefitsList(isFree: isFree),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _checkingOut ? null : () => _choosePlan(plan),
              style: ElevatedButton.styleFrom(
                backgroundColor: GlassTheme.colors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: Text(isFree ? 'Continue Free' : 'Subscribe'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _benefitsList({required bool isFree}) {
    final items = isFree
        ? [
            '3 responses per month',
            'Contact details hidden',
            'No instant notifications',
          ]
        : [
            'Unlimited responses',
            'Contact details visible',
            'Instant request notifications',
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items
          .map((t) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(isFree ? Icons.info_outline : Icons.check_circle,
                        size: 18,
                        color: isFree
                            ? GlassTheme.colors.textSecondary
                            : Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(t,
                          style: TextStyle(
                            color: GlassTheme.colors.textSecondary,
                          )),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}
