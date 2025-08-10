import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/business_service.dart';
import '../services/user_service.dart';
import '../services/driver_verification_status_service.dart';
import '../models/business_models.dart';
import '../screens/driver_profile_verification_screen.dart' as driver_verification;
import 'enhanced_user_profile_screen.dart';
import 'enhanced_driver_profile_screen.dart';
import 'business_profile_screen.dart';
import 'business_profile_screen.dart';

class SimplifiedProfileCenterScreen extends StatefulWidget {
  const SimplifiedProfileCenterScreen({super.key});

  @override
  State<SimplifiedProfileCenterScreen> createState() => _SimplifiedProfileCenterScreenState();
}

class _SimplifiedProfileCenterScreenState extends State<SimplifiedProfileCenterScreen> {
  final _auth = FirebaseAuth.instance;
  final _businessService = BusinessService();
  final _driverVerificationStatusService = DriverVerificationStatusService();
  final _userService = UserService();
  
  User? _currentUser;
  String? _userDisplayName;
  bool _isLoading = true;
  
  // Profile status data
  Map<driver_verification.DocumentType, driver_verification.DocumentVerification>? _driverStatus;
  BusinessProfile? _userBusiness;
  Map<String, dynamic>? _personalProfile;

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (_currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      // Load user profile
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();
      
      if (userDoc.exists) {
        _personalProfile = userDoc.data();
        _userDisplayName = _personalProfile?['displayName'] ?? _currentUser!.displayName ?? 'User';
      }

      // Load driver status
      _driverStatus = await _driverVerificationStatusService.getVerificationStatus(_currentUser!.uid);

      // Load business data
      _userBusiness = await _businessService.getUserBusiness(_currentUser!.uid);

    } catch (e) {
      print('Error loading profile data: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Center', style: TextStyle(fontFamily: 'Poppins')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadProfileData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(),
                    const SizedBox(height: 20),
                    _buildProfileOverviewCards(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(
                  (_userDisplayName ?? 'U')[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                        fontFamily: 'Poppins',
                      ),
                    ),
                    Text(
                      _userDisplayName ?? 'User',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Manage your profile, business, and driver verification from here.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOverviewCards() {
    return Column(
      children: [
        _buildProfileCard(
          'Personal Profile',
          'Manage your personal information and account settings',
          Icons.person,
          Colors.green,
          _getPersonalProfileStatus(),
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EnhancedUserProfileScreen(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildProfileCard(
          'Driver Profile',
          'Complete driver verification to start accepting requests',
          Icons.drive_eta,
          Colors.orange,
          _getDriverProfileStatus(),
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const EnhancedDriverProfileScreen(),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildProfileCard(
          'Business Profile',
          'Manage your business information and verification',
          Icons.business,
          Colors.blue,
          _getBusinessProfileStatus(),
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BusinessProfileScreen(
                userId: _currentUser!.uid,
                businessProfile: _userBusiness,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(
    String title,
    String description,
    IconData icon,
    Color color,
    Map<String, dynamic> status,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
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
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatusIndicator(status, color),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(Map<String, dynamic> status, Color color) {
    final percentage = status['percentage'] as double;
    final statusText = status['text'] as String;
    final statusColor = status['color'] as Color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: statusColor,
                fontFamily: 'Poppins',
              ),
            ),
            Text(
              '${(percentage * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: statusColor,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
          minHeight: 4,
        ),
      ],
    );
  }

  Map<String, dynamic> _getPersonalProfileStatus() {
    if (_personalProfile == null) {
      return {
        'percentage': 0.3,
        'text': 'Basic profile created',
        'color': Colors.orange,
      };
    }

    int completedFields = 0;
    int totalFields = 5;

    if (_personalProfile!['displayName']?.isNotEmpty == true) completedFields++;
    if (_personalProfile!['email']?.isNotEmpty == true) completedFields++;
    if (_personalProfile!['phone']?.isNotEmpty == true) completedFields++;
    if (_personalProfile!['address']?.isNotEmpty == true) completedFields++;
    if (_personalProfile!['profileImage']?.isNotEmpty == true) completedFields++;

    final percentage = completedFields / totalFields;

    if (percentage == 1.0) {
      return {
        'percentage': percentage,
        'text': 'Profile completed',
        'color': Colors.green,
      };
    } else if (percentage > 0.5) {
      return {
        'percentage': percentage,
        'text': 'Profile partially completed',
        'color': Colors.orange,
      };
    } else {
      return {
        'percentage': percentage,
        'text': 'Profile needs completion',
        'color': Colors.red,
      };
    }
  }

  Map<String, dynamic> _getDriverProfileStatus() {
    if (_driverStatus == null) {
      return {
        'percentage': 0.0,
        'text': 'Driver profile not started',
        'color': Colors.grey,
      };
    }

    final totalDocs = _driverStatus!.length;
    final verifiedDocs = _driverStatus!.values.where((doc) => doc.status == driver_verification.VerificationStatus.approved).length;
    
    final percentage = totalDocs > 0 ? (verifiedDocs / totalDocs) : 0.0;

    if (percentage == 1.0) {
      return {
        'percentage': percentage,
        'text': 'Driver fully verified',
        'color': Colors.green,
      };
    } else if (percentage > 0) {
      return {
        'percentage': percentage,
        'text': 'Driver verification in progress',
        'color': Colors.orange,
      };
    } else {
      return {
        'percentage': 0.0,
        'text': 'Driver verification pending',
        'color': Colors.red,
      };
    }
  }

  Map<String, dynamic> _getBusinessProfileStatus() {
    if (_userBusiness == null) {
      return {
        'percentage': 0.0,
        'text': 'No business registered',
        'color': Colors.grey,
      };
    }

    int verifiedCount = 0;
    int totalCount = 5;

    if (_userBusiness!.verification.isEmailVerified == true) verifiedCount++;
    if (_userBusiness!.verification.isPhoneVerified == true) verifiedCount++;
    // Add more verification checks based on your business model

    final percentage = verifiedCount / totalCount;

    if (percentage == 1.0) {
      return {
        'percentage': percentage,
        'text': 'Business fully verified',
        'color': Colors.green,
      };
    } else if (percentage > 0) {
      return {
        'percentage': percentage,
        'text': 'Business verification in progress',
        'color': Colors.orange,
      };
    } else {
      return {
        'percentage': 0.0,
        'text': 'Business verification pending',
        'color': Colors.red,
      };
    }
  }
}
