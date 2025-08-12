import 'package:flutter/material.dart';
import '../services/enhanced_user_service.dart';
import '../models/enhanced_user_model.dart';
import '../theme/app_theme.dart';

class DocumentsVerificationScreen extends StatefulWidget {
  const DocumentsVerificationScreen({Key? key}) : super(key: key);

  @override
  State<DocumentsVerificationScreen> createState() => _DocumentsVerificationScreenState();
}

class _DocumentsVerificationScreenState extends State<DocumentsVerificationScreen> {
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
      print('DEBUG: Loaded user data: ${user?.toMap()}');
      print('DEBUG: User roles: ${user?.roles.map((r) => r.name).toList()}');
      print('DEBUG: User has driver role: ${user?.hasRole(UserRole.driver)}');
      print('DEBUG: User has business role: ${user?.hasRole(UserRole.business)}');
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
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Documents & Verification'),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAccountVerificationSection(),
                    const SizedBox(height: 24),
                    const Text(
                      'Role Verifications',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_currentUser?.hasRole(UserRole.driver) == true)
                      ...[
                        _buildRoleVerificationCard(UserRole.driver),
                        const SizedBox(height: 16),
                      ],
                    if (_currentUser?.hasRole(UserRole.business) == true)
                      ...[
                        _buildRoleVerificationCard(UserRole.business),
                        const SizedBox(height: 16),
                      ],
                    if (_currentUser?.hasRole(UserRole.delivery) == true)
                      ...[
                        _buildRoleVerificationCard(UserRole.delivery),
                        const SizedBox(height: 16),
                      ],
                    // Show message if only general role
                    if (_currentUser != null && _currentUser!.roles.length <= 1 && _currentUser!.roles.contains(UserRole.general))
                      _buildNoRolesCard(),
                    const SizedBox(height: 100), // Bottom padding
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAccountVerificationSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_circle, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Account Verification',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildVerificationDetailItem(
            'Email Verification',
            _currentUser?.isEmailVerified == true,
            _currentUser?.email ?? 'Not provided',
            Icons.email,
          ),
          const SizedBox(height: 12),
          _buildVerificationDetailItem(
            'Phone Verification',
            _currentUser?.isPhoneVerified == true,
            _currentUser?.phoneNumber ?? 'Not provided',
            Icons.phone,
          ),
          const SizedBox(height: 12),
          _buildVerificationDetailItem(
            'Profile Completion',
            _currentUser?.profileComplete == true,
            _currentUser?.profileComplete == true ? 'Complete' : 'Incomplete',
            Icons.person,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleVerificationCard(UserRole role) {
    final roleData = _currentUser?.getRoleInfo(role);
    final verificationStatus = roleData?.verificationStatus;
    
    String roleTitle = _getRoleDisplayName(role);
    String statusText = _getVerificationStatusText(verificationStatus);
    Color statusColor = _getVerificationStatusColor(verificationStatus);
    IconData roleIcon = _getRoleIcon(role);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(roleIcon, size: 28, color: statusColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$roleTitle Verification',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildRoleSpecificDetails(role, verificationStatus),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/verification-status');
                  },
                  icon: const Icon(Icons.visibility, size: 18),
                  label: const Text('View Details'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: statusColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const RoundedRectangleBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _navigateToRoleVerification(role);
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Manage'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.transparent),
                    foregroundColor: statusColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const RoundedRectangleBorder(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoRolesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
      ),
      child: Column(
        children: [
          Icon(
            Icons.add_business,
            size: 48,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Unlock More Features',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add additional roles like Driver, Business, or Delivery Partner to access specialized features and earn more!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/role-management');
              },
              icon: const Icon(Icons.person_add, size: 18),
              label: const Text('Manage Roles'),
              style: AppTheme.primaryButtonStyle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleSpecificDetails(UserRole role, VerificationStatus? status) {
    switch (role) {
      case UserRole.driver:
        return _buildDetailsList([
          _DetailItem('License Document', status == VerificationStatus.approved, 'Required for driving'),
          _DetailItem('Vehicle Registration', status == VerificationStatus.approved, 'Vehicle ownership proof'),
          _DetailItem('Insurance Certificate', status == VerificationStatus.approved, 'Valid insurance coverage'),
          _DetailItem('Vehicle Photos', status == VerificationStatus.approved, 'Clear vehicle images'),
        ]);
      case UserRole.business:
        return _buildDetailsList([
          _DetailItem('Business Registration', status == VerificationStatus.approved, 'Official business documents'),
          _DetailItem('Tax Certificate', false, 'Optional for full verification'),
          _DetailItem('Bank Statement', false, 'Optional for payment processing'),
          _DetailItem('Owner ID', false, 'Optional identity verification'),
        ]);
      case UserRole.delivery:
        return _buildDetailsList([
          _DetailItem('Company Registration', status == VerificationStatus.approved, 'Delivery service license'),
          _DetailItem('Service Capabilities', status == VerificationStatus.approved, 'Available delivery types'),
          _DetailItem('Coverage Areas', status == VerificationStatus.approved, 'Service delivery zones'),
          _DetailItem('Vehicle Information', status == VerificationStatus.approved, 'Delivery vehicle details'),
        ]);
      case UserRole.general:
        return Text(
          'No additional verification required for general users.',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontStyle: FontStyle.italic,
          ),
        );
    }
  }

  Widget _buildDetailsList(List<_DetailItem> items) {
    return Column(
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _buildVerificationDetailItem(
          item.title,
          item.isVerified,
          item.description,
          _getDetailIcon(item.title),
        ),
      )).toList(),
    );
  }

  Widget _buildVerificationDetailItem(String title, bool isVerified, String subtitle, IconData icon) {
    return Row(
      children: [
        Icon(
          isVerified ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 20,
          color: isVerified ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 12),
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _navigateToRoleVerification(UserRole role) {
    switch (role) {
      case UserRole.driver:
        Navigator.pushNamed(context, '/new-driver-verification');
        break;
      case UserRole.business:
        Navigator.pushNamed(context, '/business-verification');
        break;
      case UserRole.delivery:
        Navigator.pushNamed(context, '/delivery-verification');
        break;
      default:
        break;
    }
  }

  IconData _getDetailIcon(String title) {
    if (title.contains('License') || title.contains('Registration')) return Icons.description;
    if (title.contains('Photo') || title.contains('Image')) return Icons.photo_camera;
    if (title.contains('Insurance')) return Icons.security;
    if (title.contains('Tax')) return Icons.receipt;
    if (title.contains('Bank')) return Icons.account_balance;
    if (title.contains('Service') || title.contains('Capabilities')) return Icons.build;
    if (title.contains('Coverage') || title.contains('Areas')) return Icons.map;
    if (title.contains('Vehicle')) return Icons.directions_car;
    if (title.contains('Email')) return Icons.email;
    if (title.contains('Phone')) return Icons.phone;
    if (title.contains('Profile')) return Icons.person;
    return Icons.document_scanner;
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.driver:
        return 'Driver';
      case UserRole.business:
        return 'Business';
      case UserRole.delivery:
        return 'Delivery';
      case UserRole.general:
        return 'General';
    }
  }

  String _getVerificationStatusText(VerificationStatus? status) {
    switch (status) {
      case VerificationStatus.approved:
        return 'Verified';
      case VerificationStatus.pending:
        return 'Pending';
      case VerificationStatus.rejected:
        return 'Rejected';
      case VerificationStatus.notRequired:
        return 'Not Required';
      default:
        return 'Not Started';
    }
  }

  Color _getVerificationStatusColor(VerificationStatus? status) {
    switch (status) {
      case VerificationStatus.approved:
        return Colors.green;
      case VerificationStatus.pending:
        return Colors.orange;
      case VerificationStatus.rejected:
        return Colors.red;
      case VerificationStatus.notRequired:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.driver:
        return Icons.directions_car;
      case UserRole.business:
        return Icons.business;
      case UserRole.delivery:
        return Icons.delivery_dining;
      case UserRole.general:
        return Icons.person;
    }
  }
}

class _DetailItem {
  final String title;
  final bool isVerified;
  final String description;

  _DetailItem(this.title, this.isVerified, this.description);
}
