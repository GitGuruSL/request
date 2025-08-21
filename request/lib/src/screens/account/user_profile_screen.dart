import 'package:flutter/material.dart';
import '../../services/enhanced_user_service.dart';
import '../../services/rest_auth_service.dart' hide UserModel;
import '../../models/enhanced_user_model.dart';
import 'edit_profile_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final EnhancedUserService _userService = EnhancedUserService();
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _userService.getCurrentUserModel();
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Your profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
              ? const Center(child: Text('Unable to load profile'))
              : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Your information'),
                        const SizedBox(height: 16),
                        _buildProfilePictureItem(),
                        const SizedBox(height: 8),
                        _buildInfoItem(
                          icon: Icons.person_outline,
                          title: 'Full Name',
                          value: _currentUser!.name.isNotEmpty
                              ? _currentUser!.name
                              : 'Not provided',
                          onTap: () => _navigateToEditProfile(),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoItem(
                          icon: Icons.phone_outlined,
                          title: 'Mobile',
                          value: _currentUser!.phoneNumber ?? 'Not provided',
                          isVerified: _currentUser!.isPhoneVerified,
                          verificationStatus: _currentUser!.isPhoneVerified
                              ? 'Verified'
                              : 'Not verified',
                          onTap: () => _handlePhoneVerification(),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoItem(
                          icon: Icons.email_outlined,
                          title: 'E-mail',
                          value: _currentUser!.email,
                          isVerified: _currentUser!.isEmailVerified,
                          verificationStatus: _currentUser!.isEmailVerified
                              ? 'Verified'
                              : 'Not verified',
                          onTap: () => _handleEmailVerification(),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoItem(
                          icon: Icons.cake_outlined,
                          title: 'Birthday',
                          value:
                              'Not provided', // TODO: Add date of birth to user model
                          onTap: () => _navigateToEditProfile(),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoItem(
                          icon: Icons.wc_outlined,
                          title: 'Gender',
                          value:
                              'Not specified', // TODO: Add gender to user model
                          onTap: () => _navigateToEditProfile(),
                        ),
                        const SizedBox(height: 32),
                        _buildSectionTitle('Your preferences'),
                        const SizedBox(height: 16),
                        _buildInfoItem(
                          icon: Icons.language_outlined,
                          title: 'Language',
                          value:
                              'English', // TODO: Add language preference to user model
                          onTap: () => _showLanguageOptions(),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoItem(
                          icon: Icons.emergency_outlined,
                          title: 'Add emergency contact(s)',
                          value: '${_getEmergencyContactsCount()} contacts',
                          onTap: () => _navigateToEmergencyContacts(),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoItem(
                          icon: Icons.settings_outlined,
                          title: 'Additional settings',
                          value: '',
                          onTap: () => _navigateToAdditionalSettings(),
                        ),
                        const SizedBox(height: 40),
                        _buildLogoutButton(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        color: Colors.grey,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildProfilePictureItem() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
      child: Row(
        children: [
          Icon(
            Icons.person_outline,
            color: Colors.grey[600],
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add profile picture',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                if (!_hasProfilePicture()) const SizedBox(height: 4),
                if (!_hasProfilePicture())
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '1',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[200],
            child: Icon(
              Icons.person,
              color: Colors.grey[600],
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    bool? isVerified,
    String? verificationStatus,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.grey[600],
              size: 24,
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
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (isVerified != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isVerified ? Colors.green : Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isVerified ? 'Verified' : 'Not verified',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _handleLogout,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey[300]!),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: const Text(
          'Logout',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  bool _hasProfilePicture() {
    return false; // TODO: Add profile image support
  }

  int _getEmergencyContactsCount() {
    // TODO: Implement emergency contacts count from user model
    return 2; // Placeholder
  }

  void _navigateToEditProfile() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const EditProfileScreen(),
          ),
        )
        .then((_) => _loadUserData()); // Refresh data when coming back
  }

  void _handlePhoneVerification() {
    if (_currentUser!.isPhoneVerified) {
      // Phone already verified, navigate to edit
      _navigateToEditProfile();
    } else {
      // TODO: Navigate to phone verification screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone verification feature coming soon')),
      );
    }
  }

  void _handleEmailVerification() {
    if (_currentUser!.isEmailVerified) {
      // Email already verified, navigate to edit
      _navigateToEditProfile();
    } else {
      // TODO: Navigate to email verification screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email verification feature coming soon')),
      );
    }
  }

  void _showLanguageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Select Language',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('English'),
              leading: const Icon(Icons.check),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              title: const Text('Sinhala'),
              onTap: () {
                // TODO: Implement language change
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              title: const Text('Tamil'),
              onTap: () {
                // TODO: Implement language change
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEmergencyContacts() {
    // TODO: Navigate to emergency contacts screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Emergency contacts feature coming soon')),
    );
  }

  void _navigateToAdditionalSettings() {
    // TODO: Navigate to additional settings screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Additional settings feature coming soon')),
    );
  }

  void _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await RestAuthService.instance.logout();
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error logging out: $e')),
          );
        }
      }
    }
  }
}
