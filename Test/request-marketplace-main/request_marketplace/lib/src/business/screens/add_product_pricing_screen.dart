import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../models/product_models.dart';
import '../../services/product_service.dart';
import '../../theme/app_theme.dart';

// Product Variables Data Model
class ProductVariable {
  final String id;
  final String name;
  final String type; // 'text', 'number', 'dropdown', 'multiselect'
  final List<String>? options; // For dropdown/multiselect
  final bool required;
  final String? description;

  ProductVariable({
    required this.id,
    required this.name,
    required this.type,
    this.options,
    this.required = false,
    this.description,
  });

  factory ProductVariable.fromMap(Map<String, dynamic> map) {
    return ProductVariable(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? 'text',
      options: map['possibleValues'] != null ? List<String>.from(map['possibleValues']) : null,
      required: map['isRequired'] ?? false,
      description: map['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'options': options,
      'required': required,
      'description': description,
    };
  }
}

class AddProductPricingScreen extends StatefulWidget {
  final MasterProduct product;
  final String? businessId; // Optional parameter for compatibility

  const AddProductPricingScreen({
    super.key,
    required this.product,
    this.businessId, // Optional for backward compatibility
  });

  @override
  State<AddProductPricingScreen> createState() => _AddProductPricingScreenState();
}

class _AddProductPricingScreenState extends State<AddProductPricingScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _priceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _deliveryCostController = TextEditingController();
  final _deliveryDaysController = TextEditingController();
  final _freeDeliveryThresholdController = TextEditingController();
  final _warrantyMonthsController = TextEditingController();
  final _warrantyDescriptionController = TextEditingController();
  final _businessUrlController = TextEditingController();
  final _businessPhoneController = TextEditingController();
  final _businessWhatsappController = TextEditingController();

  // State variables
  bool _freeDelivery = false;
  bool _isLoading = false;
  bool _isLoadingVariables = true;
  bool _isUploadingImages = false;
  
  // Product Variables
  List<ProductVariable> _availableVariables = [];
  List<String> _selectedVariableIds = [];
  Map<String, TextEditingController> _variableControllers = {};
  
  // Image Upload
  final ImagePicker _imagePicker = ImagePicker();
  List<XFile> _selectedImages = [];
  List<String> _uploadedImageUrls = [];

  @override
  void initState() {
    super.initState();
    _loadAvailableVariables();
  }

