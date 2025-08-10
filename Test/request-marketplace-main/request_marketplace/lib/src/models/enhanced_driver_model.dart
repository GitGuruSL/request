import 'package:cloud_firestore/cloud_firestore.dart';

enum DriverStatus { pending, approved, suspended, rejected }
enum VehicleType { threewheeler, car, bike, van, suv }
enum SubscriptionPlan { free, basic, premium }
enum VerificationStatus { pending, verified, rejected, notSubmitted }

// Individual document verification status
class DocumentVerification {
  final VerificationStatus status;
  final String? rejectionReason;
  final DateTime? verifiedAt;
  final DateTime? submittedAt;
  final String? documentUrl;

  DocumentVerification({
    this.status = VerificationStatus.notSubmitted,
    this.rejectionReason,
    this.verifiedAt,
    this.submittedAt,
    this.documentUrl,
  });

  factory DocumentVerification.fromMap(Map<String, dynamic>? data) {
    if (data == null) return DocumentVerification();
    
    return DocumentVerification(
      status: VerificationStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => VerificationStatus.notSubmitted,
      ),
      rejectionReason: data['rejectionReason'],
      verifiedAt: data['verifiedAt']?.toDate(),
      submittedAt: data['submittedAt']?.toDate(),
      documentUrl: data['documentUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.name,
      'rejectionReason': rejectionReason,
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'submittedAt': submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
      'documentUrl': documentUrl,
    };
  }

  bool get canEdit => status == VerificationStatus.rejected || status == VerificationStatus.notSubmitted;
  bool get isVerified => status == VerificationStatus.verified;
  bool get isPending => status == VerificationStatus.pending;
}

// Vehicle model for multiple vehicle support
class VehicleModel {
  final String id;
  final VehicleType type;
  final String number;
  final String model;
  final String color;
  final int year;
  final List<String> imageUrls;
  final DocumentVerification registrationVerification;
  final bool isActive;
  final DateTime createdAt;

  VehicleModel({
    required this.id,
    required this.type,
    required this.number,
    required this.model,
    required this.color,
    required this.year,
    this.imageUrls = const [],
    DocumentVerification? registrationVerification,
    this.isActive = true,
    required this.createdAt,
  }) : registrationVerification = registrationVerification ?? DocumentVerification();

