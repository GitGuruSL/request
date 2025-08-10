import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

enum RequestType { item, service, ride, rental, delivery }

enum ItemCondition { 
  newCondition('new'),
  used('used'), 
  any('any');
  
  const ItemCondition(this.value);
  final String value;
  
  @override
  String toString() => value;
  
  static ItemCondition fromString(String value) {
    return ItemCondition.values.firstWhere(
      (condition) => condition.value == value,
      orElse: () => ItemCondition.any,
    );
  }
}

class RequestModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final RequestType type;
  final ItemCondition condition; // 'new', 'used', 'any'
  final double budget;
  final String location;
  final String category;
  final String subcategory;
  final List<String> imageUrls;
  final List<String> additionalPhones;
  final String status; // 'open', 'in_progress', 'completed', 'cancelled'
  final Timestamp? deadline;
  final Timestamp createdAt;
  final Timestamp updatedAt;
  final UserModel? user;

  RequestModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.type,
    required this.condition,
    required this.budget,
    required this.location,
    required this.category,
    required this.subcategory,
    this.imageUrls = const [],
    this.additionalPhones = const [],
    this.status = 'open',
    this.deadline,
    required this.createdAt,
    required this.updatedAt,
    this.user,
  });

  // Convert a RequestModel instance to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last, // Store enum as string
      'condition': condition.toString(), // Store enum as string
      'budget': budget,
      'location': location,
      'category': category,
      'subcategory': subcategory,
      'imageUrls': imageUrls,
      'additionalPhones': additionalPhones,
      'status': status,
      'deadline': deadline,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Create a RequestModel instance from a Firestore document
  factory RequestModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return RequestModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: RequestType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => RequestType.item,
      ),
      condition: ItemCondition.fromString(data['condition'] ?? 'any'),
      budget: (data['budget'] ?? 0).toDouble(),
      location: data['location'] ?? '',
      category: data['category'] ?? '',
      subcategory: data['subcategory'] ?? '',
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      additionalPhones: List<String>.from(data['additionalPhones'] ?? []),
      status: data['status'] ?? 'open',
      deadline: data['deadline'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
      user: data['user'] != null ? UserModel.fromMap(data['user']) : null,
    );
  }

  RequestModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    RequestType? type,
    ItemCondition? condition,
    double? budget,
    String? location,
    String? category,
    String? subcategory,
    List<String>? imageUrls,
    List<String>? additionalPhones,
    String? status,
    Timestamp? deadline,
    Timestamp? createdAt,
    Timestamp? updatedAt,
  }) {
    return RequestModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      condition: condition ?? this.condition,
      budget: budget ?? this.budget,
      location: location ?? this.location,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      imageUrls: imageUrls ?? this.imageUrls,
      additionalPhones: additionalPhones ?? this.additionalPhones,
      status: status ?? this.status,
      deadline: deadline ?? this.deadline,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
