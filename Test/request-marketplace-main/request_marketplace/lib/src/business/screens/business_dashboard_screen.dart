import 'package:flutter/material.dart';
import '../../models/business_models.dart';
import '../../services/business_service.dart';
import '../screens/business_settings_screen.dart';
import 'manage_products_screen.dart';

class BusinessDashboardScreen extends StatefulWidget {
  final String businessId;
  final BusinessProfile business;

  const BusinessDashboardScreen({
    super.key,
    required this.businessId,
    required this.business,
  });

  @override
  State<BusinessDashboardScreen> createState() => _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> {
  final BusinessService _businessService = BusinessService();
  BusinessProfile? _business;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _business = widget.business;
    _loadBusiness();
  }

  Future<void> _loadBusiness() async {
    try {
      final business = await _businessService.getBusinessProfile(widget.businessId);
      setState(() {
        _business = business ?? widget.business;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading business: $e');
      setState(() {
        _business = widget.business;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFFBFE),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_business == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFFBFE),
        appBar: AppBar(
          title: const Text('Business Dashboard'),
          backgroundColor: Colors.transparent,
          foregroundColor: const Color(0xFF1D1B20),
          elevation: 0,
        ),
        body: const Center(
          child: Text('Business not found'),
        ),
      );
    }

    // Show unified business dashboard for all business types
    return _buildUnifiedBusinessDashboard(_business!);
  }

  Widget _buildUnifiedBusinessDashboard(BusinessProfile business) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBFE),
      appBar: AppBar(
        title: Text('${business.basicInfo.name} Dashboard'),
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF1D1B20),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Color(0xFF1D1B20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Business Info Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
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
                            color: const Color(0xFF6750A4).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.business,
                            color: Color(0xFF6750A4),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                business.basicInfo.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1D1B20),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _getBusinessTypeDisplayName(business.businessType),
                                style: const TextStyle(
                                  color: Color(0xFF6750A4),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (business.basicInfo.description.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        business.basicInfo.description,
                        style: const TextStyle(
                          color: Color(0xFF49454F),
                          fontSize: 16,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Business contact details
                    if (business.basicInfo.phone.isNotEmpty)
                      _buildContactRow(Icons.phone, business.basicInfo.phone),
                    if (business.basicInfo.email.isNotEmpty)
                      _buildContactRow(Icons.email, business.basicInfo.email),
                    if (business.basicInfo.address.street.isNotEmpty)
                      _buildContactRow(Icons.location_on, 
                        '${business.basicInfo.address.street}, ${business.basicInfo.address.city}'),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Business Management Section
              const Text(
                'Business Management',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1B20),
                ),
              ),
              const SizedBox(height: 16),
            
              // Manage Products Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManageProductsScreen(
                          businessId: widget.businessId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.inventory_2, color: Colors.white),
                  label: const Text('Manage Products'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6750A4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Business Settings Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BusinessSettingsScreen(
                          businessId: widget.businessId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.settings, color: Color(0xFF6750A4)),
                  label: const Text('Business Settings'),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6750A4),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF6750A4)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF49454F),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getBusinessTypeDisplayName(BusinessType type) {
    switch (type) {
      case BusinessType.retail:
        return 'Retail Business';
      case BusinessType.restaurant:
        return 'Restaurant';
      case BusinessType.service:
        return 'Service Business';
      case BusinessType.rental:
        return 'Rental Business';
      case BusinessType.logistics:
        return 'Logistics';
      case BusinessType.professional:
        return 'Professional Services';
      default:
        return 'Business';
    }
  }
}
