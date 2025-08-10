import 'package:flutter/material.dart';
import '../business/screens/product_search_screen.dart';
import '../business/screens/manage_products_screen.dart';
import '../business/screens/business_settings_screen.dart';
import '../models/business_models.dart';
import '../services/business_service.dart';

class SimpleBusinessDashboard extends StatefulWidget {
  final String businessId;

  const SimpleBusinessDashboard({
    super.key,
    required this.businessId,
  });

  @override
  State<SimpleBusinessDashboard> createState() => _SimpleBusinessDashboardState();
}

class _SimpleBusinessDashboardState extends State<SimpleBusinessDashboard> {
  final BusinessService _businessService = BusinessService();
  BusinessProfile? _business;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBusiness();
  }

  Future<void> _loadBusiness() async {
    try {
      final business = await _businessService.getBusinessProfile(widget.businessId);
      setState(() {
        _business = business;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading business: $e');
      setState(() {
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

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBFE),
      appBar: AppBar(
        title: Text(_business!.basicInfo.name),
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
                    Text(
                      _business!.basicInfo.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1B20),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _business!.basicInfo.description,
                      style: const TextStyle(
                        color: Color(0xFF49454F),
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.email,
                          size: 16,
                          color: Color(0xFF49454F),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _business!.basicInfo.email,
                          style: const TextStyle(color: Color(0xFF49454F)),
                        ),
                      ],
                    ),
                    if (_business!.basicInfo.phone.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.phone,
                            size: 16,
                            color: Color(0xFF49454F),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _business!.basicInfo.phone,
                            style: const TextStyle(color: Color(0xFF49454F)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Verification Status
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
                    const Text(
                      'Verification Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1D1B20),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          _business!.verification.isEmailVerified 
                              ? Icons.check_circle 
                              : Icons.pending,
                          color: _business!.verification.isEmailVerified 
                              ? Colors.green 
                              : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Email: ${_business!.verification.isEmailVerified ? "Verified" : "Pending"}',
                          style: const TextStyle(
                            color: Color(0xFF1D1B20),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _business!.verification.isPhoneVerified 
                              ? Icons.check_circle 
                              : Icons.pending,
                          color: _business!.verification.isPhoneVerified 
                              ? Colors.green 
                              : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Phone: ${_business!.verification.isPhoneVerified ? "Verified" : "Pending"}',
                          style: const TextStyle(
                            color: Color(0xFF1D1B20),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Actions Section Header
              const Text(
                'Business Actions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1B20),
                ),
              ),
              const SizedBox(height: 16),
            
              // Add Products Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductSearchScreen(
                          businessId: widget.businessId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                  label: const Text('Add Products & Pricing'),
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
              
              // Manage Products Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
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
                  icon: const Icon(Icons.inventory, color: Color(0xFF6750A4)),
                  label: const Text('Manage My Products'),
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
}
