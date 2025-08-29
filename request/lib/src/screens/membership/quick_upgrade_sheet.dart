import 'package:flutter/material.dart';
import '../../services/subscription_service.dart';
import '../../services/country_service.dart';
import '../../theme/glass_theme.dart';

class QuickUpgradeSheet extends StatefulWidget {
  final String contextType; // 'driver' | 'business' | 'product_seller'
  const QuickUpgradeSheet({super.key, required this.contextType});

  static Future<void> show(BuildContext context, String contextType) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: GlassTheme.colors.glassBackground.first,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: QuickUpgradeSheet(contextType: contextType),
      ),
    );
  }

  @override
  State<QuickUpgradeSheet> createState() => _QuickUpgradeSheetState();
}

class _QuickUpgradeSheetState extends State<QuickUpgradeSheet> {
  final _api = SubscriptionServiceApi.instance;
  bool _loading = true;
  bool _checkingOut = false;
  SubscriptionPlan? _recommended;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      if (widget.contextType == 'product_seller') {
        final products = await _api.fetchProductSellerPlans(activeOnly: true);
        _recommended = _pickRecommendedProductPlan(products);
      } else {
        final plans = await _api.fetchUserResponsePlans(activeOnly: true);
        final filtered = _filterByContext(plans, widget.contextType);
        _recommended = _pickRecommendedResponsePlan(filtered);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<SubscriptionPlan> _filterByContext(
      List<SubscriptionPlan> plans, String ctx) {
    final p = plans;
    if (ctx == 'driver') {
      return p
          .where((x) =>
              x.planType == 'free' || x.planType.toLowerCase().contains('ride'))
          .toList();
    }
    if (ctx == 'business') {
      return p.where((x) {
        final t = x.planType.toLowerCase();
        return x.planType == 'free' ||
            t.contains('all') ||
            t.contains('other') ||
            t.contains('general');
      }).toList();
    }
    return p;
  }

  SubscriptionPlan? _pickRecommendedResponsePlan(List<SubscriptionPlan> plans) {
    // Prefer a paid unlimited plan for the context; fallback to first paid
    final paid = plans.where((p) => !p.isFree).toList();
    if (paid.isEmpty) return null;
    // Prefer ride/all unlimited (no responseLimit)
    final unlimited = paid.where((p) => p.responseLimit == null).toList();
    if (unlimited.isNotEmpty) return unlimited.first;
    return paid.first;
  }

  SubscriptionPlan? _pickRecommendedProductPlan(List<SubscriptionPlan> plans) {
    // Prefer monthly plan; fallback to first paid
    final paid = plans.where((p) => !p.isFree).toList();
    if (paid.isEmpty) return null;
    final monthly =
        paid.firstWhere((p) => p.planType == 'monthly', orElse: () => paid[0]);
    return monthly;
  }

  Future<void> _subscribe() async {
    if (_recommended == null) return;
    setState(() => _checkingOut = true);
    try {
      final country = CountryService.instance.getCurrentCountryCode();
      final created = await _api.createSubscription(
          planId: _recommended!.id, countryCode: country);
      if (created == null) {
        _toast('Failed to start subscription');
        return;
      }
      final status = (created['status'] ?? created['state'] ?? '').toString();
      final subId =
          (created['id'] ?? created['subscription_id'] ?? '').toString();

      if (status == 'active' ||
          status == 'trialing' ||
          created['active'] == true) {
        _toast('Subscription activated');
        if (mounted) Navigator.pop(context);
        return;
      }

      // Need checkout: show gateway selection
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
      _toast('No payment methods available');
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
                Text('Select a payment method',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: GlassTheme.colors.textPrimary)),
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
          subscriptionId: subscriptionId, provider: provider);
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: _loading
          ? const SizedBox(
              height: 180, child: Center(child: CircularProgressIndicator()))
          : _recommended == null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('No plans available',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: GlassTheme.colors.textPrimary)),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/membership', arguments: {
                          'requiredSubscriptionType': widget.contextType,
                        });
                      },
                      child: const Text('See all plans'),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.verified_user,
                            color: GlassTheme.colors.primaryBlue),
                        const SizedBox(width: 8),
                        Text(
                          widget.contextType == 'driver'
                              ? 'Driver Plan'
                              : widget.contextType == 'business'
                                  ? 'Business Plan'
                                  : 'Product Seller Plan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: GlassTheme.colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _recommended!.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: GlassTheme.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _recommended!.displayPrice,
                      style: TextStyle(color: GlassTheme.colors.textSecondary),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Unlimited responses, contact visibility and instant notifications.',
                      style: TextStyle(color: GlassTheme.colors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _checkingOut ? null : _subscribe,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GlassTheme.colors.primaryBlue,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(_recommended!.isFree
                                ? 'Continue Free'
                                : 'Subscribe'),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/membership', arguments: {
                          'requiredSubscriptionType': widget.contextType,
                        });
                      },
                      child: const Text('See all plans'),
                    ),
                  ],
                ),
    );
  }
}
