// Enhanced User Model with Multi-Role Support
import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { 
  general, 
  driver, 
  delivery, 
  business 
}

enum RequestType { 
  item,      // General items
  service,   // Services
  delivery,  // Package delivery
  rental,    // Rent/lease items
  ride,      // Transportation
  price      // Price comparison
}

enum VerificationStatus {
  pending,
  approved,
  rejected,
  notRequired
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final List<UserRole> roles;
  final UserRole activeRole;
  final Map<UserRole, RoleData> roleData;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final bool profileComplete;
  final String? countryCode;
  final String? countryName;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    required this.roles,
    required this.activeRole,
    required this.roleData,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.profileComplete = false,
    this.countryCode,
    this.countryName,
    required this.createdAt,
    required this.updatedAt,
  });

  // Check if user has specific role
  bool hasRole(UserRole role) => roles.contains(role);
  
  // Check if user has any of the specified roles
  bool hasAnyRole(List<UserRole> checkRoles) => 
      roles.any((role) => checkRoles.contains(role));
  
  // Get role-specific data
  T? getRoleData<T>(UserRole role) => roleData[role]?.data as T?;
  
  // Get role data object
  RoleData? getRoleInfo(UserRole role) => roleData[role];
  
  // Check if role is verified
  bool isRoleVerified(UserRole role) => 
      roleData[role]?.verificationStatus == VerificationStatus.approved;

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'],
      roles: (map['roles'] as List<dynamic>?)
          ?.map((e) => UserRole.values.byName(e))
          .toList() ?? [UserRole.general],
      activeRole: UserRole.values.byName(map['activeRole'] ?? 'general'),
      roleData: (map['roleData'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(
              UserRole.values.byName(key),
              RoleData.fromMap(value)))
          ?? {},
      isEmailVerified: map['isEmailVerified'] ?? false,
      isPhoneVerified: map['isPhoneVerified'] ?? false,
      profileComplete: map['profileComplete'] ?? false,
      countryCode: map['countryCode'],
      countryName: map['countryName'],
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'roles': roles.map((e) => e.name).toList(),
      'activeRole': activeRole.name,
      'roleData': roleData.map((key, value) => 
          MapEntry(key.name, value.toMap())),
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'profileComplete': profileComplete,
      'countryCode': countryCode,
      'countryName': countryName,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helper method to parse DateTime from either Timestamp or String
  static DateTime _parseDateTime(dynamic dateTime) {
    if (dateTime == null) {
      return DateTime.now();
    } else if (dateTime is Timestamp) {
      return dateTime.toDate();
    } else if (dateTime is String) {
      return DateTime.parse(dateTime);
    } else {
      return DateTime.now();
    }
  }
}

class RoleData {
  final VerificationStatus verificationStatus;
  final Map<String, dynamic> data;
  final DateTime? verifiedAt;
  final String? verificationNotes;

  RoleData({
    this.verificationStatus = VerificationStatus.notRequired,
    required this.data,
    this.verifiedAt,
    this.verificationNotes,
  });

  factory RoleData.fromMap(Map<String, dynamic> map) {
    return RoleData(
      verificationStatus: VerificationStatus.values.byName(
        map['verificationStatus'] ?? 'notRequired'
      ),
      data: map['data'] ?? {},
      verifiedAt: map['verifiedAt'] != null 
          ? UserModel._parseDateTime(map['verifiedAt']) 
          : null,
      verificationNotes: map['verificationNotes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'verificationStatus': verificationStatus.name,
      'data': data,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'verificationNotes': verificationNotes,
    };
  }
}

// Specific Role Data Models
class DriverData {
  final String licenseNumber;
  final DateTime licenseExpiry;
  final String? licenseImageUrl;
  final VehicleInfo vehicle;
  final double rating;
  final int totalRides;
  final bool isAvailable;

