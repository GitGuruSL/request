import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

class ResponseModel {
  final String id;
  final String requestId;
  final String responderId;
  final String message;
  final List<String> sharedPhoneNumbers;
  final double? offeredPrice;
  final Timestamp createdAt;
  final String status; // 'pending', 'accepted', 'rejected'
  final UserModel? responder;
  
  // New fields for enhanced response details
  final bool hasExpiry;
  final DateTime? expiryDate;
  final bool deliveryAvailable;
  final double? deliveryAmount;
  final String? warranty;
  final List<String> images;
  final String? location;
  final double? latitude;
  final double? longitude;

  ResponseModel({
    required this.id,
    required this.requestId,
    required this.responderId,
    required this.message,
    this.sharedPhoneNumbers = const [],
    this.offeredPrice,
    required this.createdAt,
    this.status = 'pending',
    this.responder,
    this.hasExpiry = false,
    this.expiryDate,
    this.deliveryAvailable = false,
    this.deliveryAmount,
    this.warranty,
    this.images = const [],
    this.location,
    this.latitude,
    this.longitude,
  });

  factory ResponseModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ResponseModel(
      id: doc.id,
      requestId: data['requestId'] ?? '',
      responderId: data['responderId'] ?? '',
      message: data['message'] ?? '',
      sharedPhoneNumbers: List<String>.from(data['sharedPhoneNumbers'] ?? []),
      offeredPrice: data['offeredPrice']?.toDouble(),
      createdAt: data['createdAt'] ?? Timestamp.now(),
      status: data['status'] ?? 'pending',
      responder: data['responder'] != null ? UserModel.fromMap(data['responder']) : null,
      hasExpiry: data['hasExpiry'] ?? false,
      expiryDate: data['expiryDate'] != null ? (data['expiryDate'] as Timestamp).toDate() : null,
      deliveryAvailable: data['deliveryAvailable'] ?? false,
      deliveryAmount: data['deliveryAmount']?.toDouble(),
      warranty: data['warranty'],
      images: List<String>.from(data['images'] ?? []),
      location: data['location'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,
      'responderId': responderId,
      'message': message,
      'sharedPhoneNumbers': sharedPhoneNumbers,
      'offeredPrice': offeredPrice,
      'createdAt': createdAt,
      'status': status,
      'hasExpiry': hasExpiry,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'deliveryAvailable': deliveryAvailable,
      'deliveryAmount': deliveryAmount,
      'warranty': warranty,
      'images': images,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
