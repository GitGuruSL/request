import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/business_service.dart';

class BusinessTypeSelectionScreen extends StatelessWidget {
  const BusinessTypeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Choose Business Type',
          style: TextStyle(fontFamily: 'Poppins'),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'What type of business do you want to register?',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Choose the option that best describes your business model',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: ListView(
                  children: [
                    _buildBusinessTypeCard(
                      context,
                      icon: Icons.store,
                      title: 'Product & Service Provider',
                      subtitle: 'Sell products or provide services',
                      description: 'Respond to: Items, Services, Rentals',
                      color: const Color(0xFF4CAF50),
                      onTap: () => _navigateToRegistration(context, 'product_service'),
                    ),
                    const SizedBox(height: 20),
                    _buildBusinessTypeCard(
                      context,
                      icon: Icons.local_shipping,
                      title: 'Delivery Service',
                      subtitle: 'Provide delivery and logistics services',
                      description: 'Respond to: Items, Services, Rentals, Deliveries',
                      color: const Color(0xFF2196F3),
                      onTap: () => _navigateToRegistration(context, 'delivery_service'),
                    ),
                    const SizedBox(height: 20),
                    _buildBusinessTypeCard(
                      context,
                      icon: Icons.drive_eta,
                      title: 'Driver Service',
                      subtitle: 'Provide transportation services',
                      description: 'Respond to: Items, Services, Rentals, Rides',
                      color: const Color(0xFF9C27B0),
                      onTap: () => _navigateToDriverRegistration(context),
                      isSpecial: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessTypeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required Color color,
    required VoidCallback onTap,
    bool isSpecial = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: isSpecial ? Border.all(color: color, width: 2) : null,
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
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 20),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: color, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: color,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isSpecial) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.orange, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Requires driver verification',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _navigateToRegistration(BuildContext context, String businessType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnhancedBusinessRegistrationScreen(
          businessType: businessType,
        ),
      ),
    );
  }

  void _navigateToDriverRegistration(BuildContext context) {
    // Show driver registration info dialog first
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.drive_eta, color: Colors.purple[600]),
              const SizedBox(width: 8),
              const Text(
                'Driver Registration',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'To become a driver, you need to:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 12),
              _buildRequirement('Complete driver verification'),
              _buildRequirement('Upload required documents'),
              _buildRequirement('Provide vehicle information'),
              _buildRequirement('Pass admin approval'),
              const SizedBox(height: 16),
              const Text(
                'Once approved, you can respond to all request types including rides.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to driver verification screen
                // TODO: Implement navigation to driver verification
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[600],
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'Start Driver Registration',
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: Colors.green[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EnhancedBusinessRegistrationScreen extends StatefulWidget {
  final String businessType;

  const EnhancedBusinessRegistrationScreen({
    super.key,
    required this.businessType,
  });

  @override
  State<EnhancedBusinessRegistrationScreen> createState() => _EnhancedBusinessRegistrationScreenState();
}

class _EnhancedBusinessRegistrationScreenState extends State<EnhancedBusinessRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessService = BusinessService();
  
  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _isLoading = false;
  List<String> _selectedCategories = [];
  
  // Category options based on business type
  List<String> get _availableCategories {
    switch (widget.businessType) {
      case 'product_service':
        return [
          'Electronics', 'Clothing', 'Home & Garden', 'Automotive',
          'Food & Beverages', 'Health & Beauty', 'Sports & Recreation',
          'Books & Media', 'Toys & Games', 'Jewelry & Accessories',
          'Repair Services', 'Cleaning Services', 'Technical Services',
          'Professional Services', 'Beauty Services', 'Home Services'
        ];
      case 'delivery_service':
        return [
          'Food Delivery', 'Package Delivery', 'Document Delivery',
          'Grocery Delivery', 'Medicine Delivery', 'Furniture Delivery',
          'Same-Day Delivery', 'Express Delivery', 'International Delivery'
        ];
      default:
        return [];
    }
  }
  
  String get _businessTypeTitle {
    switch (widget.businessType) {
      case 'product_service':
        return 'Product & Service Provider';
      case 'delivery_service':
        return 'Delivery Service';
      default:
        return 'Business Registration';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          _businessTypeTitle,
          style: const TextStyle(fontFamily: 'Poppins'),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 30),
                    _buildBasicInfoSection(),
                    const SizedBox(height: 30),
                    _buildCategoriesSection(),
                    const SizedBox(height: 30),
                    _buildContactSection(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
            _buildBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    Color headerColor;
    IconData headerIcon;
    String headerDescription;
    
    switch (widget.businessType) {
      case 'product_service':
        headerColor = const Color(0xFF4CAF50);
        headerIcon = Icons.store;
        headerDescription = 'Register your business to sell products and provide services. You can respond to item, service, and rental requests.';
        break;
      case 'delivery_service':
        headerColor = const Color(0xFF2196F3);
        headerIcon = Icons.local_shipping;
        headerDescription = 'Register as a delivery service provider. You can respond to all types of requests including deliveries.';
        break;
      default:
        headerColor = Colors.grey;
        headerIcon = Icons.business;
        headerDescription = 'Register your business';
    }

    return Container(
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: headerColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(headerIcon, color: headerColor, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _businessTypeTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  headerDescription,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return _buildSection(
      title: 'Business Information',
      children: [
        _buildTextField(
          controller: _businessNameController,
          label: 'Business Name',
          hint: 'Enter your business name',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter business name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _descriptionController,
          label: 'Business Description',
          hint: 'Describe your business and services',
          maxLines: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter business description';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _addressController,
          label: 'Business Address',
          hint: 'Enter your business address',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter business address';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCategoriesSection() {
    return _buildSection(
      title: 'Service Categories',
      subtitle: 'Select the categories that apply to your business',
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableCategories.map((category) {
            final isSelected = _selectedCategories.contains(category);
            return FilterChip(
              selected: isSelected,
              label: Text(
                category,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
              backgroundColor: Colors.grey[100],
              selectedColor: const Color(0xFF6366F1),
              checkmarkColor: Colors.white,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedCategories.add(category);
                  } else {
                    _selectedCategories.remove(category);
                  }
                });
              },
            );
          }).toList(),
        ),
        if (_selectedCategories.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Please select at least one category',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red[600],
                fontFamily: 'Poppins',
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContactSection() {
    return _buildSection(
      title: 'Contact Information',
      children: [
        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number',
          hint: 'Enter business phone number',
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter phone number';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _emailController,
          label: 'Business Email',
          hint: 'Enter business email address',
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter email address';
            }
            if (!value.contains('@')) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
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
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: 'Poppins',
              ),
            ),
          ],
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6366F1)),
        ),
        labelStyle: const TextStyle(fontFamily: 'Poppins'),
        hintStyle: const TextStyle(fontFamily: 'Poppins'),
      ),
      style: const TextStyle(fontFamily: 'Poppins'),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _registerBusiness,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  'Register Business',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _registerBusiness() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one category'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Create business data
      final businessData = {
        'userId': user.uid,
        'businessName': _businessNameController.text,
        'businessType': widget.businessType,
        'description': _descriptionController.text,
        'address': _addressController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'categories': _selectedCategories,
        'isVerified': false,
        'isActive': true,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      };

      await _businessService.createBusiness(businessData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business registered successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to profile or dashboard
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
