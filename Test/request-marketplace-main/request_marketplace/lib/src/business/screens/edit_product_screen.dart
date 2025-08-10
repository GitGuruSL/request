import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/product_models.dart';
import '../../services/business_service.dart';
import '../../services/product_service.dart';

class EditProductScreen extends StatefulWidget {
  final BusinessProduct businessProduct;
  final MasterProduct masterProduct;

  const EditProductScreen({
    super.key,
    required this.businessProduct,
    required this.masterProduct,
  });

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final BusinessService _businessService = BusinessService();
  final ProductService _productService = ProductService();
  final ImagePicker _imagePicker = ImagePicker();
  
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _deliveryCostController = TextEditingController();
  final _deliveryDaysController = TextEditingController();
  final _stockController = TextEditingController();
  final _warrantyMonthsController = TextEditingController();
  final _businessNotesController = TextEditingController();
  
  List<String> _businessImages = [];
  List<XFile> _newImages = [];
  bool _isLoading = false;
  bool _isUploadingImages = false;
  bool _isInStock = true;
  bool _available = true;

  @override
  void initState() {
    super.initState();
    _loadProductData();
  }

  void _loadProductData() {
    final product = widget.businessProduct;
    
    _priceController.text = product.price.toString();
    _originalPriceController.text = product.originalPrice?.toString() ?? '';
    _deliveryCostController.text = product.deliveryInfo?.cost.toString() ?? '0';
    _deliveryDaysController.text = product.deliveryInfo?.estimatedDays.toString() ?? '1';
    _stockController.text = product.availability?.quantity.toString() ?? '1';
    _warrantyMonthsController.text = product.warrantyInfo?.months.toString() ?? '0';
    _businessNotesController.text = product.businessSpecificData['notes']?.toString() ?? '';
    
    _businessImages = List<String>.from(product.additionalImages);
    _isInStock = product.availability?.isInStock ?? true;
    _available = product.available;
  }

