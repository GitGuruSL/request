import 'package:flutter/material.dart';
import '../models/enhanced_user_model.dart';
import '../services/enhanced_user_service.dart';
import 'src/utils/firebase_shim.dart'; // Added by migration script
// REMOVED_FB_IMPORT: import 'package:firebase_auth/firebase_auth.dart';

class VerificationStatusScreen extends StatefulWidget {
  const VerificationStatusScreen({Key? key}) : super(key: key);

  @override
  State<VerificationStatusScreen> createState() => _VerificationStatusScreenState();
}

class _VerificationStatusScreenState extends State<VerificationStatusScreen> {
  final EnhancedUserService _userService = EnhancedUserService();
  UserModel? _userModel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = RestAuthService.instance.currentUser;
      if (user != null) {
        final userModel = await _userService.getUserById(user.uid);
        setState(() {
          _userModel = userModel;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Verification Status'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.black))
          : _userModel == null
              ? const Center(child: Text('User data not found'))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                left: BorderSide(color: Colors.black, width: 3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userModel!.name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _userModel!.email,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Active Role: ${_getRoleDisplayName(_userModel!.activeRole)}',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          const Text(
            'Your Roles',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Roles List
          ..._userModel!.roles.map((role) => _buildRoleCard(role)).toList(),
          
          if (_userModel!.roles.length < UserRole.values.length) ...[
            const SizedBox(height: 32),
            const Text(
              'Add New Role',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            
            ...UserRole.values.where((role) => !_userModel!.hasRole(role))
                .map((role) => _buildAddRoleCard(role)).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleCard(UserRole role) {
    final roleData = _userModel!.roleData[role];
    final isActive = _userModel!.activeRole == role;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: isActive ? Colors.black : Colors.grey,
          width: isActive ? 2 : 1,
        ),
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
                  color: _getStatusColor(roleData?.verificationStatus),
                ),
                child: Icon(
                  _getRoleIcon(role),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _getRoleDisplayName(role),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isActive ? Colors.black : Colors.black87,
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8, 
                              vertical: 4
                            ),
                            decoration: const BoxDecoration(
                              color: Colors.black,
                            ),
                            child: const Text(
                              'Active',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(roleData?.verificationStatus),
                      ),
                      child: Text(
                        _getStatusText(roleData?.verificationStatus),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              if (!isActive)
                TextButton(
                  onPressed: () => _switchRole(role),
                  child: const Text(
                    'Switch',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
            ],
          ),
          
          if (roleData?.verificationNotes != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.grey,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.black,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      roleData!.verificationNotes!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black,
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
  }

  Widget _buildAddRoleCard(UserRole role) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.5),
        ),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: Colors.grey,
          ),
          child: Icon(
            _getRoleIcon(role),
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          _getRoleDisplayName(role),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        subtitle: const Text(
          'Tap to add this role',
          style: TextStyle(color: Colors.grey),
        ),
        trailing: const Icon(
          Icons.add,
          color: Colors.black,
        ),
        onTap: () => _navigateToRoleSetup(role),
      ),
    );
  }

  String _getRoleDisplayName(UserRole role) {
    switch (role) {
      case UserRole.general:
        return 'General User';
      case UserRole.driver:
        return 'Driver';
      case UserRole.delivery:
        return 'Delivery Partner';
      case UserRole.business:
        return 'Business Owner';
    }
  }

  IconData _getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.general:
        return Icons.person;
      case UserRole.driver:
        return Icons.directions_car;
      case UserRole.delivery:
        return Icons.delivery_dining;
      case UserRole.business:
        return Icons.business;
    }
  }

  Color _getStatusColor(VerificationStatus? status) {
    switch (status) {
      case VerificationStatus.pending:
        return Colors.orange;
      case VerificationStatus.approved:
        return Colors.green;
      case VerificationStatus.rejected:
        return Colors.red;
      case VerificationStatus.notRequired:
      default:
        return Colors.blue;
    }
  }

  String _getStatusText(VerificationStatus? status) {
    switch (status) {
      case VerificationStatus.pending:
        return 'Pending Review';
      case VerificationStatus.approved:
        return 'Verified';
      case VerificationStatus.rejected:
        return 'Rejected';
      case VerificationStatus.notRequired:
      default:
        return 'Active';
    }
  }

  Future<void> _switchRole(UserRole role) async {
    try {
      await _userService.switchActiveRole(_userModel!.id, role);
      await _loadUserData(); // Refresh data
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Switched to ${_getRoleDisplayName(role)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error switching role: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToRoleSetup(UserRole role) {
    String route;
    switch (role) {
      case UserRole.general:
        route = '/main-dashboard';
        break;
      case UserRole.driver:
        route = '/new-driver-verification';
        break;
      case UserRole.delivery:
        route = '/delivery-verification';
        break;
      case UserRole.business:
        route = '/new-business-verification';
        break;
    }
    
    Navigator.pushNamed(context, route);
  }
}
