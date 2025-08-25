import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/glass_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: GlassTheme.backgroundGradient,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                GlassTheme.isDarkMode ? Brightness.light : Brightness.dark,
          ),
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios,
              color: GlassTheme.colors.textPrimary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Settings',
            style: GlassTheme.titleLarge,
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // App Preferences Section
              _buildSectionHeader('App Preferences'),
              const SizedBox(height: 12),

              // Theme Setting
              _buildThemeSetting(),
              const SizedBox(height: 12),

              // Language Setting (placeholder)
              _buildLanguageSetting(),
              const SizedBox(height: 12),

              // Notifications Setting
              _buildNotificationsSetting(),
              const SizedBox(height: 24),

              // Account Section
              _buildSectionHeader('Account'),
              const SizedBox(height: 12),

              // Change Password
              _buildChangePasswordSetting(),
              const SizedBox(height: 12),

              // Privacy Setting
              _buildPrivacySetting(),
              const SizedBox(height: 12),

              // Data & Storage
              _buildDataStorageSetting(),
              const SizedBox(height: 24),

              // Support Section
              _buildSectionHeader('Support'),
              const SizedBox(height: 12),

              // Help & Support
              _buildHelpSetting(),
              const SizedBox(height: 12),

              // About
              _buildAboutSetting(),
              const SizedBox(height: 32),

              // App Version
              _buildAppVersion(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GlassTheme.titleMedium.copyWith(
          color: GlassTheme.colors.textAccent,
        ),
      ),
    );
  }

  Widget _buildThemeSetting() {
    return GlassTheme.glassCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: GlassTheme.colors.primaryPurple.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: GlassTheme.colors.primaryPurple.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              GlassTheme.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              color: GlassTheme.colors.primaryPurple,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Theme',
                  style: GlassTheme.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  GlassTheme.isDarkMode ? 'Dark mode' : 'Light mode',
                  style: GlassTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Switch(
            value: GlassTheme.isDarkMode,
            onChanged: (value) {
              setState(() {
                GlassTheme.setTheme(value);
              });
            },
            activeThumbColor: GlassTheme.colors.primaryPurple,
            inactiveThumbColor: GlassTheme.colors.textTertiary,
            inactiveTrackColor:
                GlassTheme.colors.textTertiary.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSetting() {
    return GlassTheme.glassCard(
      child: InkWell(
        onTap: () {
          // TODO: Implement language selection
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Language settings coming soon!',
                style: GlassTheme.bodyMedium.copyWith(color: Colors.white),
              ),
              backgroundColor: GlassTheme.colors.infoColor,
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: GlassTheme.colors.primaryBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: GlassTheme.colors.primaryBlue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.language,
                color: GlassTheme.colors.primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Language',
                    style: GlassTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'English',
                    style: GlassTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: GlassTheme.colors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsSetting() {
    return GlassTheme.glassCard(
      child: InkWell(
        onTap: () {
          // TODO: Navigate to notifications settings
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Notification settings coming soon!',
                style: GlassTheme.bodyMedium.copyWith(color: Colors.white),
              ),
              backgroundColor: GlassTheme.colors.infoColor,
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: GlassTheme.colors.primaryAmber.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: GlassTheme.colors.primaryAmber.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.notifications_outlined,
                color: GlassTheme.colors.primaryAmber,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notifications',
                    style: GlassTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Manage your notification preferences',
                    style: GlassTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: GlassTheme.colors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySetting() {
    return GlassTheme.glassCard(
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, '/privacy-policy');
        },
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: GlassTheme.colors.primaryEmerald.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: GlassTheme.colors.primaryEmerald.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.privacy_tip_outlined,
                color: GlassTheme.colors.primaryEmerald,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privacy & Security',
                    style: GlassTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Control your privacy settings',
                    style: GlassTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: GlassTheme.colors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChangePasswordSetting() {
    return GlassTheme.glassCard(
      child: InkWell(
        onTap: () {
          _showChangePasswordDialog();
        },
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: GlassTheme.colors.primaryBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: GlassTheme.colors.primaryBlue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.lock_outline,
                color: GlassTheme.colors.primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Change Password',
                    style: GlassTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Update your account password',
                    style: GlassTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: GlassTheme.colors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataStorageSetting() {
    return GlassTheme.glassCard(
      child: InkWell(
        onTap: () {
          // TODO: Navigate to data storage settings
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Data & Storage settings coming soon!',
                style: GlassTheme.bodyMedium.copyWith(color: Colors.white),
              ),
              backgroundColor: GlassTheme.colors.infoColor,
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: GlassTheme.colors.primaryTeal.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: GlassTheme.colors.primaryTeal.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.storage_outlined,
                color: GlassTheme.colors.primaryTeal,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data & Storage',
                    style: GlassTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Manage app data and storage',
                    style: GlassTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: GlassTheme.colors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpSetting() {
    return GlassTheme.glassCard(
      child: InkWell(
        onTap: () {
          // TODO: Navigate to help & support
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Help & Support coming soon!',
                style: GlassTheme.bodyMedium.copyWith(color: Colors.white),
              ),
              backgroundColor: GlassTheme.colors.infoColor,
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: GlassTheme.colors.primaryRose.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: GlassTheme.colors.primaryRose.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.help_outline,
                color: GlassTheme.colors.primaryRose,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Help & Support',
                    style: GlassTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Get help and contact support',
                    style: GlassTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: GlassTheme.colors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSetting() {
    return GlassTheme.glassCard(
      child: InkWell(
        onTap: () {
          // TODO: Navigate to about page
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: GlassTheme.isDarkMode
                  ? const Color(0xFF1E293B)
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'About Request App',
                style: GlassTheme.titleMedium,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Version 1.0.0',
                    style: GlassTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'A modern request and response platform built with Flutter.',
                    style: GlassTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '© 2025 Request App. All rights reserved.',
                    style: GlassTheme.bodySmall,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Close',
                    style: GlassTheme.accent,
                  ),
                ),
              ],
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: GlassTheme.colors.primaryBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: GlassTheme.colors.primaryBlue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.info_outline,
                color: GlassTheme.colors.primaryBlue,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: GlassTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'App information and version',
                    style: GlassTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: GlassTheme.colors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppVersion() {
    return Center(
      child: Text(
        'Request App v1.0.0',
        style: GlassTheme.bodySmall.copyWith(
          color: GlassTheme.colors.textTertiary,
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isCurrentPasswordVisible = false;
    bool isNewPasswordVisible = false;
    bool isConfirmPasswordVisible = false;
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Change Password',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Current Password
                TextField(
                  controller: currentPasswordController,
                  obscureText: !isCurrentPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setDialogState(() {
                          isCurrentPasswordVisible = !isCurrentPasswordVisible;
                        });
                      },
                      icon: Icon(
                        isCurrentPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // New Password
                TextField(
                  controller: newPasswordController,
                  obscureText: !isNewPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setDialogState(() {
                          isNewPasswordVisible = !isNewPasswordVisible;
                        });
                      },
                      icon: Icon(
                        isNewPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Confirm Password
                TextField(
                  controller: confirmPasswordController,
                  obscureText: !isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setDialogState(() {
                          isConfirmPasswordVisible = !isConfirmPasswordVisible;
                        });
                      },
                      icon: Icon(
                        isConfirmPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (newPasswordController.text !=
                          confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Passwords do not match'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (newPasswordController.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Password must be at least 6 characters'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      try {
                        // TODO: Implement password change API call
                        await Future.delayed(
                            const Duration(seconds: 2)); // Simulate API call

                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password changed successfully'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to change password: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        if (context.mounted) {
                          setDialogState(() => isLoading = false);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: GlassTheme.colors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Change Password'),
            ),
          ],
        ),
      ),
    );
  }
}
