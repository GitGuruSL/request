import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/enhanced_user_model.dart';

class RoleSelectionScreen extends StatefulWidget {
  final String userId;
  final String? userName;
  final String? userEmail;
  
  const RoleSelectionScreen({
    super.key,
    required this.userId,
    this.userName,
    this.userEmail,
  });

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  final Set<UserType> _selectedRoles = {UserType.consumer}; // Consumer always selected
  UserType _primaryRole = UserType.consumer;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Roles'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.waving_hand,
                    color: Colors.white,
                    size: 32,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Welcome${widget.userName != null ? ', ${widget.userName}!' : '!'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tell us how you plan to use Request. You can always add more roles later!',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Role Selection Title
            const Text(
              'I want to:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Role Options
            _buildRoleOption(
              role: UserType.consumer,
              title: 'Request Items & Services',
              subtitle: 'Buy products, book services, get rides, hire professionals',
              icon: Icons.shopping_cart_outlined,
              color: const Color(0xFF1976D2),
              isAlwaysSelected: true,
            ),
            const SizedBox(height: 12),

            _buildRoleOption(
              role: UserType.business,
              title: 'Run a Business',
              subtitle: 'Sell products, manage inventory, track orders and customers',
              icon: Icons.business_outlined,
              color: const Color(0xFF388E3C),
            ),
            const SizedBox(height: 12),

            _buildRoleOption(
              role: UserType.serviceProvider,
              title: 'Provide Services',
              subtitle: 'Offer professional services, build portfolio, earn money',
              icon: Icons.build_outlined,
              color: const Color(0xFFFF6F00),
            ),
            const SizedBox(height: 12),

            _buildRoleOption(
              role: UserType.driver,
              title: 'Drive & Deliver',
              subtitle: 'Provide ride services, deliver items, earn flexible income',
              icon: Icons.directions_car_outlined,
              color: const Color(0xFF7B1FA2),
            ),
            const SizedBox(height: 32),

            // Primary Role Selection (if multiple selected)
            if (_selectedRoles.length > 1) ...[
              const Text(
                'Primary Role',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose your main focus - this will determine your default dashboard.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: _selectedRoles.map((role) {
                    return RadioListTile<UserType>(
                      title: Text(_getRoleTitle(role)),
                      value: role,
                      groupValue: _primaryRole,
                      onChanged: (value) {
                        setState(() {
                          _primaryRole = value!;
                        });
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Continue Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _continueSetup,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Continue Setup'),
              ),
            ),
            const SizedBox(height: 16),

            // Skip Option
            Center(
              child: TextButton(
                onPressed: _skipForNow,
                child: const Text(
                  'Skip for now - I\'ll set this up later',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleOption({
    required UserType role,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    bool isAlwaysSelected = false,
  }) {
    final isSelected = _selectedRoles.contains(role);
    
    return GestureDetector(
      onTap: isAlwaysSelected ? null : () => _toggleRole(role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey[600],
                size: 28,
              ),
            ),
            const SizedBox(width: 16),

            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? color.withOpacity(0.8) : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Selection Indicator
            if (isAlwaysSelected)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Default',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Icon(
                isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isSelected ? color : Colors.grey[400],
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  void _toggleRole(UserType role) {
    setState(() {
      if (_selectedRoles.contains(role)) {
        _selectedRoles.remove(role);
      } else {
        _selectedRoles.add(role);
      }
      
      // Update primary role if needed
      if (!_selectedRoles.contains(_primaryRole)) {
        _primaryRole = _selectedRoles.first;
      }
    });
  }

  String _getRoleTitle(UserType role) {
    switch (role) {
      case UserType.consumer:
        return 'Customer/Requester';
      case UserType.business:
        return 'Business Owner';
      case UserType.serviceProvider:
        return 'Service Provider';
      case UserType.driver:
        return 'Driver/Delivery';
      case UserType.courier:
        return 'Courier Service';
      case UserType.vanRental:
        return 'Van Rental Service';
      case UserType.hybrid:
        return 'Multiple Roles';
    }
  }

  void _continueSetup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Determine where to navigate based on selected roles
      // Priority: Business > Service Provider > Driver > Consumer only
      
      if (_selectedRoles.contains(UserType.business)) {
        // Navigate to business registration first
        Navigator.pushReplacementNamed(
          context, 
          '/business-setup',
          arguments: {
            'userId': widget.userId,
            'selectedRoles': _selectedRoles.toList(),
            'primaryRole': _primaryRole,
          },
        );
      } else if (_selectedRoles.contains(UserType.serviceProvider)) {
        // Navigate to service provider setup
        Navigator.pushReplacementNamed(
          context, 
          '/service-provider-setup',
          arguments: {
            'userId': widget.userId,
            'selectedRoles': _selectedRoles.toList(),
            'primaryRole': _primaryRole,
          },
        );
      } else if (_selectedRoles.contains(UserType.driver)) {
        // Navigate to driver setup
        Navigator.pushReplacementNamed(
          context, 
          '/driver-setup',
          arguments: {
            'userId': widget.userId,
            'selectedRoles': _selectedRoles.toList(),
            'primaryRole': _primaryRole,
          },
        );
      } else {
        // Only consumer role selected - save user preferences and go to main app
        await _saveConsumerOnlyPreferences();
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveConsumerOnlyPreferences() async {
    try {
      // Save basic user profile with consumer role
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .set({
        'userType': UserType.consumer.name,
        'primaryRole': UserType.consumer.name,
        'selectedRoles': [UserType.consumer.name],
        'profileSetupCompleted': true,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));
      
      print('Consumer-only profile saved successfully');
    } catch (e) {
      print('Error saving consumer profile: $e');
      // Don't throw error, just log it as this is optional
    }
  }

  void _skipForNow() async {
    // Save consumer-only profile and navigate to main app
    await _saveConsumerOnlyPreferences();
    Navigator.pushReplacementNamed(context, '/home');
  }
}
