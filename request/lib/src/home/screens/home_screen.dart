import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../theme/glass_theme.dart';
import '../../theme/app_theme.dart';
import '../../services/banner_service.dart';
import '../../models/banner_item.dart' as model;

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
      PageController(viewportFraction: 1.0);
  int _currentBanner = 0;
  final List<_BannerItem> _defaultBanners = const [
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
  // Remote banners + loading state
  List<model.BannerItem> _remoteBanners = const [];
  bool _loadingBanners = false;

  // Pricing + popular products
  final PricingService _pricing = PricingService();
  List<MasterProduct> _popularProducts = const [];
  bool _loadingPopular = false;

  @override
  void initState() {
    super.initState();
    _loadModules();
    _loadUnreadCounts();
    _loadPopularProducts();
    _loadBanners();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  Future<void> _loadBanners() async {
    if (_loadingBanners) return;
    setState(() => _loadingBanners = true);
    try {
      final cs = CountryService.instance;
      if (cs.countryCode == null) {
        await cs.loadPersistedCountry();
      }
      final items = await BannerService.instance.getCountryBanners(limit: 6);
      if (!mounted) return;
      setState(() => _remoteBanners = items);
    } catch (_) {
      if (!mounted) return;
      setState(() => _remoteBanners = const []);
    } finally {
      if (mounted) setState(() => _loadingBanners = false);
    }
  }

  Future<void> _loadModules() async {
    if (_loadingModules) return;
    setState(() => _loadingModules = true);
    try {
      final cs = CountryService.instance;
      if (cs.countryCode == null) {
        await cs.loadPersistedCountry();
      }
      final code = CountryService.instance.countryCode ?? 'US';
      final mods = await ModuleService.getCountryModules(code);
      if (!mounted) return;
      setState(() => _modules = mods);
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loadingModules = false);
    }
  }

  Future<void> _loadPopularProducts() async {
    if (_loadingPopular) return;
    setState(() => _loadingPopular = true);
    try {
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
          color: const Color(0xFF3B82F6),
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
      final first = user.firstName!.trim();
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
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark, // Android
          statusBarBrightness: Brightness.light, // iOS
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const SizedBox.shrink(),
        actions: [
          Stack(
            children: [
              IconButton(
                tooltip: 'Notifications',
                icon: Icon(
                  Icons.notifications_none,
                  color: AppTheme.textPrimary,
                  size: 24,
                ),
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
                  right: 8,
                  top: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
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
            padding: const EdgeInsets.only(right: 16),
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
                backgroundColor: GlassTheme.colors.primaryBlue,
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
        ],
      ),
      body: GlassTheme.backgroundContainer(
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await _loadModules();
              await _loadPopularProducts();
              await _loadBanners(); // also refresh banners
            },
            child: Column(
              children: [
                // Header with greeting
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Hello, ${_greetingName()}!',
                      style: GlassTheme.titleLarge,
                    ),
                  ),
                ),

                // Banners carousel - full width with custom padding to match grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    height: 150,
                    child: _loadingBanners
                        ? const Center(child: CircularProgressIndicator())
                        : PageView.builder(
                            controller: _bannerController,
                            padEnds: false,
                            itemCount: _remoteBanners.isNotEmpty
                                ? _remoteBanners.length
                                : _defaultBanners.length,
                            onPageChanged: (i) =>
                                setState(() => _currentBanner = i),
                            itemBuilder: (ctx, i) {
                              if (_remoteBanners.isNotEmpty) {
                                return _NetworkBannerCard(
                                  item: _remoteBanners[i],
                                );
                              }
                              return _BannerCard(
                                item: _defaultBanners[i],
                              );
                            },
                          ),
                  ),
                ),

                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _remoteBanners.isNotEmpty
                        ? _remoteBanners.length
                        : _defaultBanners.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: _currentBanner == i ? 18 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: _currentBanner == i
                            ? AppTheme.textPrimary
                            : AppTheme.textTertiary,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),

                // Rest of content in scrollable area
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const SizedBox(height: 4),

                      // Quick actions
                      Text('Quick Actions',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  )),
                      const SizedBox(height: 16),
                      _QuickActionsGrid(
                        items: _requestTypes,
                        moduleEnabled: _moduleEnabled,
                        onTap: _handleTap,
                      ),

                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Text('Popular Products',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  )),
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
                            child: Text(
                              'See All',
                              style: TextStyle(
                                color: GlassTheme.colors.primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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
                                        builder: (_) =>
                                            const PriceComparisonScreen(),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NetworkBannerCard extends StatelessWidget {
  final model.BannerItem item;
  const _NetworkBannerCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final link = item.linkUrl;
        if (link == null || link.isEmpty) return;
        if (link.startsWith('/')) {
          try {
            Navigator.of(context).pushNamed(link);
          } catch (_) {}
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF7B7B), Color(0xFFFF5E62)],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Full-bleed uploaded image as background
                Positioned.fill(
                  child: Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, st) => const SizedBox.shrink(),
                  ),
                ),
                // Subtle left-to-right overlay for readability
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withOpacity(0.20),
                          Colors.black.withOpacity(0.00),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Fallback static banner types for defaults
class _BannerItem {
  final String title;
  final String subtitle;
  final Color color;
  final IconData icon;
  const _BannerItem({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });
}

class _BannerCard extends StatelessWidget {
  final _BannerItem item;
  const _BannerCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                item.color.withOpacity(0.95),
                item.color.withOpacity(0.75),
              ],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    item.icon,
                    size: 96,
                    color: Colors.white.withOpacity(0.25),
                  ),
                ),
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
        crossAxisCount: 2,
        childAspectRatio: 2.2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemBuilder: (ctx, i) {
        final it = items[i];
        final disabled = !moduleEnabled(it.type);
        final title = it.title.split(' ').first; // concise title like "Item"
        final textColor =
            disabled ? const Color(0xFF9CA3AF) : AppTheme.textPrimary;
        final subColor =
            disabled ? const Color(0xFFB8BFC7) : AppTheme.textSecondary;

        return InkWell(
          onTap: disabled ? null : () => onTap(it),
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: GlassTheme.glassContainerDisabled(disabled: disabled),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Texts (title + subtitle)
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        it.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: subColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Right illustration/icon (no white box)
                Icon(
                  it.icon,
                  color: disabled ? const Color(0xFFCBD5E1) : it.color,
                  size: 32,
                ),
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
          decoration: GlassTheme.glassContainer,
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
                        Colors.white.withOpacity(0.7),
                        Colors.white.withOpacity(0.5),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.4),
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
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                product.brandName ?? product.brand,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: GlassTheme.colors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: GlassTheme.colors.primaryBlue.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Text(
                  _formatPriceRange(context, product),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: GlassTheme.colors.primaryBlue,
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
