import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/enhanced_user_model.dart';
import '../../services/user_profile_service.dart';

class CourierRegistrationScreen extends StatefulWidget {
  final String userId;
  
  const CourierRegistrationScreen({
    super.key,
    required this.userId,
  });

  @override
  State<CourierRegistrationScreen> createState() => _CourierRegistrationScreenState();
}

class _CourierRegistrationScreenState extends State<CourierRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserProfileService _userProfileService = UserProfileService();
  
  // Form controllers
  final _vehicleRegistrationController = TextEditingController();
  final _insuranceProviderController = TextEditingController();
  final _locationController = TextEditingController();
  final _maxWeightController = TextEditingController();
  
  // Form state
  String? _selectedVehicleType;
  bool _hasInsurance = false;
  bool _canHandleCOD = false;
  DateTime? _insuranceExpiry;
  List<String> _selectedAreas = [];
  bool _isLoading = false;

  final List<String> _vehicleTypes = [
    'Bicycle',
    'Motorbike',
    'Scooter',
    'Car',
    'Van',
    'Pickup Truck',
  ];

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
  void dispose() {
    _vehicleRegistrationController.dispose();
    _insuranceProviderController.dispose();
    _locationController.dispose();
    _maxWeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Become a Courier'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal, Colors.teal.shade50],
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
                            color: Colors.teal.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.delivery_dining,
                            size: 48,
                            color: Colors.teal[700],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Join Our Delivery Network',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Start earning money by delivering packages in your area',
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

                  // Vehicle Information
                  _buildSection(
                    title: 'Vehicle Information',
                    icon: Icons.directions_car,
                    children: [
                      _buildDropdown(
                        label: 'Vehicle Type *',
                        value: _selectedVehicleType,
                        items: _vehicleTypes,
                        onChanged: (value) => setState(() => _selectedVehicleType = value),
                        validator: (value) => value == null ? 'Please select vehicle type' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _vehicleRegistrationController,
                        decoration: InputDecoration(
                          labelText: 'Vehicle Registration Number',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.confirmation_number),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _maxWeightController,
                        decoration: InputDecoration(
                          labelText: 'Maximum Delivery Weight (kg) *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.fitness_center),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Please enter maximum weight';
                          if (double.tryParse(value!) == null) return 'Please enter valid weight';
                          return null;
                        },
                      ),
                    ],
                  ),

                  // Insurance Information
                  _buildSection(
                    title: 'Insurance & Legal',
                    icon: Icons.security,
                    children: [
                      CheckboxListTile(
                        title: const Text('I have vehicle insurance'),
                        value: _hasInsurance,
                        onChanged: (value) => setState(() => _hasInsurance = value ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                      if (_hasInsurance) ...[
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _insuranceProviderController,
                          decoration: InputDecoration(
                            labelText: 'Insurance Provider',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.shield),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.calendar_today),
                          title: Text(
                            _insuranceExpiry != null
                                ? 'Insurance Expires: ${_insuranceExpiry!.day}/${_insuranceExpiry!.month}/${_insuranceExpiry!.year}'
                                : 'Select Insurance Expiry Date',
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: _selectInsuranceExpiry,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                      ],
                    ],
                  ),

                  // Service Information
                  _buildSection(
                    title: 'Service Details',
                    icon: Icons.local_shipping,
                    children: [
                      TextFormField(
                        controller: _locationController,
                        decoration: InputDecoration(
                          labelText: 'Operating Location *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.location_on),
                        ),
                        validator: (value) => value?.isEmpty ?? true ? 'Please enter your location' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Service Areas *',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
                            selectedColor: Colors.teal.withOpacity(0.3),
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
                      const SizedBox(height: 16),
                      CheckboxListTile(
                        title: const Text('I can handle Cash on Delivery (COD)'),
                        subtitle: const Text('Accept cash payments from customers'),
                        value: _canHandleCOD,
                        onChanged: (value) => setState(() => _canHandleCOD = value ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Register Button
                  Container(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _registerCourier,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Register as Courier',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Terms and conditions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(height: 8),
                        const Text(
                          'Your application will be reviewed within 24-48 hours. You\'ll receive verification updates via email and SMS.',
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
              Icon(icon, color: Colors.teal[700]),
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

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.arrow_drop_down),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      validator: validator,
    );
  }

  Future<void> _selectInsuranceExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _insuranceExpiry = picked);
    }
  }

  Future<void> _registerCourier() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAreas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one service area')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create courier profile
      final courierProfile = CourierProfile(
        vehicleType: _selectedVehicleType,
        vehicleRegistration: _vehicleRegistrationController.text.trim(),
        hasInsurance: _hasInsurance,
        insuranceProvider: _insuranceProviderController.text.trim(),
        insuranceExpiry: _insuranceExpiry != null ? Timestamp.fromDate(_insuranceExpiry!) : null,
        currentLocation: _locationController.text.trim(),
        serviceAreas: _selectedAreas,
        canHandleCOD: _canHandleCOD,
        maxDeliveryWeight: double.tryParse(_maxWeightController.text) ?? 10.0,
        verificationStatus: VerificationStatus.pending,
      );

      // Update user profile
      await _userProfileService.addCourierProfile(widget.userId, courierProfile);

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Courier registration submitted! We\'ll review your application.'),
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