  @override
  void dispose() {
    _priceController.dispose();
    _originalPriceController.dispose();
    _deliveryCostController.dispose();
    _deliveryDaysController.dispose();
    _stockController.dispose();
    _warrantyMonthsController.dispose();
    _businessNotesController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (images.isNotEmpty) {
        setState(() {
          _newImages.addAll(images);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _newImages.add(image);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error taking photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeNewImage(int index) {
    setState(() {
      _newImages.removeAt(index);
    });
  }

  void _removeExistingImage(int index) {
    setState(() {
      _businessImages.removeAt(index);
    });
  }

  Future<List<String>> _uploadNewImages() async {
    if (_newImages.isEmpty) return [];
    
    setState(() {
      _isUploadingImages = true;
    });

    List<String> uploadedUrls = [];
    
    try {
      for (int i = 0; i < _newImages.length; i++) {
        final file = _newImages[i];
        final fileName = 'business_product_${widget.businessProduct.id}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('business_product_images')
            .child(widget.businessProduct.businessId)
            .child(fileName);

        final uploadTask = storageRef.putFile(File(file.path));
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        
        uploadedUrls.add(downloadUrl);
      }
    } catch (e) {
      print('Error uploading images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading images: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploadingImages = false;
      });
    }
    
    return uploadedUrls;
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload new images first
      final newImageUrls = await _uploadNewImages();
      
      // Combine existing and new images
      final allImages = [..._businessImages, ...newImageUrls];

      // Update product data
      final success = await _businessService.updateProductInCatalog(
        widget.businessProduct.id,
        price: double.parse(_priceController.text),
        originalPrice: _originalPriceController.text.isNotEmpty 
            ? double.parse(_originalPriceController.text) 
            : null,
        deliveryCharge: double.parse(_deliveryCostController.text),
        warrantyMonths: int.parse(_warrantyMonthsController.text),
        additionalImages: allImages,
        quantity: int.parse(_stockController.text),
        isInStock: _isInStock,
        businessSpecificData: {
          'notes': _businessNotesController.text,
          'lastUpdated': DateTime.now().toIso8601String(),
        },
      );

      if (success) {
        // Also update availability if changed
        if (_available != widget.businessProduct.available) {
          await FirebaseFirestore.instance
              .collection('business_products')
              .doc(widget.businessProduct.id)
              .update({
            'available': _available,
            'updatedAt': Timestamp.now(),
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Product updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update product'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error updating product: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Product Images',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImages();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBFE),
      appBar: AppBar(
        title: const Text('Edit Product'),
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
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Color(0xFF6750A4),
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Info Card
              Container(
                width: double.infinity,
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
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: widget.masterProduct.imageUrls.isNotEmpty
                            ? Image.network(
                                widget.masterProduct.imageUrls.first,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.image_not_supported),
                                ),
                              )
                            : Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image_not_supported),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.masterProduct.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1D1B20),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.masterProduct.description,
                              style: const TextStyle(
                                color: Color(0xFF49454F),
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.masterProduct.brand.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Brand: ${widget.masterProduct.brand}',
                                style: const TextStyle(
                                  color: Color(0xFF49454F),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Product Status
                const Text(
                  'Product Status',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1B20),
                ),
              ),
              const SizedBox(height: 16),

              SwitchListTile(
                title: const Text('Available for Sale'),
                subtitle: const Text('Customers can see and purchase this product'),
                value: _available,
                onChanged: (value) {
                  setState(() {
                    _available = value;
                  });
                },
              ),

              SwitchListTile(
                title: const Text('In Stock'),
                subtitle: const Text('Product is currently available'),
                value: _isInStock,
                onChanged: (value) {
                  setState(() {
                    _isInStock = value;
                  });
                },
              ),

              const SizedBox(height: 24),

              // Business Images Section
              const Text(
                'Your Product Images',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add your own photos to showcase the product better',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),

              // Image Grid
              if (_businessImages.isNotEmpty || _newImages.isNotEmpty) ...[
                SizedBox(
                  height: 120,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      // Existing images
                      ..._businessImages.asMap().entries.map((entry) {
                        final index = entry.key;
                        final imageUrl = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: 100,
                                    height: 100,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.broken_image),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeExistingImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
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
                      }),

                      // New images (not yet uploaded)
                      ..._newImages.asMap().entries.map((entry) {
                        final index = entry.key;
                        final imageFile = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(imageFile.path),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeNewImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
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
                              if (_isUploadingImages)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),

                      // Add image button
                      GestureDetector(
                        onTap: _showImageOptions,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 32, color: Colors.grey),
                              SizedBox(height: 4),
                              Text(
                                'Add Photo',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // No images yet
                GestureDetector(
                  onTap: _showImageOptions,
                  child: Container(
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'Add Your Product Images',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Show customers your actual product',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Pricing Information
              const Text(
                'Pricing Information',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: const InputDecoration(
                        labelText: 'Selling Price (LKR) *',
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixText: 'Rs. ',
                        labelStyle: TextStyle(color: Color(0xFF49454F)),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter selling price';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) {
                          return 'Please enter valid price';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _originalPriceController,
                      decoration: const InputDecoration(
                        labelText: 'Original Price (LKR)',
                        hintText: 'Optional',
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixText: 'Rs. ',
                        labelStyle: TextStyle(color: Color(0xFF49454F)),
                        hintStyle: TextStyle(color: Color(0xFF49454F)),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final originalPrice = double.tryParse(value);
                          if (originalPrice == null) {
                            return 'Invalid price';
                          }
                          final sellingPrice = double.tryParse(_priceController.text);
                          if (sellingPrice != null && originalPrice <= sellingPrice) {
                            return 'Should be higher than selling price';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Stock and Delivery
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      decoration: const InputDecoration(
                        labelText: 'Stock Quantity *',
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        suffixText: 'units',
                        labelStyle: TextStyle(color: Color(0xFF49454F)),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter stock';
                        }
                        final stock = int.tryParse(value);
                        if (stock == null || stock < 0) {
                          return 'Invalid stock';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _deliveryCostController,
                      decoration: const InputDecoration(
                        labelText: 'Delivery Cost (LKR) *',
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        prefixText: 'Rs. ',
                        labelStyle: TextStyle(color: Color(0xFF49454F)),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter delivery cost';
                        }
                        final cost = double.tryParse(value);
                        if (cost == null || cost < 0) {
                          return 'Invalid cost';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _deliveryDaysController,
                      decoration: const InputDecoration(
                        labelText: 'Delivery Days *',
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        suffixText: 'days',
                        labelStyle: TextStyle(color: Color(0xFF49454F)),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter delivery days';
                        }
                        final days = int.tryParse(value);
                        if (days == null || days < 0) {
                          return 'Invalid days';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _warrantyMonthsController,
                      decoration: const InputDecoration(
                        labelText: 'Warranty (Months)',
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        suffixText: 'months',
                        labelStyle: TextStyle(color: Color(0xFF49454F)),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final months = int.tryParse(value);
                          if (months == null || months < 0) {
                            return 'Invalid months';
                          }
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Business Notes
              TextFormField(
                controller: _businessNotesController,
                decoration: const InputDecoration(
                  labelText: 'Additional Notes',
                  hintText: 'Any additional information about this product',
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  labelStyle: TextStyle(color: Color(0xFF49454F)),
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              // Update Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Updating Product...'),
                          ],
                        )
                      : const Text(
                          'Update Product',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Help text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Changes will be reflected immediately. Your product images help customers see the actual item they\'ll receive.',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                        ),
                      ),
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
}
