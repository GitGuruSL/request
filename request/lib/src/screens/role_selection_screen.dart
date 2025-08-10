import 'package:flutter/material.dart';
import '../models/enhanced_user_model.dart';
import '../services/enhanced_user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final EnhancedUserService _userService = EnhancedUserService();
  
  UserRole? selectedRole;
  bool _isLoading = false;
  User? currentUser; // Change to Firebase User instead of EnhancedUserModel
  final bool isInitialSetup = true; // Add this property

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      setState(() {
        currentUser = user;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data: $e')),
      );
    }
  }

  Future<void> _selectRole(UserRole role) async {
    try {
      setState(() => _isLoading = true);

      // Create/add user role
      if (currentUser == null) {
        // Create new user with selected role - this should be handled by auth flow
        throw 'User not authenticated';
      } else {
        // Add role to existing user
        final roleData = {
          'verificationStatus': 'pending',
          'documents': {},
          'completedAt': DateTime.now(),
        };
        
        // For now, just switch to the role - full implementation would add role
        // This is a simplified version
        Navigator.pushReplacementNamed(context, _getRouteForRole(role));
      }

      // Navigate based on role
      // (This is now handled above)
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting role: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getRouteForRole(UserRole role) {
    switch (role) {
      case UserRole.general:
        return '/dashboard';
      case UserRole.driver:
        return '/driver-verification';
      case UserRole.delivery:
        return '/delivery-setup';
      case UserRole.business:
        return '/business-setup';
    }
  }

  void _navigateToRoleSetup() {
    switch (selectedRole!) {
      case UserRole.general:
        Navigator.pushReplacementNamed(context, '/main');
        break;
      case UserRole.driver:
        Navigator.pushReplacementNamed(context, '/driver-setup');
        break;
      case UserRole.delivery:
        Navigator.pushReplacementNamed(context, '/delivery-setup');
        break;
      case UserRole.business:
        Navigator.pushReplacementNamed(context, '/business-setup');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isInitialSetup) ...[
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 16),
                ],
                
                Text(
                  isInitialSetup 
                      ? 'Choose Your Role' 
                      : 'Select Active Role',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  isInitialSetup
                      ? 'How would you like to use Request Marketplace?'
                      : 'Switch to a different role or add a new one',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                if (currentUser != null && !isInitialSetup) ...[
                  _buildCurrentRoleCard(),
                  const SizedBox(height: 24),
                  Text(
                    'Available Roles',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: UserRole.values.map((role) {
                        if (!isInitialSetup && 
                            currentUser != null) {
                          // Skip roles logic for existing users
                          return const SizedBox.shrink();
                        }
                        return _buildRoleCard(role);
                      }).toList(),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: selectedRole != null && !_isLoading 
                        ? () => _selectRole(selectedRole!) 
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            isInitialSetup 
                                ? 'Continue' 
                                : 'Switch Role',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentRoleCard() {
    // Simplified for Firebase User - in a full implementation,
    // you'd fetch the enhanced user model to get role info
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.person,
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
                      'Current: General User',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.verified,
                      size: 16,
                      color: Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Verified',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleCard(UserRole role) {
    final roleInfo = _getRoleInfo(role);
    final isSelected = selectedRole == role;
    // Simplified for Firebase User - always show available roles
    final hasRole = false; // Would need to check enhanced user model
    final isVerified = false; // Would need to check enhanced user model
    
    return GestureDetector(
      onTap: () => setState(() => selectedRole = role),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                roleInfo['icon'],
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 28,
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
                        roleInfo['title'],
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary
                              : Colors.black87,
                        ),
                      ),
                      if (hasRole) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8, 
                            vertical: 4
                          ),
                          decoration: BoxDecoration(
                            color: isVerified ? Colors.green : Colors.orange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isVerified ? 'Verified' : 'Pending',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    roleInfo['description'],
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                  if (roleInfo['features'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Features: ${roleInfo['features'].join(', ')}',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getRoleInfo(UserRole role) {
    switch (role) {
      case UserRole.general:
        return {
          'title': 'General User',
          'description': 'Request items, services, and more from the community',
          'icon': Icons.person,
          'features': ['Make requests', 'Browse marketplace', 'Basic profile'],
        };
      case UserRole.driver:
        return {
          'title': 'Driver',
          'description': 'Provide ride services and transportation',
          'icon': Icons.directions_car,
          'features': ['Ride requests', 'Vehicle management', 'Earnings tracking'],
        };
      case UserRole.delivery:
        return {
          'title': 'Delivery Partner',
          'description': 'Deliver packages and items for others',
          'icon': Icons.delivery_dining,
          'features': ['Delivery jobs', 'Route optimization', 'Fleet management'],
        };
      case UserRole.business:
        return {
          'title': 'Business Owner',
          'description': 'Offer products and services to customers',
          'icon': Icons.business,
          'features': ['Business profile', 'Service listings', 'Customer management'],
        };
    }
  }
}
