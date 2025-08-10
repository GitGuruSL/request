import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart'; // Import existing UserModel for migration

// User role types
enum UserType { 
  consumer,           // Regular users making requests
  serviceProvider,    // Individual service providers
  business,          // Registered businesses
  driver,            // Ride service providers
  courier,           // Delivery service providers
  vanRental,         // Van/vehicle rental providers
  hybrid             // Multiple roles (most common)
}

// Business types for categorization
enum BusinessType {
  retail,            // Product sellers (shops, stores)
  service,           // Service providers (salons, repair shops)
  restaurant,        // Food delivery
  rental,           // Vehicle/equipment rental
  logistics,        // Delivery services
  professional      // Lawyers, doctors, consultants
}

// Verification status for different aspects
enum VerificationStatus {
  pending,
  verified,
  rejected,
  notRequired
}

class PhoneNumber {
  final String number;
  final bool isVerified;
  final bool isPrimary;
  final Timestamp? verifiedAt;

  PhoneNumber({
    required this.number,
    required this.isVerified,
    required this.isPrimary,
    this.verifiedAt,
  });

  factory PhoneNumber.fromMap(Map<String, dynamic> data) {
    return PhoneNumber(
      number: data['number'] ?? '',
      isVerified: data['isVerified'] ?? false,
      isPrimary: data['isPrimary'] ?? false,
      verifiedAt: data['verifiedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'isVerified': isVerified,
      'isPrimary': isPrimary,
      'verifiedAt': verifiedAt,
    };
  }
}

// Consumer profile for users who make requests
class ConsumerProfile {
  final String? preferredLocation;
  final List<String> favoriteCategories;
  final Map<String, dynamic> preferences;
  final int totalRequests;
  final double averageRating;

  ConsumerProfile({
    this.preferredLocation,
    this.favoriteCategories = const [],
    this.preferences = const {},
    this.totalRequests = 0,
    this.averageRating = 0.0,
  });

  factory ConsumerProfile.fromMap(Map<String, dynamic> data) {
    return ConsumerProfile(
      preferredLocation: data['preferredLocation'],
      favoriteCategories: List<String>.from(data['favoriteCategories'] ?? []),
      preferences: Map<String, dynamic>.from(data['preferences'] ?? {}),
      totalRequests: data['totalRequests'] ?? 0,
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'preferredLocation': preferredLocation,
      'favoriteCategories': favoriteCategories,
      'preferences': preferences,
      'totalRequests': totalRequests,
      'averageRating': averageRating,
    };
  }
}

// Business profile for registered businesses
class BusinessProfile {
  final String businessName;
  final String email;
  final BusinessType businessType;
  final String? businessRegistrationNumber;
  final String? taxId;
  final String description;
  final List<String> businessCategories;
  final Map<String, String> businessHours;
  final List<String> businessImages;
  final String businessAddress;
  final double latitude;
  final double longitude;
  final VerificationStatus verificationStatus;
  final String? subscriptionPlan; // basic, premium, enterprise
  final Timestamp? subscriptionExpiresAt;
  final double averageRating;
  final int totalReviews;
  final bool isActive;

  BusinessProfile({
    required this.businessName,
    required this.email,
    required this.businessType,
    this.businessRegistrationNumber,
    this.taxId,
    this.description = '',
    this.businessCategories = const [],
    this.businessHours = const {},
    this.businessImages = const [],
    this.businessAddress = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.verificationStatus = VerificationStatus.pending,
    this.subscriptionPlan,
    this.subscriptionExpiresAt,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.isActive = true,
  });

