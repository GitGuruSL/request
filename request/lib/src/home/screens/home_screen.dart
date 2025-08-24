import 'package:flutter/material.dart';
import '../../services/rest_auth_service.dart';
import '../../screens/unified_request_response/unified_request_create_screen.dart';
import '../../models/enhanced_user_model.dart' show RequestType;
import '../../screens/requests/ride/create_ride_request_screen.dart';
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
      color: Color(0xFF6366F1), // Indigo
      icon: Icons.search,
    ),
    _BannerItem(
      title: 'Compare prices',
      subtitle: 'See best offers from verified sellers',
      color: Color(0xFFF59E0B), // Amber
      icon: Icons.trending_up,
    ),
    _BannerItem(
      title: 'Quick delivery',
      subtitle: 'Send or receive anything fast',
      color: Color(0xFF10B981), // Emerald
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
  // Quick create bottom sheet removed from Home.

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
          MaterialPageRoute(builder: (_) => const PriceComparisonScreen()),
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
      backgroundColor:
          const Color(0xFFE2E8F0), // Light gray background for glass effect
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.3),
                Colors.white.withOpacity(0.1),
              ],
            ),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Good Day!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            Text(
              user?.displayName ?? user?.email ?? 'User',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            children: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.3),
                      Colors.white.withOpacity(0.15),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  tooltip: 'Notifications',
                  icon: const Icon(Icons.notifications_none,
                      color: Color(0xFF1E293B), size: 24),
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
              ),
              if (_unreadNotifications > 0)
                Positioned(
                  right: 14,
                  top: 14,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
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
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.3),
                    Colors.white.withOpacity(0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
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
                  backgroundColor: const Color(0xFF6366F1),
                  child: Text(
                    (user?.displayName?.isNotEmpty == true
                            ? user!.displayName![0]
                            : user?.email.isNotEmpty == true
                                ? user!.email[0]
                                : 'U')
                        .toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF8FAFC), // Very light gray top
              Color(0xFFE2E8F0), // Light gray
              Color(0xFFCBD5E1), // Medium gray
              Color(0xFFF1F5F9), // Light gray bottom
            ],
          ),
        ),
        child: SafeArea(
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
                        color: const Color(0xFF1E293B),
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
                            ? const Color(0xFF1E293B)
                            : const Color(0xFF94A3B8),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Quick actions section header
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.flash_on_rounded,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text('Quick Actions',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0F172A),
                                  )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _QuickActionsGrid(
                  items: _requestTypes,
                  moduleEnabled: _moduleEnabled,
                  onTap: _handleTap,
                ),

                const SizedBox(height: 24),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.15),
                        Colors.white.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.trending_up_rounded,
                          color: Color(0xFFF59E0B),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text('Popular Products',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                )),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF6366F1).withOpacity(0.15),
                              const Color(0xFF6366F1).withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const PriceComparisonScreen(),
                              ),
                            );
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'See All',
                            style: TextStyle(
                              color: Color(0xFF6366F1),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemCount: _popularProducts.length,
                        ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.3),
              Colors.white.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Colors.white.withOpacity(0.8),
              blurRadius: 15,
              offset: const Offset(-5, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Subtle pattern overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        item.color.withOpacity(0.05),
                        item.color.withOpacity(0.02),
                      ],
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.subtitle,
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: item.color.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        item.icon,
                        size: 32,
                        color: item.color,
                      ),
                    ),
                  )
                ],
              ),
            ],
          ),
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
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: disabled
                    ? [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ]
                    : [
                        Colors.white.withOpacity(0.25),
                        Colors.white.withOpacity(0.15),
                      ],
              ),
              border: Border.all(
                color: disabled
                    ? Colors.white.withOpacity(0.2)
                    : Colors.white.withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.white.withOpacity(0.7),
                  blurRadius: 8,
                  offset: const Offset(-2, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: disabled
                        ? Colors.grey.withOpacity(0.1)
                        : it.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: disabled
                          ? Colors.grey.withOpacity(0.2)
                          : it.color.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    it.icon,
                    color: disabled ? const Color(0xFF9CA3AF) : it.color,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  it.title.split(' ').first,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: disabled
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF0F172A),
                    fontSize: 13,
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
      width: 170,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.25),
                Colors.white.withOpacity(0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.7),
                blurRadius: 8,
                offset: const Offset(-2, -2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.4),
                        Colors.white.withOpacity(0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.inventory_2,
                        size: 38, color: Color(0xFF6366F1)),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                product.brandName ?? product.brand,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  _formatPriceRange(context, product),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6366F1),
                    fontSize: 12,
                  ),
                ),
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

// Removed _RequestTypeTile (legacy bottom sheet entry).

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
