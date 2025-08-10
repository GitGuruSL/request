import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../business/screens/manage_products_screen.dart';
import '../business/screens/business_settings_screen.dart';
import '../settings/screens/settings_screen.dart';
import '../services/business_service.dart';
import '../models/business_models.dart';
import 'activity_center_screen.dart';
import 'profile_center_screen.dart';
import 'simplified_profile_center_screen.dart';

class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({super.key});

  @override
  State<BusinessDashboardScreen> createState() => _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> {
  final _auth = FirebaseAuth.instance;
  final _businessService = BusinessService();
  BusinessProfile? _businessProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBusinessData();
  }

  Future<void> _loadBusinessData() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final business = await _businessService.getBusinessByUserId(currentUser.uid);
        setState(() {
          _businessProfile = business;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading business data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBFE),
      appBar: AppBar(
        title: const Text('Business Dashboard'),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1D1B20),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Color(0xFF1D1B20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6750A4), Color(0xFF7C4DFF)],
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
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.business,
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
                                    : 'Welcome back, ${_businessProfile?.basicInfo.name ?? 'Business'}!',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _businessProfile != null 
                                    ? 'Manage your business operations'
                                    : 'Ready to explore new opportunities?',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
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
              
              const SizedBox(height: 24),

              // Business Information Card
              if (_businessProfile != null) 
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
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
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF6750A4), Color(0xFF7C4DFF)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.business,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _businessProfile!.basicInfo.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1D1B20),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _businessProfile!.basicInfo.description,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => BusinessSettingsScreen(
                                    businessId: _businessProfile!.id,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      
                      // Contact Information
                      _buildContactInfo(
                        icon: Icons.phone,
                        label: 'Phone',
                        value: _businessProfile!.basicInfo.phone,
                        onTap: () {
                          // TODO: Make phone call
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildContactInfo(
                        icon: Icons.email,
                        label: 'Email',
                        value: _businessProfile!.basicInfo.email,
                        onTap: () {
                          // TODO: Send email
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildContactInfo(
                        icon: Icons.location_on,
                        label: 'Address',
                        value: '${_businessProfile!.basicInfo.address.street}, ${_businessProfile!.basicInfo.address.city}',
                        onTap: () {
                          // TODO: Open maps
                        },
                      ),
                    ],
                  ),
                ),

              if (_businessProfile != null) const SizedBox(height: 24),

              // Quick Access Section
              const Text(
                'Quick Access',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1B20),
                ),
              ),
              const SizedBox(height: 16),

              // Quick Access Grid
              Row(
                children: [
                  Expanded(
                    child: _buildQuickAccessCard(
                      context,
                      title: 'Activity Center',
                      subtitle: 'View requests & responses',
                      icon: Icons.trending_up_rounded,
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
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildQuickAccessCard(
                      context,
                      title: 'Profile Center',
                      subtitle: 'Manage profiles & docs',
                      icon: Icons.person_outline,
                      color: const Color(0xFF1B5E20),
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
              
              const SizedBox(height: 16),
              
              // Manage Products Card (Full Width)
              _buildQuickAccessCard(
                context,
                title: 'Manage Products',
                subtitle: 'Add, edit, and manage your products',
                icon: Icons.inventory_2_outlined,
                color: const Color(0xFF7C4DFF),
                isFullWidth: true,
                onTap: () {
                  if (_businessProfile != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManageProductsScreen(
                          businessId: _businessProfile!.id,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Business profile not found'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
              
              const SizedBox(height: 16),
              
              // Business Settings Card (Full Width)
              _buildQuickAccessCard(
                context,
                title: 'Business Settings',
                subtitle: 'Manage business profile and preferences',
                icon: Icons.settings_applications,
                color: const Color(0xFF2E7D32),
                isFullWidth: true,
                onTap: () {
                  if (_businessProfile != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BusinessSettingsScreen(
                          businessId: _businessProfile!.id,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Business profile not found'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),

              const SizedBox(height: 32),

              // Recent Activity Section
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1B20),
                ),
              ),
              const SizedBox(height: 16),

              _buildActivityItem(
                icon: Icons.send_outlined,
                title: 'Active Requests',
                subtitle: '1 new response today',
                count: '3',
                color: const Color(0xFF6750A4),
              ),
              const SizedBox(height: 12),

              _buildActivityItem(
                icon: Icons.schedule_outlined,
                title: 'Pending Responses',
                subtitle: 'Awaiting customer decision',
                count: '2',
                color: Colors.orange,
              ),
              const SizedBox(height: 12),

              _buildActivityItem(
                icon: Icons.check_circle_outline,
                title: 'This Month',
                subtitle: 'Completed transactions',
                count: '12',
                color: Colors.green,
              ),

              const SizedBox(height: 32),

              // Account Status Section
              const Text(
                'Account Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1B20),
                ),
              ),
              const SizedBox(height: 16),

              _buildStatusItem(
                icon: Icons.verified_user_outlined,
                title: 'Profile Verification',
                status: 'Not Verified',
                statusColor: Colors.orange,
                onTap: () {
                  // TODO: Navigate to verification
                },
              ),
            ],
          ),
        ),
      ),
    );
    );
  }

  Widget _buildQuickAccessCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isFullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: isFullWidth ? double.infinity : null,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
            child: Icon(
              icon,
              color: color,
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
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1B20),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward_ios,
            color: Colors.grey.shade400,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem({
    required IconData icon,
    required String title,
    required String status,
    required Color statusColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: statusColor,
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1D1B20),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: TextStyle(
                      fontSize: 14,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfo({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF6750A4).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF6750A4),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? 'Not provided' : value,
                  style: TextStyle(
                    fontSize: 14,
                    color: value.isEmpty ? Colors.grey[400] : const Color(0xFF1D1B20),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: Colors.grey[400],
          ),
        ],
      ),
    );
  }
}
