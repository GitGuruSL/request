import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/master_product.dart';
import '../../models/price_listing.dart';
import '../../services/pricing_service.dart';
import '../../services/enhanced_user_service.dart';
import '../../services/file_upload_service.dart';
import '../../services/country_service.dart';
import '../../services/country_filtered_data_service.dart';
import '../../theme/app_theme.dart';

class AddPriceListingScreen extends StatefulWidget {
  final MasterProduct masterProduct;
  final PriceListing? existingListing;

  const AddPriceListingScreen({
    super.key,
    required this.masterProduct,
    this.existingListing,
  });

  @override
  State<AddPriceListingScreen> createState() => _AddPriceListingScreenState();
}

class _AddPriceListingScreenState extends State<AddPriceListingScreen> {
  final _formKey = GlobalKey<FormState>();
  final PricingService _pricingService = PricingService();
  final EnhancedUserService _userService = EnhancedUserService();
  final FileUploadService _fileUploadService = FileUploadService();
  final ImagePicker _imagePicker = ImagePicker();

  // Form controllers
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _modelNumberController = TextEditingController();
  final TextEditingController _productLinkController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();

  // Form state
  String _currency = 'LKR';
  bool _isAvailable = true;
  Map<String, String> _selectedVariables = {};
  List<File> _productImages = [];
  List<String> _existingImageUrls = [];
  List<dynamic> _availableAttributes = []; // All attributes from database
  Set<String> _selectedAttributeIds = {}; // Which attributes user wants to use
  bool _isSaving = false;

  Map<String, dynamic>? _businessProfile;

  @override
  void initState() {
    super.initState();
    _loadBusinessProfile();
    _loadAvailableAttributes();
    _initializeForm();
    
    // Debug: Print available variables
    print('DEBUG: Master Product ID: ${widget.masterProduct.id}');
    print('DEBUG: Master Product Name: ${widget.masterProduct.name}');
    print('DEBUG: Available Variables: ${widget.masterProduct.availableVariables}');
    print('DEBUG: Available Variables Length: ${widget.masterProduct.availableVariables.length}');
  }

  Future<void> _loadAvailableAttributes() async {
    try {
      // Use country-filtered data service to get only active variable types
      final CountryFilteredDataService countryService = CountryFilteredDataService.instance;
      final activeVariableTypesData = await countryService.getActiveVariableTypes();
      
      setState(() {
        _availableAttributes = activeVariableTypesData.map((data) {
          return {
            'id': data['id'] ?? '',
            'name': data['name'] ?? '',
            'type': data['type'] ?? 'select',
            'required': data['required'] ?? data['isRequired'] ?? false,
            'possibleValues': List<String>.from(data['possibleValues'] ?? data['options'] ?? []),
            'description': data['description'] ?? '',
          };
        }).toList();
      });
      
      print('DEBUG: Loaded ${_availableAttributes.length} attributes from database');
      for (var attr in _availableAttributes) {
        print('DEBUG: Attribute: ${attr['name']} - Type: ${attr['type']} - Values: ${attr['possibleValues']}');
      }
    } catch (e) {
      print('Error loading attributes: $e');
    }
  }

  Future<void> _loadBusinessProfile() async {
    final userId = _userService.currentUser?.uid;
    if (userId != null) {
      final profile = await _pricingService.getBusinessProfile(userId);
      setState(() => _businessProfile = profile);
    }
  }