  factory BusinessProfile.fromMap(Map<String, dynamic> data) {
    return BusinessProfile(
      businessName: data['businessName'] ?? '',
      email: data['email'] ?? '',
      businessType: BusinessType.values.firstWhere(
        (type) => type.name == data['businessType'],
        orElse: () => BusinessType.service,
      ),
      businessRegistrationNumber: data['businessRegistrationNumber'],
      taxId: data['taxId'],
      description: data['description'] ?? '',
      businessCategories: List<String>.from(data['businessCategories'] ?? []),
      businessHours: Map<String, String>.from(data['businessHours'] ?? {}),
      businessImages: List<String>.from(data['businessImages'] ?? []),
      businessAddress: data['businessAddress'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      verificationStatus: VerificationStatus.values.firstWhere(
        (status) => status.name == data['verificationStatus'],
        orElse: () => VerificationStatus.pending,
      ),
      subscriptionPlan: data['subscriptionPlan'],
      subscriptionExpiresAt: data['subscriptionExpiresAt'],
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      totalReviews: data['totalReviews'] ?? 0,
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessName': businessName,
      'email': email,
      'businessType': businessType.name,
      'businessRegistrationNumber': businessRegistrationNumber,
      'taxId': taxId,
      'description': description,
      'businessCategories': businessCategories,
      'businessHours': businessHours,
      'businessImages': businessImages,
      'businessAddress': businessAddress,
      'latitude': latitude,
      'longitude': longitude,
      'verificationStatus': verificationStatus.name,
      'subscriptionPlan': subscriptionPlan,
      'subscriptionExpiresAt': subscriptionExpiresAt,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'isActive': isActive,
    };
  }

  bool get isVerified => verificationStatus == VerificationStatus.verified;
  bool get hasActiveSubscription => 
    subscriptionPlan != null && 
    (subscriptionExpiresAt == null || subscriptionExpiresAt!.toDate().isAfter(DateTime.now()));
}

// Service provider profile for individual professionals
class ServiceProviderProfile {
  final List<String> skills;
  final List<String> certifications;
  final String experience;
  final String description;
  final List<String> portfolioImages;
  final Map<String, double> hourlyRates; // category -> rate
  final List<String> serviceAreas;
  final bool isAvailable;
  final Map<String, bool> availability; // day -> available
  final VerificationStatus verificationStatus;
  final double averageRating;
  final int completedJobs;
  final double totalEarnings;

  ServiceProviderProfile({
    this.skills = const [],
    this.certifications = const [],
    this.experience = '',
    this.description = '',
    this.portfolioImages = const [],
    this.hourlyRates = const {},
    this.serviceAreas = const [],
    this.isAvailable = true,
    this.availability = const {},
    this.verificationStatus = VerificationStatus.pending,
    this.averageRating = 0.0,
    this.completedJobs = 0,
    this.totalEarnings = 0.0,
  });

