// New Business Registration Screen using BusinessService
// File: lib/src/screens/register_business_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/business_service.dart';
import '../models/business_models.dart';
import 'business_verification_screen.dart';

class RegisterBusinessScreen extends StatefulWidget {
  const RegisterBusinessScreen({super.key});

  @override
  State<RegisterBusinessScreen> createState() => _RegisterBusinessScreenState();
}

class _RegisterBusinessScreenState extends State<RegisterBusinessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessService = BusinessService();
  final _auth = FirebaseAuth.instance;
  
  // Form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController();
  
  BusinessType _selectedType = BusinessType.retail;
  final List<String> _selectedCategories = [];
  bool _isLoading = false;
  
  final List<String> _businessCategories = [
    'Electronics', 'Clothing', 'Food & Beverages', 'Home & Garden',
    'Automotive', 'Health & Beauty', 'Sports', 'Books & Media',
    'Services', 'Construction', 'Technology', 'Education',
    'Entertainment', 'Travel', 'Finance', 'Real Estate'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Business'),
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
      ),
      backgroundColor: const Color(0xFFFFFBFE),
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
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6750A4), Color(0xFF9575CD)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.business, color: Colors.white, size: 32),
                    SizedBox(height: 16),
                    Text(
                      'Register Your Business',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Start selling products and reach more customers',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Business Type Section (Moved to top)
              const Text(
                'Business Type',
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1B20),
                ),
              ),
              const SizedBox(height: 16),
              
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonFormField<BusinessType>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    hintText: 'Select business type',
                    hintStyle: TextStyle(
                      color: Color(0xFF79747E),
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(Icons.category, color: Color(0xFF79747E)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  items: BusinessType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getBusinessTypeDisplayName(type)),
                    );
                  }).toList(),
                  onChanged: (BusinessType? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedType = newValue;
                      });
                    }
                  },
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Basic Information Section
              const Text(
                'Basic Information',
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1B20),
                ),
              ),
              const SizedBox(height: 16),
              
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextFormField(
                  controller: _nameController,
                  style: const TextStyle(
                    color: Color(0xFF1D1B20),
                    fontSize: 16,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Business Name *',
                    hintStyle: TextStyle(
                      color: Color(0xFF79747E),
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(Icons.business, color: Color(0xFF79747E)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Business name is required';
                    }
                    return null;
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextFormField(
                  controller: _emailController,
                  style: const TextStyle(
                    color: Color(0xFF1D1B20),
                    fontSize: 16,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Business Email *',
                    hintStyle: TextStyle(
                      color: Color(0xFF79747E),
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(Icons.email, color: Color(0xFF79747E)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Enter a valid email';
                    }
                    return null;
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextFormField(
                  controller: _phoneController,
                  style: const TextStyle(
                    color: Color(0xFF1D1B20),
                    fontSize: 16,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Phone Number *',
                    hintStyle: TextStyle(
                      color: Color(0xFF79747E),
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(Icons.phone, color: Color(0xFF79747E)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Phone number is required';
                    }
                    return null;
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextFormField(
                  controller: _addressController,
                  style: const TextStyle(
                    color: Color(0xFF1D1B20),
                    fontSize: 16,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Business Address *',
                    hintStyle: TextStyle(
                      color: Color(0xFF79747E),
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(Icons.location_on, color: Color(0xFF79747E)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Address is required';
                    }
                    return null;
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Business Categories Section
              const Text(
                'Business Categories',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1B20),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select categories that best describe your business',
                style: TextStyle(color: Color(0xFF49454F), fontSize: 14),
              ),
              const SizedBox(height: 16),
              
              // Selected Categories Display
              if (_selectedCategories.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6750A4).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF6750A4).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selected Categories:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6750A4),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedCategories.map((category) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6750A4),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  category,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedCategories.remove(category);
                                    });
                                  },
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Category Selection List
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.category_outlined,
                            color: Color(0xFF6750A4),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Available Categories',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1D1B20),
                              fontSize: 14,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_selectedCategories.length}/5 selected',
                            style: const TextStyle(
                              color: Color(0xFF49454F),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Categories List
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _businessCategories.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: Colors.grey.withOpacity(0.1),
                      ),
                      itemBuilder: (context, index) {
                        final category = _businessCategories[index];
                        final isSelected = _selectedCategories.contains(category);
                        final canSelect = _selectedCategories.length < 5 || isSelected;
                        
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: canSelect ? () {
                              setState(() {
                                if (isSelected) {
                                  _selectedCategories.remove(category);
                                } else {
                                  _selectedCategories.add(category);
                                }
                              });
                            } : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  // Category Icon
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: isSelected 
                                          ? const Color(0xFF6750A4).withOpacity(0.1)
                                          : Colors.grey.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _getCategoryIcon(category),
                                      color: isSelected 
                                          ? const Color(0xFF6750A4)
                                          : Colors.grey[600],
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Category Name
                                  Expanded(
                                    child: Text(
                                      category,
                                      style: TextStyle(
                                        color: canSelect 
                                            ? const Color(0xFF1D1B20)
                                            : Colors.grey[400],
                                        fontWeight: isSelected 
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  // Selection Indicator
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle,
                                      color: Color(0xFF6750A4),
                                      size: 20,
                                    )
                                  else if (!canSelect)
                                    Icon(
                                      Icons.block,
                                      color: Colors.grey[400],
                                      size: 20,
                                    )
                                  else
                                    Icon(
                                      Icons.add_circle_outline,
                                      color: Colors.grey[400],
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Additional Information Section
              const Text(
                'Additional Information',
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D1B20),
                ),
              ),
              const SizedBox(height: 16),
              
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextFormField(
                  controller: _descriptionController,
                  style: const TextStyle(
                    color: Color(0xFF1D1B20),
                    fontSize: 16,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Business Description',
                    hintStyle: TextStyle(
                      color: Color(0xFF79747E),
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(Icons.description, color: Color(0xFF79747E)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  maxLines: 3,
                ),
              ),
              
              const SizedBox(height: 16),
              
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextFormField(
                  controller: _websiteController,
                  style: const TextStyle(
                    color: Color(0xFF1D1B20),
                    fontSize: 16,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Website (Optional)',
                    hintStyle: TextStyle(
                      color: Color(0xFF79747E),
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(Icons.language, color: Color(0xFF79747E)),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  keyboardType: TextInputType.url,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Register Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6750A4),
                    foregroundColor: Colors.white,
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
                      : const Text(
                          'Register Business',
                          style: TextStyle(
                            fontSize: 16, 
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Terms Notice
              const Text(
                'By registering, you agree to our Terms of Service and Privacy Policy. '
                'Your business will need to be verified before you can start selling.',
                style: TextStyle(color: Color(0xFF49454F), fontSize: 12),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  String _getBusinessTypeDisplayName(BusinessType type) {
    switch (type) {
      case BusinessType.retail:
        return 'Retail Store';
      case BusinessType.service:
        return 'Service Provider';
      case BusinessType.restaurant:
        return 'Restaurant/Food';
      case BusinessType.rental:
        return 'Rental Business';
      case BusinessType.logistics:
        return 'Delivery/Logistics';
      case BusinessType.professional:
        return 'Professional Services';
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Electronics':
        return Icons.devices;
      case 'Clothing':
        return Icons.checkroom;
      case 'Food & Beverages':
        return Icons.restaurant;
      case 'Home & Garden':
        return Icons.home_outlined;
      case 'Automotive':
        return Icons.directions_car;
      case 'Health & Beauty':
        return Icons.spa;
      case 'Sports':
        return Icons.sports_soccer;
      case 'Books & Media':
        return Icons.library_books;
      case 'Services':
        return Icons.build;
      case 'Construction':
        return Icons.construction;
      case 'Technology':
        return Icons.computer;
      case 'Education':
        return Icons.school;
      case 'Entertainment':
        return Icons.movie;
      case 'Travel':
        return Icons.flight;
      case 'Finance':
        return Icons.account_balance;
      case 'Real Estate':
        return Icons.business;
      default:
        return Icons.category;
    }
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one business category'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Create business address
      final businessAddress = BusinessAddress(
        street: _addressController.text.trim(),
        city: '', // TODO: Parse from address or add separate field
        state: '',
        country: 'Sri Lanka',
        postalCode: '',
        latitude: 0.0,
        longitude: 0.0,
      );

      // Create business basic info
      final basicInfo = BusinessBasicInfo(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: businessAddress,
        businessType: _selectedType,
        categories: _selectedCategories,
        description: _descriptionController.text.trim().isNotEmpty 
            ? _descriptionController.text.trim() 
            : 'No description provided',
        website: _websiteController.text.trim().isNotEmpty 
            ? _websiteController.text.trim() 
            : null,
        logoUrl: '', // TODO: Add logo upload functionality
      );

      // Register business with correct parameters
      final businessId = await _businessService.registerBusiness(
        userId: currentUser.uid,
        basicInfo: basicInfo,
        businessType: _selectedType,
        productCategories: _selectedCategories,
      );

      if (businessId != null && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business registered successfully! Please verify your contact information.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Navigate to verification screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BusinessVerificationScreen(businessId: businessId),
          ),
        );
      } else {
        throw Exception('Failed to register business. Please try again.');
      }
    } catch (e) {
      print('❌ Business registration error: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to register business: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    super.dispose();
  }
}
