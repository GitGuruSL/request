import 'package:cloud_firestore/cloud_firestore.dart';

class PriceListing {
  final String id;
  final String businessId;
  final String businessName;
  final String businessLogo;
  final String masterProductId;
  final String productName;
  final String brand;
  final String category;
  final String subcategory;
  final double price;
  final String currency;
  final String? modelNumber;
  final Map<String, String> selectedVariables;
  final List<String> productImages;
  final String? productLink;
  final String? whatsappNumber;
  final bool isAvailable;
  final int stockQuantity;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int clickCount;
  final double rating;
  final int reviewCount;

  PriceListing({
    required this.id,
    required this.businessId,
    required this.businessName,
    required this.businessLogo,
    required this.masterProductId,
    required this.productName,
    required this.brand,
    required this.category,
    required this.subcategory,
    required this.price,
    required this.currency,
    this.modelNumber,
    required this.selectedVariables,
    required this.productImages,
    this.productLink,
    this.whatsappNumber,
    required this.isAvailable,
    required this.stockQuantity,
    required this.createdAt,
    required this.updatedAt,
    this.clickCount = 0,
    this.rating = 0.0,
    this.reviewCount = 0,
  });

  factory PriceListing.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PriceListing(
      id: doc.id,
      businessId: data['businessId'] ?? '',
      businessName: data['businessName'] ?? '',
      businessLogo: data['businessLogo'] ?? '',
      masterProductId: data['masterProductId'] ?? '',
      productName: data['productName'] ?? '',
      brand: data['brand'] ?? '',
      category: data['category'] ?? '',
      subcategory: data['subcategory'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'LKR',
      modelNumber: data['modelNumber'],
      selectedVariables: Map<String, String>.from(data['selectedVariables'] ?? {}),
      productImages: List<String>.from(data['productImages'] ?? []),
      productLink: data['productLink'],
      whatsappNumber: data['whatsappNumber'],
      isAvailable: data['isAvailable'] ?? true,
      stockQuantity: data['stockQuantity'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      clickCount: data['clickCount'] ?? 0,
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'businessId': businessId,
      'businessName': businessName,
      'businessLogo': businessLogo,
      'masterProductId': masterProductId,
      'productName': productName,
      'brand': brand,
      'category': category,
      'subcategory': subcategory,
      'price': price,
      'currency': currency,
      'modelNumber': modelNumber,
      'selectedVariables': selectedVariables,
      'productImages': productImages,
      'productLink': productLink,
      'whatsappNumber': whatsappNumber,
      'isAvailable': isAvailable,
      'stockQuantity': stockQuantity,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'clickCount': clickCount,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }

  PriceListing copyWith({
    String? id,
    String? businessId,
    String? businessName,
    String? businessLogo,
    String? masterProductId,
    String? productName,
    String? brand,
    String? category,
    String? subcategory,
    double? price,
    String? currency,
    String? modelNumber,
    Map<String, String>? selectedVariables,
    List<String>? productImages,
    String? productLink,
    String? whatsappNumber,
    bool? isAvailable,
    int? stockQuantity,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? clickCount,
    double? rating,
    int? reviewCount,
  }) {
    return PriceListing(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      businessName: businessName ?? this.businessName,
      businessLogo: businessLogo ?? this.businessLogo,
      masterProductId: masterProductId ?? this.masterProductId,
      productName: productName ?? this.productName,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      modelNumber: modelNumber ?? this.modelNumber,
      selectedVariables: selectedVariables ?? this.selectedVariables,
      productImages: productImages ?? this.productImages,
      productLink: productLink ?? this.productLink,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      isAvailable: isAvailable ?? this.isAvailable,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      clickCount: clickCount ?? this.clickCount,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }
}
