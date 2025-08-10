// Product Models for Centralized Product Category System
// Support for AI-powered product addition and business management

import 'package:cloud_firestore/cloud_firestore.dart';

/// Product Category Model - Centrally managed by backend
class ProductCategory {
  final String id;
  final String name;
  final String description;
  final String? parentCategoryId; // For subcategories
  final List<String> subcategoryIds;
  final String iconUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> metadata; // For AI processing hints

  ProductCategory({
    required this.id,
    required this.name,
    required this.description,
    this.parentCategoryId,
    this.subcategoryIds = const [],
    required this.iconUrl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  factory ProductCategory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductCategory(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      parentCategoryId: data['parentCategoryId'],
      subcategoryIds: List<String>.from(data['subcategoryIds'] ?? []),
      iconUrl: data['iconUrl'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp 
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      metadata: data['metadata'] ?? {},
    );
  }

  factory ProductCategory.fromMap(Map<String, dynamic> data, String id) {
    return ProductCategory(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      parentCategoryId: data['parentCategoryId'],
      subcategoryIds: List<String>.from(data['subcategoryIds'] ?? []),
      iconUrl: data['iconUrl'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp 
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      metadata: data['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'parentCategoryId': parentCategoryId,
      'subcategoryIds': subcategoryIds,
      'iconUrl': iconUrl,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toMap() {
    return toFirestore();
  }
}

/// Master Product Model - AI-generated base product data
class MasterProduct {
  final String id;
  final String name;
  final String description;
  final String categoryId;
  final String subcategoryId;
  final String brand;
  final Map<String, dynamic> specifications; // Technical specs
  final List<String> imageUrls;
  final List<String> keywords; // For search optimization
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ProductAIData? aiData; // AI processing information

  MasterProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryId,
    required this.subcategoryId,
    required this.brand,
    this.specifications = const {},
    this.imageUrls = const [],
    this.keywords = const [],
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.aiData,
  });

  factory MasterProduct.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MasterProduct(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      categoryId: data['categoryId'] ?? '',
      subcategoryId: data['subcategoryId'] ?? '',
      brand: data['brand'] ?? '',
      specifications: data['specifications'] ?? {},
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      keywords: List<String>.from(data['keywords'] ?? []),
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp 
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      aiData: data['aiData'] != null 
          ? ProductAIData.fromMap(data['aiData']) 
          : null,
    );
  }

  factory MasterProduct.fromMap(Map<String, dynamic> data, String id) {
    return MasterProduct(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      categoryId: data['categoryId'] ?? '',
      subcategoryId: data['subcategoryId'] ?? '',
      brand: data['brand'] ?? '',
      specifications: Map<String, dynamic>.from(data['specifications'] ?? {}),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      keywords: List<String>.from(data['keywords'] ?? []),
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp 
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      aiData: data['aiData'] != null 
          ? ProductAIData.fromMap(data['aiData']) 
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'categoryId': categoryId,
      'subcategoryId': subcategoryId,
      'brand': brand,
      'specifications': specifications,
      'imageUrls': imageUrls,
      'keywords': keywords,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'aiData': aiData?.toMap(),
    };
  }

  Map<String, dynamic> toMap() {
    return toFirestore();
  }
}

/// Business Product Listing - Business-specific pricing and details
class BusinessProduct {
  final String id;
  final String businessId;
  final String masterProductId;
  final String? businessName;
  final double price;
  final int stock;
  final bool available;
  final String? businessNotes;
  final String status; // pending, approved, rejected
  final String? submittedBy;
  final double? originalPrice; // For showing discounts
  final ProductDeliveryInfo? deliveryInfo;
  final ProductWarrantyInfo? warrantyInfo;
  final List<String> additionalImages; // Business-specific images
  final String? businessUrl; // Click-through URL
  final String? businessPhone;
  final String? businessWhatsapp;
  final ProductAvailability? availability;
  final int clickCount; // For revenue tracking
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final Map<String, dynamic> businessSpecificData;

  BusinessProduct({
    required this.id,
    required this.businessId,
    required this.masterProductId,
    this.businessName,
    required this.price,
    this.stock = 0,
    this.available = true,
    this.businessNotes,
    this.status = 'pending',
    this.submittedBy,
    this.originalPrice,
    this.deliveryInfo,
    this.warrantyInfo,
    this.additionalImages = const [],
    this.businessUrl,
    this.businessPhone,
    this.businessWhatsapp,
    this.availability,
    this.clickCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.businessSpecificData = const {},
  });

  factory BusinessProduct.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BusinessProduct(
      id: doc.id,
      businessId: data['businessId'] ?? '',
      masterProductId: data['masterProductId'] ?? '',
      businessName: data['businessName'],
      price: (data['price'] ?? 0).toDouble(),
      stock: data['stock'] ?? 0,
      available: data['available'] ?? true,
      businessNotes: data['businessNotes'],
      status: data['status'] ?? 'pending',
      submittedBy: data['submittedBy'],
      originalPrice: data['originalPrice']?.toDouble(),
      deliveryInfo: data['deliveryInfo'] != null 
          ? ProductDeliveryInfo.fromMap(data['deliveryInfo'])
          : null,
      warrantyInfo: data['warrantyInfo'] != null 
          ? ProductWarrantyInfo.fromMap(data['warrantyInfo'])
          : null,
      additionalImages: List<String>.from(data['additionalImages'] ?? []),
      businessUrl: data['businessUrl'],
      businessPhone: data['businessPhone'],
      businessWhatsapp: data['businessWhatsapp'],
      availability: data['availability'] != null 
          ? ProductAvailability.fromMap(data['availability'])
          : null,
      clickCount: data['clickCount'] ?? 0,
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp 
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      isActive: data['isActive'] ?? true,
      businessSpecificData: data['businessSpecificData'] ?? {},
    );
  }

  factory BusinessProduct.fromMap(Map<String, dynamic> data, String id) {
    return BusinessProduct(
      id: id,
      businessId: data['businessId'] ?? '',
      masterProductId: data['masterProductId'] ?? '',
      businessName: data['businessName'],
      price: (data['price'] ?? 0).toDouble(),
      stock: data['stock'] ?? 0,
      available: data['available'] ?? true,
      businessNotes: data['businessNotes'],
      status: data['status'] ?? 'pending',
      submittedBy: data['submittedBy'],
      originalPrice: data['originalPrice']?.toDouble(),
      deliveryInfo: data['deliveryInfo'] != null 
          ? ProductDeliveryInfo.fromMap(data['deliveryInfo'])
          : null,
      warrantyInfo: data['warrantyInfo'] != null 
          ? ProductWarrantyInfo.fromMap(data['warrantyInfo'])
          : null,
      additionalImages: List<String>.from(data['additionalImages'] ?? []),
      businessUrl: data['businessUrl'],
      businessPhone: data['businessPhone'],
      businessWhatsapp: data['businessWhatsapp'],
      availability: data['availability'] != null 
          ? ProductAvailability.fromMap(data['availability'])
          : null,
      clickCount: data['clickCount'] ?? 0,
      createdAt: data['createdAt'] is Timestamp 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp 
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      isActive: data['isActive'] ?? true,
      businessSpecificData: data['businessSpecificData'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'businessId': businessId,
      'masterProductId': masterProductId,
      'businessName': businessName,
      'price': price,
      'stock': stock,
      'available': available,
      'businessNotes': businessNotes,
      'status': status,
      'submittedBy': submittedBy,
      'originalPrice': originalPrice,
      'deliveryInfo': deliveryInfo?.toMap(),
      'warrantyInfo': warrantyInfo?.toMap(),
      'additionalImages': additionalImages,
      'businessUrl': businessUrl,
      'businessPhone': businessPhone,
      'businessWhatsapp': businessWhatsapp,
      'availability': availability?.toMap(),
      'clickCount': clickCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
      'businessSpecificData': businessSpecificData,
    };
  }

  Map<String, dynamic> toMap() {
    return toFirestore();
  }

  /// Calculate discount percentage
  double? get discountPercentage {
    if (originalPrice == null || originalPrice! <= price) return null;
    return ((originalPrice! - price) / originalPrice!) * 100;
  }

  /// Check if product is in stock
  bool get isInStock => availability?.isInStock ?? (stock > 0 && available);
}

/// Product Delivery Information
class ProductDeliveryInfo {
  final double cost;
  final int estimatedDays;
  final List<String> availableAreas; // Delivery areas
  final bool isFreeDelivery;
  final double? freeDeliveryThreshold; // Minimum order for free delivery
  final Map<String, double>? areaSpecificCosts; // Different costs per area

  ProductDeliveryInfo({
    required this.cost,
    required this.estimatedDays,
    this.availableAreas = const [],
    this.isFreeDelivery = false,
    this.freeDeliveryThreshold,
    this.areaSpecificCosts,
  });

  factory ProductDeliveryInfo.fromMap(Map<String, dynamic> map) {
    return ProductDeliveryInfo(
      cost: (map['cost'] ?? 0).toDouble(),
      estimatedDays: map['estimatedDays'] ?? 0,
      availableAreas: List<String>.from(map['availableAreas'] ?? []),
      isFreeDelivery: map['isFreeDelivery'] ?? false,
      freeDeliveryThreshold: map['freeDeliveryThreshold']?.toDouble(),
      areaSpecificCosts: map['areaSpecificCosts'] != null 
          ? Map<String, double>.from(map['areaSpecificCosts']) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cost': cost,
      'estimatedDays': estimatedDays,
      'availableAreas': availableAreas,
      'isFreeDelivery': isFreeDelivery,
      'freeDeliveryThreshold': freeDeliveryThreshold,
      'areaSpecificCosts': areaSpecificCosts,
    };
  }
}

/// Product Warranty Information
class ProductWarrantyInfo {
  final int months;
  final String type; // manufacturer, seller, extended
  final String description;
  final bool hasExtendedWarranty;
  final double? extendedWarrantyCost;
  final int? extendedWarrantyMonths;

  ProductWarrantyInfo({
    required this.months,
    required this.type,
    required this.description,
    this.hasExtendedWarranty = false,
    this.extendedWarrantyCost,
    this.extendedWarrantyMonths,
  });

  factory ProductWarrantyInfo.fromMap(Map<String, dynamic> map) {
    return ProductWarrantyInfo(
      months: map['months'] ?? 0,
      type: map['type'] ?? '',
      description: map['description'] ?? '',
      hasExtendedWarranty: map['hasExtendedWarranty'] ?? false,
      extendedWarrantyCost: map['extendedWarrantyCost']?.toDouble(),
      extendedWarrantyMonths: map['extendedWarrantyMonths'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'months': months,
      'type': type,
      'description': description,
      'hasExtendedWarranty': hasExtendedWarranty,
      'extendedWarrantyCost': extendedWarrantyCost,
      'extendedWarrantyMonths': extendedWarrantyMonths,
    };
  }
}

/// Product Availability Information
class ProductAvailability {
  final bool isInStock;
  final int quantity;
  final DateTime? restockDate;
  final bool allowPreOrder;
  final int? preOrderDays;

  ProductAvailability({
    required this.isInStock,
    required this.quantity,
    this.restockDate,
    this.allowPreOrder = false,
    this.preOrderDays,
  });

  factory ProductAvailability.fromMap(Map<String, dynamic> map) {
    return ProductAvailability(
      isInStock: map['isInStock'] ?? false,
      quantity: map['quantity'] ?? 0,
      restockDate: map['restockDate'] != null 
          ? (map['restockDate'] is Timestamp 
              ? (map['restockDate'] as Timestamp).toDate() 
              : DateTime.now())
          : null,
      allowPreOrder: map['allowPreOrder'] ?? false,
      preOrderDays: map['preOrderDays'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isInStock': isInStock,
      'quantity': quantity,
      'restockDate': restockDate != null 
          ? Timestamp.fromDate(restockDate!) 
          : null,
      'allowPreOrder': allowPreOrder,
      'preOrderDays': preOrderDays,
    };
  }
}

/// AI Data for product processing
class ProductAIData {
  final String source; // Where AI got the data
  final double confidence; // AI confidence score
  final DateTime processedAt;
  final Map<String, dynamic> extractedData; // Raw AI extracted data
  final bool needsVerification;

  ProductAIData({
    required this.source,
    required this.confidence,
    required this.processedAt,
    this.extractedData = const {},
    this.needsVerification = false,
  });

  factory ProductAIData.fromMap(Map<String, dynamic> map) {
    return ProductAIData(
      source: map['source'] ?? '',
      confidence: (map['confidence'] ?? 0).toDouble(),
      processedAt: map['processedAt'] is Timestamp 
          ? (map['processedAt'] as Timestamp).toDate()
          : DateTime.now(),
      extractedData: map['extractedData'] ?? {},
      needsVerification: map['needsVerification'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'source': source,
      'confidence': confidence,
      'processedAt': Timestamp.fromDate(processedAt),
      'extractedData': extractedData,
      'needsVerification': needsVerification,
    };
  }
}

/// Product Search Result with pricing comparison
class ProductSearchResult {
  final MasterProduct product;
  final List<BusinessProduct> businessListings;
  final BusinessProduct? cheapestListing;
  final double? priceRange; // Difference between highest and lowest
  final int totalBusinesses;

  ProductSearchResult({
    required this.product,
    required this.businessListings,
    this.cheapestListing,
    this.priceRange,
    required this.totalBusinesses,
  });

  /// Get price range string for display
  String get priceRangeDisplay {
    if (businessListings.isEmpty) return 'No listings';
    if (businessListings.length == 1) {
      return 'LKR ${businessListings.first.price.toStringAsFixed(2)}';
    }
    
    final lowest = businessListings.map((b) => b.price).reduce((a, b) => a < b ? a : b);
    final highest = businessListings.map((b) => b.price).reduce((a, b) => a > b ? a : b);
    
    return 'LKR ${lowest.toStringAsFixed(2)} - ${highest.toStringAsFixed(2)}';
  }

  /// Get discount information
  String? get bestDiscountDisplay {
    double? bestDiscount;
    for (final listing in businessListings) {
      final discount = listing.discountPercentage;
      if (discount != null && (bestDiscount == null || discount > bestDiscount)) {
        bestDiscount = discount;
      }
    }
    return bestDiscount != null ? '${bestDiscount.toStringAsFixed(0)}% OFF' : null;
  }
}

/// Click tracking for revenue
class ProductClick {
  final String id;
  final String businessProductId;
  final String userId;
  final String? sessionId;
  final DateTime clickedAt;
  final String? referrer;
  final Map<String, dynamic> metadata;

  ProductClick({
    required this.id,
    required this.businessProductId,
    required this.userId,
    this.sessionId,
    required this.clickedAt,
    this.referrer,
    this.metadata = const {},
  });

  factory ProductClick.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProductClick(
      id: doc.id,
      businessProductId: data['businessProductId'] ?? '',
      userId: data['userId'] ?? '',
      sessionId: data['sessionId'],
      clickedAt: data['clickedAt'] is Timestamp 
          ? (data['clickedAt'] as Timestamp).toDate()
          : DateTime.now(),
      referrer: data['referrer'],
      metadata: data['metadata'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'businessProductId': businessProductId,
      'userId': userId,
      'sessionId': sessionId,
      'clickedAt': Timestamp.fromDate(clickedAt),
      'referrer': referrer,
      'metadata': metadata,
    };
  }
}
