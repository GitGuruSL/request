import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'activity_center_screen.dart';
import 'profile_center_screen.dart';
import 'simplified_profile_center_screen.dart';
import '../requests/screens/create_item_request_screen.dart';
import '../browse/screens/browse_screen.dart';
import '../chat/screens/conversations_screen.dart';
import '../business/screens/manage_products_screen.dart';
import '../services/business_service.dart';
import '../services/driver_service.dart';
import '../models/business_models.dart';
import '../models/user_model.dart';
import '../models/driver_model.dart';

class MainDashboardScreen extends StatefulWidget {
  const MainDashboardScreen({super.key});

  @override
  State<MainDashboardScreen> createState() => _MainDashboardScreenState();
}

class _MainDashboardScreenState extends State<MainDashboardScreen> {
  final _auth = FirebaseAuth.instance;
  final _businessService = BusinessService();
  final _driverService = DriverService();
  
  UserModel? _user;
  List<BusinessProfile> _userBusinesses = [];
  DriverModel? _driverProfile;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        // Load user businesses
        final business = await _businessService.getBusinessByUserId(currentUser.uid);
        List<BusinessProfile> businesses = [];
        if (business != null) {
          businesses.add(business);
        }

        // Load driver profile
        DriverModel? driverProfile;
        try {
          driverProfile = await _driverService.getDriverProfile();
        } catch (e) {
          // Driver profile doesn't exist, which is fine
          print('No driver profile found: $e');
        }
        
        setState(() {
          _user = UserModel(
            id: currentUser.uid,
            email: currentUser.email ?? '',
            displayName: currentUser.displayName ?? 'User',
            phoneNumber: currentUser.phoneNumber ?? '',
            photoURL: currentUser.photoURL,
            createdAt: Timestamp.now(),
          );
          _userBusinesses = businesses;
          _driverProfile = driverProfile;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showBusinessSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Business'),
          content: const Text('Choose which business to manage products for:'),
          actions: _userBusinesses.map((business) {
            return TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ManageProductsScreen(
                      businessId: business.id,
                    ),
                  ),
                );
              },
              child: Text(business.basicInfo.name),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBFE),
      appBar: AppBar(
        title: const Text('Main Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1D1B20),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6750A4), Color(0xFF9575CD)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isLoading 
                                  ? 'Welcome back!'
                                  : 'Welcome back, ${_user?.displayName ?? 'User'}!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _userBusinesses.isNotEmpty 
                                  ? 'Manage your ${_userBusinesses.length} business${_userBusinesses.length > 1 ? 'es' : ''}'
                                  : 'Ready to explore new opportunities?',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),

            // Quick Access Cards
            const Text(
              'Quick Access',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1B20),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildQuickAccessCard(
                    icon: Icons.timeline,
                    title: 'Activity Center',
                    subtitle: 'View requests & responses',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6750A4), Color(0xFF9575CD)],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ActivityCenterScreen(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAccessCard(
                    icon: Icons.account_circle,
                    title: 'Profile Center',
                    subtitle: 'Manage profiles & docs',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2E7D32), Color(0xFF4CAF50)],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SimplifiedProfileCenterScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Manage Products Card (Full Width)
            Container(
              width: double.infinity,
              height: 90, // Increased height to fix overflow
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE65100), Color(0xFFFF9800)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    // Navigate to manage products screen
                    if (_userBusinesses.isNotEmpty) {
                      if (_userBusinesses.length == 1) {
                        // Single business - go directly to manage products
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ManageProductsScreen(
                              businessId: _userBusinesses.first.id,
                            ),
                          ),
                        );
                      } else {
                        // Multiple businesses - show business selection dialog
                        _showBusinessSelectionDialog();
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please register a business first to manage products'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  child: Row(
                    children: [
                      const Icon(
                        Icons.inventory_2_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Manage Products',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add, edit, and manage products',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12, // Reduced font size
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Recent Activity Summary
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1B20),
              ),
            ),
            const SizedBox(height: 16),

            _buildActivitySummaryCard(
              title: 'Active Requests',
              count: '3',
              subtitle: '1 new response today',
              icon: Icons.send_outlined,
              color: const Color(0xFF6750A4),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ActivityCenterScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            _buildActivitySummaryCard(
              title: 'Pending Responses',
              count: '2',
              subtitle: 'Awaiting customer decision',
              icon: Icons.schedule,
              color: Colors.orange,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ActivityCenterScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            _buildActivitySummaryCard(
              title: 'This Month',
              count: '12',
              subtitle: 'Completed transactions',
              icon: Icons.check_circle_outline,
              color: Colors.green,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ActivityCenterScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Status Cards
            const Text(
              'Account Status',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1B20),
              ),
            ),
            const SizedBox(height: 16),

            _buildStatusCard(
              title: 'Profile Verification',
              status: _user?.isVerified == true ? 'Verified' : 'Not Verified',
              statusColor: _user?.isVerified == true ? Colors.green : Colors.orange,
              icon: Icons.verified_user,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SimplifiedProfileCenterScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            _buildStatusCard(
              title: 'Driver Documents',
              status: _driverProfile != null 
                  ? (_driverProfile!.isVerified == true ? 'Verified' : 'Pending') 
                  : 'Not Setup',
              statusColor: _driverProfile != null 
                  ? (_driverProfile!.isVerified == true ? Colors.green : Colors.orange)
                  : Colors.red,
              icon: Icons.drive_eta,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SimplifiedProfileCenterScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            _buildStatusCard(
              title: _userBusinesses.isEmpty 
                  ? 'Business Registration'
                  : '${_userBusinesses.length} Business${_userBusinesses.length > 1 ? 'es' : ''}',
              status: _userBusinesses.isEmpty 
                  ? 'Not Setup' 
                  : _userBusinesses.length > 1 
                      ? 'Multiple Active'
                      : 'Active',
              statusColor: _userBusinesses.isEmpty 
                  ? Colors.red 
                  : _userBusinesses.length > 1 
                      ? Colors.blue
                      : Colors.green,
              icon: _userBusinesses.isEmpty ? Icons.business : Icons.store,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SimplifiedProfileCenterScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // Action Buttons
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1B20),
              ),
            ),
            const SizedBox(height: 16),

            _buildActionButton(
              icon: Icons.add,
              title: 'Post New Request',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateItemRequestScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            _buildActionButton(
              icon: Icons.search,
              title: 'Browse Requests',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BrowseScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            _buildActionButton(
              icon: Icons.message,
              title: 'Messages',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ConversationsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120, // Fixed height for consistency
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySummaryCard({
    required String title,
    required String count,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF1D1B20),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        count,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
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

  Widget _buildStatusCard({
    required String title,
    required String status,
    required Color statusColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: statusColor, size: 20),
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
                      color: Color(0xFF1D1B20),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
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

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6750A4).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF6750A4),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF1D1B20),
                    ),
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
        ),
      ),
    );
  }
}
