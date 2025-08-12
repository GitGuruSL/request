import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/enhanced_user_service.dart';
import '../models/enhanced_user_model.dart';
import '../theme/app_theme.dart';

class RoleManagementScreen extends StatefulWidget {
  const RoleManagementScreen({Key? key}) : super(key: key);

  @override
  _RoleManagementScreenState createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen> {
  final EnhancedUserService _userService = EnhancedUserService();
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Map<UserRole, VerificationStatus> _verificationStatuses = {};

  Future<void> _loadUserData() async {
    try {
      print('🔍 Loading user data...');
      
      UserModel? user;
      try {
        user = await _userService.getCurrentUserModel();
        print('✅ Successfully loaded user model: ${user?.name}');
      } catch (userError) {
        print('❌ Error loading user model: $userError');
        print('📍 User error stack trace: ${StackTrace.current}');
        throw userError;
      }
      
      // Also load verification statuses from the verification collections
      try {
        await _loadVerificationStatuses();
        print('✅ Successfully loaded verification statuses');
      } catch (verificationError) {
        print('❌ Error loading verification statuses: $verificationError');
        print('📍 Verification error stack trace: ${StackTrace.current}');
        // Don't throw here, just log the error
      }
      
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ Error loading user data: $e');
      print('📍 Full error stack trace: $stackTrace');
      
      // Check if it's a casting error
      if (e.toString().contains('is not a subtype of type') && e.toString().contains('List<dynamic>')) {
        print('🎯 Detected List casting error');
        print('🔍 This is likely a Firebase data structure mismatch');
        print('💡 Suggestion: Check Firebase document structure for arrays vs maps');
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Show user-friendly error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading user data. Please try again.'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _loadUserData(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadVerificationStatuses() async {
    try {
      final user = await _userService.getCurrentUser();
      if (user == null) return;

      // Check driver verification status
      try {
        final driverDoc = await FirebaseFirestore.instance
            .collection('new_driver_verifications')
            .doc(user.uid)
            .get();
        
        if (driverDoc.exists) {
          final data = driverDoc.data();
          if (data != null) {
            final status = data['status'] as String? ?? 'pending';
            _verificationStatuses[UserRole.driver] = _parseVerificationStatus(status);
          }
        }
      } catch (e) {
        print('Error loading driver verification status: $e');
      }

      // Check business verification status
      try {
        final businessDoc = await FirebaseFirestore.instance
            .collection('new_business_verifications')
            .doc(user.uid)
            .get();
        
        if (businessDoc.exists) {
          final data = businessDoc.data();
          if (data != null) {
            final status = data['status'] as String? ?? 'pending';
            _verificationStatuses[UserRole.business] = _parseVerificationStatus(status);
          }
        }
      } catch (e) {
        print('Error loading business verification status: $e');
      }
    } catch (e) {
      print('Error loading verification statuses: $e');
    }
  }

  VerificationStatus _parseVerificationStatus(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return VerificationStatus.approved;
      case 'rejected':
        return VerificationStatus.rejected;
      case 'pending':
        return VerificationStatus.pending;
      default:
        return VerificationStatus.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Role Management'),
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
                    const Text(
                      'Your Roles',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage your roles and verification status',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Driver Role Card
                    _buildRoleCard(UserRole.driver),
                    const SizedBox(height: 16),
                    
                    // Business Role Card
                    _buildRoleCard(UserRole.business),
                    const SizedBox(height: 32),
                    
                    // Role Benefits Section
                    _buildRoleBenefitsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildRoleCard(UserRole role) {
    final hasRole = _currentUser?.hasRole(role) == true;
    final roleData = _currentUser?.getRoleInfo(role);
    
    // Check if there's a verification request submitted (even if not officially a role yet)
    final submittedVerificationStatus = _verificationStatuses[role];
    final hasVerificationRequest = submittedVerificationStatus != null;
    
    // Use submitted verification status if available, otherwise use user's role status
    final verificationStatus = submittedVerificationStatus ?? roleData?.verificationStatus;
    
    String roleTitle = _getRoleDisplayName(role);
    String statusText;
    Color statusColor;
    
    if (hasVerificationRequest || hasRole) {
      statusText = _getVerificationStatusText(verificationStatus);
      statusColor = _getVerificationStatusColor(verificationStatus);
    } else {
      statusText = 'Not Registered';
      statusColor = Colors.grey;
    }
    
    IconData roleIcon = _getRoleIcon(role);
    String subtitle = _getRoleSubtitle(role, hasVerificationRequest || hasRole);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(roleIcon, size: 32, color: statusColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      roleTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
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
          
          if (hasVerificationRequest || hasRole) ...[
            const SizedBox(height: 20),
            _buildRoleDetails(role, verificationStatus),
            const SizedBox(height: 20),
            _buildRoleActions(role, hasVerificationRequest, verificationStatus),
          ] else ...[
            const SizedBox(height: 16),
            Text(
              _getRoleDescription(role),
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _registerRole(role),
                icon: const Icon(Icons.add, size: 18),
                label: Text('Register as $roleTitle'),
                style: AppTheme.primaryButtonStyle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleDetails(UserRole role, VerificationStatus? status) {
    List<_RoleRequirement> requirements = _getRoleRequirements(role, status);
    
    return Column(
      children: requirements.map((req) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Icon(
              req.isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 20,
              color: req.isCompleted ? Colors.green : Colors.grey,
            ),
            const SizedBox(width: 12),
            Icon(req.icon, size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                req.title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildRoleActions(UserRole role, bool hasVerificationRequest, VerificationStatus? status) {
    if (role == UserRole.driver || role == UserRole.business) {
      // Driver and Business get simplified single manage icon
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: () => role == UserRole.driver ? _manageDriverDetails() : _manageRole(role),
            icon: const Icon(Icons.settings, size: 24),
            style: IconButton.styleFrom(
              backgroundColor: _getVerificationStatusColor(status),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(12),
            ),
            tooltip: role == UserRole.driver ? 'Manage Driver Profile' : 'Manage Business Profile',
          ),
        ],
      );
    }
    
    // Other roles get full button layout
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _viewRoleDetails(role),
            icon: const Icon(Icons.visibility, size: 18),
            label: const Text('View Details'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getVerificationStatusColor(status),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: const RoundedRectangleBorder(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _manageRole(role),
            icon: const Icon(Icons.settings, size: 18),
            label: const Text('Manage'),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.transparent),
              foregroundColor: _getVerificationStatusColor(status),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: const RoundedRectangleBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoleBenefitsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Role Benefits',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBenefitItem(Icons.directions_car, 'Driver', 'Accept ride requests, earn money driving, flexible schedule'),
          const SizedBox(height: 12),
          _buildBenefitItem(Icons.business, 'Business Owner', 'Post service requests, manage your business, reach more customers'),
          const SizedBox(height: 16),
          Text(
            '💡 Pro Tip: You can be both a Driver and Business Owner to maximize your earning potential!',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _registerRole(UserRole role) {
    switch (role) {
      case UserRole.driver:
        Navigator.pushNamed(context, '/driver-verification').then((_) => _loadUserData());
        break;
      case UserRole.business:
        Navigator.pushNamed(context, '/business-verification').then((_) => _loadUserData());
        break;
      default:
        break;
    }
  }

  void _viewRoleDetails(UserRole role) {
    Navigator.pushNamed(context, '/verification-status');
  }

  void _manageRole(UserRole role) {
    switch (role) {
      case UserRole.driver:
        Navigator.pushNamed(context, '/new-driver-documents-view').then((_) => _loadUserData());
        break;
      case UserRole.business:
        Navigator.pushNamed(context, '/business-documents-view').then((_) => _loadUserData());
        break;
      default:
        break;
    }
  }

  void _manageDriverDetails() {
    Navigator.pushNamed(context, '/driver-documents-view').then((_) => _loadUserData());
  }

  List<_RoleRequirement> _getRoleRequirements(UserRole role, VerificationStatus? status) {
    final isVerified = status == VerificationStatus.approved;
    
    switch (role) {
      case UserRole.driver:
        return [
          _RoleRequirement('License Document', isVerified, Icons.description),
          _RoleRequirement('Vehicle Registration', isVerified, Icons.description),
          _RoleRequirement('Insurance Certificate', isVerified, Icons.security),
          _RoleRequirement('Vehicle Photos', isVerified, Icons.photo_camera),
        ];
      case UserRole.business:
        return [
          _RoleRequirement('Business Registration', isVerified, Icons.business),
          _RoleRequirement('Business Information', isVerified, Icons.info),
          _RoleRequirement('Contact Details', isVerified, Icons.contact_phone),
          _RoleRequirement('Service Categories', isVerified, Icons.category),
        ];
      default:
        return [];
    }
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.driver:
        return 'Driver';
      case UserRole.business:
        return 'Business Owner';
      default:
        return 'Unknown';
    }
  }

  String _getRoleSubtitle(UserRole role, bool hasRole) {
    if (!hasRole) {
      switch (role) {
        case UserRole.driver:
          return 'Drive and earn money with flexible hours';
        case UserRole.business:
          return 'Manage your business and reach customers';
        default:
          return '';
      }
    }
    
    switch (role) {
      case UserRole.driver:
        return 'Accept ride requests and deliveries';
      case UserRole.business:
        return 'Post requests and manage services';
      default:
        return '';
    }
  }

  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.driver:
        return 'As a driver, you can accept ride requests, delivery jobs, and earn money with flexible working hours. Complete verification to start earning.';
      case UserRole.business:
        return 'As a business owner, you can post service requests, manage your business profile, and connect with customers. Choose between service business or delivery business.';
      default:
        return '';
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
      default:
        return Icons.person;
    }
  }
}

class _RoleRequirement {
  final String title;
  final bool isCompleted;
  final IconData icon;

  _RoleRequirement(this.title, this.isCompleted, this.icon);
}