  DriverData({
    required this.licenseNumber,
    required this.licenseExpiry,
    this.licenseImageUrl,
    required this.vehicle,
    this.rating = 0.0,
    this.totalRides = 0,
    this.isAvailable = true,
  });

  factory DriverData.fromMap(Map<String, dynamic> map) {
    return DriverData(
      licenseNumber: map['licenseNumber'] ?? '',
      licenseExpiry: UserModel._parseDateTime(map['licenseExpiry']),
      licenseImageUrl: map['licenseImageUrl'],
      vehicle: VehicleInfo.fromMap(map['vehicle']),
      rating: (map['rating'] ?? 0.0).toDouble(),
      totalRides: map['totalRides'] ?? 0,
      isAvailable: map['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'licenseNumber': licenseNumber,
      'licenseExpiry': licenseExpiry.toIso8601String(),
      'licenseImageUrl': licenseImageUrl,
      'vehicle': vehicle.toMap(),
      'rating': rating,
      'totalRides': totalRides,
      'isAvailable': isAvailable,
    };
  }
}

class VehicleInfo {
  final String make;
  final String model;
  final String year;
  final String plateNumber;
  final String color;
  final int seatingCapacity;
  final List<String> vehicleImages;

  VehicleInfo({
    required this.make,
    required this.model,
    required this.year,
    required this.plateNumber,
    required this.color,
    required this.seatingCapacity,
    this.vehicleImages = const [],
  });

