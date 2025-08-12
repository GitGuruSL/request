import 'package:cloud_firestore/cloud_firestore.dart';

class MasterProduct {
  final String id;
  final String name;
  final String brand;
  final String category;
  final String subcategory;
  final String description;
  final List<String> images;
  final Map<String, List<String>> availableVariables;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int businessListingsCount;

  MasterProduct({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.subcategory,
    required this.description,
    required this.images,
    required this.availableVariables,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.businessListingsCount = 0,
  });

  factory MasterProduct.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MasterProduct(
      id: doc.id,
      name: data['name'] ?? '',
      brand: data['brand'] ?? '',
      category: data['category'] ?? '',
      subcategory: data['subcategory'] ?? '',
      description: data['description'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      availableVariables: Map<String, List<String>>.from(
        (data['availableVariables'] ?? {}).map(
          (key, value) => MapEntry(key, List<String>.from(value)),
        ),
      ),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      businessListingsCount: data['businessListingsCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'brand': brand,
      'category': category,
      'subcategory': subcategory,
      'description': description,
      'images': images,
      'availableVariables': availableVariables,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'businessListingsCount': businessListingsCount,
    };
  }
}
