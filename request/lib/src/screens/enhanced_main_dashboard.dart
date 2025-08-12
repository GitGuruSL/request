import 'package:flutter/material.dart';
import '../models/enhanced_user_model.dart';
import '../models/request_model.dart';
import '../services/enhanced_user_service.dart';
import '../services/enhanced_request_service.dart';

class EnhancedMainDashboard extends StatefulWidget {
  const EnhancedMainDashboard({Key? key}) : super(key: key);

  @override
  State<EnhancedMainDashboard> createState() => _EnhancedMainDashboardState();
}

class _EnhancedMainDashboardState extends State<EnhancedMainDashboard> {
  final EnhancedUserService _userService = EnhancedUserService();
  final EnhancedRequestService _requestService = EnhancedRequestService();
  
  UserModel? currentUser;
  bool isLoading = true;
  int _currentIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _userService.getCurrentUserModel();
      setState(() {
        currentUser = user;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Please log in to continue'),
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigation(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, ${currentUser!.name.split(' ').first}!',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            _getRoleDisplayName(currentUser!.activeRole),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.white70,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => Navigator.pushNamed(context, '/notifications'),
        ),
        PopupMenuButton(
          icon: CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white,
            child: Text(
              currentUser!.name.isNotEmpty 
                  ? currentUser!.name[0].toUpperCase() 
                  : 'U',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          itemBuilder: (context) => [
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.person),
                  SizedBox(width: 8),
                  Text('Profile'),
                ],
              ),
              onTap: () => Navigator.pushNamed(context, '/profile'),
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.swap_horiz),
                  SizedBox(width: 8),
                  Text('Switch Role'),
                ],
              ),
              onTap: () => Navigator.pushNamed(context, '/role-selection'),
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.settings),
                  SizedBox(width: 8),
                  Text('Settings'),
                ],
              ),
              onTap: () => Navigator.pushNamed(context, '/settings'),
            ),
            PopupMenuItem(
              child: const Row(
                children: [
                  Icon(Icons.logout, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Logout', style: TextStyle(color: Colors.red)),
                ],
              ),
              onTap: () => _logout(),
            ),
          ],
        ),
      ],
    );
  }

  Drawer _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(currentUser!.name),
            accountEmail: Text(currentUser!.email),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                currentUser!.name.isNotEmpty 
                    ? currentUser!.name[0].toUpperCase() 
                    : 'U',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          
          // Role-specific menu items
          ...currentUser!.roles.map((role) => _buildRoleMenuItem(role)),
          
          const Divider(),
          
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Add New Role'),
            onTap: () => Navigator.pushNamed(context, '/role-selection'),
          ),
          
          const Divider(),
          
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Statistics'),
            onTap: () => Navigator.pushNamed(context, '/statistics'),
          ),
          
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            onTap: () => Navigator.pushNamed(context, '/support'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleMenuItem(UserRole role) {
    final isActive = role == currentUser!.activeRole;
    final isVerified = currentUser!.isRoleVerified(role);
    final roleInfo = _getRoleInfo(role);
    
    return ListTile(
      leading: Icon(
        roleInfo['icon'],
        color: isActive 
            ? Theme.of(context).colorScheme.primary 
            : Colors.grey,
      ),
      title: Text(
        roleInfo['title'],
        style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive 
              ? Theme.of(context).colorScheme.primary 
              : null,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isVerified)
            const Icon(Icons.verified, color: Colors.green, size: 16),
          if (!isVerified)
            const Icon(Icons.pending, color: Colors.orange, size: 16),
          if (isActive)
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
              size: 16,
            ),
        ],
      ),
      onTap: isActive ? null : () => _switchRole(role),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return _buildRequestsTab();
      case 2:
        return _buildResponsesTab();
      case 3:
        return _buildMessagesTab();
      default:
        return _buildDashboardTab();
    }
  }

  Widget _buildDashboardTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRoleStatusCard(),
          const SizedBox(height: 16),
          _buildQuickActions(),
          const SizedBox(height: 16),
          _buildRecentActivity(),
          const SizedBox(height: 16),
          _buildRecommendedRequests(),
        ],
      ),
    );
  }

  Widget _buildRoleStatusCard() {
    final activeRole = currentUser!.activeRole;
    final isVerified = currentUser!.isRoleVerified(activeRole);
    final roleInfo = _getRoleInfo(activeRole);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              roleInfo['icon'],
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  roleInfo['title'],
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isVerified ? Icons.verified : Icons.pending,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isVerified ? 'Verified' : 'Verification Pending',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (!isVerified)
            ElevatedButton(
              onPressed: () => _completeVerification(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Complete'),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = _getQuickActionsForRole(currentUser!.activeRole);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildActionCard(action);
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(Map<String, dynamic> action) {
    return GestureDetector(
      onTap: action['onTap'],
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              action['icon'],
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              action['title'],
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: const Text(
            'No recent activity',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedRequests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended for You',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: const Text(
            'No recommendations available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsTab() {
    return Center(
      child: Text('Requests Tab - ${currentUser!.activeRole.name}'),
    );
  }

  Widget _buildResponsesTab() {
    return Center(
      child: Text('Responses Tab - ${currentUser!.activeRole.name}'),
    );
  }

  Widget _buildMessagesTab() {
    return const Center(
      child: Text('Messages Tab'),
    );
  }

  BottomNavigationBar _buildBottomNavigation() {
    final navItems = _getNavItemsForRole(currentUser!.activeRole);
    
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey,
      items: navItems.map((item) => BottomNavigationBarItem(
        icon: Icon(item['icon']),
        label: item['label'],
      )).toList(),
    );
  }

  FloatingActionButton? _buildFloatingActionButton() {
    final fabAction = _getFabActionForRole(currentUser!.activeRole);
    if (fabAction == null) return null;
    
    return FloatingActionButton(
      onPressed: fabAction['onPressed'],
      backgroundColor: Theme.of(context).colorScheme.primary,
      child: Icon(fabAction['icon']),
    );
  }

  // Helper methods
  String _getRoleDisplayName(UserRole role) {
    return _getRoleInfo(role)['title'];
  }

  Map<String, dynamic> _getRoleInfo(UserRole role) {
    switch (role) {
      case UserRole.general:
        return {'title': 'General User', 'icon': Icons.person};
      case UserRole.driver:
        return {'title': 'Driver', 'icon': Icons.directions_car};
      case UserRole.delivery:
        return {'title': 'Delivery Partner', 'icon': Icons.delivery_dining};
      case UserRole.business:
        return {'title': 'Business Owner', 'icon': Icons.business};
    }
  }

  List<Map<String, dynamic>> _getQuickActionsForRole(UserRole role) {
    switch (role) {
      case UserRole.general:
        return [
          {
            'title': 'New Request',
            'icon': Icons.add_box,
            'onTap': () => Navigator.pushNamed(context, '/create-request'),
          },
          {
            'title': 'Browse Market',
            'icon': Icons.shopping_bag,
            'onTap': () => Navigator.pushNamed(context, '/marketplace'),
          },
          {
            'title': 'My Requests',
            'icon': Icons.list_alt,
            'onTap': () => Navigator.pushNamed(context, '/my-requests'),
          },
          {
            'title': 'Find Services',
            'icon': Icons.search,
            'onTap': () => Navigator.pushNamed(context, '/search'),
          },
        ];
      case UserRole.driver:
        return [
          {
            'title': 'Go Online',
            'icon': Icons.power_settings_new,
            'onTap': () => _toggleDriverAvailability(),
          },
          {
            'title': 'Ride Requests',
            'icon': Icons.directions_car,
            'onTap': () => Navigator.pushNamed(context, '/ride-requests'),
          },
          {
            'title': 'My Earnings',
            'icon': Icons.attach_money,
            'onTap': () => Navigator.pushNamed(context, '/earnings'),
          },
          {
            'title': 'Vehicle Info',
            'icon': Icons.car_repair,
            'onTap': () => Navigator.pushNamed(context, '/vehicle-info'),
          },
        ];
      case UserRole.delivery:
        return [
          {
            'title': 'Available Jobs',
            'icon': Icons.work,
            'onTap': () => Navigator.pushNamed(context, '/delivery-jobs'),
          },
          {
            'title': 'My Deliveries',
            'icon': Icons.local_shipping,
            'onTap': () => Navigator.pushNamed(context, '/my-deliveries'),
          },
          {
            'title': 'Fleet Status',
            'icon': Icons.inventory,
            'onTap': () => Navigator.pushNamed(context, '/fleet-status'),
          },
          {
            'title': 'Service Areas',
            'icon': Icons.map,
            'onTap': () => Navigator.pushNamed(context, '/service-areas'),
          },
        ];
      case UserRole.business:
        return [
          {
            'title': 'Add Product',
            'icon': Icons.add_shopping_cart,
            'onTap': () => Navigator.pushNamed(context, '/add-product'),
          },
          {
            'title': 'Orders',
            'icon': Icons.receipt_long,
            'onTap': () => Navigator.pushNamed(context, '/orders'),
          },
          {
            'title': 'Customers',
            'icon': Icons.people,
            'onTap': () => Navigator.pushNamed(context, '/customers'),
          },
          {
            'title': 'Analytics',
            'icon': Icons.analytics,
            'onTap': () => Navigator.pushNamed(context, '/business-analytics'),
          },
        ];
    }
  }

  List<Map<String, dynamic>> _getNavItemsForRole(UserRole role) {
    final baseItems = [
      {'icon': Icons.dashboard, 'label': 'Dashboard'},
      {'icon': Icons.list, 'label': 'Requests'},
      {'icon': Icons.reply_all, 'label': 'Responses'},
      {'icon': Icons.message, 'label': 'Messages'},
    ];

    switch (role) {
      case UserRole.driver:
        baseItems[1] = {'icon': Icons.directions_car, 'label': 'Rides'};
        break;
      case UserRole.delivery:
        baseItems[1] = {'icon': Icons.local_shipping, 'label': 'Deliveries'};
        break;
      case UserRole.business:
        baseItems[1] = {'icon': Icons.shopping_bag, 'label': 'Products'};
        baseItems[2] = {'icon': Icons.receipt, 'label': 'Orders'};
        break;
      default:
        break;
    }

    return baseItems;
  }

  Map<String, dynamic>? _getFabActionForRole(UserRole role) {
    switch (role) {
      case UserRole.general:
        return {
          'icon': Icons.add,
          'onPressed': () => Navigator.pushNamed(context, '/create-request'),
        };
      case UserRole.business:
        return {
          'icon': Icons.add_shopping_cart,
          'onPressed': () => Navigator.pushNamed(context, '/add-product'),
        };
      default:
        return null;
    }
  }

  Future<void> _switchRole(UserRole role) async {
    try {
      await _userService.switchActiveRole(currentUser!.id, role);
      await _loadUserData();
      Navigator.pop(context); // Close drawer
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error switching role: $e')),
      );
    }
  }

  void _completeVerification() {
    switch (currentUser!.activeRole) {
      case UserRole.driver:
        Navigator.pushNamed(context, '/new-driver-verification');
        break;
      case UserRole.delivery:
        Navigator.pushNamed(context, '/delivery-verification');
        break;
      case UserRole.business:
        Navigator.pushNamed(context, '/business-verification');
        break;
      default:
        break;
    }
  }

  void _toggleDriverAvailability() {
    // Implementation for toggling driver online/offline status
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Implement logout
              Navigator.pushNamedAndRemoveUntil(
                context, 
                '/login', 
                (route) => false
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
