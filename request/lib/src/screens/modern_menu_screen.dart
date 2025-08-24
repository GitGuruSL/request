import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/enhanced_user_service.dart';
import '../services/user_registration_service.dart';
import '../services/rest_notification_service.dart';
// Removed direct RestAuthService usage in this screen
import 'my_activities_screen.dart';
import 'help_support_screen.dart';
import 'notification_screen.dart';
import 'driver_subscription_screen.dart';
import 'account/user_profile_screen.dart';
import 'about_us_simple_screen.dart';
import 'pricing/business_product_dashboard.dart';

class ModernMenuScreen extends StatefulWidget {
  const ModernMenuScreen({super.key});

  @override
  State<ModernMenuScreen> createState() => _ModernMenuScreenState();
}

class _ModernMenuScreenState extends State<ModernMenuScreen> {
  final AuthService _authService = AuthService.instance;
  final EnhancedUserService _userService = EnhancedUserService();

  // Removed content pages and privacy policy section
  Map<String, dynamic>? _currentUser;
  bool _isLoading = true;
  String? _profileImageUrl;
  bool _isDriver = false;
  // Product seller flag no longer used for menu routing; dashboard self-gates
  int _unreadTotal = 0;
  int _unreadMessages = 0;
  // Removed admin/business gating; keep Ride Alerts gated by driver status only.

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      // Load user data
      final user = _authService.currentUser;
      if (user != null) {
        final userData = await _userService.getUserById(user.uid);
        setState(() {
          _currentUser = userData?.toMap();
          _profileImageUrl = null; // No profile image in current model
        });
      }

      // Determine role flags from REST auth user
      // Roles/Products are now always visible; no role gating needed here.

      // Check driver registration to gate Ride Alerts and product seller status
      bool isDriver = false;
      try {
        final regs =
            await UserRegistrationService.instance.getUserRegistrations();
        isDriver = regs?.isApprovedDriver == true;
      } catch (_) {}

