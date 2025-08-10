import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  bool _emergencyContactsEnabled = true;
  bool _tripSharingEnabled = true;
  bool _safetyCheckInsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Safety Center',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Emergency Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.red.shade600, Colors.red.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.emergency,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Emergency',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap to call emergency services',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _callEmergency(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Call 911',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Safety Features
          _buildSectionHeader('Safety Features'),
          _buildSafetyCard([
            _buildSafetyTile(
              icon: Icons.share_location,
              title: 'Share Trip',
              subtitle: 'Share your trip details with trusted contacts',
              onTap: () => _shareTripDetails(),
            ),
            _buildSafetyTile(
              icon: Icons.contacts,
              title: 'Emergency Contacts',
              subtitle: 'Manage your emergency contact list',
              onTap: () => _manageEmergencyContacts(),
            ),
            _buildSafetyTile(
              icon: Icons.report,
              title: 'Report Safety Incident',
              subtitle: 'Report a safety concern or incident',
              onTap: () => _reportIncident(),
            ),
            _buildSafetyTile(
              icon: Icons.access_time,
              title: 'Safety Check-in',
              subtitle: 'Set automatic safety check-ins',
              onTap: () => _setupSafetyCheckIn(),
            ),
          ]),

          const SizedBox(height: 24),

          // Safety Settings
          _buildSectionHeader('Safety Settings'),
          _buildSafetyCard([
            SwitchListTile(
              title: const Text(
                'Emergency Contacts',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Allow emergency contacts to be notified',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              value: _emergencyContactsEnabled,
              onChanged: (value) => setState(() => _emergencyContactsEnabled = value),
              activeColor: Colors.orange,
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.contact_emergency,
                  color: Colors.orange,
                  size: 24,
                ),
              ),
            ),
            SwitchListTile(
              title: const Text(
                'Trip Sharing',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Automatically share trip details',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              value: _tripSharingEnabled,
              onChanged: (value) => setState(() => _tripSharingEnabled = value),
              activeColor: Colors.blue,
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.share,
                  color: Colors.blue,
                  size: 24,
                ),
              ),
            ),
            SwitchListTile(
              title: const Text(
                'Safety Check-ins',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: Text(
                'Enable automatic safety check-ins',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
              value: _safetyCheckInsEnabled,
              onChanged: (value) => setState(() => _safetyCheckInsEnabled = value),
              activeColor: Colors.green,
              secondary: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 24,
                ),
              ),
            ),
          ]),

          const SizedBox(height: 24),

          // Safety Tips
          _buildSectionHeader('Safety Tips'),
          _buildSafetyCard([
            _buildSafetyTile(
              icon: Icons.lightbulb,
              title: 'Safety Guidelines',
              subtitle: 'Learn about safety best practices',
              onTap: () => _showSafetyGuidelines(),
            ),
            _buildSafetyTile(
              icon: Icons.warning,
              title: 'Safety Warnings',
              subtitle: 'View current safety alerts',
              onTap: () => _showSafetyWarnings(),
            ),
            _buildSafetyTile(
              icon: Icons.school,
              title: 'Safety Training',
              subtitle: 'Learn safety procedures and protocols',
              onTap: () => _showSafetyTraining(),
            ),
          ]),

          const SizedBox(height: 24),

          // Trust & Verification
          _buildSectionHeader('Trust & Verification'),
          _buildSafetyCard([
            _buildSafetyTile(
              icon: Icons.verified_user,
              title: 'Verify Your Identity',
              subtitle: 'Complete identity verification',
              onTap: () => _verifyIdentity(),
            ),
            _buildSafetyTile(
              icon: Icons.rate_review,
              title: 'Rating System',
              subtitle: 'How our rating system works',
              onTap: () => _showRatingInfo(),
            ),
            _buildSafetyTile(
              icon: Icons.security,
              title: 'Background Checks',
              subtitle: 'Learn about our background check process',
              onTap: () => _showBackgroundCheckInfo(),
            ),
          ]),

          const SizedBox(height: 32),

          // Safety Hotline
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.support_agent,
                  size: 48,
                  color: Colors.blue.shade600,
                ),
                const SizedBox(height: 12),
                Text(
                  'Safety Support Hotline',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '24/7 Safety Support Available',
                  style: TextStyle(
                    color: Colors.blue.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _callSafetyHotline(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Call Safety Hotline',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSafetyCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSafetyTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final color = iconColor ?? AppTheme.primaryColor;
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: color,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: AppTheme.textSecondary,
          fontSize: 13,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppTheme.textSecondary,
      ),
      onTap: onTap,
    );
  }

  void _callEmergency() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Call'),
        content: const Text(
          'You are about to call emergency services (911). This will connect you directly to emergency responders.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              launchUrl(Uri.parse('tel:911'));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Call 911'),
          ),
        ],
      ),
    );
  }

  void _callSafetyHotline() {
    launchUrl(Uri.parse('tel:+15551234567'));
  }

  void _shareTripDetails() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share Trip'),
        content: const Text(
          'Share your current trip details with your emergency contacts for added safety.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement trip sharing
            },
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  void _manageEmergencyContacts() {
    // TODO: Navigate to emergency contacts management
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency Contacts'),
        content: const Text('Emergency contacts management will be implemented.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _reportIncident() {
    // TODO: Navigate to incident reporting
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Incident'),
        content: const Text('Incident reporting form will be implemented.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _setupSafetyCheckIn() {
    // TODO: Navigate to safety check-in setup
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Safety Check-in'),
        content: const Text('Safety check-in setup will be implemented.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSafetyGuidelines() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Safety Guidelines'),
        content: const SingleChildScrollView(
          child: Text(
            '• Always verify the identity of service providers\n'
            '• Share your trip details with trusted contacts\n'
            '• Trust your instincts - if something feels wrong, prioritize your safety\n'
            '• Keep your phone charged and accessible\n'
            '• Use in-app communication when possible\n'
            '• Report any safety concerns immediately\n'
            '• Follow local safety regulations and guidelines',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSafetyWarnings() {
    // TODO: Show current safety alerts
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Safety Warnings'),
        content: const Text('No current safety warnings in your area.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSafetyTraining() {
    // TODO: Navigate to safety training modules
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Safety Training'),
        content: const Text('Safety training modules will be implemented.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _verifyIdentity() {
    // TODO: Navigate to identity verification
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Identity Verification'),
        content: const Text('Identity verification process will be implemented.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showRatingInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rating System'),
        content: const Text(
          'Our rating system helps ensure quality and safety by allowing users to rate their experiences. High-rated providers get more visibility, while low-rated providers may face account restrictions.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showBackgroundCheckInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Background Checks'),
        content: const Text(
          'All service providers undergo comprehensive background checks including criminal history, driving records (for drivers), and identity verification to ensure user safety.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
