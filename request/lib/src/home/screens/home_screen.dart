import 'package:flutter/material.dart';
import '../../services/rest_auth_service.dart';
import '../../screens/unified_request_response/unified_request_create_screen.dart';
import '../../models/enhanced_user_model.dart' show RequestType;
import '../../screens/requests/ride/create_ride_request_screen.dart';
import '../../screens/requests/create_price_request_screen.dart';
import '../../services/rest_support_services.dart'
    show CountryService, ModuleService, CountryModules; // Module gating
import '../../services/pricing_service.dart';
import '../../models/master_product.dart';
import '../../screens/pricing/price_comparison_screen.dart';
import '../../widgets/coming_soon_widget.dart';
import '../../services/rest_notification_service.dart';
import '../../screens/notification_screen.dart';
import '../../screens/account/user_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CountryModules? _modules;
  bool _loadingModules = false;
  int _unreadNotifications = 0;

  // UI: banners & popular products
  final PageController _bannerController =
      PageController(viewportFraction: 0.9);
  int _currentBanner = 0;
  final List<_BannerItem> _banners = const [
    _BannerItem(
      title: 'Find what you need',
      subtitle: 'Post a request and let others help',
      color: Color(0xFFEEF5FF),
      icon: Icons.search,
    ),
    _BannerItem(
      title: 'Compare prices',
      subtitle: 'See best offers from verified sellers',
      color: Color(0xFFFFF3E7),
      icon: Icons.trending_up,
    ),
    _BannerItem(
      title: 'Quick delivery',
      subtitle: 'Send or receive anything fast',
      color: Color(0xFFEFFAF0),
      icon: Icons.local_shipping,
    ),
  ];

  final PricingService _pricing = PricingService();
  List<MasterProduct> _popularProducts = const [];
  bool _loadingPopular = false;

  @override
  void initState() {
    super.initState();
    _loadModules();
    _loadUnreadCounts();
    _loadPopularProducts();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _loadModules() async {
    if (_loadingModules) return;
    setState(() => _loadingModules = true);
    try {
      // Ensure country code is available
      final cs = CountryService.instance;
      if (cs.countryCode == null) {
        await cs.loadPersistedCountry();
      }
      final code = cs.getCurrentCountryCode();
      final mods = await ModuleService.getCountryModules(code);
      if (mounted) setState(() => _modules = mods);
    } catch (_) {
      // Silent; fallback logic in _moduleEnabled
    } finally {
      if (mounted) setState(() => _loadingModules = false);
    }
  }

  Future<void> _loadPopularProducts() async {
    setState(() => _loadingPopular = true);
    try {
      // Use empty query to get popular/top products from backend
      final products = await _pricing.searchProducts(query: '', limit: 16);
      if (!mounted) return;
      setState(() => _popularProducts = products);
    } catch (_) {
      if (!mounted) return;
    } finally {
      if (mounted) setState(() => _loadingPopular = false);
    }
  }

  Future<void> _loadUnreadCounts() async {
    try {
      final counts = await RestNotificationService.instance.unreadCounts();
      if (!mounted) return;
      setState(() => _unreadNotifications = counts.total);
    } catch (_) {
      if (!mounted) return;
      setState(() => _unreadNotifications = 0);
    }
  }

  List<_RequestType> get _requestTypes => [
        _RequestType(
          type: 'item',
          title: 'Item Request',
          subtitle: 'Request for products or items',
          icon: Icons.shopping_bag,
          color: const Color(0xFFFF6B35),
        ),
        _RequestType(
          type: 'service',
          title: 'Service Request',
          subtitle: 'Request for services',
          icon: Icons.build,
          color: const Color(0xFF00BCD4),
        ),
        _RequestType(
          type: 'rental',
          title: 'Rental Request',
          subtitle: 'Rent vehicles, equipment, or items',
          icon: Icons.vpn_key,
          color: const Color(0xFF2196F3),
        ),
        _RequestType(
          type: 'delivery',
          title: 'Delivery Request',
          subtitle: 'Request for delivery services',
          icon: Icons.local_shipping,
          color: const Color(0xFF4CAF50),
        ),
        _RequestType(
          type: 'ride',
          title: 'Ride Request',
          subtitle: 'Request for transportation',
          icon: Icons.directions_car,
          color: const Color(0xFFFFC107),
        ),
        _RequestType(
          type: 'price',
          title: 'Price Request',
          subtitle: 'Request price quotes for items or services',
          icon: Icons.trending_up,
          color: const Color(0xFF9C27B0),
        ),
      ];

  String _greetingName() {
    final user = RestAuthService.instance.currentUser;
    if (user == null) return '';
    if (user.firstName != null && user.firstName!.trim().isNotEmpty) {
      return _capitalize(user.firstName!.trim());
    }
    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      final first = user.displayName!.trim().split(RegExp(r'\s+')).first;
      if (first.isNotEmpty) return _capitalize(first);
    }
    final emailLocal = user.email.split('@').first;
    if (emailLocal.isEmpty) return '';
    final token = emailLocal.split(RegExp(r'[._-]+')).firstWhere(
          (p) => p.isNotEmpty,
          orElse: () => emailLocal,
        );
    return _capitalize(token);
  }

  String _capitalize(String s) => s.isEmpty
      ? s
      : s.length == 1
          ? s.toUpperCase()
          : s[0].toUpperCase() + s.substring(1);

  void _openCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final items = _requestTypes;
        final loading = _loadingModules && _modules == null;
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Create New Request',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                    ),
                    const SizedBox(height: 24),
                    if (loading)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          children: items
                              .map(
                                (it) => _RequestTypeTile(
                                  icon: it.icon,
                                  iconColor: it.color,
                                  title: it.title,
                                  subtitle: it.subtitle,
                                  disabled: !_moduleEnabled(it.type),
                                  onTap: () => _handleTap(it),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  bool _moduleEnabled(String type) {
    final key = switch (type) {
      'rental' => 'rent',
      _ => type,
    };
    final mods = _modules;
    if (mods == null) return true;
    return mods.isModuleEnabled(key);
  }

  void _handleTap(_RequestType it) {
    if (!_moduleEnabled(it.type)) {
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ComingSoonWidget(
            title: it.title,
            description:
                'This feature is not available in your country yet. We\'re working to bring ${it.title.toLowerCase()} to your region soon!',
            icon: it.icon,
          ),
        ),
      );
      return;
    }
    _selectRequestType(it.type);
  }

  void _selectRequestType(String type) {
    Navigator.of(context).pop();
    switch (type) {
      case 'item':
        _openUnified(RequestType.item);
        break;
      case 'service':
        _openUnified(RequestType.service);
        break;
      case 'rental':
        _openUnified(RequestType.rental);
        break;
      case 'delivery':
        _openUnified(RequestType.delivery);
        break;
      case 'ride':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateRideRequestScreen()),
        );
        break;
      case 'price':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreatePriceRequestScreen()),
        );
        break;
    }
  }

  void _openUnified(RequestType type) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UnifiedRequestCreateScreen(initialType: type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = RestAuthService.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const SizedBox.shrink(),
        actions: [
          Stack(
            children: [
              IconButton(
                tooltip: 'Notifications',
                icon: const Icon(Icons.notifications_none),
                onPressed: () async {
                  try {
                    await Navigator.pushNamed(context, '/notifications');
                  } catch (_) {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationScreen(),
                      ),
                    );
                  }
                  await _loadUnreadCounts();
                },
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 10,
                  top: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$_unreadNotifications',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              splashRadius: 22,
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const UserProfileScreen(),
                  ),
                );
                await _loadUnreadCounts();
              },
              icon: CircleAvatar(
                radius: 16,
                child: Text(
                  (user?.displayName?.isNotEmpty == true
                          ? user!.displayName![0]
                          : user?.email.isNotEmpty == true
                              ? user!.email[0]
                              : 'U')
                      .toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadModules();
            await _loadPopularProducts();
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Hello, ${_greetingName()}!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              // Banners carousel
              SizedBox(
                height: 140,
                child: PageView.builder(
                  controller: _bannerController,
                  itemCount: _banners.length,
                  onPageChanged: (i) => setState(() => _currentBanner = i),
                  itemBuilder: (ctx, i) => _BannerCard(item: _banners[i]),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _banners.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    width: _currentBanner == i ? 18 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: _currentBanner == i
                          ? Colors.black87
                          : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Quick actions
              Text('Quick actions',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              _QuickActionsGrid(
                items: _requestTypes,
                moduleEnabled: _moduleEnabled,
                onTap: _handleTap,
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  Text('Popular products',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PriceComparisonScreen(),
                        ),
                      );
                    },
                    child: const Text('See all'),
                  ),
                ],
              ),
              SizedBox(
                height: 210,
                child: _loadingPopular
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (ctx, i) => _ProductCard(
                          product: _popularProducts[i],
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PriceComparisonScreen(),
                              ),
                            );
                          },
                        ),
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemCount: _popularProducts.length,
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateSheet,
        tooltip: 'New Request',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _BannerItem {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  const _BannerItem(
      {required this.title,
      required this.subtitle,
      required this.color,
      required this.icon});
}

