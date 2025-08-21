import 'package:flutter/material.dart';
import '../services/content_service.dart';
import '../services/auth_service.dart';
import '../services/enhanced_user_service.dart';
import 'content_page_screen.dart';
import 'my_activities_screen.dart';
import 'settings_privacy_screen.dart';
import 'help_support_screen.dart';
import 'about_request_screen.dart';
import 'notification_screen.dart';
import 'driver_subscription_screen.dart';
import 'api_test_screen.dart';
import 'account/user_profile_screen.dart';

class ModernMenuScreen extends StatefulWidget {
  const ModernMenuScreen({super.key});

  @override
  State<ModernMenuScreen> createState() => _ModernMenuScreenState();
}

class _ModernMenuScreenState extends State<ModernMenuScreen> {
  final ContentService _contentService = ContentService.instance;
  final AuthService _authService = AuthService.instance;
  final EnhancedUserService _userService = EnhancedUserService();

  List<ContentPage> _pages = [];
  Map<String, dynamic>? _currentUser;
  bool _isLoading = true;
  String? _profileImageUrl;

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

      // Load content pages
      final pages = await _contentService.getPages();

      if (mounted) {
        setState(() {
          _pages = pages;
          _isLoading = false;
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

            // Content pages section
            if (_pages.isNotEmpty) _buildContentPagesSection(),
            const SizedBox(height: 12),

            // Account actions section
            _buildAccountActionsSection(),
            const SizedBox(height: 120),
          ]),
        ),
      ],
    );
  }

  Widget _buildUserProfile() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.blue.withOpacity(0.3),
            child: Icon(Icons.person, color: Colors.blue, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            _currentUser?['name'] ??
                _currentUser?['displayName'] ??
                'Fathima Nusra',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            'View your profile',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

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
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/account'),
                  child: CircleAvatar(
                      radius: 24,
                      backgroundImage: _profileImageUrl != null &&
                              _profileImageUrl!.isNotEmpty
                          ? NetworkImage(_profileImageUrl!)
                          : null,
                      backgroundColor: Colors.grey[300],
                      child:
                          _profileImageUrl == null || _profileImageUrl!.isEmpty
                              ? Icon(Icons.person,
                                  color: Colors.grey[600], size: 28)
                              : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserProfileScreen(),
                        ),
                      ),
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
      _MenuItem(
        title: 'Roles',
        icon: Icons.work_outline,
        color: Colors.purple,
        route: '/role-management',
      ),
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
      ),
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
        child: GridView.builder(
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
              onTap: () {
                if (item.route != null) {
                  if (item.route == '/activities') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MyActivitiesScreen()),
                    );
                  } else if (item.route == '/notifications') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const NotificationScreen()),
                    );
                  } else if (item.route == '/driver-subscriptions') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              const DriverSubscriptionScreen()),
                    );
                  } else {
                    Navigator.pushNamed(context, item.route!);
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
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContentPagesSection() {
    // Group pages by category
    final pagesByCategory = <String, List<ContentPage>>{};
    for (final page in _pages) {
      final key =
          (page.category ?? '').isEmpty ? 'uncategorized' : page.category!;
      pagesByCategory.putIfAbsent(key, () => []).add(page);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.pages,
                    color: Colors.blue,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Information Pages',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ...pagesByCategory.entries.map((entry) {
            return _buildPageCategory(entry.key, entry.value, pagesByCategory);
          }),
        ],
      ),
    );
  }

  Widget _buildPageCategory(String category, List<ContentPage> pages,
      Map<String, List<ContentPage>> pagesByCategory) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (category.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              category.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
        ...pages.map((page) {
          return _buildActionTile(
            icon: Icons.article,
            title: page.title,
            subtitle: page.type == 'country_specific' ? 'Local Content' : null,
            color: Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ContentPageScreen(
                    slug: page.slug,
                    title: page.title,
                  ),
                ),
              );
            },
            showDivider: page != pages.last,
          );
        }),
        if (pages.isNotEmpty && category != pagesByCategory.keys.last)
          const SizedBox(height: 8),
      ],
    );
  }

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
            icon: Icons.developer_mode,
            title: 'API Test Screen',
            subtitle: 'Test REST API connectivity',
            color: Colors.purple,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ApiTestScreen()),
            ),
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
            icon: Icons.settings,
            title: 'Settings & Privacy',
            subtitle: 'Manage app settings and privacy',
            color: Colors.grey,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const SettingsPrivacyScreen()),
            ),
          ),
          _buildActionTile(
            icon: Icons.info_outline,
            title: 'About Request',
            subtitle: 'Learn more about the app',
            color: Colors.grey,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const AboutRequestScreen()),
            ),
          ),
          _buildActionTile(
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
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required Color color,
    required VoidCallback onTap,
    bool showDivider = true,
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

  _MenuItem({
    required this.title,
    required this.icon,
    required this.color,
    this.route,
  });
}
