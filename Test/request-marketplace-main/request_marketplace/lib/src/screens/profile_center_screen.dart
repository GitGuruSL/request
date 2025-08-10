import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/business_service.dart';
import '../services/user_service.dart';
import '../models/business_models.dart';
import '../profiles/screens/business_registration_screen.dart';
import 'business_type_selection_screen.dart';
import '../profiles/screens/edit_profile_screen.dart';
import '../drivers/driver_verification_screen.dart';
import '../business/screens/business_dashboard_screen.dart';
import '../business/screens/business_settings_screen.dart';
import '../business/screens/edit_business_screen.dart';
import 'driver_profile_verification_screen.dart' as driver_verification;
import '../services/driver_verification_status_service.dart';

class ProfileCenterScreen extends StatefulWidget {
  const ProfileCenterScreen({super.key});

  @override
  State<ProfileCenterScreen> createState() => _ProfileCenterScreenState();
}

class _ProfileCenterScreenState extends State<ProfileCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _businessService = BusinessService();
  final _driverVerificationStatusService = DriverVerificationStatusService();
  final _userService = UserService();
  List<BusinessProfile> _userBusinesses = [];
  bool _isLoadingBusinesses = true;
  User? _currentUser;
  Map<String, dynamic>? _verificationStatus;
  Map<String, int>? _driverVerificationCounts;
  String? _userDisplayName;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentUser = _auth.currentUser;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    await Future.wait([
      _loadUserBusinesses(),
      _loadVerificationStatus(),
      _loadUserDisplayName(),
      _loadDriverVerificationStatus(),
    ]);
  }

  Future<void> _loadUserDisplayName() async {
    try {
      final userProfile = await _userService.getCurrentUser();
      if (userProfile != null && userProfile.displayName != null) {
        setState(() {
          _userDisplayName = userProfile.displayName;
        });
      }
    } catch (e) {
      print('Error loading user display name: $e');
    }
  }

  Future<void> _loadVerificationStatus() async {
    if (_currentUser != null) {
      try {
        // Check verification status from Firebase
        final phoneNumber = _currentUser?.phoneNumber;
        _verificationStatus = {
          'phoneVerified': phoneNumber != null && phoneNumber.isNotEmpty,
          'emailVerified': _currentUser?.emailVerified ?? false,
        };
        setState(() {});
      } catch (e) {
        print('Error loading verification status: $e');
      }
    }
  }

  Future<void> _loadUserBusinesses() async {
    print('🏢 Loading user business (single business per user)...');
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        print('👤 Current user ID: ${currentUser.uid}');
        
        BusinessProfile? userBusiness;
        
        // Method 1: Check businesses collection first
        print('📋 Method 1: Checking businesses collection...');
        try {
          final businessQuery = await FirebaseFirestore.instance
              .collection('businesses')
              .where('userId', isEqualTo: currentUser.uid)
              .limit(1) // Only get one business
              .get();
          
          if (businessQuery.docs.isNotEmpty) {
            final doc = businessQuery.docs.first;
            final data = doc.data();
            print('✅ Found business in collection: ${data['basicInfo']?['name'] ?? data['businessName'] ?? 'Unknown'}');
            
            // Convert from businesses collection format to BusinessProfile
            userBusiness = BusinessProfile(
              id: doc.id,
              userId: data['userId'] ?? currentUser.uid,
              basicInfo: BusinessBasicInfo(
                name: data['basicInfo']?['name'] ?? data['businessName'] ?? '',
                email: data['basicInfo']?['email'] ?? data['email'] ?? '',
                phone: data['basicInfo']?['phone'] ?? data['phone'] ?? '',
                description: data['basicInfo']?['description'] ?? data['description'] ?? '',
                logoUrl: data['basicInfo']?['logoUrl'] ?? data['logoUrl'] ?? '',
                address: BusinessAddress(
                  street: data['basicInfo']?['address']?['street'] ?? data['businessAddress'] ?? '',
                  city: data['basicInfo']?['address']?['city'] ?? '',
                  state: data['basicInfo']?['address']?['state'] ?? '',
                  country: data['basicInfo']?['address']?['country'] ?? '',
                  postalCode: data['basicInfo']?['address']?['postalCode'] ?? '',
                  latitude: (data['basicInfo']?['address']?['latitude'] ?? data['latitude'] ?? 0.0).toDouble(),
                  longitude: (data['basicInfo']?['address']?['longitude'] ?? data['longitude'] ?? 0.0).toDouble(),
                ),
                businessType: _parseBusinessType(data['basicInfo']?['businessType'] ?? data['businessType']),
                categories: List<String>.from(data['basicInfo']?['categories'] ?? data['businessCategories'] ?? data['categories'] ?? []),
              ),
              verification: BusinessVerification(
                overallStatus: _parseVerificationStatus(data['verification']?['overallStatus'] ?? data['verificationStatus']),
                verifiedAt: _parseDateTime(data['verification']?['verifiedAt'] ?? data['verifiedAt']),
              ),
              businessType: _parseBusinessType(data['basicInfo']?['businessType'] ?? data['businessType']),
              settings: BusinessSettings(
                businessHours: BusinessHours.fromMap(data['settings']?['businessHours'] ?? data['businessHours'] ?? {}),
                notifications: NotificationSettings.fromMap(data['settings']?['notifications'] ?? {}),
              ),
              analytics: BusinessAnalytics.fromMap(data['analytics'] ?? {}),
              subscription: SubscriptionInfo.fromMap(data['subscription'] ?? {}),
              createdAt: _parseDateTime(data['createdAt']) ?? DateTime.now(),
              updatedAt: _parseDateTime(data['updatedAt']) ?? DateTime.now(),
              isActive: data['isActive'] ?? true,
            );
          }
        } catch (businessCollectionError) {
          print('❌ Error querying businesses collection: $businessCollectionError');
        }
        
        // Method 2: If no business in collection, check user document
        if (userBusiness == null) {
          print('📋 Method 2: Checking user document for business profile...');
          try {
            final userDoc = await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .get();
            
            if (userDoc.exists) {
              final userData = userDoc.data() as Map<String, dynamic>;
              final businessProfileData = userData['businessProfile'] as Map<String, dynamic>?;
              
              if (businessProfileData != null) {
                print('✅ Found business profile in user document: ${businessProfileData['businessName']}');
                
                userBusiness = BusinessProfile(
                  id: currentUser.uid, // Use userId as business ID for simplicity
                  userId: currentUser.uid,
                  basicInfo: BusinessBasicInfo(
                    name: businessProfileData['businessName'] ?? '',
                    email: businessProfileData['email'] ?? '',
                    phone: userData['phoneNumber'] ?? '',
                    description: businessProfileData['description'] ?? '',
                    logoUrl: '',
                    address: BusinessAddress(
                      street: businessProfileData['businessAddress'] ?? '',
                      city: '',
                      state: '',
                      country: '',
                      postalCode: '',
                      latitude: (businessProfileData['latitude'] ?? 0.0).toDouble(),
                      longitude: (businessProfileData['longitude'] ?? 0.0).toDouble(),
                    ),
                    businessType: _parseBusinessType(businessProfileData['businessType']),
                    categories: List<String>.from(businessProfileData['businessCategories'] ?? []),
                  ),
                  verification: BusinessVerification(
                    overallStatus: _parseVerificationStatus(businessProfileData['verificationStatus']),
                    verifiedAt: businessProfileData['verificationStatus'] == 'verified'
                        ? _parseDateTime(userData['createdAt'])
                        : null,
                  ),
                  businessType: _parseBusinessType(businessProfileData['businessType']),
                  settings: BusinessSettings(
                    businessHours: BusinessHours.fromMap(businessProfileData['businessHours'] ?? {}),
                    notifications: NotificationSettings.fromMap({}),
                  ),
                  analytics: BusinessAnalytics.fromMap({}),
                  subscription: SubscriptionInfo.fromMap({}),
                  createdAt: _parseDateTime(userData['createdAt']) ?? DateTime.now(),
                  updatedAt: DateTime.now(),
                  isActive: businessProfileData['isActive'] ?? true,
                );
              }
            }
          } catch (userDocError) {
            print('❌ Error reading user document: $userDocError');
          }
        }
        
        print('� User business: ${userBusiness?.basicInfo.name ?? 'None'}');
        
        setState(() {
          _userBusinesses = userBusiness != null ? [userBusiness] : [];
          _isLoadingBusinesses = false;
        });
      } else {
        print('❌ No current user');
        setState(() {
          _isLoadingBusinesses = false;
        });
      }
    } catch (e) {
      print('❌ Error loading user business: $e');
      setState(() {
        _isLoadingBusinesses = false;
      });
    }
  }

  BusinessType _parseBusinessType(String? type) {
    switch (type?.toLowerCase()) {
      case 'retail':
        return BusinessType.retail;
      case 'service':
        return BusinessType.service;
      case 'restaurant':
        return BusinessType.restaurant;
      case 'rental':
        return BusinessType.rental;
      case 'logistics':
        return BusinessType.logistics;
      case 'professional':
        return BusinessType.professional;
      default:
        return BusinessType.service;
    }
  }

  VerificationStatus _parseVerificationStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'verified':
      case 'approved':
        return VerificationStatus.verified;
      case 'pending':
        return VerificationStatus.pending;
      case 'rejected':
        return VerificationStatus.rejected;
      default:
        return VerificationStatus.pending;
    }
  }

  DateTime? _parseDateTime(dynamic dateTime) {
    if (dateTime == null) return null;
    
    try {
      if (dateTime is Timestamp) {
        return dateTime.toDate();
      } else if (dateTime is String) {
        return DateTime.parse(dateTime);
      } else if (dateTime is DateTime) {
        return dateTime;
      }
    } catch (e) {
      print('Error parsing datetime: $e');
    }
    
    return null;
  }

  Future<void> _loadDriverVerificationStatus() async {
    if (_currentUser != null) {
      try {
        final counts = await _driverVerificationStatusService
            .getVerificationCounts(_currentUser!.uid);
        setState(() {
          _driverVerificationCounts = counts;
        });
      } catch (e) {
        print('Error loading driver verification status: $e');
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBFE),
      appBar: AppBar(
        title: const Text('Profile Center'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1D1B20),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Color(0xFF1D1B20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6750A4),
          unselectedLabelColor: const Color(0xFF49454F),
          indicatorColor: const Color(0xFF6750A4),
          tabs: const [
            Tab(text: 'Personal', icon: Icon(Icons.person_outlined)),
            Tab(text: 'Driver', icon: Icon(Icons.drive_eta_outlined)),
            Tab(text: 'Business', icon: Icon(Icons.business_outlined)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPersonalProfileTab(),
          _buildDriverProfileTab(),
          _buildBusinessProfileTab(),
        ],
      ),
    );
  }

  Widget _buildPersonalProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6750A4), Color(0xFF9575CD)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: const Icon(
                    Icons.person,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _getUserDisplayName(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _auth.currentUser?.email ?? 'No email',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Profile Options
          _buildProfileOption(
            icon: Icons.edit,
            title: 'Edit Profile',
            subtitle: 'Update your personal information',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              ).then((_) {
                // Refresh user data when returning from edit profile
                _loadUserData();
              });
            },
          ),
          const SizedBox(height: 12),
          _buildProfileOption(
            icon: Icons.security,
            title: 'Security Settings',
            subtitle: 'Change password, 2FA settings',
            onTap: () {
              _showFeatureComingSoon('Security Settings');
            },
          ),
          const SizedBox(height: 12),
          _buildProfileOption(
            icon: Icons.verified_user,
            title: 'Account Verification',
            subtitle: 'Verify your phone and email',
            onTap: () {
              _showVerificationDetails();
            },
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getVerificationStatusColor().withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getVerificationStatusText(),
                style: TextStyle(
                  color: _getVerificationStatusColor(),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildProfileOption(
            icon: Icons.notifications,
            title: 'Profile Notifications',
            subtitle: 'Profile-specific notification preferences',
            onTap: () {
              _showNotificationInfo();
            },
          ),
          const SizedBox(height: 12),
          _buildProfileOption(
            icon: Icons.privacy_tip,
            title: 'Privacy Settings',
            subtitle: 'Control your data and privacy',
            onTap: () {
              _showFeatureComingSoon('Privacy Settings');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDriverProfileTab() {
    return StreamBuilder<DocumentSnapshot>(
      stream: _currentUser != null
          ? _firestore.collection('drivers').doc(_currentUser!.uid).snapshots()
          : null,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(50),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final driverData = snapshot.hasData && snapshot.data!.exists
            ? snapshot.data!.data() as Map<String, dynamic>?
            : null;

        return Container(
          color: Colors.white, // Keep background white
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Driver Header - Using verification status blue-grey color
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF607D8B), Color(0xFF455A64)], // Blue-grey like verification status
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.drive_eta, color: Colors.white, size: 28),
                    SizedBox(height: 12),
                    Text(
                      'Driver Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Track your verification status and resubmit documents',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Verification Status Overview
              _buildDriverVerificationCard(driverData),
              const SizedBox(height: 20),

              // Document Management
              const Text(
                'Document Verification Status',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1B20),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Track the verification progress of each required document',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),

              // Document List with Status Details
              ..._buildDriverDocumentsList(driverData),

              const SizedBox(height: 24),

              // Upload All Documents Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const driver_verification.DriverProfileVerificationScreen(),
                      ),
                    ).then((_) => _loadUserData());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload_file),
                      SizedBox(width: 8),
                      Text(
                        'Upload/Manage Documents',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Vehicle Information
              const Text(
                'Vehicle Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1B20),
                ),
              ),
              const SizedBox(height: 16),

              _buildDriverVehicleInfoCard(driverData),
            ],
          ),
        ),
        );
      },
    );
  }

  Widget _buildBusinessProfileTab() {
    return RefreshIndicator(
      onRefresh: _loadUserBusinesses,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Business Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.business, color: Colors.white, size: 28),
                  SizedBox(height: 12),
                  Text(
                    'Business Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Manage your businesses and start selling',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // My Business Section
            const Text(
              'My Business',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1D1B20),
              ),
            ),
            const SizedBox(height: 16),

            // Business Cards or Empty State
            if (_isLoadingBusinesses)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (_userBusinesses.isNotEmpty)
              ..._userBusinesses.map((business) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildMyBusinessCard(business),
              )).toList()
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.business_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Businesses Registered',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Register your first business to start selling products and services on the marketplace.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 20),

            // Add New Business Button - Only show if no businesses registered
            if (_userBusinesses.isEmpty) ...[
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF6750A4).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () async {
                      final currentUser = _auth.currentUser;
                      if (currentUser != null) {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BusinessTypeSelectionScreen(),
                          ),
                        );
                        // Refresh the businesses list when returning from registration
                        if (result == true || mounted) {
                          _loadUserBusinesses();
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please log in to register a business'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6750A4).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.add_business,
                              color: Color(0xFF6750A4),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Text(
                              'Register New Business',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF6750A4),
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward,
                            color: Color(0xFF6750A4),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Container(
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
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1B20),
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildVerificationCard() {
    final counts = _driverVerificationCounts ?? {
      'approved': 0,
      'pending': 0,
      'rejected': 0,
      'notSubmitted': 6, // Default 6 documents
      'total': 6,
    };

    final approvedCount = counts['approved'] ?? 0;
    final totalCount = counts['total'] ?? 6;
    final pendingCount = counts['pending'] ?? 0;
    final rejectedCount = counts['rejected'] ?? 0;
    
    final progress = totalCount > 0 ? approvedCount / totalCount : 0.0;
    
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.upload_file;
    String statusText = 'Submit required documents to start driving';
    String mainTitle = 'Driver Verification';
    
    if (rejectedCount > 0) {
      statusColor = Colors.red;
      statusIcon = Icons.error_outline;
      statusText = '$rejectedCount document(s) rejected - resubmit required';
      mainTitle = 'Verification Issues';
    } else if (pendingCount > 0) {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
      statusText = '$pendingCount document(s) under review';
      mainTitle = 'Review in Progress';
    } else if (approvedCount == totalCount && totalCount > 0) {
      statusColor = Colors.green;
      statusIcon = Icons.verified_user;
      statusText = 'All documents verified - you can start driving!';
      mainTitle = 'Verification Complete';
    } else if (approvedCount > 0) {
      statusColor = Colors.blue;
      statusIcon = Icons.upload_file;
      statusText = '$approvedCount of $totalCount documents verified';
      mainTitle = 'Verification in Progress';
    }

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mainTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1D1B20),
                      ),
                    ),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(statusColor),
          ),
          const SizedBox(height: 8),
          Text(
            '$approvedCount of $totalCount documents verified',
            style: const TextStyle(fontSize: 12, color: Color(0xFF49454F)),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard({
    required String title,
    required String status,
    required Color statusColor,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
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
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: statusColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1B20),
          ),
        ),
        subtitle: Text(
          status,
          style: TextStyle(color: statusColor, fontSize: 13),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Widget _buildVehicleInfoCard() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.directions_car,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No Vehicle Registered',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1D1B20),
                      ),
                    ),
                    Text(
                      'Add your vehicle information',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DriverVerificationScreen(),
                    ),
                  );
                },
                child: const Text('Add Vehicle'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMyBusinessCard(BusinessProfile business) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Business Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6750A4), Color(0xFF9575CD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.store,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business.basicInfo.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1D1B20),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      business.basicInfo.categories.isNotEmpty 
                          ? business.basicInfo.categories.join(' • ') 
                          : 'No categories',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Business Contact Information
          if (business.basicInfo.phone.isNotEmpty)
            _buildBusinessDetailItem(Icons.phone, business.basicInfo.phone),
          if (business.basicInfo.phone.isNotEmpty) const SizedBox(height: 8),
          
          if (business.basicInfo.email.isNotEmpty)
            _buildBusinessDetailItem(Icons.email, business.basicInfo.email),
          if (business.basicInfo.email.isNotEmpty) const SizedBox(height: 8),
          
          if (business.basicInfo.address.street.isNotEmpty)
            _buildBusinessDetailItem(
              Icons.location_on, 
              '${business.basicInfo.address.street}, ${business.basicInfo.address.city}'
            ),
          if (business.basicInfo.address.street.isNotEmpty) const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Edit Business',
                  Icons.edit,
                  const Color(0xFF1976D2),
                  () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditBusinessScreen(
                          businessId: business.id,
                          business: business,
                        ),
                      ),
                    );
                    if (result == true) {
                      _loadUserBusinesses(); // Refresh business list
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Settings',
                  Icons.settings,
                  const Color(0xFF6750A4),
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BusinessSettingsScreen(
                          businessId: business.id,
                          initialBusiness: business,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessDetailItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessStatusBadge(String status) {
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (status.toLowerCase()) {
      case 'verified':
        statusColor = Colors.green;
        statusText = 'Verified';
        statusIcon = Icons.verified;
        break;
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Pending';
        statusIcon = Icons.pending;
        break;
      default:
        statusColor = Colors.red;
        statusText = 'Not Verified';
        statusIcon = Icons.warning;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getVerificationStatusText() {
    if (_verificationStatus == null) return 'Loading...';
    
    bool phoneVerified = _verificationStatus!['phoneVerified'] ?? false;
    bool emailVerified = _verificationStatus!['emailVerified'] ?? false;
    
    if (phoneVerified && emailVerified) {
      return 'Verified';
    } else if (phoneVerified || emailVerified) {
      return 'Partial';
    } else {
      return 'Pending';
    }
  }

  Color _getVerificationStatusColor() {
    if (_verificationStatus == null) return Colors.grey;
    
    bool phoneVerified = _verificationStatus!['phoneVerified'] ?? false;
    bool emailVerified = _verificationStatus!['emailVerified'] ?? false;
    
    if (phoneVerified && emailVerified) {
      return Colors.green;
    } else if (phoneVerified || emailVerified) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  Color _getBusinessStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Navigation helper methods
  void _navigateToBusinessRegistration() {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BusinessRegistrationScreen(
            userId: currentUser.uid,
          ),
        ),
      ).then((result) {
        if (result == true || mounted) {
          _loadUserBusinesses();
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to access business features'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _navigateToBusinessDashboard() {
    if (_userBusinesses.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BusinessDashboardScreen(
            businessId: _userBusinesses.first.id,
            business: _userBusinesses.first,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No business found. Please register a business first.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // Helper methods
  String _getUserDisplayName() {
    // First check if we have user profile data from Firestore
    if (_userDisplayName != null && _userDisplayName!.isNotEmpty) {
      return _userDisplayName!;
    }

    final user = _auth.currentUser;
    if (user == null) return 'Guest User';

    // Then try to get display name from Firebase Auth
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }

    // If no display name, try to extract name from email
    if (user.email != null && user.email!.isNotEmpty) {
      // Get part before @ symbol and capitalize it
      String emailPrefix = user.email!.split('@')[0];
      // Replace dots, dashes, underscores with spaces and capitalize first letter
      String formatted = emailPrefix
          .replaceAll(RegExp(r'[._-]'), ' ')
          .split(' ')
          .map((word) => word.isNotEmpty 
              ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
              : word)
          .join(' ');
      return formatted.isNotEmpty ? formatted : 'User';
    }

    // If no display name or email, just return "User" (don't show phone digits)
    return 'User';
  }

  void _showFeatureComingSoon(String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(featureName),
        content: const Text('This feature is coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showNotificationInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profile Notifications'),
        content: const Text(
          'This section manages profile-specific notifications like:\n\n'
          '• Profile verification updates\n'
          '• Business status changes\n'
          '• Driver document approvals\n'
          '• Profile completion reminders\n\n'
          'For general app notifications (messages, orders, etc.), '
          'please check the Account Settings page.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showFeatureComingSoon('Profile Notification Settings');
            },
            child: const Text('Configure'),
          ),
        ],
      ),
    );
  }

  void _showVerificationDetails() {
    String message = '';
    if (_verificationStatus != null) {
      bool phoneVerified = _verificationStatus!['phoneVerified'] ?? false;
      bool emailVerified = _verificationStatus!['emailVerified'] ?? false;

      if (phoneVerified && emailVerified) {
        message = 'Your account is fully verified!\n\n';
      } else {
        message = 'Verification Status:\n\n';
      }

      message += 'Phone: ${phoneVerified ? '✅ Verified' : '❌ Not Verified'}\n';
      message += 'Email: ${emailVerified ? '✅ Verified' : '❌ Not Verified'}';

      if (!phoneVerified || !emailVerified) {
        message += '\n\nPlease complete your verification in Account Settings.';
      }
    } else {
      message = 'Loading verification status...';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account Verification'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessCard(BusinessProfile business) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  business.basicInfo.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF1D1B20),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getBusinessStatusColor(business.verification.overallStatus.name == 'verified' ? 'Verified' : 'Pending').withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  business.verification.overallStatus.name == 'verified' ? 'Verified' : 'Pending',
                  style: TextStyle(
                    color: _getBusinessStatusColor(business.verification.overallStatus.name == 'verified' ? 'Verified' : 'Pending'),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Category: ${business.basicInfo.categories.isNotEmpty ? business.basicInfo.categories.join(', ') : 'No categories'}',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          if (business.basicInfo.address.street.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Address: ${business.basicInfo.address.street}, ${business.basicInfo.address.city}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Email: ${business.basicInfo.email.isNotEmpty ? business.basicInfo.email : 'Not provided'}',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              TextButton(
                onPressed: () {
                  // Navigate to business details
                },
                child: const Text('View Details'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDriverVerificationCard(Map<String, dynamic>? driverData) {
    if (driverData == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          children: [
            Icon(Icons.person_add, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Driver Profile Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a driver profile to start verification',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    final verification = driverData['documentVerification'] as Map<String, dynamic>? ?? {};
    final documents = ['driverPhoto', 'license', 'insurance', 'vehicleRegistration'];
    
    int approved = 0;
    int rejected = 0;
    int pending = 0;
    List<String> rejectedDocs = [];
    
    for (String doc in documents) {
      try {
        final docData = verification[doc] as Map<String, dynamic>?;
        final status = docData?['status']?.toString() ?? 'pending';
        
        if (status == 'approved') {
          approved++;
        } else if (status == 'rejected') {
          rejected++;
          rejectedDocs.add(doc);
        } else {
          pending++;
        }
      } catch (e) {
        print('Error processing document $doc: $e');
        pending++;
      }
    }

    final vehicleImages = driverData['vehicleImageUrls'] as List<dynamic>? ?? [];
    final vehicleCount = vehicleImages.length;
    final isVerified = driverData['isVerified'] == true;
    final progress = documents.isNotEmpty ? approved / documents.length : 0.0;
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    String mainTitle;
    
    if (rejected > 0) {
      statusColor = Colors.red;
      statusIcon = Icons.error_outline;
      statusText = '$rejected document(s) rejected - resubmit required';
      mainTitle = 'Verification Issues';
    } else if (approved == documents.length && vehicleCount >= 4 && isVerified) {
      statusColor = Colors.green;
      statusIcon = Icons.verified_user;
      statusText = 'All documents verified - you can start driving!';
      mainTitle = 'Verification Complete';
    } else if (pending > 0) {
      statusColor = Colors.orange;
      statusIcon = Icons.schedule;
      statusText = '$pending document(s) under review';
      mainTitle = 'Review in Progress';
    } else if (approved > 0) {
      statusColor = Colors.blue;
      statusIcon = Icons.upload_file;
      statusText = '$approved of ${documents.length} documents verified';
      mainTitle = 'Verification in Progress';
    } else {
      statusColor = Colors.grey;
      statusIcon = Icons.upload_file;
      statusText = 'Submit required documents to start driving';
      mainTitle = 'Driver Verification';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  statusIcon,
                  color: statusColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mainTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFF1D1B20),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          
          // Stats Row
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$approved',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      'Approved',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (pending > 0) Expanded(
                child: Column(
                  children: [
                    Text(
                      '$pending',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    Text(
                      'Pending',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (rejected > 0) Expanded(
                child: Column(
                  children: [
                    Text(
                      '$rejected',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    Text(
                      'Rejected',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '${documents.length}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D1B20),
                      ),
                    ),
                    Text(
                      'Total',
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
        ],
      ),
    );
  }

  List<Widget> _buildDriverDocumentsList(Map<String, dynamic>? driverData) {
    if (driverData == null) {
      return [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: const Center(
            child: Text(
              'No driver profile found. Upload documents to get started.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ];
    }

    final verification = driverData['documentVerification'] as Map<String, dynamic>? ?? {};
    
    final documentTitles = {
      'driverPhoto': 'Driver Photo',
      'license': 'Driving License',
      'insurance': 'Insurance Certificate',
      'vehicleRegistration': 'Vehicle Registration',
    };

    final documentIcons = {
      'driverPhoto': Icons.person,
      'license': Icons.credit_card,
      'insurance': Icons.security,
      'vehicleRegistration': Icons.directions_car,
    };

    return documentTitles.entries.map((entry) {
      final docType = entry.key;
      final title = entry.value;
      final icon = documentIcons[docType] ?? Icons.description;
      final docData = verification[docType] as Map<String, dynamic>?;

      String status = 'not_uploaded';
      String? rejectionReason;
      DateTime? submittedAt;
      DateTime? reviewedAt;

      if (docData != null) {
        status = docData['status']?.toString() ?? 'pending';
        rejectionReason = docData['notes']?.toString() ?? docData['reason']?.toString();
        
        try {
          submittedAt = docData['submittedAt'] is Timestamp 
              ? (docData['submittedAt'] as Timestamp).toDate()
              : null;
          reviewedAt = docData['approvedAt'] is Timestamp 
              ? (docData['approvedAt'] as Timestamp).toDate()
              : docData['rejectedAt'] is Timestamp 
                  ? (docData['rejectedAt'] as Timestamp).toDate()
                  : null;
        } catch (e) {
          print('Error parsing dates: $e');
          submittedAt = null;
          reviewedAt = null;
        }
      }

      // Check if document has URL
      String? documentUrl;
      try {
        if (docType == 'driverPhoto') {
          documentUrl = driverData['photoUrl']?.toString();
        } else {
          final documentImageUrls = driverData['documentImageUrls'] as List<dynamic>?;
          if (documentImageUrls != null && documentImageUrls.isNotEmpty) {
            // For now, assume first URL (this could be improved with better mapping)
            documentUrl = documentImageUrls.first?.toString();
          }
        }

        if (documentUrl != null && status == 'not_uploaded') {
          status = 'pending';
        }
      } catch (e) {
        print('Error getting document URL: $e');
        documentUrl = null;
      }

      Color statusColor;
      String statusText;
      IconData statusIcon;

      switch (status) {
        case 'approved':
          statusColor = Colors.green;
          statusText = 'Approved';
          statusIcon = Icons.check_circle;
          break;
        case 'pending':
          statusColor = Colors.orange;
          statusText = 'Under Review';
          statusIcon = Icons.schedule;
          break;
        case 'rejected':
          statusColor = Colors.red;
          statusText = 'Rejected';
          statusIcon = Icons.cancel;
          break;
        default:
          statusColor = Colors.grey;
          statusText = 'Not Submitted';
          statusIcon = Icons.upload_file;
      }

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
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
          children: [
            ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: statusColor, size: 22),
              ),
              title: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFF1D1B20),
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(statusIcon, size: 16, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (submittedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Submitted: ${_formatDriverDate(submittedAt)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (reviewedAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Reviewed: ${_formatDriverDate(reviewedAt)}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
              trailing: status == 'rejected' 
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: const Text(
                      'Resubmit',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
              onTap: () {
                try {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const driver_verification.DriverProfileVerificationScreen(),
                    ),
                  ).then((_) => _loadUserData());
                } catch (e) {
                  print('Error navigating to verification screen: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error opening verification screen: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
            
            // Rejection Reason
            if (status == 'rejected' && 
                rejectionReason != null && 
                rejectionReason.isNotEmpty && 
                rejectionReason != 'Document rejected by admin') ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, 
                            size: 16, color: Colors.red[700]),
                        const SizedBox(width: 6),
                        Text(
                          'Rejection Reason:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      rejectionReason,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          try {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const driver_verification.DriverProfileVerificationScreen(),
                              ),
                            ).then((_) => _loadUserData());
                          } catch (e) {
                            print('Error navigating to verification screen: $e');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error opening verification screen: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: const Text(
                          'Resubmit Document',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }).toList();
  }

  Widget _buildDriverVehicleInfoCard(Map<String, dynamic>? driverData) {
    if (driverData == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: const Center(
          child: Text(
            'No vehicle information available',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final vehicleImages = driverData['vehicleImageUrls'] as List<dynamic>? ?? [];
    final vehicleApprovals = driverData['vehicleImageApprovals'] as List<dynamic>? ?? [];
    
    int approvedCount = 0;
    int rejectedCount = 0;
    int pendingCount = 0;
    List<Map<String, dynamic>> rejectedImages = [];
    
    try {
      for (int i = 0; i < vehicleApprovals.length && i < vehicleImages.length; i++) {
        final approval = vehicleApprovals[i] as Map<String, dynamic>?;
        final status = approval?['status']?.toString();
        
        if (status == 'approved') {
          approvedCount++;
        } else if (status == 'rejected') {
          rejectedCount++;
          rejectedImages.add({
            'index': i + 1,
            'reason': approval?['reason']?.toString() ?? 'No reason provided',
            'timestamp': approval?['timestamp'] != null 
                ? (approval!['timestamp'] as Timestamp).toDate()
                : null,
          });
        } else {
          pendingCount++;
        }
      }
    } catch (e) {
      print('Error calculating vehicle approval counts: $e');
      approvedCount = 0;
      rejectedCount = 0;
      pendingCount = 0;
    }

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.directions_car,
                  color: Colors.blue,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vehicle Images',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1D1B20),
                      ),
                    ),
                    Text(
                      '$approvedCount of ${vehicleImages.length} images approved',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Status Statistics
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$approvedCount',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    Text(
                      'Approved',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (pendingCount > 0)
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$pendingCount',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      Text(
                        'Pending',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              if (rejectedCount > 0)
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        '$rejectedCount',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      Text(
                        'Rejected',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '4',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D1B20),
                      ),
                    ),
                    Text(
                      'Required',
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
          
          // Rejected Images Details
          if (rejectedImages.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700], size: 18),
                      const SizedBox(width: 8),
                      Text(
                        'Rejected Images Details',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...rejectedImages.map((image) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Image ${image['index']}: ',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.red[600],
                          ),
                        ),
                        Expanded(
                          child: Text(
                            image['reason'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
          ],
          
          // Status Messages
          if (approvedCount < 4) ...[
            const SizedBox(height: 16),
            if (rejectedCount > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange[700], size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$rejectedCount image(s) rejected. Please resubmit them to continue.',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                'You need at least 4 approved vehicle images to start driving.',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
          
          // Action Buttons
          if (rejectedCount > 0) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Add safety checks before opening dialog
                  if (rejectedImages.isNotEmpty && _currentUser != null) {
                    _showVehicleImageResubmitDialog(rejectedImages);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Unable to open resubmit dialog. Please try again.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.refresh, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Resubmit Rejected Images ($rejectedCount)',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (vehicleImages.length < 4) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const driver_verification.DriverProfileVerificationScreen(),
                    ),
                  ).then((_) => _loadUserData());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Add Vehicle Images',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
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

  String _formatDriverDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showVehicleImageResubmitDialog(List<Map<String, dynamic>> rejectedImages) {
    // Check if user is authenticated
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication error. Please sign in again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _VehicleImageManagerDialog(
        userId: _currentUser!.uid,
        rejectedImages: rejectedImages,
        onImagesUpdated: () => _loadUserData(),
      ),
    );
  }
}

class _VehicleImageManagerDialog extends StatefulWidget {
  final String userId;
  final List<Map<String, dynamic>> rejectedImages;
  final VoidCallback onImagesUpdated;

  const _VehicleImageManagerDialog({
    required this.userId,
    required this.rejectedImages,
    required this.onImagesUpdated,
  });

  @override
  State<_VehicleImageManagerDialog> createState() => _VehicleImageManagerDialogState();
}

class _VehicleImageManagerDialogState extends State<_VehicleImageManagerDialog> {
  final ImagePicker _picker = ImagePicker();
  bool _uploading = false;
  Map<int, bool> _uploadingImages = {};

  Future<void> _replaceImage(int imageIndex) async {
    try {
      // Validate input
      if (imageIndex < 0 || imageIndex > 3) {
        throw Exception('Invalid image index');
      }
      
      // Check if widget is still mounted before accessing context
      if (!mounted) return;

      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      // Check again if widget is still mounted
      if (!mounted) return;

      setState(() {
        _uploadingImages[imageIndex] = true;
      });

      // Upload to Firebase Storage with better error handling
      final storage = FirebaseStorage.instance;
      final fileName = 'vehicle_images/${widget.userId}/image_${imageIndex + 1}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = storage.ref().child(fileName);
      
      print('Uploading file: ${image.path}');
      print('Storage path: $fileName');
      
      final uploadTask = ref.putFile(File(image.path));
      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();
      
      print('Upload successful, download URL: $downloadUrl');

      // Update Firestore - use direct update instead of transaction for simplicity
      final driverDoc = FirebaseFirestore.instance.collection('drivers').doc(widget.userId);
      
      print('Updating Firestore document: ${widget.userId}');
      
      // First get the current document
      final docSnapshot = await driverDoc.get();
      if (!docSnapshot.exists) {
        throw Exception('Driver profile not found');
      }
      
      final data = docSnapshot.data() as Map<String, dynamic>? ?? {};
      List<dynamic> imageUrls = List.from(data['vehicleImageUrls'] ?? []);
      List<dynamic> approvals = List.from(data['vehicleImageApprovals'] ?? []);
      
      print('Current imageUrls: $imageUrls');
      print('Current approvals: $approvals');
      
      // Ensure we have enough slots
      while (imageUrls.length <= imageIndex) {
        imageUrls.add('');
      }
      while (approvals.length <= imageIndex) {
        approvals.add({
          'status': 'pending',
          'timestamp': Timestamp.now(),
        });
      }
      
      // Update the specific image
      imageUrls[imageIndex] = downloadUrl;
      approvals[imageIndex] = {
        'status': 'pending',
        'timestamp': Timestamp.now(),
        'resubmitted': true,
      };
      
      print('Updating imageUrls: $imageUrls');
      print('Updating approvals: $approvals');
      
      // Update the document
      await driverDoc.update({
        'vehicleImageUrls': imageUrls,
        'vehicleImageApprovals': approvals,
      });
      
      print('Firestore update successful');

      // Call the callback to refresh parent data
      widget.onImagesUpdated();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vehicle image ${imageIndex + 1} uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error replacing image: $e');
      if (mounted) {
        String errorMessage;
        if (e.toString().contains('permission-denied')) {
          errorMessage = 'Permission denied. Please check your account permissions.';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your connection.';
        } else if (e.toString().contains('storage')) {
          errorMessage = 'Storage error. Please try again.';
        } else {
          errorMessage = 'Failed to upload image. Please try again.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploadingImages[imageIndex] = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red),
          SizedBox(width: 8),
          Text('Rejected Vehicle Images'),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The following images were rejected and need to be resubmitted:',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ...widget.rejectedImages.map((image) {
              // Add null safety checks
              final imageIndex = ((image['index'] as int?) ?? 1) - 1; // Convert to 0-based index
              final reason = image['reason']?.toString() ?? 'No reason provided';
              final isUploading = _uploadingImages[imageIndex] == true;
              
              // Ensure imageIndex is valid
              if (imageIndex < 0) {
                return const SizedBox.shrink();
              }
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Vehicle Image ${(image['index'] as int?) ?? 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red[700],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Reason: $reason',
                                style: TextStyle(
                                  color: Colors.red[600],
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: isUploading ? null : () => _replaceImage(imageIndex),
                          icon: isUploading 
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.camera_alt, size: 16),
                          label: Text(isUploading ? 'Uploading...' : 'Replace'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: const Size(0, 36),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tap "Replace" to take a new photo for each rejected image. Make sure the image is clear and shows the vehicle properly.',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