  // Load available variables from Firestore
  Future<void> _loadAvailableVariables() async {
    try {
      setState(() {
        _isLoadingVariables = true;
      });

      final snapshot = await FirebaseFirestore.instance
          .collection('custom_product_variables')
          .get();

      final variables = snapshot.docs
          .map((doc) => ProductVariable.fromMap({...doc.data(), 'id': doc.id}))
          .toList();

      setState(() {
        _availableVariables = variables;
        _isLoadingVariables = false;
      });

      print('🔧 Loaded ${variables.length} product variables');
    } catch (e) {
      setState(() {
        _isLoadingVariables = false;
      });
      print('Error loading product variables: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading product variables: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Add variable to selected list
  void _addVariable() {
    final unselectedVariables = _availableVariables
        .where((v) => !_selectedVariableIds.contains(v.id))
        .toList();

    if (unselectedVariables.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All available variables have been added'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Variable to Add',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: unselectedVariables.length,
                itemBuilder: (context, index) {
                  final variable = unselectedVariables[index];
                  return ListTile(
                    title: Text(variable.name),
                    subtitle: variable.description != null
                        ? Text(variable.description!)
                        : null,
                    trailing: Chip(
                      label: Text(variable.type),
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    ),
                    onTap: () {
                      setState(() {
                        _selectedVariableIds.add(variable.id);
                        _variableControllers[variable.id] = TextEditingController();
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Remove variable from selected list
  void _removeVariable(String variableId) {
    setState(() {
      _selectedVariableIds.remove(variableId);
      _variableControllers[variableId]?.dispose();
      _variableControllers.remove(variableId);
    });
  }

  // Build variable input field
  Widget _buildVariableField(ProductVariable variable) {
    final controller = _variableControllers[variable.id]!;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  variable.name + (variable.required ? ' *' : ''),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _removeVariable(variable.id),
                icon: const Icon(Icons.close, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          if (variable.description != null) ...[
            const SizedBox(height: 4),
            Text(
              variable.description!,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
          const SizedBox(height: 8),
          if (variable.type == 'dropdown' && variable.options != null)
            DropdownButtonFormField<String>(
              value: controller.text.isEmpty ? null : controller.text,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              hint: Text(
                'Select option',
                style: TextStyle(color: Colors.grey.shade400),
              ),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              items: variable.options!.map((option) {
                return DropdownMenuItem(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: (value) {
                controller.text = value ?? '';
              },
            )
          else
            TextFormField(
              controller: controller,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                hintText: variable.type == 'number' ? 'Enter number' : 'Enter text',
                hintStyle: TextStyle(color: Colors.grey.shade400),
              ),
              keyboardType: variable.type == 'number' 
                  ? TextInputType.number 
                  : TextInputType.text,
              validator: variable.required ? (value) {
                if (value == null || value.isEmpty) {
                  return 'This field is required';
                }
                return null;
              } : null,
            ),
        ],
      ),
    );
  }

  // Image Upload Methods
  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
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
          _selectedImages.add(image);
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

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Product Images',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppTheme.primaryColor),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImages();
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppTheme.primaryColor),
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

  Future<List<String>> _uploadImages() async {
    if (_selectedImages.isEmpty) return [];

    setState(() {
      _isUploadingImages = true;
    });

    final uploadedUrls = <String>[];

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      for (int i = 0; i < _selectedImages.length; i++) {
        final file = _selectedImages[i];
        final fileName = 'business_product_${user.uid}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('business_product_images')
            .child(user.uid)
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

  // Helper function to safely parse delivery days
  int _parseDeliveryDays(String text) {
    if (text.isEmpty) return 1;
    
    // Remove any whitespace
    text = text.trim();
    
    // Check if it's a range (e.g., "1-4", "3-7")
    if (text.contains('-')) {
      final parts = text.split('-');
      if (parts.length == 2) {
        final start = int.tryParse(parts[0].trim());
        final end = int.tryParse(parts[1].trim());
        if (start != null && end != null) {
          // Return the average of the range, or the end value
          return end;
        }
      }
    }
    
    // Try to parse as a single number
    final parsed = int.tryParse(text);
    if (parsed != null && parsed > 0) {
      return parsed;
    }
    
    // Default to 1 if parsing fails
    return 1;
  }

  // Helper function to safely parse double values
  double _parseDouble(String text, double defaultValue) {
    if (text.isEmpty) return defaultValue;
    final parsed = double.tryParse(text.trim());
    return parsed ?? defaultValue;
  }

  // Helper function to safely parse integer values
  int _parseInt(String text, int defaultValue) {
    if (text.isEmpty) return defaultValue;
    final parsed = int.tryParse(text.trim());
    return parsed ?? defaultValue;
  }

  Future<void> _addPricingAndPublish() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get the business ID - prefer widget.businessId, fallback to user's business profile
      String businessId = widget.businessId ?? user.uid;
      
      // If no business ID was passed, try to get it from user's business profile
      if (widget.businessId == null) {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
          
          if (userDoc.exists) {
            final userData = userDoc.data()!;
            final businessProfile = userData['businessProfile'] as Map<String, dynamic>?;
            if (businessProfile != null && businessProfile['businessId'] != null) {
              businessId = businessProfile['businessId'] as String;
              print('🔍 Debug: Using business ID from user profile: $businessId');
            }
          }
        } catch (e) {
          print('🔍 Debug: Could not get business ID from user profile: $e');
        }
      }

      // Prepare delivery info
      final deliveryInfo = ProductDeliveryInfo(
        cost: _parseDouble(_deliveryCostController.text, 0.0),
        estimatedDays: _parseDeliveryDays(_deliveryDaysController.text),
        isFreeDelivery: _freeDelivery,
        freeDeliveryThreshold: _freeDelivery && _freeDeliveryThresholdController.text.isNotEmpty
            ? _parseDouble(_freeDeliveryThresholdController.text, 0.0)
            : null,
      );

      // Prepare warranty info
      final warrantyInfo = ProductWarrantyInfo(
        months: _parseInt(_warrantyMonthsController.text, 0),
        type: 'manufacturer',
        description: _warrantyDescriptionController.text.isNotEmpty 
            ? _warrantyDescriptionController.text 
            : 'Standard warranty',
      );

      // Prepare availability info
      final availability = ProductAvailability(
        isInStock: true,
        quantity: 999, // Default high quantity
        restockDate: null,
      );

      // Upload images if any are selected
      List<String> imageUrls = [];
      if (_selectedImages.isNotEmpty) {
        imageUrls = await _uploadImages();
      }

      // Add variable data to business specific data
      final businessSpecificData = <String, dynamic>{};
      final variableData = <String, String>{};
      for (final variableId in _selectedVariableIds) {
        final controller = _variableControllers[variableId];
        if (controller != null && controller.text.isNotEmpty) {
          final variable = _availableVariables.firstWhere((v) => v.id == variableId);
          variableData[variable.name] = controller.text;
        }
      }
      if (variableData.isNotEmpty) {
        businessSpecificData['variables'] = variableData;
      }

      // Add image URLs to business specific data
      if (imageUrls.isNotEmpty) {
        businessSpecificData['images'] = imageUrls;
      }

      print('🔍 Debug: About to add business product with data:');
      print('- businessId: $businessId');
      print('- masterProductId: ${widget.product.id}');
      print('- widget.product.name: ${widget.product.name}');
      print('- price: ${_parseDouble(_priceController.text, 0.0)}');
      print('- businessSpecificData: $businessSpecificData');

      final productId = await ProductService().addBusinessProduct(
        businessId: businessId,
        masterProductId: widget.product.id,
        price: _parseDouble(_priceController.text, 0.0),
        originalPrice: _originalPriceController.text.isNotEmpty 
            ? _parseDouble(_originalPriceController.text, 0.0) 
            : null,
        deliveryInfo: deliveryInfo,
        warrantyInfo: warrantyInfo,
        availability: availability,
        businessUrl: _businessUrlController.text.isNotEmpty 
            ? _businessUrlController.text 
            : null,
        businessPhone: _businessPhoneController.text.isNotEmpty 
            ? _businessPhoneController.text 
            : null,
        businessWhatsapp: _businessWhatsappController.text.isNotEmpty 
            ? _businessWhatsappController.text 
            : null,
        businessSpecificData: businessSpecificData,
      );

      print('🔍 Debug: Product added with ID: $productId');

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product published successfully! ID: $productId'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Debug',
              onPressed: () async {
                // Debug: Check if product was actually saved
                print('🔍 Debug: Checking products using ProductService...');
                final productService = ProductService();
                final productsFromService = await productService.getBusinessProducts(businessId);
                print('🔍 Debug: ProductService found ${productsFromService.length} products');
                
                print('🔍 Debug: Checking products directly from Firestore...');
                final directSnapshot = await FirebaseFirestore.instance
                    .collection('business_products')
                    .where('businessId', isEqualTo: businessId)
                    .get();
                print('🔍 Debug: Direct Firestore query found ${directSnapshot.docs.length} products');
                
                for (final doc in directSnapshot.docs) {
                  final data = doc.data();
                  print('  - Product ${doc.id}:');
                  print('    businessId: ${data['businessId']}');
                  print('    masterProductId: ${data['masterProductId']}');
                  print('    price: ${data['price']}');
                  print('    isActive: ${data['isActive']}');
                  print('    status: ${data['status']}');
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('Error adding pricing: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding pricing: $e'),
            backgroundColor: Colors.red,
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Pricing',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Publishing your product...',
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: null,
                    child: Text('Go Back'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: widget.product.imageUrls.isNotEmpty
                                ? Image.network(
                                    widget.product.imageUrls.first,
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
                                  widget.product.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.product.description,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    widget.product.brand,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Product Variables Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Product Variables',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            if (!_isLoadingVariables && _availableVariables.isNotEmpty)
                              GestureDetector(
                                onTap: _addVariable,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add, size: 16, color: AppTheme.primaryColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Add Variable',
                                        style: TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        if (_isLoadingVariables)
                          const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        else if (_availableVariables.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Column(
                              children: [
                                Icon(
                                  Icons.settings_outlined,
                                  size: 32,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'No variables available',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (_selectedVariableIds.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.add_box_outlined,
                                  size: 32,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'No variables selected',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _addVariable,
                                  child: Text(
                                    'Tap + to add variables',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Column(
                            children: _selectedVariableIds.map((variableId) {
                              final variable = _availableVariables.firstWhere((v) => v.id == variableId);
                              return _buildVariableField(variable);
                            }).toList(),
                          ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Product Images Section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Product Images',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              if (_selectedImages.isEmpty)
                                Column(
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Add product images to showcase your business',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton.icon(
                                      onPressed: _showImageOptions,
                                      icon: const Icon(Icons.add_a_photo),
                                      label: const Text('Add Images'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.primaryColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Column(
                                  children: [
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 8,
                                        childAspectRatio: 1,
                                      ),
                                      itemCount: _selectedImages.length,
                                      itemBuilder: (context, index) {
                                        return Stack(
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.grey[300]!,
                                                ),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.file(
                                                  File(_selectedImages[index].path),
                                                  fit: BoxFit.cover,
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                ),
                                              ),
                                            ),
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: GestureDetector(
                                                onTap: () => _removeImage(index),
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
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 16),
                                    OutlinedButton.icon(
                                      onPressed: _showImageOptions,
                                      icon: const Icon(Icons.add),
                                      label: const Text('Add More Images'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.primaryColor,
                                        side: BorderSide(color: AppTheme.primaryColor),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Pricing Information
                    const Text(
                      'Pricing Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Selling Price (LKR) *',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextFormField(
                            controller: _priceController,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Enter selling price',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              border: InputBorder.none,
                              prefixText: 'Rs. ',
                              prefixStyle: TextStyle(color: Colors.grey.shade600),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter selling price';
                              }
                              final price = double.tryParse(value);
                              if (price == null) {
                                return 'Please enter valid price';
                              }
                              if (price <= 0) {
                                return 'Price must be greater than 0';
                              }
                              if (price > 10000000) {
                                return 'Price seems too high';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Original Price (LKR)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextFormField(
                            controller: _originalPriceController,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Optional - for showing discounts',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              border: InputBorder.none,
                              prefixText: 'Rs. ',
                              prefixStyle: TextStyle(color: Colors.grey.shade600),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final originalPrice = double.tryParse(value);
                                if (originalPrice == null) {
                                  return 'Please enter valid price';
                                }
                                final sellingPrice = double.tryParse(_priceController.text);
                                if (sellingPrice != null && originalPrice <= sellingPrice) {
                                  return 'Original price should be higher than selling price';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Delivery Information
                    const Text(
                      'Delivery Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Delivery Cost (LKR)',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextFormField(
                                  controller: _deliveryCostController,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'Rs. 0',
                                    hintStyle: TextStyle(color: Colors.grey.shade400),
                                    border: InputBorder.none,
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      final cost = double.tryParse(value);
                                      if (cost == null || cost < 0) {
                                        return 'Enter valid delivery cost';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Delivery Days',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              Text(
                                'e.g., 3 or 1-7 for range',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextFormField(
                                  controller: _deliveryDaysController,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'e.g., 3 or 1-7',
                                    hintStyle: TextStyle(color: Colors.grey.shade400),
                                    border: InputBorder.none,
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      final days = _parseDeliveryDays(value);
                                      if (days <= 0 || days > 365) {
                                        return 'Enter valid delivery days (1-365)';
                                      }
                                    }
                                    return null;
                                  },
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    CheckboxListTile(
                      title: const Text('Free Delivery'),
                      value: _freeDelivery,
                      onChanged: (value) {
                        setState(() {
                          _freeDelivery = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),

                    if (_freeDelivery) ...[
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Free Delivery Threshold (LKR)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: TextFormField(
                              controller: _freeDeliveryThresholdController,
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Minimum order value for free delivery',
                                hintStyle: TextStyle(color: Colors.grey.shade400),
                                border: InputBorder.none,
                                prefixText: 'Rs. ',
                                prefixStyle: TextStyle(color: Colors.grey.shade600),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (value) {
                                if (_freeDelivery && (value == null || value.isEmpty)) {
                                  return 'Enter free delivery threshold';
                                }
                                if (value != null && value.isNotEmpty) {
                                  final threshold = double.tryParse(value);
                                  if (threshold == null || threshold <= 0) {
                                    return 'Enter valid threshold amount';
                                  }
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Warranty Information
                    const Text(
                      'Warranty Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Warranty (Months)',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextFormField(
                                  controller: _warrantyMonthsController,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: '12',
                                    hintStyle: TextStyle(color: Colors.grey.shade400),
                                    border: InputBorder.none,
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      final months = int.tryParse(value);
                                      if (months == null || months < 0 || months > 120) {
                                        return 'Enter valid warranty months (0-120)';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Warranty Description',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextFormField(
                                  controller: _warrantyDescriptionController,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'Brand warranty',
                                    hintStyle: TextStyle(color: Colors.grey.shade400),
                                    border: InputBorder.none,
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Contact Information
                    const Text(
                      'Contact Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Business Website/URL',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextFormField(
                            controller: _businessUrlController,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'https://yourwebsite.com',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.link, color: Colors.grey.shade400),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Business Phone',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextFormField(
                                  controller: _businessPhoneController,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: '+94771234567',
                                    hintStyle: TextStyle(color: Colors.grey.shade400),
                                    border: InputBorder.none,
                                    prefixIcon: Icon(Icons.phone, color: Colors.grey.shade400),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  keyboardType: TextInputType.phone,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'WhatsApp',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextFormField(
                                  controller: _businessWhatsappController,
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: '+94771234567',
                                    hintStyle: TextStyle(color: Colors.grey.shade400),
                                    border: InputBorder.none,
                                    prefixIcon: Icon(Icons.chat, color: Colors.grey.shade400),
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  keyboardType: TextInputType.phone,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Publish Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _addPricingAndPublish,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              )
                            : const Text(
                                'Publish Product',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppTheme.primaryColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'After adding, customers will be able to see your product with pricing and contact you directly.',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
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

  @override
  void dispose() {
    _priceController.dispose();
    _originalPriceController.dispose();
    _deliveryCostController.dispose();
    _deliveryDaysController.dispose();
    _freeDeliveryThresholdController.dispose();
    _warrantyMonthsController.dispose();
    _warrantyDescriptionController.dispose();
    _businessUrlController.dispose();
    _businessPhoneController.dispose();
    _businessWhatsappController.dispose();
    
    // Dispose variable controllers
    for (final controller in _variableControllers.values) {
      controller.dispose();
    }
    
    super.dispose();
  }
}
