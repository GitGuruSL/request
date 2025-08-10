import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/enhanced_user_model.dart';
import '../../services/user_profile_service.dart';

class VanRentalRegistrationScreen extends StatefulWidget {
  final String userId;
  
  const VanRentalRegistrationScreen({
    super.key,
    required this.userId,
  });

  @override
  State<VanRentalRegistrationScreen> createState() => _VanRentalRegistrationScreenState();
}

class _VanRentalRegistrationScreenState extends State<VanRentalRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserProfileService _userProfileService = UserProfileService();
  
  // Form controllers
  final _businessNameController = TextEditingController();
  final _businessRegistrationController = TextEditingController();
  final _locationController = TextEditingController();
  final _depositPercentController = TextEditingController();
  
  // Form state
  bool _hasBusinessLicense = false;
  bool _acceptsDeposit = true;
  List<String> _selectedAreas = [];
  bool _isLoading = false;

  final List<String> _serviceAreas = [
    'Colombo',
    'Kandy',
    'Galle',
    'Matara',
    'Jaffna',
    'Batticaloa',
    'Kurunegala',
    'Anuradhapura',
    'Ratnapura',
    'Badulla',
  ];

  @override
  void initState() {
    super.initState();
    _depositPercentController.text = '20'; // Default 20%
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessRegistrationController.dispose();
    _locationController.dispose();
    _depositPercentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Van Rental Business'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo, Colors.indigo.shade50],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.indigo.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.airport_shuttle,
                            size: 48,
                            color: Colors.indigo[700],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Start Your Rental Business',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Rent out your vehicles and earn passive income',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Business Information
                  _buildSection(
                    title: 'Business Information',
                    icon: Icons.business,
                    children: [
                      TextFormField(
                        controller: _businessNameController,
                        decoration: InputDecoration(
                          labelText: 'Business Name *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.storefront),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Please enter business name' : null,
                      ),
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        title: const Text('I have a business license'),
                        subtitle: const Text('Required for commercial vehicle rental'),
                        value: _hasBusinessLicense,
                        onChanged: (value) => setState(() => _hasBusinessLicense = value ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      if (_hasBusinessLicense) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _businessRegistrationController,
                          decoration: InputDecoration(
                            labelText: 'Business Registration Number',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.confirmation_number),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Location Information
                  _buildSection(
                    title: 'Operating Location',
                    icon: Icons.location_on,
                    children: [
                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'Main Operating Location *',
                          hintText: 'Where are your vehicles located?',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.place),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Please enter your location' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Service Areas *',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Select areas where you can deliver vehicles',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _serviceAreas.map((area) {
                          final isSelected = _selectedAreas.contains(area);
                          return FilterChip(
                            label: Text(area),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedAreas.add(area);
                                } else {
                                  _selectedAreas.remove(area);
                                }
                              });
                            },
                            selectedColor: Colors.indigo.withOpacity(0.3),
                          );
                        }).toList(),
                      ),
                      if (_selectedAreas.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Please select at least one service area',
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                    ],
                  ),

                  // Rental Policies
                  _buildSection(
                    title: 'Rental Policies',
                    icon: Icons.policy,
                    children: [
                      CheckboxListTile(
                        title: const Text('Require security deposit'),
                        subtitle: const Text('Recommended for vehicle protection'),
                        value: _acceptsDeposit,
                        onChanged: (value) => setState(() => _acceptsDeposit = value ?? true),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      if (_acceptsDeposit) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _depositPercentController,
                          decoration: InputDecoration(
                            labelText: 'Security Deposit Percentage (%)',
                            hintText: 'Percentage of rental cost',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.percent),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value?.isEmpty ?? true) return 'Please enter deposit percentage';
                            final percent = double.tryParse(value!);
                            if (percent == null || percent < 0 || percent > 100) {
                              return 'Please enter valid percentage (0-100)';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Vehicle Requirements',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '• Valid vehicle registration\n'
                              '• Current insurance coverage\n'
                              '• Regular maintenance records\n'
                              '• Clean vehicle condition',
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Register Button
                  Container(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _registerVanRental,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Register Rental Business',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Next Steps
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.timeline, color: Colors.blue[700]),
                        const SizedBox(height: 8),
                        const Text(
                          'Next Steps',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '1. Complete registration\n'
                          '2. Add your vehicles\n'
                          '3. Get verified\n'
                          '4. Start receiving rental requests',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.indigo[700]),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Future<void> _registerVanRental() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAreas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one service area')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create van rental profile
      final vanRentalProfile = VanRentalProfile(
        businessName: _businessNameController.text.trim(),
        businessRegistration: _businessRegistrationController.text.trim(),
        hasBusinessLicense: _hasBusinessLicense,
        operatingLocation: _locationController.text.trim(),
        serviceAreas: _selectedAreas,
        acceptsDeposit: _acceptsDeposit,
        securityDepositPercent: double.tryParse(_depositPercentController.text) ?? 20.0,
        verificationStatus: VerificationStatus.pending,
        rentalPolicies: {
          'requiresDeposit': _acceptsDeposit,
          'depositPercent': double.tryParse(_depositPercentController.text) ?? 20.0,
          'createdAt': Timestamp.now(),
        },
      );

      // Update user profile
      await _userProfileService.addVanRentalProfile(widget.userId, vanRentalProfile);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Van rental business registered! Add your vehicles to start earning.'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
