// REMOVED_FB_IMPORT: import 'package:cloud_firestore/cloud_firestore.dart';

import 'src/utils/firebase_shim.dart'; // Added by migration script

class ProductVariable {
  final String name;
  final String type;
  final bool required;
  final List<String> values;

  ProductVariable({
    required this.name,
    required this.type,
    required this.required,
    required this.values,
  });

  factory ProductVariable.fromMap(Map<String, dynamic> data) {
    return ProductVariable(
      name: data['name'] ?? '',
      type: data['type'] ?? 'select',
      required: data['required'] ?? false,
      values: List<String>.from(data['values'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'required': required,
      'values': values,
    };
  }
}

class MasterProduct {
  final String id;
  final String name;
  final String brand;
  final String category;
  final String subcategory;
  final String description;
  final List<String> images;
  final Map<String, ProductVariable> availableVariables;
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
      availableVariables: _parseAvailableVariables(data['availableVariables']),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      businessListingsCount: data['businessListingsCount'] ?? 0,
    );
  }

  factory MasterProduct.fromJson(Map<String, dynamic> json) {
    return MasterProduct(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      brand: json['brand']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      subcategory: json['subcategory']?.toString() ?? '',
      description: json['description'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      availableVariables: _parseAvailableVariables(json['availableVariables']),
      isActive: json['isActive'] ?? true,
      createdAt:
          DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt:
          DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      businessListingsCount:
          json['businessListingsCount'] ?? json['listingCount'] ?? 0,
    );
  }

  static Map<String, ProductVariable> _parseAvailableVariables(dynamic data) {
    if (data == null) return {};

    final Map<String, ProductVariable> variables = {};

    if (data is Map<String, dynamic>) {
      data.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          // New format with ProductVariable objects
          variables[key] = ProductVariable.fromMap(value);
        } else if (value is List) {
          // Legacy format with simple string lists
          variables[key] = ProductVariable(
            name: key,
            type: 'select',
            required: false,
            values: List<String>.from(value),
          );
        }
      });
    }

    return variables;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'brand': brand,
      'category': category,
      'subcategory': subcategory,
      'description': description,
      'images': images,
      'availableVariables': availableVariables.map(
        (key, variable) => MapEntry(key, variable.toMap()),
      ),
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'businessListingsCount': businessListingsCount,
    };
  }
}