  void _initializeForm() {
    if (widget.existingListing != null) {
      final listing = widget.existingListing!;
      _priceController.text = listing.price.toString();
      _stockController.text = listing.stockQuantity.toString();
      _modelNumberController.text = listing.modelNumber ?? '';
      _productLinkController.text = listing.productLink ?? '';
      _whatsappController.text = listing.whatsappNumber ?? '';
      _currency = listing.currency;
      _isAvailable = listing.isAvailable;
      _selectedVariables = Map.from(listing.selectedVariables);
      
      // Initialize selected attribute IDs based on existing variables
      _selectedAttributeIds = _selectedVariables.keys.toSet();
      
      _existingImageUrls = List.from(listing.productImages);
    } else {
      // Set default WhatsApp from business profile
      if (_businessProfile != null && _businessProfile!['whatsappNumber'] != null) {
        _whatsappController.text = _businessProfile!['whatsappNumber'];
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _productImages.add(File(image.path));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  void _removeImage(int index, {bool isExisting = false}) {
    setState(() {
      if (isExisting) {
        _existingImageUrls.removeAt(index);
      } else {
        _productImages.removeAt(index);
      }
    });
  }

  Future<void> _saveListing() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validate required variables
    final missingVariables = <String>[];
    for (final attribute in _availableAttributes) {
      final attributeId = attribute['id'];
      final attributeName = attribute['name'] ?? '';
      final isRequired = attribute['required'] ?? false;
      
      if (isRequired && 
          (!_selectedVariables.containsKey(attributeId) || 
           _selectedVariables[attributeId]?.isEmpty == true)) {
        missingVariables.add(attributeName);
      }
    }
    
    if (missingVariables.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please select: ${missingVariables.join(', ')}',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final userId = _userService.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      // Upload new images
      List<String> imageUrls = List.from(_existingImageUrls);
      
      for (final imageFile in _productImages) {
        final imageUrl = await _fileUploadService.uploadFile(
          imageFile,
          'price_listings/${widget.masterProduct.id}/${DateTime.now().millisecondsSinceEpoch}',
        );
        imageUrls.add(imageUrl);
      }

      // Create price listing
      final countryService = CountryService.instance;
      final userCountryCode = countryService.countryCode ?? 'LK';
      final userCountryName = countryService.countryName ?? 'Sri Lanka';
      
      final priceListing = PriceListing(
        id: widget.existingListing?.id ?? '',
        businessId: userId,
        businessName: _businessProfile?['businessName'] ?? 'Unknown Business',
        businessLogo: _businessProfile?['businessLogo'] ?? '',
        masterProductId: widget.masterProduct.id,
        productName: widget.masterProduct.name,
        brand: widget.masterProduct.brand,
        category: widget.masterProduct.category,
        subcategory: widget.masterProduct.subcategory,
        price: double.parse(_priceController.text),
        currency: _currency,
        modelNumber: _modelNumberController.text.isEmpty ? null : _modelNumberController.text,
        selectedVariables: _selectedVariables,
        productImages: imageUrls,
        productLink: _productLinkController.text.isEmpty ? null : _productLinkController.text,
        whatsappNumber: _whatsappController.text.isEmpty ? null : _whatsappController.text,
        isAvailable: _isAvailable,
        stockQuantity: int.tryParse(_stockController.text) ?? 0,
        createdAt: widget.existingListing?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        clickCount: widget.existingListing?.clickCount ?? 0,
        rating: widget.existingListing?.rating ?? 0.0,
        reviewCount: widget.existingListing?.reviewCount ?? 0,
        country: userCountryCode,
        countryName: userCountryName,
      );

      await _pricingService.addOrUpdatePriceListing(priceListing);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingListing == null 
                  ? 'Price listing added successfully!'
                  : 'Price listing updated successfully!'
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving listing: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textPrimary,
        title: Text(
          widget.existingListing == null ? 'Add Price' : 'Edit Price'
        ),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildProductHeader(),
              _buildPriceForm(),
              _buildVariablesSection(),
              _buildImagesSection(),
              _buildContactSection(),
              _buildSaveButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[100],
            ),
            child: widget.masterProduct.images.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      widget.masterProduct.images.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Icon(Icons.image, color: Colors.grey[400]),
                    ),
                  )
                : Icon(Icons.image, color: Colors.grey[400]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.masterProduct.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.masterProduct.brand} • ${widget.masterProduct.category}',
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
    );
  }

  Widget _buildPriceForm() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pricing Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Price and currency
          Row(
            children: [
              SizedBox(
                width: 100,
                child: DropdownButtonFormField<String>(
                  value: _currency,
                  decoration: const InputDecoration(
                    labelText: 'Currency',
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                  items: ['LKR', 'USD', 'EUR'].map((currency) {
                    return DropdownMenuItem(
                      value: currency,
                      child: Text(currency),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _currency = value!);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price *',
                    filled: true,
                    fillColor: AppTheme.backgroundColor,
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Price is required';
                    if (double.tryParse(value!) == null) return 'Invalid price';
                    return null;
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Stock quantity
          TextFormField(
            controller: _stockController,
            decoration: const InputDecoration(
              labelText: 'Stock Quantity',
              helperText: 'Leave empty if stock varies',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderSide: BorderSide.none),
            ),
            keyboardType: TextInputType.number,
          ),
          
          const SizedBox(height: 16),
          
          // Model number
          TextFormField(
            controller: _modelNumberController,
            decoration: const InputDecoration(
              labelText: 'Model Number (Optional)',
              helperText: 'e.g., XPS-13-9315, iPhone-14-Pro',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderSide: BorderSide.none),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Availability switch
          Row(
            children: [
              const Text('Product Available'),
              const Spacer(),
              Switch(
                value: _isAvailable,
                onChanged: (value) => setState(() => _isAvailable = value),
                activeColor: AppTheme.primaryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVariablesSection() {
    if (_availableAttributes.isEmpty) {
      return const SizedBox();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune,
                color: Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Product Specifications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Select which specifications apply to your product',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          
          // Step 1: Select which attributes to use
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline, 
                         color: AppTheme.textSecondary, 
                         size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Step 1: Choose Relevant Attributes',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableAttributes.map((attribute) {
                    final attributeId = attribute['id'];
                    final attributeName = attribute['name'] ?? '';
                    final isSelected = _selectedAttributeIds.contains(attributeId);
                    
                    return FilterChip(
                      label: Text(
                        attributeName,
                        style: TextStyle(
                          color: isSelected ? AppTheme.textPrimary : AppTheme.textSecondary,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedAttributeIds.add(attributeId);
                          } else {
                            _selectedAttributeIds.remove(attributeId);
                            _selectedVariables.remove(attributeId);
                          }
                        });
                      },
                      selectedColor: Colors.transparent,
                      backgroundColor: Colors.transparent,
                      side: BorderSide.none,
                      checkmarkColor: Colors.transparent,
                      elevation: 0,
                      pressElevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          
          // Step 2: Fill in values for selected attributes
          if (_selectedAttributeIds.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit_outlined, 
                           color: AppTheme.textSecondary, 
                           size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'Step 2: Fill in the Details',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  ..._availableAttributes
                      .where((attr) => _selectedAttributeIds.contains(attr['id']))
                      .map((attribute) {
                    final attributeId = attribute['id'];
                    final attributeName = attribute['name'] ?? '';
                    final attributeType = attribute['type'] ?? 'select';
                    final possibleValues = List<String>.from(attribute['possibleValues'] ?? []);
                    final description = attribute['description'] ?? '';
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            attributeName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              description,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          
                          if (attributeType == 'select' || attributeType == 'dropdown') ...[
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundColor, // flat background contrast
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _selectedVariables[attributeId],
                                hint: Text(
                                  'Select $attributeName',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  border: InputBorder.none,
                                ),
                                items: possibleValues.map((option) {
                                  return DropdownMenuItem(
                                    value: option,
                                    child: Text(
                                      option,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    if (value != null) {
                                      _selectedVariables[attributeId] = value;
                                    } else {
                                      _selectedVariables.remove(attributeId);
                                    }
                                  });
                                },
                              ),
                            ),
                          ] else if (attributeType == 'text') ...[
                            TextFormField(
                              initialValue: _selectedVariables[attributeId],
                              decoration: InputDecoration(
                                hintText: 'Enter $attributeName',
                                filled: true,
                                fillColor: Colors.white,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  if (value.isNotEmpty) {
                                    _selectedVariables[attributeId] = value;
                                  } else {
                                    _selectedVariables.remove(attributeId);
                                  }
                                });
                              },
                            ),
                          ] else if (attributeType == 'boolean') ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Switch(
                                    value: _selectedVariables[attributeId] == 'true',
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedVariables[attributeId] = value.toString();
                                      });
                                    },
                                    activeColor: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _selectedVariables[attributeId] == 'true' ? 'Yes' : 'No',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImagesSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Product Images',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Add Image'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_existingImageUrls.isEmpty && _productImages.isEmpty)
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image, color: Colors.grey[400], size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'No images added',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Existing images
                  ..._existingImageUrls.asMap().entries.map((entry) {
                    final index = entry.key;
                    final imageUrl = entry.value;
                    return _buildImageThumbnail(
                      imageUrl: imageUrl,
                      onRemove: () => _removeImage(index, isExisting: true),
                    );
                  }),
                  
                  // New images
                  ..._productImages.asMap().entries.map((entry) {
                    final index = entry.key;
                    final imageFile = entry.value;
                    return _buildImageThumbnail(
                      imageFile: imageFile,
                      onRemove: () => _removeImage(index),
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail({
    String? imageUrl,
    File? imageFile,
    required VoidCallback onRemove,
  }) {
    return Container(
      width: 100,
      height: 100,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[100],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageFile != null
                  ? Image.file(imageFile, fit: BoxFit.cover, width: 100, height: 100)
                  : Image.network(imageUrl!, fit: BoxFit.cover, width: 100, height: 100),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _productLinkController,
            decoration: const InputDecoration(
              labelText: 'Product Link (Optional)',
              helperText: 'Link to your product page or online store',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderSide: BorderSide.none),
            ),
            keyboardType: TextInputType.url,
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _whatsappController,
            decoration: const InputDecoration(
              labelText: 'WhatsApp Number (Optional)',
              helperText: 'Include country code (e.g., +94771234567)',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderSide: BorderSide.none),
            ),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveListing,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                widget.existingListing == null ? 'Add Price Listing' : 'Update Price Listing',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    _stockController.dispose();
    _productLinkController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }
}
