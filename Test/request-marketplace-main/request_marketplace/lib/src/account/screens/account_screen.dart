import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:request_marketplace/src/dashboard/screens/unified_dashboard_screen.dart';
import 'package:request_marketplace/src/chat/screens/conversations_screen.dart';
import 'package:request_marketplace/src/services/auth_service.dart';
import 'package:request_marketplace/src/services/chat_service.dart';
import 'package:request_marketplace/src/services/business_service.dart';
import 'package:request_marketplace/src/models/business_models.dart';
import 'package:request_marketplace/src/screens/simple_business_dashboard.dart';
import 'package:request_marketplace/src/screens/register_business_screen.dart';
import 'package:request_marketplace/src/screens/business_type_selection_screen.dart';
import 'package:request_marketplace/src/auth/screens/welcome_screen.dart';
import 'package:request_marketplace/src/profiles/screens/edit_profile_screen.dart';
import 'package:request_marketplace/src/settings/screens/settings_screen.dart';
import 'package:request_marketplace/src/support/screens/help_support_screen.dart';
import 'package:request_marketplace/src/settings/screens/about_screen.dart';
import 'package:request_marketplace/src/settings/screens/language_settings_screen.dart';
import 'package:request_marketplace/src/screens/activity_center_screen.dart';
import 'package:request_marketplace/src/screens/profile_center_screen.dart';
import 'package:request_marketplace/src/screens/simplified_profile_center_screen.dart';
import 'package:request_marketplace/src/screens/main_dashboard_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final AuthService _authService = AuthService();
  final ChatService _chatService = ChatService();
  final BusinessService _businessService = BusinessService();
  int _unreadCount = 0;
  BusinessProfile? _userBusiness;
  bool _isLoadingBusiness = true;
  String _userName = 'User';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    _checkUserBusiness();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        // First try to get displayName from Firebase Auth
        String? displayName = currentUser.displayName;
        String? email = currentUser.email;
        
        // If no displayName, try to get from Firestore
        if (displayName == null || displayName.isEmpty) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();
          
          if (userDoc.exists) {
            final userData = userDoc.data();
            displayName = userData?['name'] ?? userData?['displayName'];
          }
        }
        
        if (mounted) {
          setState(() {
            _userName = displayName ?? email?.split('@')[0] ?? 'User';
            _userEmail = email ?? '';
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _chatService.getUnreadMessageCount();
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    } catch (e) {
      print('Error loading unread count: $e');
    }
  }

  Future<void> _checkUserBusiness() async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser != null) {
        final business = await _businessService.getBusinessByUserId(currentUser.uid);
        if (mounted) {
          setState(() {
            _userBusiness = business;
            _isLoadingBusiness = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingBusiness = false;
          });
        }
      }
    } catch (e) {
      print('Error checking user business: $e');
      if (mounted) {
        setState(() {
          _isLoadingBusiness = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Account',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1D1B20),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1D1B20),
        elevation: 0,
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Header
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B46C1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: Text(
                      _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _userName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF1D1B20),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _userEmail,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                  ),
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
          
          // Main Menu Items
          _buildMenuItem(
            icon: Icons.dashboard_outlined,
            title: 'Dashboard',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MainDashboardScreen()),
            ),
          ),
          
          _buildMenuItem(
            icon: Icons.chat_bubble_outline,
            title: 'Messages',
            badge: _unreadCount > 0 ? _unreadCount.toString() : null,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ConversationsScreen()),
            ),
          ),
          
          _buildMenuItem(
            icon: Icons.timeline,
            title: 'Activity Center',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ActivityCenterScreen()),
            ),
          ),
          
          _buildMenuItem(
            icon: Icons.account_circle,
            title: 'Profile Center',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SimplifiedProfileCenterScreen()),
            ),
          ),
          
          if (_isLoadingBusiness)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_userBusiness != null)
            _buildMenuItem(
              icon: Icons.business_outlined,
              title: 'My Business - ${_userBusiness!.basicInfo.name}',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SimpleBusinessDashboard(businessId: _userBusiness!.id),
                ),
              ),
            )
          else
            _buildMenuItem(
              icon: Icons.add_business_outlined,
              title: 'Register Business',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BusinessTypeSelectionScreen()),
              ),
            ),
          
          _buildMenuItem(
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
          
          _buildMenuItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HelpSupportScreen()),
            ),
          ),
          
          _buildMenuItem(
            icon: Icons.info_outline,
            title: 'About',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AboutScreen()),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Logout Button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD32F2F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.logout, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? badge,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF666666),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1D1B20),
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD32F2F),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF666666),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
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

    if (confirmed == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          (route) => false,
        );
      }
    }
  }
}