      // Fetch unread counts
      int unreadTotal = 0;
      int unreadMessages = 0;
      try {
        final counts = await RestNotificationService.instance.unreadCounts();
        unreadTotal = counts.total;
        unreadMessages = counts.messages;
      } catch (_) {}

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isDriver = isDriver;
          _unreadTotal = unreadTotal;
          _unreadMessages = unreadMessages;
        });
      }
    } catch (e) {
      print('Error loading menu data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A), // Dark charcoal background
      body: _isLoading ? _buildLoadingState() : _buildMenuContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }

  Widget _buildMenuContent() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2C2C2C), // Charcoal top
            Color(0xFF1A1A1A), // Darker bottom
          ],
        ),
      ),
      child: CustomScrollView(
        slivers: [
          // Modern header with centered profile
          SliverToBoxAdapter(
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // Centered Profile Section
                  _buildCenteredProfileSection(),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),

          // Menu content
          SliverList(
            delegate: SliverChildListDelegate([
              // Modern grid sections
              _buildMenuGrid(),
              const SizedBox(height: 20),

              // Account actions section
              _buildAccountActionsSection(),
              const SizedBox(height: 20),

              // Logout separated
              _buildLogoutSection(),
              const SizedBox(height: 120),
            ]),
          ),
        ],
      ),
    );
  }

  // Note: User profile header is rendered via _buildCenteredProfileSection()

  Widget _buildCenteredProfileSection() {
    return Column(
      children: [
        // Logo/App Title
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Menu',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search, color: Colors.white, size: 28),
                onPressed: () => Navigator.pushNamed(context, '/search'),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Centered Profile Picture
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const UserProfileScreen(),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundImage:
                  _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                      ? NetworkImage(_profileImageUrl!)
                      : null,
              backgroundColor: const Color(0xFF404040),
              child: _profileImageUrl == null || _profileImageUrl!.isEmpty
                  ? const Icon(
                      Icons.person,
                      color: Colors.white70,
                      size: 50,
                    )
                  : null,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Centered Name
        Text(
          _currentUser?['name'] ?? _currentUser?['displayName'] ?? 'User',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        // Membership status or subtitle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_user,
                color: Colors.white.withOpacity(0.8),
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'Member',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuGrid() {
    final accountItems = [
      _MenuItem(
        title: 'Roles',
        icon: Icons.work_outline,
        color: const Color(0xFF6366F1), // Indigo
        route: '/role-management',
      ),
      _MenuItem(
        title: 'Products',
        icon: Icons.inventory_2_outlined,
        color: const Color(0xFFF59E0B), // Amber
        route: 'products', // handled specially
      ),
      _MenuItem(
        title: 'Messages',
        icon: Icons.message_outlined,
        color: const Color(0xFF10B981), // Emerald
        route: '/messages',
        badgeCount: _unreadMessages,
      ),
      _MenuItem(
        title: 'My Activities',
        icon: Icons.history,
        color: const Color(0xFF06B6D4), // Cyan
        route: '/activities',
      ),
      _MenuItem(
        title: 'Notifications',
        icon: Icons.notifications_outlined,
        color: const Color(0xFFEF4444), // Red
        route: '/notifications',
        badgeCount: _unreadTotal,
      ),
      if (_isDriver)
        _MenuItem(
          title: 'Ride Alerts',
          icon: Icons.directions_car,
          color: const Color(0xFF3B82F6), // Blue
          route: '/driver-subscriptions',
        ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3.0,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: accountItems.length,
            itemBuilder: (context, index) {
              final item = accountItems[index];
              return InkWell(
                onTap: () async {
                  if (item.route != null) {
                    if (item.route == '/activities') {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const MyActivitiesScreen()),
                      );
                    } else if (item.route == '/notifications') {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const NotificationScreen()),
                      );
                    } else if (item.route == '/driver-subscriptions') {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const DriverSubscriptionScreen()),
                      );
                    } else if (item.route == 'products') {
                      // Always route to the business product dashboard; it self-gates for non-approved users
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                const BusinessProductDashboard()),
                      );
                    } else {
                      await Navigator.pushNamed(context, item.route!);
                    }
                    // Refresh badges after returning
                    if (mounted) {
                      _loadData();
                    }
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: item.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          item.icon,
                          color: item.color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if ((item.badgeCount ?? 0) > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${item.badgeCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          if (!_isDriver)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Become a verified driver to enable Ride Alerts',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  // Removed Information Pages section

  Widget _buildAccountActionsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildActionTile(
            icon: Icons.workspace_premium_outlined,
            title: 'Membership',
            subtitle: 'Manage your membership',
            color: const Color(0xFF8B5CF6), // Purple
            onTap: () => Navigator.pushNamed(context, '/membership'),
          ),
          _buildActionTile(
            icon: Icons.help_outline,
            title: 'Help and Support',
            subtitle: 'Get help when you need it',
            color: const Color(0xFF06B6D4), // Cyan
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const HelpSupportScreen()),
            ),
          ),
          _buildActionTile(
            icon: Icons.payment_outlined,
            title: 'Payment',
            subtitle: 'Accepted payment methods',
            color: const Color(0xFF10B981), // Emerald
            onTap: () =>
                Navigator.pushNamed(context, '/settings/payment-methods'),
          ),
          _buildActionTile(
            icon: Icons.info_outline,
            title: 'About Us',
            subtitle: 'About Request',
            color: const Color(0xFF6B7280), // Gray
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AboutUsSimpleScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: _buildActionTile(
        icon: Icons.logout,
        title: 'Log Out',
        subtitle: 'Sign out of your account',
        color: const Color(0xFFEF4444), // Red
        onTap: () async {
          final shouldLogout = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF2C2C2C),
              title: const Text(
                'Log Out',
                style: TextStyle(color: Colors.white),
              ),
              content: const Text(
                'Are you sure you want to log out?',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'Log Out',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );

          if (shouldLogout == true) {
            await _authService.signOut();
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/login');
            }
          }
        },
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.white.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final Color color;
  final String? route;
  final int? badgeCount;
  _MenuItem({
    required this.title,
    required this.icon,
    required this.color,
    this.route,
    this.badgeCount,
  });
}
