import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../utils/firebase_shim.dart'; // corrected relative path
import '../services/enhanced_user_service.dart';
import '../services/contact_verification_service.dart';
import '../services/api_client.dart';
import '../models/enhanced_user_model.dart';
import '../theme/app_theme.dart';

class RoleManagementScreen extends StatefulWidget {
  const RoleManagementScreen({Key? key}) : super(key: key);
  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen> {
  final EnhancedUserService _userService = EnhancedUserService();
  UserModel? _currentUser;
  bool _isLoading = true;
  final Map<UserRole, VerificationStatus> _verificationStatuses = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _userService.getCurrentUserModel();
      await _loadVerificationStatuses();
      if (!mounted) return;
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: const Text('Failed to load user data'),
            action: SnackBarAction(label: 'Retry', onPressed: _loadUserData)),
      );
    }
  }

  Future<void> _loadVerificationStatuses() async {
    try {
      final user = await _userService.getCurrentUser();
      if (user == null) return;

      // Driver verification via backend
      try {
        final resp = await ApiClient.instance
            .get('/api/driver-verifications/user/${user.uid}');
        if (kDebugMode)
          print(
              'Driver API response success: ${resp.isSuccess}, data: ${resp.data}');
        if (resp.isSuccess && resp.data != null) {
          final data = resp.data as Map<String, dynamic>;
          if (kDebugMode) print('Driver verification raw: $data');
          final rawStatus =
              (data['status'] ?? 'pending').toString().trim().toLowerCase();
          final isVerifiedFlag =
              data['is_verified'] == true || data['isVerified'] == true;
          if (kDebugMode)
            print(
                'Driver status analysis: rawStatus="$rawStatus", isVerifiedFlag=$isVerifiedFlag, userRoles=${user.roles}');
          var parsed = _parseVerificationStatus(rawStatus);
          if (rawStatus == 'approved' ||
              isVerifiedFlag ||
              user.roles.contains('driver')) {
            parsed = VerificationStatus.approved;
            if (kDebugMode) print('Driver status set to APPROVED');
          } else {
            if (kDebugMode) print('Driver status remains: $parsed');
          }
          _verificationStatuses[UserRole.driver] = parsed;
        } else {
          if (kDebugMode)
            print(
                'Driver API failed or no data: success=${resp.isSuccess}, data=${resp.data}');
        }
      } catch (e) {
        if (kDebugMode) print('Driver status fetch error: $e');
        if (user.roles.contains('driver')) {
          _verificationStatuses[UserRole.driver] = VerificationStatus.approved;
        }
      }

      // Business verification via Firestore (still legacy)
      try {
        final businessDoc = await FirebaseFirestore.instance
            .collection('new_business_verifications')
            .doc(user.uid)
            .get();
        if (businessDoc.exists) {
          final data = businessDoc.data();
          final status = (data['status'] as String? ?? 'pending').toLowerCase();
          final businessType =
              (data['businessType'] as String? ?? '').toLowerCase();
          final contactStatus = await ContactVerificationService.instance
              .getLinkedCredentialsStatus();
          VerificationStatus mapped;
          if (status == 'approved' &&
              contactStatus.businessPhoneVerified &&
              contactStatus.businessEmailVerified) {
            mapped = VerificationStatus.approved;
          } else if (status == 'rejected') {
            mapped = VerificationStatus.rejected;
          } else {
            mapped = VerificationStatus.pending;
          }
          if (businessType == 'delivery') {
            _verificationStatuses[UserRole.delivery] = mapped;
          } else {
            _verificationStatuses[UserRole.business] = mapped;
          }
        }
      } catch (e) {
        if (kDebugMode) print('Business status fetch error: $e');
      }
    } catch (e) {
      if (kDebugMode) print('Verification load error: $e');
    }
  }

  VerificationStatus _parseVerificationStatus(String status) {
    switch (status) {
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
            onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  _isLoading = true;
                });
                _loadUserData();
              })
        ],
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
                    const Text('Your Roles',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary)),
                    const SizedBox(height: 8),
                    Text('Manage your roles and verification status',
                        style: TextStyle(
                            fontSize: 16, color: AppTheme.textSecondary)),
                    const SizedBox(height: 24),
                    _buildRoleCard(UserRole.driver),
                    const SizedBox(height: 16),
                    _buildRoleCard(UserRole.business),
                    const SizedBox(height: 32),
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
    final submittedStatus = _verificationStatuses[role];
    final hasVerificationRequest = submittedStatus != null;
    final verificationStatus = submittedStatus ?? roleData?.verificationStatus;
    final roleTitle = _getRoleDisplayName(role);
    final statusText = hasVerificationRequest || hasRole
        ? _getVerificationStatusText(verificationStatus)
        : 'Not Registered';
    final statusColor = hasVerificationRequest || hasRole
        ? _getVerificationStatusColor(verificationStatus)
        : Colors.grey;
    final roleIcon = _getRoleIcon(role);
    final subtitle = _getRoleSubtitle(role, hasVerificationRequest || hasRole);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: AppTheme.backgroundColor,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(roleIcon, size: 32, color: statusColor),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(roleTitle,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style:
                        TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
              ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: statusColor.withOpacity(0.1),
            child: Text(statusText,
                style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold)),
          )
        ]),
        if (hasVerificationRequest || hasRole) ...[
          const SizedBox(height: 20),
          _buildRoleDetails(role, verificationStatus),
          const SizedBox(height: 20),
          _buildRoleActions(role, hasVerificationRequest, verificationStatus),
        ] else ...[
          const SizedBox(height: 16),
          Text(_getRoleDescription(role),
              style: TextStyle(
                  fontSize: 14, color: AppTheme.textSecondary, height: 1.4)),
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
        ]
      ]),
    );
  }

  Widget _buildRoleDetails(UserRole role, VerificationStatus? status) {
    final reqs = _getRoleRequirements(role, status);
    return Column(
      children: reqs
          .map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Icon(
                      r.isCompleted
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 20,
                      color: r.isCompleted ? Colors.green : Colors.grey),
                  const SizedBox(width: 12),
                  Icon(r.icon, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(r.title,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textPrimary)))
                ]),
              ))
          .toList(),
    );
  }

  Widget _buildRoleActions(
      UserRole role, bool hasVerificationRequest, VerificationStatus? status) {
    if (role == UserRole.driver ||
        role == UserRole.business ||
        role == UserRole.delivery) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: () => role == UserRole.driver
                ? _manageDriverDetails()
                : _manageRole(role),
            icon: const Icon(Icons.settings, size: 24),
            style: IconButton.styleFrom(
              backgroundColor: _getVerificationStatusColor(status),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(12),
            ),
            tooltip: role == UserRole.driver
                ? 'Manage Driver Profile'
                : role == UserRole.delivery
                    ? 'Manage Delivery Profile'
                    : 'Manage Business Profile',
          )
        ],
      );
    }
    return Row(children: [
      Expanded(
          child: ElevatedButton.icon(
        onPressed: () => _viewRoleDetails(role),
        icon: const Icon(Icons.visibility, size: 18),
        label: const Text('View Details'),
        style: ElevatedButton.styleFrom(
            backgroundColor: _getVerificationStatusColor(status),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: const RoundedRectangleBorder()),
      )),
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
            shape: const RoundedRectangleBorder()),
      ))
    ]);
  }

  Widget _buildRoleBenefitsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: AppTheme.primaryColor.withOpacity(0.05),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.star, color: AppTheme.primaryColor, size: 24),
          const SizedBox(width: 12),
          const Text('Role Benefits',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary))
        ]),
        const SizedBox(height: 16),
        _buildBenefitItem(Icons.directions_car, 'Driver',
            'Accept ride requests, earn money driving, flexible schedule'),
        const SizedBox(height: 12),
        _buildBenefitItem(Icons.business, 'Business Owner',
            'Post service requests, manage your business, reach more customers'),
        const SizedBox(height: 16),
        Text(
            'Pro Tip: You can be both a Driver and Business Owner to maximize your earning potential!',
            style: TextStyle(
                fontSize: 14,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic)),
      ]),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String description) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 20, color: AppTheme.primaryColor),
      const SizedBox(width: 12),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary)),
        Text(description,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary))
      ]))
    ]);
  }

  void _registerRole(UserRole role) {
    if (role == UserRole.driver) {
      Navigator.pushNamed(context, '/driver-verification')
          .then((_) => _loadUserData());
    } else if (role == UserRole.business) {
      Navigator.pushNamed(context, '/business-registration')
          .then((_) => _loadUserData());
    }
  }

  void _viewRoleDetails(UserRole role) {
    Navigator.pushNamed(context, '/verification-status');
  }

  void _manageRole(UserRole role) {
    switch (role) {
      case UserRole.driver:
        Navigator.pushNamed(context, '/driver-documents-view')
            .then((_) => _loadUserData());
        break;
      case UserRole.business:
        Navigator.pushNamed(context, '/business-verification')
            .then((_) => _loadUserData());
        break;
      case UserRole.delivery:
        Navigator.pushNamed(context, '/delivery-verification')
            .then((_) => _loadUserData());
        break;
      default:
        break;
    }
  }

  void _manageDriverDetails() {
    Navigator.pushNamed(context, '/driver-documents-view')
        .then((_) => _loadUserData());
  }

  List<_RoleRequirement> _getRoleRequirements(
      UserRole role, VerificationStatus? status) {
    final isVerified = status == VerificationStatus.approved;
    switch (role) {
      case UserRole.driver:
        return [
          _RoleRequirement('License Document', isVerified, Icons.description),
          _RoleRequirement(
              'Vehicle Registration', isVerified, Icons.description),
          _RoleRequirement('Insurance Certificate', isVerified, Icons.security),
          _RoleRequirement('Vehicle Photos', isVerified, Icons.photo_camera),
        ];
      case UserRole.business:
        return [
          _RoleRequirement('Business Registration', isVerified, Icons.business),
          _RoleRequirement(
              'Contact Verification', isVerified, Icons.verified_user),
          _RoleRequirement('Business Documents', isVerified, Icons.description),
          _RoleRequirement('Business Profile', isVerified, Icons.store),
        ];
      case UserRole.delivery:
        return [
          _RoleRequirement(
              'Company Registration', isVerified, Icons.local_shipping),
          _RoleRequirement(
              'Contact Verification', isVerified, Icons.verified_user),
          _RoleRequirement('Service Capabilities', isVerified, Icons.settings),
          _RoleRequirement(
              'Vehicle Documentation', isVerified, Icons.description),
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
      case UserRole.delivery:
        return 'Delivery';
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
        case UserRole.delivery:
          return 'Provide delivery services';
        default:
          return '';
      }
    }
    switch (role) {
      case UserRole.driver:
        return 'Accept ride requests and deliveries';
      case UserRole.business:
        return 'Post requests and manage services';
      case UserRole.delivery:
        return 'Manage delivery capabilities';
      default:
        return '';
    }
  }

  String _getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.driver:
        return 'As a driver, you can accept ride requests, delivery jobs, and earn money with flexible hours.';
      case UserRole.business:
        return 'As a business owner, you can post service requests and reach customers.';
      case UserRole.delivery:
        return 'As a delivery partner, you can accept delivery requests and manage capabilities.';
      default:
        return '';
    }
  }

  String _getVerificationStatusText(VerificationStatus? status) {
    switch (status) {
      case VerificationStatus.approved:
        return 'Approved';
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
      case UserRole.delivery:
        return Icons.local_shipping;
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
