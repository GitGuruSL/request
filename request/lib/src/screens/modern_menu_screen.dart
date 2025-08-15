import 'package:flutter/material.dart';
import '../services/enhanced_auth_service.dart';
import '../services/enhanced_user_service.dart';
import '../services/content_service.dart';
import '../models/enhanced_user_model.dart';
import '../services/country_service.dart';
import 'content_page_screen.dart';

class ModernMenuScreen extends StatefulWidget {
  const ModernMenuScreen({super.key});

  @override
  State<ModernMenuScreen> createState() => _ModernMenuScreenState();
}

class _ModernMenuScreenState extends State<ModernMenuScreen> {
  final EnhancedUserService _userService = EnhancedUserService();
  final EnhancedAuthService _authService = EnhancedAuthService.instance;
  final ContentService _contentService = ContentService.instance;
  
  UserModel? _currentUser;
  List<ContentPage> _pages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      final userFuture = _userService.getCurrentUserModel();
      final pagesFuture = _contentService.getPages();
      
      final results = await Future.wait([userFuture, pagesFuture]);
      
      if (mounted) {
        setState(() {
          _currentUser = results[0] as UserModel?;
          _pages = results[1] as List<ContentPage>;
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
      appBar: AppBar(
        title: const Text('Menu'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              Navigator.pushNamed(context, '/content-test');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
              Navigator.pushNamed(context, '/settings');
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Navigate to search
              Navigator.pushNamed(context, '/search');
            },
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingState() : _buildMenuContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildMenuContent() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // User Profile Section
            _buildUserProfile(),
            
            // Create Profile/Page Section
            if (_currentUser != null) _buildCreateSection(),
            
            // Main Menu Grid
            _buildMainMenuGrid(),
            
            // Content Pages Section
            if (_pages.isNotEmpty) _buildContentPagesSection(),
            
            // Additional Options
            _buildAdditionalOptions(),
            
            // Footer
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfile() {
    if (_currentUser == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.grey[300],
              child: Icon(
                Icons.person,
                size: 35,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sign in to your account',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Access all features and manage your requests',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              _currentUser!.name.isNotEmpty 
                  ? _currentUser!.name[0].toUpperCase()
                  : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentUser!.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentUser!.email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildCreateSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add,
              color: Colors.black87,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create new request',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Get quotes and offers from service providers',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainMenuGrid() {
    final menuItems = [
      MenuGridItem(
        title: 'Saved',
        icon: Icons.bookmark,
        color: Colors.purple,
        onTap: () => Navigator.pushNamed(context, '/saved'),
      ),
      MenuGridItem(
        title: 'Marketplace',
        icon: Icons.store,
        color: Colors.blue,
        onTap: () => Navigator.pushNamed(context, '/marketplace'),
      ),
      MenuGridItem(
        title: 'Memories',
        icon: Icons.access_time,
        color: Colors.blue,
        onTap: () => Navigator.pushNamed(context, '/memories'),
      ),
      MenuGridItem(
        title: 'Groups',
        icon: Icons.group,
        color: Colors.blue,
        onTap: () => Navigator.pushNamed(context, '/groups'),
      ),
      MenuGridItem(
        title: 'Reels',
        icon: Icons.play_circle,
        color: Colors.red,
        onTap: () => Navigator.pushNamed(context, '/reels'),
      ),
      MenuGridItem(
        title: 'Find friends',
        icon: Icons.person_search,
        color: Colors.blue,
        onTap: () => Navigator.pushNamed(context, '/find-friends'),
      ),
      MenuGridItem(
        title: 'Feeds',
        icon: Icons.feed,
        color: Colors.blue,
        onTap: () => Navigator.pushNamed(context, '/feeds'),
      ),
      MenuGridItem(
        title: 'Events',
        icon: Icons.event,
        color: Colors.red,
        onTap: () => Navigator.pushNamed(context, '/events'),
      ),
      MenuGridItem(
        title: 'Avatars',
        icon: Icons.face,
        color: Colors.blue,
        onTap: () => Navigator.pushNamed(context, '/avatars'),
      ),
      MenuGridItem(
        title: 'Birthdays',
        icon: Icons.cake,
        color: Colors.pink,
        onTap: () => Navigator.pushNamed(context, '/birthdays'),
      ),
      MenuGridItem(
        title: 'Finds',
        icon: Icons.diamond,
        color: Colors.pink,
        onTap: () => Navigator.pushNamed(context, '/finds'),
      ),
      MenuGridItem(
        title: 'Games',
        icon: Icons.games,
        color: Colors.blue,
        onTap: () => Navigator.pushNamed(context, '/games'),
      ),
      MenuGridItem(
        title: 'Messenger Kids',
        icon: Icons.child_care,
        color: Colors.green,
        onTap: () => Navigator.pushNamed(context, '/messenger-kids'),
      ),
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ],
        ],
      ),
      child: Column(
        children: [
          // Show first 6 items in grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              final item = menuItems[index];
              return _buildGridItem(item);
            },
          ),
          
          // See More button
          if (menuItems.length > 6) ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: () {
                // Show expanded menu
                _showExpandedMenu(menuItems.sublist(6));
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'See Less',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.keyboard_arrow_up,
                      color: Colors.grey[600],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGridItem(MenuGridItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                item.icon,
                color: item.color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentPagesSection() {
    // Group pages by category
    final pagesByCategory = <String, List<ContentPage>>{};
    for (final page in _pages) {
      pagesByCategory.putIfAbsent(page.category, () => []).add(page);
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.pages,
                color: Colors.orange,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Pages',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...pagesByCategory.entries.map((entry) {
            return _buildPageCategory(entry.key, entry.value);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildPageCategory(String category, List<ContentPage> pages) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (category.isNotEmpty) ...[
          Text(
            category.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
        ],
        ...pages.map((page) {
          return InkWell(
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
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.article,
                      color: Colors.orange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      page.title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        if (pages.isNotEmpty) const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAdditionalOptions() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildOptionTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () => Navigator.pushNamed(context, '/help'),
          ),
          _buildOptionTile(
            icon: Icons.settings,
            title: 'Settings & Privacy',
            onTap: () => Navigator.pushNamed(context, '/settings'),
          ),
          _buildOptionTile(
            icon: Icons.apps,
            title: 'Also from Meta',
            onTap: () => Navigator.pushNamed(context, '/meta-apps'),
          ),
          if (_currentUser != null) ...[
            const Divider(height: 32),
            _buildOptionTile(
              icon: Icons.logout,
              title: 'Logout',
              onTap: _handleLogout,
              isDestructive: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isDestructive 
                ? Colors.red.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDestructive ? Colors.red : Colors.grey[700],
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: isDestructive ? Colors.red : null,
          ),
        ),
        trailing: const Icon(
          Icons.keyboard_arrow_down,
          color: Colors.grey,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final countryCode = CountryService.instance.countryCode?.toUpperCase() ?? 'Global';
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'Request Marketplace',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Country: $countryCode',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '© 2025 Request Marketplace. All rights reserved.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showExpandedMenu(List<MenuGridItem> additionalItems) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'More Options',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 3.5,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: additionalItems.length,
                      itemBuilder: (context, index) {
                        return _buildGridItem(additionalItems[index]);
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      try {
        await _authService.signOut();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error signing out: $e')),
          );
        }
      }
    }
  }
}

class MenuGridItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  MenuGridItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
