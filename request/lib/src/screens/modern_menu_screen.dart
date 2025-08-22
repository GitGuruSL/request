import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/enhanced_user_service.dart';
import '../services/user_registration_service.dart';
import '../services/rest_notification_service.dart';
import '../services/rest_auth_service.dart';
import 'my_activities_screen.dart';
import 'help_support_screen.dart';
import 'notification_screen.dart';
import 'driver_subscription_screen.dart';
import 'account/user_profile_screen.dart';
import 'about_us_simple_screen.dart';

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
  int _unreadTotal = 0;
  int _unreadMessages = 0;
  bool _isAdmin = false;
  bool _isBusiness = false;

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
      try {
        final restUser = RestAuthService.instance.currentUser;
        final role = restUser?.role ?? 'user';
        _isAdmin = role == 'super_admin' || role == 'country_admin';
        _isBusiness = role == 'business';
      } catch (_) {}

      // Check driver registration to gate Ride Alerts
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
      backgroundColor: Colors.grey[50],
      body: _isLoading ? _buildLoadingState() : _buildMenuContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildMenuContent() {
    return CustomScrollView(
      slivers: [
        // Facebook-style header
        SliverAppBar(
          expandedHeight: 80,
          floating: false,
          pinned: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey, width: 0.2),
                ),
              ),
              child: const SafeArea(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Menu',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => Navigator.pushNamed(context, '/search'),
            ),
          ],
        ),

        // Menu content
        SliverList(
          delegate: SliverChildListDelegate([
            const SizedBox(height: 12),

            // User Profile Card
            _buildUserProfileCard(),
            const SizedBox(height: 12),

            // Facebook-style grid sections
            _buildMenuGrid(),
            const SizedBox(height: 12),

            // Information Pages and Privacy Policy removed per requirement

            // Account actions section (simplified)
            _buildAccountActionsSection(),
            const SizedBox(height: 12),

            // Logout separated
            _buildLogoutSection(),
            const SizedBox(height: 120),
          ]),
        ),
      ],
    );
  }

  // Note: User profile header is rendered via _buildUserProfileCard()

  Widget _buildUserProfileCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundImage:
                      _profileImageUrl != null && _profileImageUrl!.isNotEmpty
                          ? NetworkImage(_profileImageUrl!)
                          : null,
                  backgroundColor: Colors.grey[300],
                  child: _profileImageUrl == null || _profileImageUrl!.isEmpty
                      ? Icon(Icons.person, color: Colors.grey[600], size: 28)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    _currentUser?['name'] ??
                        _currentUser?['displayName'] ??
                        'User',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UserProfileScreen(),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey[600],
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid() {
    final accountItems = [
      if (_isAdmin || _isBusiness)
        _MenuItem(
          title: 'Roles',
          icon: Icons.work_outline,
          color: Colors.purple,
          route: '/role-management',
        ),
      if (_isAdmin || _isBusiness)
        _MenuItem(
          title: 'Products',
          icon: Icons.inventory_2_outlined,
          color: Colors.orange,
          route: '/business-pricing',
        ),
      _MenuItem(
        title: 'Messages',
        icon: Icons.message_outlined,
        color: Colors.green,
        route: '/messages',
        badgeCount: _unreadMessages,
      ),
      _MenuItem(
        title: 'My Activities',
        icon: Icons.history,
        color: Colors.teal,
        route: '/activities',
      ),
      _MenuItem(
        title: 'Notifications',
        icon: Icons.notifications_outlined,
        color: Colors.red,
        route: '/notifications',
        badgeCount: _unreadTotal,
      ),
      if (_isDriver)
        _MenuItem(
          title: 'Ride Alerts',
          icon: Icons.directions_car,
          color: Colors.blue,
          route: '/driver-subscriptions',
        ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3.0,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
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
                      } else {
                        await Navigator.pushNamed(context, item.route!);
                      }
                      // Refresh badges after returning
                      if (mounted) {
                        _loadData();
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          color: item.color,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if ((item.badgeCount ?? 0) > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
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
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Become a verified driver to enable Ride Alerts',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Removed Information Pages section

  Widget _buildAccountActionsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildActionTile(
            icon: Icons.workspace_premium_outlined,
            title: 'Membership',
            subtitle: 'Manage your membership',
            color: Colors.blueGrey,
            onTap: () => Navigator.pushNamed(context, '/membership'),
          ),
          _buildActionTile(
            icon: Icons.help_outline,
            title: 'Help and Support',
            subtitle: 'Get help when you need it',
            color: Colors.grey,
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
            color: Colors.indigo,
            onTap: () =>
                Navigator.pushNamed(context, '/settings/payment-methods'),
          ),
          _buildActionTile(
            icon: Icons.info_outline,
            title: 'About Us',
            subtitle: 'About Request',
            color: Colors.grey,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: _buildActionTile(
        icon: Icons.logout,
        title: 'Log Out',
        subtitle: 'Sign out of your account',
        color: Colors.grey,
        onTap: () async {
          final shouldLogout = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Log Out'),
              content: const Text('Are you sure you want to log out?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Log Out'),
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: color,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
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
