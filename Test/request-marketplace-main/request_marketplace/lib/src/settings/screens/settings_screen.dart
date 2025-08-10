import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../legal/screens/privacy_policy_screen.dart';
import '../../legal/screens/terms_of_service_screen.dart';
import 'notification_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1D1B20),
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1D1B20),
        elevation: 0,
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App Settings Section
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 12),
                  child: Text(
                    'App Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationSettingsScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Privacy & Legal Section
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 12),
                  child: Text(
                    'Privacy & Legal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.shield_outlined,
                  title: 'Privacy Policy',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PrivacyPolicyScreen(),
                    ),
                  ),
                ),
                _buildMenuItem(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TermsOfServiceScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // App Version
          const Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(
                color: Color(0xFF666666),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isDestructive ? Colors.red : const Color(0xFF666666),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDestructive ? Colors.red : const Color(0xFF1D1B20),
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF666666),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
