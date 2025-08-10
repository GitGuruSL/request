import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import '../profiles/screens/edit_profile_screen.dart';

class EnhancedUserProfileScreen extends StatefulWidget {
  const EnhancedUserProfileScreen({super.key});

  @override
  State<EnhancedUserProfileScreen> createState() => _EnhancedUserProfileScreenState();
}

class _EnhancedUserProfileScreenState extends State<EnhancedUserProfileScreen> {
  final _userService = UserService();
  final _auth = FirebaseAuth.instance;
  User? _currentUser;
  UserModel? _userProfile;
  bool _isLoading = true;
  Map<String, dynamic> _verificationStatus = {};

  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    
    try {
      _userProfile = await _userService.getCurrentUser();
      await _loadVerificationStatus();
    } catch (e) {
      print('Error loading user data: $e');
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadVerificationStatus() async {
    if (_currentUser != null) {
      try {
        final phoneNumber = _currentUser?.phoneNumber;
        _verificationStatus = {
          'phoneVerified': phoneNumber != null && phoneNumber.isNotEmpty,
          'emailVerified': _currentUser?.emailVerified ?? false,
        };
      } catch (e) {
        print('Error loading verification status: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Profile', style: TextStyle(fontFamily: 'Poppins')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Color(0xFF1D1B20)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 24),
                    _buildVerificationSection(),
                    const SizedBox(height: 24),
                    _buildPersonalInfoSection(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
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
              CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Text(
                  _getUserInitials(),
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
                      _userProfile?.displayName ?? 'User Profile',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentUser?.email ?? 'No email',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
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
            'Manage your personal profile and verification status.',
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

  Widget _buildVerificationSection() {
    final emailVerified = _verificationStatus['emailVerified'] == true;
    final phoneVerified = _verificationStatus['phoneVerified'] == true;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.verified_user,
                  color: Colors.green.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Verification Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildVerificationItem(
            'Email Verification',
            emailVerified,
            Icons.email,
            'Verify your email address',
          ),
          const SizedBox(height: 12),
          _buildVerificationItem(
            'Phone Verification', 
            phoneVerified,
            Icons.phone,
            'Verify your phone number',
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationItem(String title, bool isVerified, IconData icon, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isVerified ? Colors.green.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isVerified ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isVerified ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isVerified ? Colors.green : Colors.grey,
              size: 20,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isVerified ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isVerified ? Colors.green : Colors.grey,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.blue.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Personal Information',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.person, 'Full Name', _userProfile?.displayName ?? 'Not provided'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.email, 'Email', _currentUser?.email ?? 'Not provided'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.phone, 'Phone', _currentUser?.phoneNumber ?? 'Not provided'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.calendar_today, 'Member Since', _formatTimestamp(_userProfile?.createdAt)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
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
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.settings,
                  color: Colors.purple.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              ),
              icon: const Icon(Icons.edit),
              label: const Text('Edit Profile', style: TextStyle(fontFamily: 'Poppins')),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getUserInitials() {
    final displayName = _userProfile?.displayName ?? _currentUser?.email ?? 'U';
    if (displayName.contains(' ')) {
      final names = displayName.split(' ');
      return '${names.first[0]}${names.last[0]}'.toUpperCase();
    }
    return displayName[0].toUpperCase();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not available';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'Not available';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }
}