  factory ServiceProviderProfile.fromMap(Map<String, dynamic> data) {
    return ServiceProviderProfile(
      skills: List<String>.from(data['skills'] ?? []),
      certifications: List<String>.from(data['certifications'] ?? []),
      experience: data['experience'] ?? '',
      description: data['description'] ?? '',
      portfolioImages: List<String>.from(data['portfolioImages'] ?? []),
      hourlyRates: Map<String, double>.from(
        (data['hourlyRates'] ?? {}).map((k, v) => MapEntry(k, v.toDouble())),
      ),
      serviceAreas: List<String>.from(data['serviceAreas'] ?? []),
      isAvailable: data['isAvailable'] ?? true,
      availability: Map<String, bool>.from(data['availability'] ?? {}),
      verificationStatus: VerificationStatus.values.firstWhere(
        (status) => status.name == data['verificationStatus'],
        orElse: () => VerificationStatus.pending,
      ),
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      completedJobs: data['completedJobs'] ?? 0,
      totalEarnings: (data['totalEarnings'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'skills': skills,
      'certifications': certifications,
      'experience': experience,
      'description': description,
      'portfolioImages': portfolioImages,
      'hourlyRates': hourlyRates,
      'serviceAreas': serviceAreas,
      'isAvailable': isAvailable,
      'availability': availability,
      'verificationStatus': verificationStatus.name,
      'averageRating': averageRating,
      'completedJobs': completedJobs,
      'totalEarnings': totalEarnings,
    };
  }

  bool get isVerified => verificationStatus == VerificationStatus.verified;
}

// Driver profile for ride service providers
class DriverProfile {
  final String licenseNumber;
  final Timestamp licenseExpiryDate;
  final List<String> vehicleIds; // References to registered vehicles
  final bool isOnline;
  final String currentLocation;
  final double latitude;
  final double longitude;
  final VerificationStatus verificationStatus;
  final double averageRating;
  final int completedRides;
  final double totalEarnings;
  final Map<String, dynamic> drivingHistory;

  DriverProfile({
    required this.licenseNumber,
    required this.licenseExpiryDate,
    this.vehicleIds = const [],
    this.isOnline = false,
    this.currentLocation = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.verificationStatus = VerificationStatus.pending,
    this.averageRating = 0.0,
    this.completedRides = 0,
    this.totalEarnings = 0.0,
    this.drivingHistory = const {},
  });

  factory DriverProfile.fromMap(Map<String, dynamic> data) {
    return DriverProfile(
      licenseNumber: data['licenseNumber'] ?? '',
      licenseExpiryDate: data['licenseExpiryDate'] ?? Timestamp.now(),
      vehicleIds: List<String>.from(data['vehicleIds'] ?? []),
      isOnline: data['isOnline'] ?? false,
      currentLocation: data['currentLocation'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      verificationStatus: VerificationStatus.values.firstWhere(
        (status) => status.name == data['verificationStatus'],
        orElse: () => VerificationStatus.pending,
      ),
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      completedRides: data['completedRides'] ?? 0,
      totalEarnings: (data['totalEarnings'] ?? 0.0).toDouble(),
      drivingHistory: Map<String, dynamic>.from(data['drivingHistory'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'licenseNumber': licenseNumber,
      'licenseExpiryDate': licenseExpiryDate,
      'vehicleIds': vehicleIds,
      'isOnline': isOnline,
      'currentLocation': currentLocation,
      'latitude': latitude,
      'longitude': longitude,
      'verificationStatus': verificationStatus.name,
      'averageRating': averageRating,
      'completedRides': completedRides,
      'totalEarnings': totalEarnings,
      'drivingHistory': drivingHistory,
    };
  }

  bool get isVerified => verificationStatus == VerificationStatus.verified;
  bool get hasValidLicense => licenseExpiryDate.toDate().isAfter(DateTime.now());
}

// Courier profile for delivery service providers
class CourierProfile {
  final String? vehicleType; // bike, scooter, car, van, etc.
  final String? vehicleRegistration;
  final bool hasInsurance;
  final String? insuranceProvider;
  final Timestamp? insuranceExpiry;
  final bool isOnline;
  final String currentLocation;
  final double latitude;
  final double longitude;
  final VerificationStatus verificationStatus;
  final double averageRating;
  final int completedDeliveries;
  final double totalEarnings;
  final List<String> serviceAreas; // Areas where they operate
  final bool canHandleCOD; // Cash on delivery
  final double maxDeliveryWeight; // in kg
  final Map<String, dynamic> deliveryHistory;

  CourierProfile({
    this.vehicleType,
    this.vehicleRegistration,
    this.hasInsurance = false,
    this.insuranceProvider,
    this.insuranceExpiry,
    this.isOnline = false,
    this.currentLocation = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.verificationStatus = VerificationStatus.pending,
    this.averageRating = 0.0,
    this.completedDeliveries = 0,
    this.totalEarnings = 0.0,
    this.serviceAreas = const [],
    this.canHandleCOD = false,
    this.maxDeliveryWeight = 10.0,
    this.deliveryHistory = const {},
  });

  factory CourierProfile.fromMap(Map<String, dynamic> data) {
    return CourierProfile(
      vehicleType: data['vehicleType'],
      vehicleRegistration: data['vehicleRegistration'],
      hasInsurance: data['hasInsurance'] ?? false,
      insuranceProvider: data['insuranceProvider'],
      insuranceExpiry: data['insuranceExpiry'],
      isOnline: data['isOnline'] ?? false,
      currentLocation: data['currentLocation'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      verificationStatus: VerificationStatus.values.firstWhere(
        (status) => status.name == data['verificationStatus'],
        orElse: () => VerificationStatus.pending,
      ),
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      completedDeliveries: data['completedDeliveries'] ?? 0,
      totalEarnings: (data['totalEarnings'] ?? 0.0).toDouble(),
      serviceAreas: List<String>.from(data['serviceAreas'] ?? []),
      canHandleCOD: data['canHandleCOD'] ?? false,
      maxDeliveryWeight: (data['maxDeliveryWeight'] ?? 10.0).toDouble(),
      deliveryHistory: Map<String, dynamic>.from(data['deliveryHistory'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicleType': vehicleType,
      'vehicleRegistration': vehicleRegistration,
      'hasInsurance': hasInsurance,
      'insuranceProvider': insuranceProvider,
      'insuranceExpiry': insuranceExpiry,
      'isOnline': isOnline,
      'currentLocation': currentLocation,
      'latitude': latitude,
      'longitude': longitude,
      'verificationStatus': verificationStatus.name,
      'averageRating': averageRating,
      'completedDeliveries': completedDeliveries,
      'totalEarnings': totalEarnings,
      'serviceAreas': serviceAreas,
      'canHandleCOD': canHandleCOD,
      'maxDeliveryWeight': maxDeliveryWeight,
      'deliveryHistory': deliveryHistory,
    };
  }

  bool get isVerified => verificationStatus == VerificationStatus.verified;
  bool get hasValidInsurance => insuranceExpiry?.toDate().isAfter(DateTime.now()) ?? false;
}

// Van Rental profile for vehicle rental service providers
class VanRentalProfile {
  final List<String> vehicleIds; // References to owned vehicles
  final String businessName;
  final String? businessRegistration;
  final bool hasBusinessLicense;
  final String operatingLocation;
  final double latitude;
  final double longitude;
  final VerificationStatus verificationStatus;
  final double averageRating;
  final int completedRentals;
  final double totalEarnings;
  final List<String> serviceAreas;
  final Map<String, dynamic> rentalPolicies; // Terms, conditions, etc.
  final bool acceptsDeposit;
  final double securityDepositPercent; // Percentage of rental cost
  final Map<String, dynamic> rentalHistory;

  VanRentalProfile({
    this.vehicleIds = const [],
    this.businessName = '',
    this.businessRegistration,
    this.hasBusinessLicense = false,
    this.operatingLocation = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.verificationStatus = VerificationStatus.pending,
    this.averageRating = 0.0,
    this.completedRentals = 0,
    this.totalEarnings = 0.0,
    this.serviceAreas = const [],
    this.rentalPolicies = const {},
    this.acceptsDeposit = true,
    this.securityDepositPercent = 20.0,
    this.rentalHistory = const {},
  });

  factory VanRentalProfile.fromMap(Map<String, dynamic> data) {
    return VanRentalProfile(
      vehicleIds: List<String>.from(data['vehicleIds'] ?? []),
      businessName: data['businessName'] ?? '',
      businessRegistration: data['businessRegistration'],
      hasBusinessLicense: data['hasBusinessLicense'] ?? false,
      operatingLocation: data['operatingLocation'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      verificationStatus: VerificationStatus.values.firstWhere(
        (status) => status.name == data['verificationStatus'],
        orElse: () => VerificationStatus.pending,
      ),
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      completedRentals: data['completedRentals'] ?? 0,
      totalEarnings: (data['totalEarnings'] ?? 0.0).toDouble(),
      serviceAreas: List<String>.from(data['serviceAreas'] ?? []),
      rentalPolicies: Map<String, dynamic>.from(data['rentalPolicies'] ?? {}),
      acceptsDeposit: data['acceptsDeposit'] ?? true,
      securityDepositPercent: (data['securityDepositPercent'] ?? 20.0).toDouble(),
      rentalHistory: Map<String, dynamic>.from(data['rentalHistory'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'vehicleIds': vehicleIds,
      'businessName': businessName,
      'businessRegistration': businessRegistration,
      'hasBusinessLicense': hasBusinessLicense,
      'operatingLocation': operatingLocation,
      'latitude': latitude,
      'longitude': longitude,
      'verificationStatus': verificationStatus.name,
      'averageRating': averageRating,
      'completedRentals': completedRentals,
      'totalEarnings': totalEarnings,
      'serviceAreas': serviceAreas,
      'rentalPolicies': rentalPolicies,
      'acceptsDeposit': acceptsDeposit,
      'securityDepositPercent': securityDepositPercent,
      'rentalHistory': rentalHistory,
    };
  }

  bool get isVerified => verificationStatus == VerificationStatus.verified;
  bool get hasVehicles => vehicleIds.isNotEmpty;
}

// Enhanced user model with multiple roles
class EnhancedUserModel {
  final String id;
  final String? displayName;
  final String? email;
  final String? phoneNumber; // Primary phone for backward compatibility
  final List<PhoneNumber> phoneNumbers;
  final String? photoURL;
  final bool isVerified; // Basic verification
  final Timestamp? createdAt;
  
  // Multi-role support
  final UserType primaryType;
  final List<UserType> roles; // User can have multiple roles
  
  // Profile data for different roles
  final ConsumerProfile? consumerProfile;
  final BusinessProfile? businessProfile;
  final ServiceProviderProfile? serviceProviderProfile;
  final DriverProfile? driverProfile;
  final CourierProfile? courierProfile;
  final VanRentalProfile? vanRentalProfile;

  EnhancedUserModel({
    required this.id,
    this.displayName,
    this.email,
    this.phoneNumber,
    this.phoneNumbers = const [],
    this.photoURL,
    this.isVerified = false,
    this.createdAt,
    this.primaryType = UserType.consumer,
    this.roles = const [UserType.consumer],
    this.consumerProfile,
    this.businessProfile,
    this.serviceProviderProfile,
    this.driverProfile,
    this.courierProfile,
    this.vanRentalProfile,
  });

  factory EnhancedUserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    // Parse phone numbers
    List<PhoneNumber> phoneNumbers = [];
    if (data['phoneNumbers'] != null) {
      phoneNumbers = (data['phoneNumbers'] as List)
          .map((phone) => PhoneNumber.fromMap(phone))
          .toList();
    }
    
    // Parse roles
    List<UserType> roles = [UserType.consumer];
    if (data['roles'] != null) {
      roles = (data['roles'] as List)
          .map((role) => UserType.values.firstWhere(
                (type) => type.name == role,
                orElse: () => UserType.consumer,
              ))
          .toList();
    }
    
    return EnhancedUserModel(
      id: doc.id,
      displayName: data['displayName'] ?? data['name'],
      email: data['email'],
      phoneNumber: data['phoneNumber'],
      phoneNumbers: phoneNumbers,
      photoURL: data['photoURL'],
      isVerified: data['isVerified'] ?? false,
      createdAt: data['createdAt'],
      primaryType: UserType.values.firstWhere(
        (type) => type.name == data['primaryType'],
        orElse: () => UserType.consumer,
      ),
      roles: roles,
      consumerProfile: data['consumerProfile'] != null 
          ? ConsumerProfile.fromMap(data['consumerProfile']) 
          : null,
      businessProfile: data['businessProfile'] != null 
          ? BusinessProfile.fromMap(data['businessProfile']) 
          : null,
      serviceProviderProfile: data['serviceProviderProfile'] != null 
          ? ServiceProviderProfile.fromMap(data['serviceProviderProfile']) 
          : null,
      driverProfile: data['driverProfile'] != null 
          ? DriverProfile.fromMap(data['driverProfile']) 
          : null,
      courierProfile: data['courierProfile'] != null 
          ? CourierProfile.fromMap(data['courierProfile']) 
          : null,
      vanRentalProfile: data['vanRentalProfile'] != null 
          ? VanRentalProfile.fromMap(data['vanRentalProfile']) 
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': id,
      'displayName': displayName,
      'name': displayName,
      'email': email,
      'phoneNumber': phoneNumber,
      'phoneNumbers': phoneNumbers.map((phone) => phone.toMap()).toList(),
      'photoURL': photoURL,
      'isVerified': isVerified,
      'createdAt': createdAt,
      'primaryType': primaryType.name,
      'roles': roles.map((role) => role.name).toList(),
      'consumerProfile': consumerProfile?.toMap(),
      'businessProfile': businessProfile?.toMap(),
      'serviceProviderProfile': serviceProviderProfile?.toMap(),
      'driverProfile': driverProfile?.toMap(),
      'courierProfile': courierProfile?.toMap(),
      'vanRentalProfile': vanRentalProfile?.toMap(),
    };
  }

  // Helper methods
  bool hasRole(UserType role) => roles.contains(role);
  
  List<String> get verifiedPhoneNumbers {
    return phoneNumbers
        .where((phone) => phone.isVerified)
        .map((phone) => phone.number)
        .toList();
  }

  String? get primaryPhoneNumber {
    final primary = phoneNumbers.firstWhere(
      (phone) => phone.isPrimary && phone.isVerified,
      orElse: () => phoneNumbers.isNotEmpty 
          ? phoneNumbers.first 
          : PhoneNumber(number: '', isVerified: false, isPrimary: false),
    );
    return primary.number.isNotEmpty ? primary.number : phoneNumber;
  }

  // Check if user can perform certain actions
  bool get canCreateBusinessListings => hasRole(UserType.business) && 
      businessProfile?.isVerified == true;
  
  bool get canProvideServices => hasRole(UserType.serviceProvider) && 
      serviceProviderProfile?.isVerified == true;
  
  bool get canDriveRides => hasRole(UserType.driver) && 
      driverProfile?.isVerified == true;

  bool get canProvideDelivery => hasRole(UserType.courier) && 
      courierProfile?.isVerified == true;
  
  bool get canProvideVanRental => hasRole(UserType.vanRental) && 
      vanRentalProfile?.isVerified == true;

  // Migration from old UserModel
  factory EnhancedUserModel.fromLegacyUser(UserModel oldUser) {
    // Convert old phone numbers to new format
    List<PhoneNumber> convertedPhones = oldUser.phoneNumbers
        .map((oldPhone) => PhoneNumber(
              number: oldPhone.number,
              isVerified: oldPhone.isVerified,
              isPrimary: oldPhone.isPrimary,
              verifiedAt: oldPhone.verifiedAt,
            ))
        .toList();

    return EnhancedUserModel(
      id: oldUser.id,
      displayName: oldUser.displayName,
      email: oldUser.email,
      phoneNumber: oldUser.phoneNumber,
      phoneNumbers: convertedPhones,
      photoURL: oldUser.photoURL,
      isVerified: oldUser.isVerified,
      createdAt: oldUser.createdAt,
      primaryType: UserType.consumer,
      roles: [UserType.consumer],
      consumerProfile: ConsumerProfile(), // Create basic consumer profile
    );
  }
}
