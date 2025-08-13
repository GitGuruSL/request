import 'package:flutter/material.dart';
import '../../services/pricing_service.dart';
import '../../theme/app_theme.dart';

class BusinessProfileModal extends StatefulWidget {
  final String businessId;

  const BusinessProfileModal({
    super.key,
    required this.businessId,
  });

  @override
  State<BusinessProfileModal> createState() => _BusinessProfileModalState();
}

class _BusinessProfileModalState extends State<BusinessProfileModal> {
  final PricingService _pricingService = PricingService();
  
  Map<String, dynamic>? _businessProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBusinessProfile();
  }

  Future<void> _loadBusinessProfile() async {
    try {
      final profile = await _pricingService.getBusinessProfile(widget.businessId);
      setState(() {
        _businessProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading business profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.business,
                    color: AppTheme.textPrimary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Business Profile',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: AppTheme.textPrimary),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: _isLoading ? _buildLoadingState() : _buildBusinessInfo(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildBusinessInfo() {
    if (_businessProfile == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text('Business profile not found'),
        ),
      );
    }

    final profile = _businessProfile!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Business logo and name
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey[100],
                child: profile['businessLogo']?.isNotEmpty == true
                    ? ClipOval(
                        child: Image.network(
                          profile['businessLogo'],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Text(
                                (profile['businessName'] as String)[0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        ),
                      )
                    : Text(
                        (profile['businessName'] as String)[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            profile['businessName'] ?? 'Unknown Business',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (profile['isVerified'] == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'VERIFIED',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile['businessCategory'] ?? 'Unknown Category',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Stats
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Products',
                  '${profile['totalListings'] ?? 0}',
                  Icons.inventory,
                  AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Clicks',
                  '${profile['totalClicks'] ?? 0}',
                  Icons.mouse,
                  Colors.orange,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Business description
          if (profile['businessDescription']?.isNotEmpty == true) ...[
            _buildInfoSection(
              'About',
              profile['businessDescription'],
              Icons.info_outline,
            ),
            const SizedBox(height: 20),
          ],
          
          // Contact information
          _buildContactInfo(profile),
          
          const SizedBox(height: 20),
          
          // Join date
          if (profile['joinDate'] != null)
            _buildInfoSection(
              'Member Since',
              _formatDate(profile['joinDate']),
              Icons.calendar_today,
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String content, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildContactInfo(Map<String, dynamic> profile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.contact_phone, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
            const Text(
              'Contact Information',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (profile['businessEmail']?.isNotEmpty == true)
          _buildContactItem(
            Icons.email,
            'Email',
            profile['businessEmail'],
          ),
        
        if (profile['businessPhone']?.isNotEmpty == true)
          _buildContactItem(
            Icons.phone,
            'Phone',
            profile['businessPhone'],
          ),
        
        if (profile['whatsappNumber']?.isNotEmpty == true)
          _buildContactItem(
            Icons.message,
            'WhatsApp',
            profile['whatsappNumber'],
          ),
        
        if (profile['businessAddress']?.isNotEmpty == true)
          _buildContactItem(
            Icons.location_on,
            'Address',
            profile['businessAddress'],
          ),
        
        if (profile['website']?.isNotEmpty == true)
          _buildContactItem(
            Icons.language,
            'Website',
            profile['website'],
          ),
      ],
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[500]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    try {
      if (date == null) return 'Unknown';
      
      DateTime dateTime;
      if (date is String) {
        dateTime = DateTime.parse(date);
      } else {
        dateTime = date;
      }
      
      return '${_getMonthName(dateTime.month)} ${dateTime.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
