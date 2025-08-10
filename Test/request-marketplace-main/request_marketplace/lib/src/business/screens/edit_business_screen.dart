import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/business_models.dart';
import '../../services/business_service.dart';

class EditBusinessScreen extends StatefulWidget {
  final String businessId;
  final BusinessProfile business;

  const EditBusinessScreen({
    super.key,
    required this.businessId,
    required this.business,
  });

  @override
  State<EditBusinessScreen> createState() => _EditBusinessScreenState();
}

class _EditBusinessScreenState extends State<EditBusinessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessService = BusinessService();
  
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _descriptionController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _postalCodeController;
  
  bool _isLoading = false;
  List<String> _selectedCategories = [];
  
  final List<String> _availableCategories = [
    'Electronics', 'Clothing', 'Food & Beverages', 'Home & Garden',
    'Automotive', 'Health & Beauty', 'Sports', 'Books & Media',
    'Services', 'Construction', 'Technology', 'Education',
    'Entertainment', 'Travel', 'Finance', 'Real Estate'
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final business = widget.business;
    _nameController = TextEditingController(text: business.basicInfo.name);
    _emailController = TextEditingController(text: business.basicInfo.email);
    _phoneController = TextEditingController(text: business.basicInfo.phone);
    _descriptionController = TextEditingController(text: business.basicInfo.description);
    _streetController = TextEditingController(text: business.basicInfo.address.street);
    _cityController = TextEditingController(text: business.basicInfo.address.city);
    _postalCodeController = TextEditingController(text: business.basicInfo.address.postalCode);
    _selectedCategories = List.from(business.basicInfo.categories);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBFE),
      appBar: AppBar(
        title: const Text('Edit Business'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1D1B20),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Color(0xFF1D1B20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveChanges,
            child: _isLoading 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.edit, color: Colors.white, size: 28),
                    const SizedBox(height: 12),
                    const Text(
                      'Edit Business Information',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Update your business details and information',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Basic Information
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _nameController,
                label: 'Business Name',
                icon: Icons.business,
                validator: (value) => value?.isEmpty == true ? 'Business name is required' : null,
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _emailController,
                label: 'Business Email',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty == true) return 'Email is required';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                    return 'Enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _phoneController,
                label: 'Business Phone',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) => value?.isEmpty == true ? 'Phone number is required' : null,
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _descriptionController,
                label: 'Business Description',
                icon: Icons.description,
                maxLines: 3,
                validator: (value) => value?.isEmpty == true ? 'Description is required' : null,
              ),
              const SizedBox(height: 24),

              // Categories
              _buildSectionTitle('Business Categories'),
              const SizedBox(height: 16),
              _buildCategoriesSection(),
              const SizedBox(height: 24),

              // Address Information
              _buildSectionTitle('Business Address'),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _streetController,
                label: 'Street Address',
                icon: Icons.location_on,
                validator: (value) => value?.isEmpty == true ? 'Street address is required' : null,
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _cityController,
                label: 'City',
                icon: Icons.location_city,
                validator: (value) => value?.isEmpty == true ? 'City is required' : null,
              ),
              const SizedBox(height: 16),
              
              _buildTextField(
                controller: _postalCodeController,
                label: 'Postal Code',
                icon: Icons.local_post_office,
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty == true ? 'Postal code is required' : null,
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6750A4),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Save Changes',
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
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1D1B20),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF6750A4)),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Business Categories',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF1D1B20),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableCategories.map((category) {
              final isSelected = _selectedCategories.contains(category);
              return FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedCategories.add(category);
                    } else {
                      _selectedCategories.remove(category);
                    }
                  });
                },
                selectedColor: const Color(0xFF6750A4).withOpacity(0.2),
                checkmarkColor: const Color(0xFF6750A4),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one business category'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Update business information
      final updatedBasicInfo = BusinessBasicInfo(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        logoUrl: widget.business.basicInfo.logoUrl, // Keep existing logo
        whatsapp: widget.business.basicInfo.whatsapp, // Keep existing whatsapp
        website: widget.business.basicInfo.website, // Keep existing website
        bannerImages: widget.business.basicInfo.bannerImages, // Keep existing banners
        businessType: widget.business.basicInfo.businessType, // Keep existing business type
        categories: _selectedCategories,
        socialLinks: widget.business.basicInfo.socialLinks, // Keep existing social links
        address: BusinessAddress(
          street: _streetController.text.trim(),
          city: _cityController.text.trim(),
          state: widget.business.basicInfo.address.state ?? '', // Keep existing state
          postalCode: _postalCodeController.text.trim(),
          country: widget.business.basicInfo.address.country, // Keep existing country
          latitude: widget.business.basicInfo.address.latitude, // Keep existing coordinates
          longitude: widget.business.basicInfo.address.longitude,
        ),
      );

      await _businessService.updateBusinessInfo(
        widget.businessId,
        updatedBasicInfo,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business information updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Return true to indicate changes were made
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating business: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isLoading = false);
  }
}