  factory VehicleModel.fromMap(String id, Map<String, dynamic> data) {
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
    
    return VehicleModel(
      id: id,
      type: VehicleType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => VehicleType.car,
      ),
      number: data['number'] ?? '',
      model: data['model'] ?? '',
      color: data['color'] ?? '',
      year: data['year'] ?? 2020,
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      registrationVerification: DocumentVerification.fromMap(data['registrationVerification']),
      isActive: data['isActive'] ?? true,
      createdAt: parseTimestamp(data['createdAt'], DateTime.now()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'number': number,
      'model': model,
      'color': color,
      'year': year,
      'imageUrls': imageUrls,
      'registrationVerification': registrationVerification.toMap(),
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

// Enhanced driver model with field-by-field verification
class EnhancedDriverModel {
  final String id;
  final String userId;
  final String name;
  final String? photoUrl;
  
  // License information
  final String licenseNumber;
  final DateTime licenseExpiry;
  final DocumentVerification licenseVerification;
  
  // Insurance information
  final String insuranceNumber;
  final DateTime insuranceExpiry;
  final DocumentVerification insuranceVerification;
  
  // Driver photo verification
  final DocumentVerification photoVerification;
  
  // Multiple vehicles support
  final List<VehicleModel> vehicles;
  final String? primaryVehicleId;
  
  // Overall status and ratings
  final DriverStatus status;
  final SubscriptionPlan subscriptionPlan;
  final DateTime? subscriptionExpiry;
  final double rating;
  final int totalRides;
  final double totalEarnings;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  EnhancedDriverModel({
    required this.id,
    required this.userId,
    required this.name,
    this.photoUrl,
    required this.licenseNumber,
    required this.licenseExpiry,
    DocumentVerification? licenseVerification,
    required this.insuranceNumber,
    required this.insuranceExpiry,
    DocumentVerification? insuranceVerification,
    DocumentVerification? photoVerification,
    this.vehicles = const [],
    this.primaryVehicleId,
    this.status = DriverStatus.pending,
    this.subscriptionPlan = SubscriptionPlan.free,
    this.subscriptionExpiry,
    this.rating = 0.0,
    this.totalRides = 0,
    this.totalEarnings = 0.0,
    this.isAvailable = false,
    required this.createdAt,
    required this.updatedAt,
  }) : licenseVerification = licenseVerification ?? DocumentVerification(),
       insuranceVerification = insuranceVerification ?? DocumentVerification(),
       photoVerification = photoVerification ?? DocumentVerification();

  factory EnhancedDriverModel.fromFirestore(DocumentSnapshot doc) {
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
    
    return EnhancedDriverModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? 'Unknown Driver',
      photoUrl: data['photoUrl'],
      licenseNumber: data['licenseNumber'] ?? '',
      licenseExpiry: parseTimestamp(data['licenseExpiry'], now.add(const Duration(days: 365))),
      licenseVerification: DocumentVerification.fromMap(data['licenseVerification']),
      insuranceNumber: data['insuranceNumber'] ?? '',
      insuranceExpiry: parseTimestamp(data['insuranceExpiry'], now.add(const Duration(days: 365))),
      insuranceVerification: DocumentVerification.fromMap(data['insuranceVerification']),
      photoVerification: DocumentVerification.fromMap(data['photoVerification']),
      vehicles: (data['vehicles'] as List<dynamic>?)
          ?.asMap()
          .entries
          .map((entry) => VehicleModel.fromMap(entry.key.toString(), entry.value))
          .toList() ?? [],
      primaryVehicleId: data['primaryVehicleId'],
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
      isAvailable: data['isAvailable'] ?? false,
      createdAt: parseTimestamp(data['createdAt'], now),
      updatedAt: parseTimestamp(data['updatedAt'], now),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'photoUrl': photoUrl,
      'licenseNumber': licenseNumber,
      'licenseExpiry': Timestamp.fromDate(licenseExpiry),
      'licenseVerification': licenseVerification.toMap(),
      'insuranceNumber': insuranceNumber,
      'insuranceExpiry': Timestamp.fromDate(insuranceExpiry),
      'insuranceVerification': insuranceVerification.toMap(),
      'photoVerification': photoVerification.toMap(),
      'vehicles': vehicles.map((v) => v.toMap()).toList(),
      'primaryVehicleId': primaryVehicleId,
      'status': status.name,
      'subscriptionPlan': subscriptionPlan.name,
      'subscriptionExpiry': subscriptionExpiry != null ? Timestamp.fromDate(subscriptionExpiry!) : null,
      'rating': rating,
      'totalRides': totalRides,
      'totalEarnings': totalEarnings,
      'isAvailable': isAvailable,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Helper methods
  bool get isFullyVerified => 
      licenseVerification.isVerified && 
      insuranceVerification.isVerified && 
      photoVerification.isVerified &&
      vehicles.any((v) => v.registrationVerification.isVerified);

  bool get canBeApproved => isFullyVerified;

  VehicleModel? get primaryVehicle {
    if (primaryVehicleId != null) {
      try {
        return vehicles.firstWhere((v) => v.id == primaryVehicleId);
      } catch (e) {
        // Vehicle not found, return first available or null
      }
    }
    return vehicles.isNotEmpty ? vehicles.first : null;
  }

  List<DocumentVerification> get allVerifications => [
    licenseVerification,
    insuranceVerification,
    photoVerification,
    ...vehicles.map((v) => v.registrationVerification),
  ];

  int get verifiedDocumentsCount => allVerifications.where((v) => v.isVerified).length;
  int get pendingDocumentsCount => allVerifications.where((v) => v.isPending).length;
  int get rejectedDocumentsCount => allVerifications.where((v) => v.status == VerificationStatus.rejected).length;
}
