import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../../models/business_models.dart';
import '../../services/business_service.dart';
import '../../services/unified_otp_service.dart';
import '../../widgets/unified_otp_widget.dart';

class BusinessSettingsScreen extends StatefulWidget {
  final String businessId;
  final BusinessProfile? initialBusiness;

  const BusinessSettingsScreen({
    super.key,
    required this.businessId,
    this.initialBusiness,
  });

  @override
  State<BusinessSettingsScreen> createState() => _BusinessSettingsScreenState();
}

class _BusinessSettingsScreenState extends State<BusinessSettingsScreen> {
  final BusinessService _businessService = BusinessService();
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _addressController = TextEditingController();
  final _websiteController = TextEditingController();
  
  BusinessProfile? _business;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingLogo = false;
  
  // Settings
  bool _allowOnlineOrders = true;
  bool _acceptCashOnDelivery = true;
  bool _acceptCardPayments = false;
  bool _offerHomeDelivery = true;
  bool _allowStorePickup = true;
  bool _notifyOnNewOrders = true;
  bool _notifyOnLowStock = true;
  
  double _minimumOrderAmount = 0.0;
  double _deliveryFee = 0.0;
  int _deliveryRadius = 10; // km

  @override
  void initState() {
    super.initState();
    _loadBusinessProfile();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    _addressController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _loadBusinessProfile() async {
    print('🔧 BusinessSettingsScreen: Loading business with ID: ${widget.businessId}');
    
    setState(() {
      _isLoading = true;
    });

    try {
      BusinessProfile? business;
      
      // First, try to use the passed business object if available
      if (widget.initialBusiness != null) {
        print('🔧 BusinessSettingsScreen: Using passed business object: ${widget.initialBusiness!.basicInfo.name}');
        business = widget.initialBusiness;
      } else {
        // Fall back to loading from Firestore
        print('🔧 BusinessSettingsScreen: Loading from Firestore...');
        business = await _businessService.getBusinessProfile(widget.businessId);
      }
      
      print('🔧 BusinessSettingsScreen: Business loaded: ${business?.basicInfo.name ?? 'null'}');
      
      if (business != null) {
        print('🔧 BusinessSettingsScreen: Business details:');
        print('   - Name: ${business.basicInfo.name}');
        print('   - Email: ${business.basicInfo.email}');
        print('   - Phone: ${business.basicInfo.phone}');
        print('   - Address: ${business.basicInfo.address.street}');
        
        setState(() {
          _business = business;
          _businessNameController.text = business!.basicInfo.name;
          _descriptionController.text = business.basicInfo.description;
          // Remove country code prefix if it exists since we add it in the UI
          String phoneNumber = business.basicInfo.phone;
          if (phoneNumber.startsWith('+94')) {
            phoneNumber = phoneNumber.substring(3).trim();
          }
          _phoneController.text = phoneNumber;
          
          String? whatsappNumber = business.basicInfo.whatsapp;
          if (whatsappNumber != null && whatsappNumber.startsWith('+94')) {
            whatsappNumber = whatsappNumber.substring(3).trim();
          }
          _whatsappController.text = whatsappNumber ?? '';
          
          _addressController.text = business.basicInfo.address.fullAddress.isNotEmpty 
              ? business.basicInfo.address.fullAddress 
              : business.basicInfo.address.street;
          _websiteController.text = business.basicInfo.website ?? '';
          
          // Load settings from business profile if available
          _loadBusinessSettings(business);
        });
        
        // Auto-verify email if it matches the logged-in user's email
        _checkAutoVerifyEmail(business);
      } else {
        print('❌ BusinessSettingsScreen: No business found with ID: ${widget.businessId}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business not found. Please try again.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('❌ BusinessSettingsScreen: Error loading business profile: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading business profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadBusinessSettings(BusinessProfile business) {
    // Load settings from business profile
    // These would typically be stored in a separate settings document
    // For now, using default values
    setState(() {
      _allowOnlineOrders = true;
      _acceptCashOnDelivery = true;
      _acceptCardPayments = false;
      _offerHomeDelivery = true;
      _allowStorePickup = true;
      _notifyOnNewOrders = true;
      _notifyOnLowStock = true;
      _minimumOrderAmount = 0.0;
      _deliveryFee = 200.0;
      _deliveryRadius = 10;
    });
  }

  Future<void> _saveBusinessInfo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Ensure phone numbers have proper country code format
      String phoneNumber = _phoneController.text.trim();
      if (!phoneNumber.startsWith('+94')) {
        phoneNumber = '+94$phoneNumber';
      }
      
      String whatsappNumber = _whatsappController.text.trim();
      if (whatsappNumber.isNotEmpty && !whatsappNumber.startsWith('+94')) {
        whatsappNumber = '+94$whatsappNumber';
      }

      // Update business basic info
      Map<String, dynamic> updateData = {
        'basicInfo.name': _businessNameController.text.trim(),
        'basicInfo.description': _descriptionController.text.trim(),
        'basicInfo.phone': phoneNumber,
        'basicInfo.whatsapp': whatsappNumber.isEmpty ? null : whatsappNumber,
        'basicInfo.address.street': _addressController.text.trim(),
        'basicInfo.website': _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
        'updatedAt': Timestamp.now(),
      };

      // Reset phone verification if phone number changed
      if (_business!.basicInfo.phone != phoneNumber) {
        updateData['verification.isPhoneVerified'] = false;
      }

      await FirebaseFirestore.instance
          .collection('businesses')
          .doc(widget.businessId)
          .update(updateData);

      // Reload business profile to refresh verification status
      await _loadBusinessProfile();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Business information updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error updating business info: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating business info: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _saveBusinessSettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // Save business settings to a separate document
      await FirebaseFirestore.instance
          .collection('business_settings')
          .doc(widget.businessId)
          .set({
        'businessId': widget.businessId,
        'allowOnlineOrders': _allowOnlineOrders,
        'acceptCashOnDelivery': _acceptCashOnDelivery,
        'acceptCardPayments': _acceptCardPayments,
        'offerHomeDelivery': _offerHomeDelivery,
        'allowStorePickup': _allowStorePickup,
        'notifyOnNewOrders': _notifyOnNewOrders,
        'notifyOnLowStock': _notifyOnLowStock,
        'minimumOrderAmount': _minimumOrderAmount,
        'deliveryFee': _deliveryFee,
        'deliveryRadius': _deliveryRadius,
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Business settings saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error saving business settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving settings: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
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

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBFE),
      appBar: AppBar(
        title: const Text('Business Settings'),
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
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Container(
              color: Colors.transparent,
              child: TabBar(
                labelColor: const Color(0xFF6750A4),
                unselectedLabelColor: const Color(0xFF49454F),
                indicatorColor: const Color(0xFF6750A4),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: 'Business Info', icon: Icon(Icons.business)),
                  Tab(text: 'Settings', icon: Icon(Icons.settings)),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildBusinessInfoTab(),
                  _buildSettingsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Verification Status Section
            const Text(
              'Verification Status',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D1B20),
              ),
            ),
            const SizedBox(height: 16),
            
            if (_business != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Column(
                  children: [
                    // Email Verification
                    Row(
                      children: [
                        Icon(
                          _business!.verification.isEmailVerified 
                              ? Icons.verified 
                              : Icons.warning,
                          color: _business!.verification.isEmailVerified 
                              ? Colors.green 
                              : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Email: ${_business!.basicInfo.email}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1D1B20),
                            ),
                          ),
                        ),
                        if (!_business!.verification.isEmailVerified) ...[
                          TextButton(
                            onPressed: _sendEmailVerification,
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF6750A4),
                            ),
                            child: const Text('Send Verification'),
                          ),
                          TextButton(
                            onPressed: _markEmailAsVerified,
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF6750A4),
                            ),
                            child: const Text('Already Verified?'),
                          ),
                        ],
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Phone Verification
                    Row(
                      children: [
                        Icon(
                          _business!.verification.isPhoneVerified 
                              ? Icons.verified 
                              : Icons.warning,
                          color: _business!.verification.isPhoneVerified 
                              ? Colors.green 
                              : Colors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Phone: ${_business!.basicInfo.phone}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF1D1B20),
                            ),
                          ),
                        ),
                        if (!_business!.verification.isPhoneVerified) ...[
                          TextButton(
                            onPressed: _sendPhoneVerification,
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF6750A4),
                            ),
                            child: const Text('Verify Phone'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
            ],
            
            const Text(
              'Basic Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1D1B20),
              ),
            ),
            const SizedBox(height: 16),
            
            // Business Logo Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.business_center,
                        color: Color(0xFF6750A4),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Business Logo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1D1B20),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      // Current Logo Display
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F2FA),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _business?.basicInfo.logoUrl != null && _business!.basicInfo.logoUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  _business!.basicInfo.logoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.business, size: 40, color: Color(0xFF6750A4)),
                                ),
                              )
                            : const Icon(Icons.business, size: 40, color: Color(0xFF6750A4)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Upload your business logo to make it easier for customers to recognize your business.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF49454F),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: _isUploadingLogo ? null : _uploadBusinessLogo,
                              icon: _isUploadingLogo 
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.upload, color: Colors.white),
                              label: Text(_isUploadingLogo ? 'Uploading...' : 'Upload Logo'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6750A4),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Business Name
            TextFormField(
              controller: _businessNameController,
              decoration: const InputDecoration(
                labelText: 'Business Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                labelStyle: TextStyle(color: Color(0xFF49454F)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Business name is required';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                labelStyle: TextStyle(color: Color(0xFF49454F)),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Description is required';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Phone
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                labelStyle: TextStyle(color: Color(0xFF49454F)),
                prefixText: '+94 ',
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Phone number is required';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // WhatsApp
            TextFormField(
              controller: _whatsappController,
              decoration: const InputDecoration(
                labelText: 'WhatsApp Number (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                labelStyle: TextStyle(color: Color(0xFF49454F)),
                prefixText: '+94 ',
              ),
              keyboardType: TextInputType.phone,
            ),
            
            const SizedBox(height: 16),
            
            // Address
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Business Address (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                labelStyle: TextStyle(color: Color(0xFF49454F)),
              ),
              maxLines: 2,
            ),
            
            const SizedBox(height: 16),
            
            // Website
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(
                labelText: 'Website (Optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                labelStyle: TextStyle(color: Color(0xFF49454F)),
                prefixText: 'https://',
              ),
              keyboardType: TextInputType.url,
            ),
            
            const SizedBox(height: 24),
            
            // Save Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveBusinessInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6750A4),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save Business Info',
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
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Settings
          _buildSettingsSection(
            'Order Settings',
            [
              _buildSwitchTile(
                'Allow Online Orders',
                'Customers can place orders through the app',
                _allowOnlineOrders,
                (value) => setState(() => _allowOnlineOrders = value),
              ),
              _buildSwitchTile(
                'Accept Cash on Delivery',
                'Allow customers to pay when they receive the order',
                _acceptCashOnDelivery,
                (value) => setState(() => _acceptCashOnDelivery = value),
              ),
              _buildSwitchTile(
                'Accept Card Payments',
                'Accept online card payments (requires setup)',
                _acceptCardPayments,
                (value) => setState(() => _acceptCardPayments = value),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Delivery Settings
          _buildSettingsSection(
            'Delivery Settings',
            [
              _buildSwitchTile(
                'Offer Home Delivery',
                'Deliver products to customer addresses',
                _offerHomeDelivery,
                (value) => setState(() => _offerHomeDelivery = value),
              ),
              _buildSwitchTile(
                'Allow Store Pickup',
                'Customers can collect orders from your store',
                _allowStorePickup,
                (value) => setState(() => _allowStorePickup = value),
              ),
              if (_offerHomeDelivery) ...[
                const SizedBox(height: 16),
                _buildNumberField(
                  'Delivery Fee (Rs.)',
                  _deliveryFee,
                  (value) => setState(() => _deliveryFee = value),
                ),
                const SizedBox(height: 16),
                _buildNumberField(
                  'Delivery Radius (km)',
                  _deliveryRadius.toDouble(),
                  (value) => setState(() => _deliveryRadius = value.round()),
                ),
              ],
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Order Limits
          _buildSettingsSection(
            'Order Limits',
            [
              _buildNumberField(
                'Minimum Order Amount (Rs.)',
                _minimumOrderAmount,
                (value) => setState(() => _minimumOrderAmount = value),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Notification Settings
          _buildSettingsSection(
            'Notifications',
            [
              _buildSwitchTile(
                'New Order Notifications',
                'Get notified when customers place orders',
                _notifyOnNewOrders,
                (value) => setState(() => _notifyOnNewOrders = value),
              ),
              _buildSwitchTile(
                'Low Stock Alerts',
                'Get notified when products are running low',
                _notifyOnLowStock,
                (value) => setState(() => _notifyOnLowStock = value),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Save Settings Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveBusinessSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: _isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save Settings'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1D1B20),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: Column(children: children),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF1D1B20),
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(
          color: Color(0xFF49454F),
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF6750A4),
    );
  }

  Widget _buildNumberField(
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return TextFormField(
      initialValue: value.toString(),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide.none,
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide.none,
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: Color(0xFF49454F)),
      ),
      keyboardType: TextInputType.number,
      onChanged: (text) {
        final parsedValue = double.tryParse(text);
        if (parsedValue != null) {
          onChanged(parsedValue);
        }
      },
    );
  }

  Future<void> _sendEmailVerification() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final businessEmail = _business?.basicInfo.email;
      
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You must be logged in to verify email'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Check if business email is available
      if (businessEmail == null || businessEmail.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please save your business email first'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Check if email is already verified
      if (_business?.verification.isEmailVerified == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email is already verified!'),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }

      // Check if user's email matches business email
      if (user.email == businessEmail) {
        if (user.emailVerified) {
          // User's email is verified and matches business email, auto-verify
          await FirebaseFirestore.instance
              .collection('businesses')
              .doc(widget.businessId)
              .update({
            'verification.isEmailVerified': true,
            'updatedAt': Timestamp.now(),
          });
          
          await _loadBusinessProfile();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Email automatically verified! (Matches your login email)'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // User's email matches but not verified, send verification
          await user.sendEmailVerification();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification email sent to your login email! Please check your inbox.'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } else {
        // Business email is different from login email
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Business email ($businessEmail) is different from your login email (${user.email ?? 'Not available'}). '
              'Please use the "Already Verified?" option if this email is verified elsewhere.',
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sending verification email: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendPhoneVerification() async {
    try {
      // First check if phone is already verified
      if (_business?.verification.isPhoneVerified == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Phone number is already verified!'),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }

      String phoneNumber = _business?.basicInfo.phone ?? '';
      if (phoneNumber.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please save your phone number first'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Show unified OTP verification dialog
      _showUnifiedOtpDialog(phoneNumber);
    } catch (e) {
      print('Error starting phone verification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting phone verification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showUnifiedOtpDialog(String phoneNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Verify Business Phone',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  UnifiedOtpWidget(
                    context: VerificationContext.businessRegistration,
                    initialPhoneNumber: phoneNumber,
                    showPhoneInput: false,
                    title: 'Verify Business Phone',
                    subtitle: 'Confirm your business contact number',
                    onVerificationComplete: (phoneNumber, isVerified) async {
                      if (isVerified) {
                        // Update business verification status
                        await FirebaseFirestore.instance
                            .collection('businesses')
                            .doc(widget.businessId)
                            .update({
                          'verification.isPhoneVerified': true,
                          'updatedAt': Timestamp.now(),
                        });
                        
                        Navigator.of(context).pop();
                        await _loadBusinessProfile();
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Business phone verified successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    onError: (error) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Verification failed: $error'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }



  Future<void> _checkAutoVerifyEmail(BusinessProfile business) async {
    // Skip if email is already verified
    if (business.verification.isEmailVerified) {
      return;
    }

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && 
          currentUser.email != null && 
          currentUser.emailVerified &&
          currentUser.email == business.basicInfo.email) {
        
        // Email addresses match and user's email is verified, auto-verify
        await FirebaseFirestore.instance
            .collection('businesses')
            .doc(widget.businessId)
            .update({
          'verification.isEmailVerified': true,
          'updatedAt': Timestamp.now(),
        });
        
        // Reload to update the UI
        await _loadBusinessProfile();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📧 Email automatically verified! (Matches your verified login)'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      print('Error in auto-verify email check: $e');
    }
  }

  Future<void> _markEmailAsVerified() async {
    try {
      // Check if the business email matches the logged-in user's email
      final currentUser = FirebaseAuth.instance.currentUser;
      String businessEmail = _business?.basicInfo.email ?? '';
      
      if (currentUser != null && currentUser.email == businessEmail && currentUser.emailVerified) {
        // Emails match and user's email is verified, auto-verify
        await FirebaseFirestore.instance
            .collection('businesses')
            .doc(widget.businessId)
            .update({
          'verification.isEmailVerified': true,
          'updatedAt': Timestamp.now(),
        });
        
        await _loadBusinessProfile();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email verified automatically! (Matches your verified login email)'),
            backgroundColor: Colors.green,
          ),
        );
        return;
      }
      
      // Emails don't match or user email not verified, show confirmation dialog
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Mark Email as Verified'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Email verification status:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Your login: ${currentUser?.email ?? 'Not available'} ${currentUser?.emailVerified == true ? '(Verified)' : '(Not verified)'}'),
                Text('Business: $businessEmail'),
                const SizedBox(height: 16),
                const Text(
                  'Are you sure this business email is already verified? '
                  'Only mark as verified if you have access to this email and can receive emails.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes, Mark as Verified'),
              ),
            ],
          );
        },
      );

      if (confirm == true) {
        await FirebaseFirestore.instance
            .collection('businesses')
            .doc(widget.businessId)
            .update({
          'verification.isEmailVerified': true,
          'updatedAt': Timestamp.now(),
        });
        
        await _loadBusinessProfile();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email marked as verified!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating email verification status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _uploadBusinessLogo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() {
        _isUploadingLogo = true;
      });

      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('business_logos')
          .child('${widget.businessId}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      final uploadTask = storageRef.putFile(File(image.path));
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Update business profile with new logo URL
      await FirebaseFirestore.instance
          .collection('businesses')
          .doc(widget.businessId)
          .update({
        'basicInfo.logoUrl': downloadUrl,
        'updatedAt': Timestamp.now(),
      });

      // Reload business profile
      await _loadBusinessProfile();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Business logo uploaded successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error uploading business logo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading logo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploadingLogo = false;
      });
    }
  }
}
