import 'package:cloud_firestore/cloud_firestore.dart';

enum DriverStatus { pending, approved, suspended, rejected }
enum VehicleType { threewheeler, car, bike, van, suv }
enum SubscriptionPlan { free, basic, premium }

class DriverModel {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String phoneNumber;
  final String photoUrl;
  final String licenseNumber;
  final DateTime licenseExpiry;
  final String vehicleType;
  final String vehicleNumber;
  final String vehicleModel;
  final String vehicleColor;
  final int vehicleYear;
  final String insuranceNumber;
  final DateTime insuranceExpiry;
  final List<String> driverImageUrls;
  final List<String> vehicleImageUrls;
  final List<String> documentImageUrls;
  final DriverStatus status;
  final SubscriptionPlan subscriptionPlan;
  final DateTime? subscriptionExpiry;
  final double rating;
  final int totalRides;
  final double totalEarnings;
  final bool availability;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  DriverModel({
    required this.id,
    required this.userId,
    required this.name,
    this.email = '',
    this.phoneNumber = '',
    this.photoUrl = '',
    required this.licenseNumber,
    required this.licenseExpiry,
    required this.vehicleType,
    required this.vehicleNumber,
    required this.vehicleModel,
    required this.vehicleColor,
    required this.vehicleYear,
    required this.insuranceNumber,
    required this.insuranceExpiry,
    this.driverImageUrls = const [],
    this.vehicleImageUrls = const [],
    this.documentImageUrls = const [],
    this.status = DriverStatus.pending,
    this.subscriptionPlan = SubscriptionPlan.free,
    this.subscriptionExpiry,
    this.rating = 0.0,
    this.totalRides = 0,
    this.totalEarnings = 0.0,
    this.availability = false,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'licenseNumber': licenseNumber,
      'licenseExpiry': Timestamp.fromDate(licenseExpiry),
      'vehicleType': vehicleType,
      'vehicleNumber': vehicleNumber,
      'vehicleModel': vehicleModel,
      'vehicleColor': vehicleColor,
      'vehicleYear': vehicleYear,
      'insuranceNumber': insuranceNumber,
      'insuranceExpiry': Timestamp.fromDate(insuranceExpiry),
      'driverImageUrls': driverImageUrls,
      'vehicleImageUrls': vehicleImageUrls,
      'documentImageUrls': documentImageUrls,
      'status': status.name,
      'subscriptionPlan': subscriptionPlan.name,
      'subscriptionExpiry': subscriptionExpiry != null ? Timestamp.fromDate(subscriptionExpiry!) : null,
      'rating': rating,
      'totalRides': totalRides,
      'totalEarnings': totalEarnings,
      'availability': availability,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory DriverModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Safe timestamp parsing helper
    DateTime parseTimestamp(dynamic value, DateTime fallback) {
      try {
        if (value is Timestamp) {
          return value.toDate();
        }
        return fallback;
      } catch (e) {
        return fallback;
      }
    }
    
    final now = DateTime.now();
    
    return DriverModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phoneNumber'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      licenseNumber: data['licenseNumber'] ?? '',
      licenseExpiry: parseTimestamp(data['licenseExpiry'], now.add(const Duration(days: 365))),
      vehicleType: data['vehicleType'] ?? '',
      vehicleNumber: data['vehicleNumber'] ?? '',
      vehicleModel: data['vehicleModel'] ?? '',
      vehicleColor: data['vehicleColor'] ?? '',
      vehicleYear: data['vehicleYear'] ?? 2020,
      insuranceNumber: data['insuranceNumber'] ?? '',
      insuranceExpiry: parseTimestamp(data['insuranceExpiry'], now.add(const Duration(days: 365))),
      driverImageUrls: List<String>.from(data['driverImageUrls'] ?? []),
      vehicleImageUrls: List<String>.from(data['vehicleImageUrls'] ?? []),
      documentImageUrls: List<String>.from(data['documentImageUrls'] ?? []),
      status: DriverStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => DriverStatus.pending,
      ),
      subscriptionPlan: SubscriptionPlan.values.firstWhere(
        (e) => e.name == data['subscriptionPlan'],
        orElse: () => SubscriptionPlan.free,
      ),
      subscriptionExpiry: data['subscriptionExpiry'] != null 
          ? parseTimestamp(data['subscriptionExpiry'], now)
          : null,
      rating: (data['rating'] ?? 0.0).toDouble(),
      totalRides: data['totalRides'] ?? 0,
      totalEarnings: (data['totalEarnings'] ?? 0.0).toDouble(),
      availability: data['availability'] ?? false,
      isVerified: data['isVerified'] ?? false,
      createdAt: parseTimestamp(data['createdAt'], now),
      updatedAt: parseTimestamp(data['updatedAt'], now),
    );
  }
}
