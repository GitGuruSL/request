import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/master_product.dart';
import '../../models/price_listing.dart';
import '../../services/pricing_service.dart';
import '../../services/enhanced_user_service.dart';
import '../../services/file_upload_service.dart';
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
  final TextEditingController _productLinkController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();

  // Form state
  String _currency = 'LKR';
  bool _isAvailable = true;
  Map<String, String> _selectedVariables = {};
  List<File> _productImages = [];
  List<String> _existingImageUrls = [];
  bool _isSaving = false;

  Map<String, dynamic>? _businessProfile;

  @override
  void initState() {
    super.initState();
    _loadBusinessProfile();
    _initializeForm();
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
      _productLinkController.text = listing.productLink ?? '';
      _whatsappController.text = listing.whatsappNumber ?? '';
      _currency = listing.currency;
      _isAvailable = listing.isAvailable;
      _selectedVariables = Map.from(listing.selectedVariables);
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
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
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
                    fillColor: Colors.white,
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
                    fillColor: Colors.white,
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
    if (widget.masterProduct.availableVariables.isEmpty) {
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
          const Text(
            'Product Specifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          ...widget.masterProduct.availableVariables.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedVariables[entry.key],
                    hint: Text('Select ${entry.key}'),
                    decoration: const InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderSide: BorderSide.none),
                    ),
                    items: entry.value.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(option),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        if (value != null) {
                          _selectedVariables[entry.key] = value;
                        } else {
                          _selectedVariables.remove(entry.key);
                        }
                      });
                    },
                  ),
                ],
              ),
            );
          }).toList(),
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
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!, style: BorderStyle.solid),
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
