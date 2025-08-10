import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../drivers/driver_status_dashboard.dart';
import '../../drivers/driver_verification_screen.dart';
import '../../services/driver_verification_service.dart';
import '../../requests/screens/create_service_request_screen.dart';
import '../../requests/screens/request_detail_screen.dart';
import '../../requests/screens/edit_request_screen.dart';
import '../../models/request_model.dart';
import '../../business/screens/business_product_management_screen.dart';
import '../../theme/app_theme.dart';
import '../../routes/routes.dart';

class UnifiedDashboardScreen extends StatefulWidget {
  const UnifiedDashboardScreen({super.key});

  @override
  State<UnifiedDashboardScreen> createState() => _UnifiedDashboardScreenState();
}

class _UnifiedDashboardScreenState extends State<UnifiedDashboardScreen>
    with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  TabController? _tabController;
  User? _currentUser;
  List<String> _userRoles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    if (_currentUser == null) {
      setState(() {
        _isLoading = false;
        _userRoles = ['Overview', 'Consumer']; // Fallback roles
      });
      return;
    }

    try {
      // Check if user has different roles by checking various collections
      await _checkUserRoles();

      // Initialize tab controller based on roles after we have them
      if (_userRoles.isNotEmpty) {
        _tabController = TabController(
          length: _userRoles.length,
          vsync: this,
        );
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user profile: $e');
      setState(() {
        _isLoading = false;
        _userRoles = ['Overview', 'Consumer']; // Fallback roles
      });

      // Create TabController with fallback roles
      _tabController = TabController(
        length: _userRoles.length,
        vsync: this,
      );
    }
  }

  Future<void> _checkUserRoles() async {
    if (_currentUser == null) return;

    try {
      List<String> roles = ['Overview']; // Always have overview

      // Check if user is a driver
      try {
        final driverDoc =
            await _firestore.collection('drivers').doc(_currentUser!.uid).get();
        if (driverDoc.exists) {
          roles.add('Driver');
        }
      } catch (e) {
        print('Error checking driver role: $e');
      }

      // Check if user is a business
      try {
        final businessQuery = await _firestore
            .collection('businesses')
            .where('userId', isEqualTo: _currentUser!.uid)
            .limit(1)
            .get();
        if (businessQuery.docs.isNotEmpty) {
          roles.add('Business');
        }
      } catch (e) {
        print('Error checking business role: $e');
      }

      // Check if user is a service provider
      try {
        final serviceDoc = await _firestore
            .collection('service_providers')
            .doc(_currentUser!.uid)
            .get();
        if (serviceDoc.exists) {
          roles.add('Service Provider');
        }
      } catch (e) {
        print('Error checking service provider role: $e');
      }

      // Always add consumer role as default
      roles.add('Consumer');

      setState(() {
        _userRoles = roles;
      });
    } catch (e) {
      print('Error in _checkUserRoles: $e');
      // Fallback to basic roles if everything fails
      setState(() {
        _userRoles = ['Overview', 'Consumer'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Dashboard'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          // Safety Button
          IconButton(
            icon: Icon(
              Icons.shield,
              color: Colors.orange.shade600,
            ),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.safety),
            tooltip: 'Safety Center',
          ),
          // Settings Button
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
            tooltip: 'Settings',
          ),
          // Profile Menu
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle),
            onSelected: (value) => _handleMenuSelection(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'help',
                child: ListTile(
                  leading: Icon(Icons.help),
                  title: Text('Help & Support'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'about',
                child: ListTile(
                  leading: Icon(Icons.info),
                  title: Text('About'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Sign Out', style: TextStyle(color: Colors.red)),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: _userRoles.isNotEmpty
            ? TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: const Color(0xFF4F46E5),
                unselectedLabelColor: Colors.grey,
                indicatorColor: const Color(0xFF4F46E5),
                tabs: _userRoles
                    .map((role) => Tab(
                          text: role,
                          icon: _getRoleIcon(role),
                        ))
                    .toList(),
              )
            : null,
      ),
      body: _userRoles.isNotEmpty
          ? TabBarView(
              controller: _tabController,
              children:
                  _userRoles.map((role) => _buildRoleContent(role)).toList(),
            )
          : _buildNoRoleContent(),
    );
  }

  Widget _getRoleIcon(String role) {
    switch (role) {
      case 'Overview':
        return const Icon(Icons.dashboard, size: 20);
      case 'Driver':
        return const Icon(Icons.drive_eta, size: 20);
      case 'Business':
        return const Icon(Icons.business, size: 20);
      case 'Service Provider':
        return const Icon(Icons.handyman, size: 20);
      case 'Consumer':
        return const Icon(Icons.person, size: 20);
      default:
        return const Icon(Icons.info, size: 20);
    }
  }

  Widget _buildRoleContent(String role) {
    switch (role) {
      case 'Overview':
        return _buildOverviewContent();
      case 'Driver':
        return _buildDriverContent();
      case 'Business':
        return _buildBusinessContent();
      case 'Service Provider':
        return _buildServiceProviderContent();
      case 'Consumer':
        return _buildConsumerContent();
      default:
        return _buildDefaultContent(role);
    }
  }

  Widget _buildOverviewContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: _currentUser?.photoURL != null
                        ? NetworkImage(_currentUser!.photoURL!)
                        : null,
                    child: _currentUser?.photoURL == null
                        ? Text(
                            _currentUser?.displayName?.substring(0, 1) ?? 'U')
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentUser?.displayName ?? 'User',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(_currentUser?.email ?? ''),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 4,
                          children: _userRoles
                              .where((role) => role != 'Overview')
                              .map((role) => Chip(
                                    label: Text(role,
                                        style: const TextStyle(fontSize: 12)),
                                    backgroundColor: const Color(0xFF4F46E5)
                                        .withOpacity(0.1),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Driver verification banner (only show if user is a driver)
          if (_userRoles.contains('Driver')) ...[
            StreamBuilder<Map<String, dynamic>>(
              stream: DriverVerificationService().streamVerificationStatus(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!['error'] == null) {
                  return VerificationNotificationBanner(
                    verificationSummary: snapshot.data!,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const DriverVerificationScreen(),
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],

          // Quick Stats
          const Text(
            'Quick Stats',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          FutureBuilder<Map<String, int>>(
            future: _getQuickStats(),
            builder: (context, snapshot) {
              final stats = snapshot.data ?? {'requests': 0, 'activities': 0};
              return Row(
                children: [
                  Expanded(
                    child: _buildStatCard('Active Roles',
                        '${_userRoles.length - 1}', Icons.person_outline),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard('Requests', '${stats['requests']}', Icons.list_alt),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard('Activities', '${stats['activities']}', Icons.timeline),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),

          // Recent Activities
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activities',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () async {
                  // Create a sample activity for testing
                  try {
                    await _firestore.collection('activities').add({
                      'userId': _currentUser?.uid,
                      'type': 'login',
                      'description': 'Logged into the app',
                      'timestamp': Timestamp.now(),
                    });
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sample activity created!')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                child: const Text('Test', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('activities')
                .where('userId', isEqualTo: _currentUser?.uid)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.timeline, size: 48, color: Colors.grey),
                        const SizedBox(height: 8),
                        const Text('No recent activities'),
                        const SizedBox(height: 8),
                        Text(
                          'Activities like creating requests, submitting responses, and updating your profile will appear here',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        // Test button to create sample activity
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await _firestore.collection('activities').add({
                                'userId': _currentUser?.uid,
                                'type': 'test_activity',
                                'description': 'Test activity created from dashboard',
                                'timestamp': FieldValue.serverTimestamp(),
                                'details': {
                                  'source': 'dashboard_test_button',
                                  'timestamp': DateTime.now().toIso8601String(),
                                },
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Test activity created!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error creating activity: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Create Test Activity'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...snapshot.data!.docs.take(3).map((doc) {
                        final activity = doc.data() as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                _getActivityIcon(activity['type']),
                                size: 20,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      activity['description'] ?? 'Activity',
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      _formatTimestamp(activity['timestamp']),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      if (snapshot.data!.docs.length > 3) ...[
                        const Divider(),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              // Switch to Consumer tab to see all activities
                              if (_tabController != null && _userRoles.contains('Consumer')) {
                                final consumerIndex = _userRoles.indexOf('Consumer');
                                _tabController!.animateTo(consumerIndex);
                              }
                            },
                            child: Text('View all ${snapshot.data!.docs.length} activities'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      child: Column(
        children: [
          Icon(
            icon, 
            color: AppTheme.primaryColor,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.headingSmall.copyWith(
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDriverContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Driver Dashboard',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.verified_user),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DriverVerificationScreen(),
                    ),
                  );
                },
                tooltip: 'Manage Verification',
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Driver Status Dashboard Widget
          DriverStatusDashboard(
            onNavigateToVerification: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DriverVerificationScreen(),
                ),
              );
            },
            onNavigateToVehicles: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DriverVerificationScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // Quick Actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const DriverVerificationScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.assignment),
                          label: const Text('Documents'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const DriverVerificationScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.directions_car),
                          label: const Text('Vehicles'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business Dashboard',
            style: AppTheme.headingMedium.copyWith(
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLarge),
          
          // Quick Business Actions
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
            ),
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Actions',
                  style: AppTheme.headingSmall.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickActionItem(
                        icon: Icons.inventory_2_outlined,
                        title: 'Products',
                        subtitle: 'Manage inventory',
                        onTap: () async {
                          // Get business ID first
                          try {
                            final businessQuery = await _firestore
                                .collection('businesses')
                                .where('userId', isEqualTo: _currentUser!.uid)
                                .limit(1)
                                .get();
                            
                            if (businessQuery.docs.isNotEmpty) {
                              final businessId = businessQuery.docs.first.id;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BusinessProductManagementScreen(
                                    businessId: businessId,
                                  ),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please register your business first'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingMedium),
                    Expanded(
                      child: _buildQuickActionItem(
                        icon: Icons.receipt_long_outlined,
                        title: 'Orders',
                        subtitle: 'View & manage',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Orders management coming soon!')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingLarge),
          
          // Business Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Products', '0', Icons.inventory_2),
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              Expanded(
                child: _buildStatCard('Orders', '0', Icons.receipt),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLarge),
          
          // Business Requests
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Business Requests',
                style: AppTheme.headingSmall.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateServiceRequestScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Post Request'),
                style: AppTheme.primaryButtonStyle,
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('requests')
                .where('userId', isEqualTo: _currentUser?.uid)
                .where('type', isEqualTo: 'business')
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
                  ),
                  padding: const EdgeInsets.all(AppTheme.spacingLarge),
                  child: Column(
                    children: [
                      Icon(
                        Icons.business_center, 
                        size: 48, 
                        color: AppTheme.textTertiary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No business requests yet',
                        style: AppTheme.bodyLarge.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Start by posting your first business request',
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final request = doc.data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(request['title'] ?? 'Business Request'),
                      subtitle: Text(request['category'] ?? 'General'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(request['status']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          request['status'] ?? 'pending',
                          style: TextStyle(color: _getStatusColor(request['status'])),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildServiceProviderContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Service Provider Dashboard',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Service Provider Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard('Services Offered', '0', Icons.handyman),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard('Completed Jobs', '0', Icons.done_all),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Available Requests
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Available Service Requests',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () {
                  setState(() {});
                },
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh requests',
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('requests')
                .where('type', isEqualTo: 'service')
                .where('status', isEqualTo: 'open')
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Icon(Icons.search, size: 48, color: Colors.grey),
                        const SizedBox(height: 8),
                        Text('No service requests available'),
                        const SizedBox(height: 8),
                        Text(
                          'Check back later for new opportunities',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final request = doc.data() as Map<String, dynamic>;
                  final isMyRequest = request['userId'] == _currentUser?.uid;
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(request['title'] ?? 'Service Request'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(request['category'] ?? 'General'),
                          Text(
                            'Budget: LKR ${request['budget'] ?? 0}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      trailing: isMyRequest
                          ? const Chip(
                              label: Text('Your Request'),
                              backgroundColor: Colors.blue,
                            )
                          : ElevatedButton(
                              onPressed: () {
                                // Navigate to respond to request
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Response feature coming soon!'),
                                  ),
                                );
                              },
                              child: const Text('Respond'),
                            ),
                      isThreeLine: true,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildConsumerContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Check if user is not a driver and show option to become one
          if (!_userRoles.contains('Driver')) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6750A4).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.drive_eta_outlined,
                          color: Color(0xFF6750A4),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Become a Driver',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1D1B20),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Start earning by responding to ride requests',
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xFF49454F),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Complete verification to get started and join thousands of drivers earning in your area.',
                    style: TextStyle(
                      fontSize: 15,
                      color: const Color(0xFF49454F),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showDriverRegistrationDialog();
                      },
                      icon: const Icon(Icons.person_add_outlined),
                      label: const Text('Start Driver Registration'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6750A4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // My Responses Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.reply, color: Colors.purple.shade700),
                          const SizedBox(width: 8),
                          const Text(
                            'My Responses',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Scaffold(
                                body: Center(child: Text('My Responses - Coming Soon')),
                              ),
                            ),
                          );
                        },
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('responses')
                        .where('responderId', isEqualTo: _currentUser?.uid)
                        .limit(3)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Column(
                          children: [
                            const Icon(Icons.inbox, size: 32, color: Colors.grey),
                            const SizedBox(height: 8),
                            const Text('No responses yet'),
                            const SizedBox(height: 8),
                            const Text(
                              'Responses you send to requests will appear here',
                              style: TextStyle(color: Colors.grey, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const Scaffold(
                                      body: Center(child: Text('My Responses - Coming Soon')),
                                    ),
                                  ),
                                );
                              },
                              child: const Text('View My Responses'),
                            ),
                          ],
                        );
                      }

                      return Column(
                        children: [
                          ...snapshot.data!.docs.take(3).map((doc) {
                            final responseData = doc.data() as Map<String, dynamic>;
                            final status = responseData['status'] ?? 'pending';
                            final requestId = responseData['requestId'];
                            final message = responseData['message'] ?? '';
                            final createdAt = responseData['createdAt'] as Timestamp?;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getStatusColor(status),
                                  child: Icon(
                                    _getStatusIcon(status),
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                                title: FutureBuilder<DocumentSnapshot>(
                                  future: _firestore.collection('requests').doc(requestId).get(),
                                  builder: (context, requestSnapshot) {
                                    if (requestSnapshot.hasData) {
                                      final requestData = requestSnapshot.data!.data() as Map<String, dynamic>?;
                                      final title = requestData?['title'] ?? 'Unknown Request';
                                      return Text(
                                        title,
                                        style: const TextStyle(fontWeight: FontWeight.w500),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      );
                                    }
                                    return const Text('Loading...');
                                  },
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      'Status: ${status.toUpperCase()}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _getStatusColor(status),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: createdAt != null
                                    ? Text(
                                        _formatTimestamp(createdAt),
                                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                                      )
                                    : null,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const Scaffold(
                                        body: Center(child: Text('My Responses - Coming Soon')),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          }).toList(),
                          if (snapshot.data!.docs.length > 3) ...[
                            const Divider(),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const Scaffold(
                                        body: Center(child: Text('My Responses - Coming Soon')),
                                      ),
                                    ),
                                  );
                                },
                                child: Text('View all ${snapshot.data!.docs.length} responses'),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Requests',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () async {
                  try {
                    final allRequests = await _firestore.collection('requests').get();
                    final userRequests = await _firestore
                        .collection('requests')
                        .where('userId', isEqualTo: _currentUser?.uid)
                        .get();
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Total: ${allRequests.docs.length}, Yours: ${userRequests.docs.length}'),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                  
                  // Force rebuild to refresh the stream
                  setState(() {});
                },
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh requests',
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('requests')
                .where('userId', isEqualTo: _currentUser?.uid)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.error, size: 48, color: Colors.red),
                        const SizedBox(height: 8),
                        const Text('Error loading requests'),
                        const SizedBox(height: 8),
                        Text('${snapshot.error}'),
                      ],
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.inbox, size: 48, color: Colors.grey),
                        const SizedBox(height: 8),
                        const Text('No requests yet'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CreateServiceRequestScreen(),
                              ),
                            );
                          },
                          child: const Text('Create First Request'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final request = doc.data() as Map<String, dynamic>;
                  final requestModel = RequestModel.fromFirestore(doc);
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(request['title'] ?? 'Request'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(request['type'] ?? 'Unknown'),
                          if (request['budget'] != null)
                            Text(
                              'Budget: LKR ${request['budget']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.green,
                              ),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(request['status'])
                                  .withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              request['status'] ?? 'pending',
                              style: TextStyle(
                                  color: _getStatusColor(request['status'])),
                            ),
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'view':
                                  _viewRequest(requestModel);
                                  break;
                                case 'edit':
                                  _editRequest(requestModel);
                                  break;
                                case 'delete':
                                  _deleteRequest(doc.id, request['title'] ?? 'Request');
                                  break;
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'view',
                                child: Row(
                                  children: [
                                    Icon(Icons.visibility),
                                    const SizedBox(width: 8),
                                    Text('View Details'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit),
                                    const SizedBox(width: 8),
                                    Text('Edit Request'),
                                  ],
                                ),
                              ),
                              if (request['status'] == 'pending' || request['status'] == 'open')
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      const SizedBox(width: 8),
                                      Text('Delete Request', 
                                           style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () => _viewRequest(requestModel),
                      isThreeLine: request['budget'] != null,
                    ),
                  );
                }).toList(),
              );
            },
          ),
          
          const SizedBox(height: 24),
          
          // All Activities Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'All Activities',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () {
                  setState(() {});
                },
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh activities',
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('activities')
                .where('userId', isEqualTo: _currentUser?.uid)
                .limit(20)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.error, size: 48, color: Colors.red),
                        const SizedBox(height: 8),
                        const Text('Error loading activities'),
                        const SizedBox(height: 8),
                        Text('${snapshot.error}'),
                      ],
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Icon(Icons.inbox, size: 48, color: Colors.grey),
                        const SizedBox(height: 8),
                        const Text('No activities yet'),
                        const SizedBox(height: 8),
                        const Text(
                          'Your activities will appear here as you use the app',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        // Test button to create sample activity
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await _firestore.collection('activities').add({
                                'userId': _currentUser?.uid,
                                'type': 'test_activity',
                                'description': 'Test activity created from All Activities section',
                                'timestamp': FieldValue.serverTimestamp(),
                                'details': {
                                  'source': 'all_activities_test_button',
                                  'timestamp': DateTime.now().toIso8601String(),
                                },
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Test activity created! Check Recent Activities.'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error creating activity: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Create Test Activity'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4F46E5),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final activity = doc.data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.withOpacity(0.1),
                        child: Icon(
                          _getActivityIcon(activity['type']),
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      title: Text(activity['description'] ?? 'Activity'),
                      subtitle: Text(_formatTimestamp(activity['timestamp'])),
                      trailing: activity['details'] != null
                          ? Icon(
                              Icons.info_outline,
                              color: Colors.grey[400],
                              size: 16,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    
    switch (status.toLowerCase()) {
      case 'accepted':
      case 'completed':
        return Colors.green;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      case 'in_progress':
        return Colors.blue;
      case 'expired':
        return Colors.grey;
      default: // pending, open, etc.
        return Colors.orange;
    }
  }

  Widget _buildDefaultContent(String role) {
    return Center(
      child: Text('$role content coming soon...'),
    );
  }

  Widget _buildNoRoleContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Welcome to Your Dashboard!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your profile to access more features',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Future<void> _showDriverRegistrationDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Become a Driver'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Complete your basic information to start the driver verification process.',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your full name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      setState(() => isLoading = true);

                      try {
                        final success = await DriverVerificationService()
                            .createDriverProfile(
                          name: nameController.text.trim(),
                          phone: phoneController.text.trim(),
                        );

                        if (success) {
                          Navigator.pop(context); // Close dialog

                          // Refresh the dashboard to show driver tab
                          await _loadUserProfile();

                          // Navigate to verification screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const DriverVerificationScreen(),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to create driver profile'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } finally {
                        setState(() => isLoading = false);
                      }
                    },
              child: isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Register'),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, int>> _getQuickStats() async {
    if (_currentUser == null) {
      return {'requests': 0, 'activities': 0};
    }

    try {
      final requestsSnapshot = await _firestore
          .collection('requests')
          .where('userId', isEqualTo: _currentUser!.uid)
          .get();

      final activitiesSnapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: _currentUser!.uid)
          .get();

      return {
        'requests': requestsSnapshot.docs.length,
        'activities': activitiesSnapshot.docs.length,
      };
    } catch (e) {
      print('Error fetching quick stats: $e');
      return {'requests': 0, 'activities': 0};
    }
  }

  IconData _getActivityIcon(String? type) {
    switch (type) {
      case 'create_request':
        return Icons.add_circle_outline;
      case 'respond_to_request':
        return Icons.reply;
      case 'update_profile':
        return Icons.person;
      case 'verify_document':
        return Icons.verified;
      case 'login':
        return Icons.login;
      default:
        return Icons.timeline;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown time';
    
    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is String) {
      dateTime = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      return 'Unknown time';
    }
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  // Request management methods
  void _viewRequest(RequestModel request) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RequestDetailScreen(request: request),
      ),
    );
  }

  void _editRequest(RequestModel request) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditRequestScreen(request: request),
      ),
    ).then((result) {
      // Refresh the list if the request was updated
      if (result == true) {
        setState(() {});
      }
    });
  }

  void _deleteRequest(String requestId, String requestTitle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Are you sure you want to delete "$requestTitle"?'),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performDeleteRequest(requestId, requestTitle);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _performDeleteRequest(String requestId, String requestTitle) async {
    try {
      // Delete the request
      await _firestore.collection('requests').doc(requestId).delete();

      // Create activity log
      await _firestore.collection('activities').add({
        'userId': _currentUser?.uid,
        'type': 'delete_request',
        'description': 'Deleted request: $requestTitle',
        'timestamp': Timestamp.now(),
        'details': {
          'requestId': requestId,
          'requestTitle': requestTitle,
        },
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'expired':
        return Icons.schedule_rounded;
      default: // pending
        return Icons.pending;
    }
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: AppTheme.borderLight, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(height: AppTheme.spacingSmall),
                Text(
                  title,
                  style: AppTheme.bodyLarge.copyWith(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTheme.bodySmall.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleMenuSelection(String value) {
    switch (value) {
      case 'help':
        Navigator.pushNamed(context, AppRoutes.helpSupport);
        break;
      case 'about':
        Navigator.pushNamed(context, AppRoutes.about);
        break;
      case 'logout':
        _showSignOutDialog();
        break;
    }
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _auth.signOut();
                if (context.mounted) {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, AppRoutes.welcome);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error signing out: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }
}
