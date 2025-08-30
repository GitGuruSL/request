import 'package:flutter/material.dart';
import '../theme/glass_theme.dart';
import '../theme/app_theme.dart';

class RoleManagementScreen extends StatefulWidget {
  const RoleManagementScreen({super.key});

  @override
  State<RoleManagementScreen> createState() => _RoleManagementScreenState();
}

class _RoleManagementScreenState extends State<RoleManagementScreen> {
  String? _selectedRole;

  @override
  Widget build(BuildContext context) {
    return GlassTheme.backgroundContainer(
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('Choose Your Role'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppTheme.textPrimary,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                decoration: GlassTheme.glassContainer,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Your Role',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: GlassTheme.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose how you plan to use the Request app. You can change this later.',
                      style: TextStyle(
                        fontSize: 16,
                        color: GlassTheme.colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Role Options
              Expanded(
                child: ListView(
                  children: [
                    // 1. General Responder
                    _buildRoleCard(
                      title: 'General Responder',
                      subtitle: 'Respond to general requests',
                      description:
                          'Answer various types of requests that we specify. Great for earning by helping others with their needs.',
                      icon: Icons.handshake,
                      color: Colors.blue,
                      value: 'general',
                    ),

                    // 2. Business Registration
                    _buildRoleCard(
                      title: 'Register as Business',
                      subtitle: 'Business services & delivery',
                      description:
                          'Get notifications for requests in your business category when you subscribe. Includes delivery services and all business types.',
                      icon: Icons.business,
                      color: Colors.green,
                      value: 'business',
                    ),

                    // 3. Driver
                    _buildRoleCard(
                      title: 'Driver',
                      subtitle: 'Provide ride services',
                      description:
                          'Register as a driver to receive ride requests. Requires verification and proper documentation.',
                      icon: Icons.local_taxi,
                      color: Colors.orange,
                      value: 'driver',
                    ),
                  ],
                ),
              ),

              // Continue Button
              if (_selectedRole != null) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _navigateToRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlassTheme.colors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Continue with Registration',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String title,
    required String subtitle,
    required String description,
    required IconData icon,
    required Color color,
    required String value,
  }) {
    final isSelected = _selectedRole == value;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isSelected
            ? GlassTheme.colors.primaryBlue.withOpacity(0.1)
            : GlassTheme.colors.glassBackground.first,
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedRole = value;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: GlassTheme.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? GlassTheme.colors.primaryBlue
                            : GlassTheme.colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: GlassTheme.colors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Selection indicator
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: GlassTheme.colors.primaryBlue,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToRegistration() {
    if (_selectedRole == null) return;

    // Navigate directly to role-specific registration forms
    switch (_selectedRole) {
      case 'general':
        // For general responders, they can start using the app immediately
        // Just navigate to home with a success message
        _showSuccessAndNavigateHome(
            'General Responder role selected! You can now start responding to requests.');
        break;

      case 'business':
        // Navigate directly to business registration form
        Navigator.pushNamed(context, '/business-registration');
        break;

      case 'driver':
        // Navigate directly to driver registration form
        Navigator.pushNamed(context, '/driver-registration');
        break;
    }
  }

  void _showSuccessAndNavigateHome(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );

    // Navigate to home after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    });
  }
}