  factory VehicleInfo.fromMap(Map<String, dynamic> map) {
    return VehicleInfo(
      make: map['make'] ?? '',
      model: map['model'] ?? '',
      year: map['year'] ?? '',
      plateNumber: map['plateNumber'] ?? '',
      color: map['color'] ?? '',
      seatingCapacity: map['seatingCapacity'] ?? 4,
      vehicleImages: List<String>.from(map['vehicleImages'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'make': make,
      'model': model,
      'year': year,
      'plateNumber': plateNumber,
      'color': color,
      'seatingCapacity': seatingCapacity,
      'vehicleImages': vehicleImages,
    };
  }
}

class DeliveryData {
  final String businessName;
  final String businessAddress;
  final List<String> serviceAreas;
  final List<String> vehicleTypes;
  final DeliveryCapabilities capabilities;
  final double rating;
  final int totalDeliveries;
  final bool isAvailable;

  DeliveryData({
    required this.businessName,
    required this.businessAddress,
    required this.serviceAreas,
    required this.vehicleTypes,
    required this.capabilities,
    this.rating = 0.0,
    this.totalDeliveries = 0,
    this.isAvailable = true,
  });

  factory DeliveryData.fromMap(Map<String, dynamic> map) {
    return DeliveryData(
      businessName: map['businessName'] ?? '',
      businessAddress: map['businessAddress'] ?? '',
      serviceAreas: List<String>.from(map['serviceAreas'] ?? []),
      vehicleTypes: List<String>.from(map['vehicleTypes'] ?? []),
      capabilities: DeliveryCapabilities.fromMap(map['capabilities']),
      rating: (map['rating'] ?? 0.0).toDouble(),
      totalDeliveries: map['totalDeliveries'] ?? 0,
      isAvailable: map['isAvailable'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'businessAddress': businessAddress,
      'serviceAreas': serviceAreas,
      'vehicleTypes': vehicleTypes,
      'capabilities': capabilities.toMap(),
      'rating': rating,
      'totalDeliveries': totalDeliveries,
      'isAvailable': isAvailable,
    };
  }
}

class DeliveryCapabilities {
  final double maxWeight; // in kg
  final double maxVolume; // in cubic meters
  final bool fragileItems;
  final bool refrigerated;
  final bool express;
  final int maxDistance; // in km

  DeliveryCapabilities({
    required this.maxWeight,
    required this.maxVolume,
    this.fragileItems = false,
    this.refrigerated = false,
    this.express = false,
    required this.maxDistance,
  });

  factory DeliveryCapabilities.fromMap(Map<String, dynamic> map) {
    return DeliveryCapabilities(
      maxWeight: (map['maxWeight'] ?? 0.0).toDouble(),
      maxVolume: (map['maxVolume'] ?? 0.0).toDouble(),
      fragileItems: map['fragileItems'] ?? false,
      refrigerated: map['refrigerated'] ?? false,
      express: map['express'] ?? false,
      maxDistance: map['maxDistance'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'maxWeight': maxWeight,
      'maxVolume': maxVolume,
      'fragileItems': fragileItems,
      'refrigerated': refrigerated,
      'express': express,
      'maxDistance': maxDistance,
    };
  }
}

class BusinessData {
  final String businessName;
  final String businessType;
  final String businessAddress;
  final String businessPhone;
  final String businessEmail;
  final String? businessLicense;
  final String? businessLicenseImageUrl;
  final List<String> businessImages;
  final BusinessHours businessHours;
  final double rating;
  final int totalOrders;
  final bool isActive;

  BusinessData({
    required this.businessName,
    required this.businessType,
    required this.businessAddress,
    required this.businessPhone,
    required this.businessEmail,
    this.businessLicense,
    this.businessLicenseImageUrl,
    this.businessImages = const [],
    required this.businessHours,
    this.rating = 0.0,
    this.totalOrders = 0,
    this.isActive = true,
  });

  factory BusinessData.fromMap(Map<String, dynamic> map) {
    return BusinessData(
      businessName: map['businessName'] ?? '',
      businessType: map['businessType'] ?? '',
      businessAddress: map['businessAddress'] ?? '',
      businessPhone: map['businessPhone'] ?? '',
      businessEmail: map['businessEmail'] ?? '',
      businessLicense: map['businessLicense'],
      businessLicenseImageUrl: map['businessLicenseImageUrl'],
      businessImages: List<String>.from(map['businessImages'] ?? []),
      businessHours: BusinessHours.fromMap(map['businessHours']),
      rating: (map['rating'] ?? 0.0).toDouble(),
      totalOrders: map['totalOrders'] ?? 0,
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'businessType': businessType,
      'businessAddress': businessAddress,
      'businessPhone': businessPhone,
      'businessEmail': businessEmail,
      'businessLicense': businessLicense,
      'businessLicenseImageUrl': businessLicenseImageUrl,
      'businessImages': businessImages,
      'businessHours': businessHours.toMap(),
      'rating': rating,
      'totalOrders': totalOrders,
      'isActive': isActive,
    };
  }
}

class BusinessHours {
  final Map<String, TimeSlot> weeklyHours;
  final bool is24x7;
  final List<String> holidays;

  BusinessHours({
    required this.weeklyHours,
    this.is24x7 = false,
    this.holidays = const [],
  });

  factory BusinessHours.fromMap(Map<String, dynamic> map) {
    return BusinessHours(
      weeklyHours: (map['weeklyHours'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(key, TimeSlot.fromMap(value)))
          ?? {},
      is24x7: map['is24x7'] ?? false,
      holidays: List<String>.from(map['holidays'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'weeklyHours': weeklyHours.map((key, value) => 
          MapEntry(key, value.toMap())),
      'is24x7': is24x7,
      'holidays': holidays,
    };
  }
}

class TimeSlot {
  final String startTime; // "09:00"
  final String endTime;   // "18:00"
  final bool isClosed;

  TimeSlot({
    required this.startTime,
    required this.endTime,
    this.isClosed = false,
  });

  factory TimeSlot.fromMap(Map<String, dynamic> map) {
    return TimeSlot(
      startTime: map['startTime'] ?? '09:00',
      endTime: map['endTime'] ?? '18:00',
      isClosed: map['isClosed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startTime': startTime,
      'endTime': endTime,
      'isClosed': isClosed,
    };
  }
}