class _BannerCard extends StatelessWidget {
  final _BannerItem item;
  const _BannerCard({required this.item});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Container(
        decoration: BoxDecoration(
          color: item.color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(item.subtitle,
                      style: TextStyle(color: Colors.grey.shade700)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(item.icon, size: 36, color: Colors.black54),
            )
          ],
        ),
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  final List<_RequestType> items;
  final bool Function(String) moduleEnabled;
  final void Function(_RequestType) onTap;
  const _QuickActionsGrid({
    required this.items,
    required this.moduleEnabled,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.05,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (ctx, i) {
        final it = items[i];
        final disabled = !moduleEnabled(it.type);
        return InkWell(
          onTap: disabled ? null : () => onTap(it),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color:
                  disabled ? Colors.grey.shade100 : it.color.withOpacity(0.08),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(it.icon, color: disabled ? Colors.grey : it.color),
                const SizedBox(height: 8),
                Text(
                  it.title.split(' ').first,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: disabled ? Colors.grey : Colors.black87,
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProductCard extends StatelessWidget {
  final MasterProduct product;
  final VoidCallback onTap;
  const _ProductCard({required this.product, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(Icons.inventory_2,
                        size: 36, color: Colors.black38),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                product.brandName ?? product.brand,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Text(
                _formatPriceRange(context, product),
                style: const TextStyle(fontWeight: FontWeight.w600),
              )
            ],
          ),
        ),
      ),
    );
  }

  String _formatPriceRange(BuildContext context, MasterProduct p) {
    final cs = CountryService.instance;
    final min = p.minPrice ?? p.avgPrice ?? 0;
    final max = p.maxPrice ?? p.avgPrice ?? 0;
    if (min == 0 && max == 0) return '—';
    if (min == max) return cs.formatPrice(min);
    return '${cs.formatPrice(min)} - ${cs.formatPrice(max)}';
  }
}

class _RequestTypeTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool disabled;
  final VoidCallback onTap;
  const _RequestTypeTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: disabled ? Colors.grey.withOpacity(0.05) : null,
              ),
              child: Icon(
                icon,
                color: disabled ? Colors.grey : iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: disabled ? Colors.grey[400] : Colors.grey[600],
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            if (disabled)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.4)),
                ),
                child: const Text(
                  'Coming Soon',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RequestType {
  final String type;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _RequestType({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
