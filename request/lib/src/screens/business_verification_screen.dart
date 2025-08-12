import 'package:flutter/material.dart';
import '../services/enhanced_user_service.dart';
import '../models/enhanced_user_model.dart';
import '../theme/app_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/file_upload_service.dart';
import 'dart:io';

class BusinessVerificationScreen extends StatefulWidget {
  const BusinessVerificationScreen({Key? key}) : super(key: key);

  @override
  State<BusinessVerificationScreen> createState() => _BusinessVerificationScreenState();
}

class _BusinessVerificationScreenState extends State<BusinessVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final EnhancedUserService _userService = EnhancedUserService();
  final FileUploadService _fileUploadService = FileUploadService();
  
  // Business Information Controllers
  final _businessNameController = TextEditingController();
  final _businessEmailController = TextEditingController();
  final _businessPhoneController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _businessDescriptionController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _taxIdController = TextEditingController();
  
  // Business Documents
  File? _businessLicenseFile;
  File? _taxCertificateFile;
  File? _insuranceDocumentFile;
  
  String? _businessLicenseUrl;
  String? _taxCertificateUrl;
  String? _insuranceDocumentUrl;
  
  // Business Logo
  File? _businessLogoFile;
  String? _businessLogoUrl;
  
  // Business Category
  String? _selectedCategory;
  final List<String> _businessCategories = [
    'Restaurant',
    'Retail Store',
    'Grocery',
    'Pharmacy',
    'Electronics',
    'Clothing',
    'Hardware',
    'Services',
    'Other',
  ];
  
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserData();
  }

  Future<void> _loadCurrentUserData() async {
    try {
      final currentUser = await _userService.getCurrentUser();
      if (currentUser != null) {
        setState(() {
          _businessEmailController.text = currentUser.email ?? '';
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Business Verification'),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildBusinessInformationSection(),
              const SizedBox(height: 24),
              _buildBusinessDocumentsSection(),
              const SizedBox(height: 24),
              _buildBusinessLogoSection(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: AppTheme.backgroundColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.business, color: AppTheme.primaryColor, size: 32),
              const SizedBox(width: 12),
              const Text(
                'Business Verification',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete your business verification to start offering services on our platform.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessInformationSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: AppTheme.backgroundColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.business_center, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Business Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _businessNameController,
            label: 'Business Name *',
            hint: 'Enter your business name',
            validator: (value) => value?.isEmpty ?? true ? 'Business name is required' : null,
          ),
          _buildTextField(
            controller: _businessEmailController,
            label: 'Business Email *',
            hint: 'Enter business email',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Business email is required';
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value!)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          _buildTextField(
            controller: _businessPhoneController,
            label: 'Business Phone *',
            hint: 'Enter business phone number',
            keyboardType: TextInputType.phone,
            validator: (value) => value?.isEmpty ?? true ? 'Business phone is required' : null,
          ),
          _buildTextField(
            controller: _businessAddressController,
            label: 'Business Address *',
            hint: 'Enter complete business address',
            maxLines: 3,
            validator: (value) => value?.isEmpty ?? true ? 'Business address is required' : null,
          ),
          _buildTextField(
            controller: _businessDescriptionController,
            label: 'Business Description *',
            hint: 'Describe your business and services',
            maxLines: 4,
            validator: (value) => value?.isEmpty ?? true ? 'Business description is required' : null,
          ),
          _buildDropdownField(),
          _buildTextField(
            controller: _licenseNumberController,
            label: 'Business License Number *',
            hint: 'Enter business license number',
            validator: (value) => value?.isEmpty ?? true ? 'License number is required' : null,
          ),
          _buildTextField(
            controller: _taxIdController,
            label: 'Tax ID / VAT Number',
            hint: 'Enter tax ID or VAT number (optional)',
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessDocumentsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: AppTheme.backgroundColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Business Documents',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please upload clear, high-quality photos of your documents. Supported formats: JPG, PNG, PDF.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildDocumentUpload(
            title: 'Business License *',
            description: 'Official business registration/license document',
            file: _businessLicenseFile,
            url: _businessLicenseUrl,
            onTap: () => _pickDocument('business_license'),
            isRequired: true,
          ),
          _buildDocumentUpload(
            title: 'Tax Certificate',
            description: 'Tax registration certificate (if applicable)',
            file: _taxCertificateFile,
            url: _taxCertificateUrl,
            onTap: () => _pickDocument('tax_certificate'),
            isRequired: false,
          ),
          _buildDocumentUpload(
            title: 'Insurance Document',
            description: 'Business insurance certificate (if applicable)',
            file: _insuranceDocumentFile,
            url: _insuranceDocumentUrl,
            onTap: () => _pickDocument('insurance'),
            isRequired: false,
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessLogoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: AppTheme.backgroundColor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.image, color: AppTheme.primaryColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Business Logo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildLogoUpload(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLines,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            validator: validator,
            keyboardType: keyboardType,
            maxLines: maxLines ?? 1,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppTheme.textSecondary.withOpacity(0.5),
                fontSize: 14,
              ),
              filled: true,
              fillColor: AppTheme.backgroundColor,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              enabledBorder: const OutlineInputBorder(
                borderSide: BorderSide.none,
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide.none,
              ),
              errorBorder: const OutlineInputBorder(
                borderSide: BorderSide.none,
              ),
              focusedErrorBorder: const OutlineInputBorder(
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Business Category *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundColor,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                hint: Text(
                  'Select business category',
                  style: TextStyle(
                    color: AppTheme.textSecondary.withOpacity(0.5),
                    fontSize: 14,
                  ),
                ),
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.textSecondary),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                ),
                dropdownColor: AppTheme.backgroundColor,
                items: _businessCategories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentUpload({
    required String title,
    required String description,
    required File? file,
    required String? url,
    required VoidCallback onTap,
    required bool isRequired,
  }) {
    final hasDocument = file != null || url != null;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasDocument ? Colors.green.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasDocument ? Icons.check_circle : Icons.upload_file,
                color: hasDocument ? Colors.green : AppTheme.textSecondary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(hasDocument ? Icons.refresh : Icons.upload),
              label: Text(hasDocument ? 'Replace Document' : 'Upload Document'),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasDocument ? Colors.orange : AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (file != null) ...[
            const SizedBox(height: 8),
            Text(
              'Selected: ${file!.path.split('/').last}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogoUpload() {
    final hasLogo = _businessLogoFile != null || _businessLogoUrl != null;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
      ),
      child: Column(
        children: [
          if (hasLogo) ...[
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
              ),
              child: _businessLogoFile != null
                  ? ClipRRect(
                      child: Image.file(
                        _businessLogoFile!,
                        fit: BoxFit.cover,
                      ),
                    )
                  : _businessLogoUrl != null
                      ? ClipRRect(
                          child: Image.network(
                            _businessLogoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.business, size: 64, color: Colors.grey);
                            },
                          ),
                        )
                      : const Icon(Icons.business, size: 64, color: Colors.grey),
            ),
            const SizedBox(height: 16),
          ] else ...[
            Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(
                color: Colors.grey[200],
              ),
              child: const Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _pickBusinessLogo,
              icon: Icon(hasLogo ? Icons.refresh : Icons.camera_alt),
              label: Text(hasLogo ? 'Change Logo' : 'Add Business Logo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: hasLogo ? Colors.orange : Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload a clear logo for your business (optional)',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitVerification,
        style: AppTheme.primaryButtonStyle.copyWith(
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        child: _isSubmitting
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Submitting Verification...'),
                ],
              )
            : const Text(
                'Submit Business Verification',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  Future<void> _pickDocument(String type) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2000,
        maxHeight: 2000,
        imageQuality: 85,
      );
      
      if (file != null) {
        setState(() {
          switch (type) {
            case 'business_license':
              _businessLicenseFile = File(file.path);
              break;
            case 'tax_certificate':
              _taxCertificateFile = File(file.path);
              break;
            case 'insurance':
              _insuranceDocumentFile = File(file.path);
              break;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking document: $e')),
      );
    }
  }

  Future<void> _pickBusinessLogo() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );
      
      if (file != null) {
        setState(() {
          _businessLogoFile = File(file.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking logo: $e')),
      );
    }
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a business category')),
      );
      return;
    }
    
    if (_businessLicenseFile == null && _businessLicenseUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Business license document is required')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final currentUser = await _userService.getCurrentUser();
      if (currentUser == null) throw Exception('User not authenticated');

      // Upload documents
      String? businessLicenseUrl = _businessLicenseUrl;
      String? taxCertificateUrl = _taxCertificateUrl;
      String? insuranceDocumentUrl = _insuranceDocumentUrl;
      String? businessLogoUrl = _businessLogoUrl;

      if (_businessLicenseFile != null) {
        businessLicenseUrl = await _fileUploadService.uploadFile(
          _businessLicenseFile!,
          'business_documents/${currentUser.uid}/business_license.jpg',
        );
      }

      if (_taxCertificateFile != null) {
        taxCertificateUrl = await _fileUploadService.uploadFile(
          _taxCertificateFile!,
          'business_documents/${currentUser.uid}/tax_certificate.jpg',
        );
      }

      if (_insuranceDocumentFile != null) {
        insuranceDocumentUrl = await _fileUploadService.uploadFile(
          _insuranceDocumentFile!,
          'business_documents/${currentUser.uid}/insurance_document.jpg',
        );
      }

      if (_businessLogoFile != null) {
        businessLogoUrl = await _fileUploadService.uploadFile(
          _businessLogoFile!,
          'business_logos/${currentUser.uid}/logo.jpg',
        );
      }

      // Submit business verification
      await _userService.submitBusinessVerification({
        'userId': currentUser.uid,
        'businessName': _businessNameController.text,
        'businessEmail': _businessEmailController.text,
        'businessPhone': _businessPhoneController.text,
        'businessAddress': _businessAddressController.text,
        'businessDescription': _businessDescriptionController.text,
        'businessCategory': _selectedCategory!,
        'licenseNumber': _licenseNumberController.text,
        'taxId': _taxIdController.text.isNotEmpty ? _taxIdController.text : null,
        'businessLicenseUrl': businessLicenseUrl,
        'taxCertificateUrl': taxCertificateUrl,
        'insuranceDocumentUrl': insuranceDocumentUrl,
        'businessLogoUrl': businessLogoUrl,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
        'documentVerification': {
          'businessLicense': {
            'status': 'pending',
            'submittedAt': FieldValue.serverTimestamp(),
          },
          'taxCertificate': taxCertificateUrl != null ? {
            'status': 'pending',
            'submittedAt': FieldValue.serverTimestamp(),
          } : null,
          'insurance': insuranceDocumentUrl != null ? {
            'status': 'pending',
            'submittedAt': FieldValue.serverTimestamp(),
          } : null,
        },
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business verification submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacementNamed(context, '/business-documents-view');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting verification: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _businessEmailController.dispose();
    _businessPhoneController.dispose();
    _businessAddressController.dispose();
    _businessDescriptionController.dispose();
    _licenseNumberController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }
}
