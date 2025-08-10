// Business Models for Product Management and Registration
// Supports centralized product category system with AI integration

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Enhanced Business Profile Model
class BusinessProfile {
  final String id;
  final String userId; // Owner of the business
  final BusinessBasicInfo basicInfo;
  final BusinessVerification verification;
  final BusinessType businessType;
  final List<String> productCategories; // Categories they deal with
  final BusinessSettings settings;
  final BusinessAnalytics analytics;
  final SubscriptionInfo subscription;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  BusinessProfile({
    required this.id,
    required this.userId,
    required this.basicInfo,
    required this.verification,
    required this.businessType,
    this.productCategories = const [],
    required this.settings,
    required this.analytics,
    required this.subscription,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory BusinessProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BusinessProfile(
      id: doc.id,
      userId: data['userId'] ?? '',
      basicInfo: BusinessBasicInfo.fromMap(data['basicInfo'] ?? {}),
      verification: BusinessVerification.fromMap(data['verification'] ?? {}),
      businessType: BusinessType.values.firstWhere(
        (type) => type.toString() == data['businessType'],
        orElse: () => BusinessType.retail,
      ),
      productCategories: List<String>.from(data['productCategories'] ?? []),
      settings: BusinessSettings.fromMap(data['settings'] ?? {}),
      analytics: BusinessAnalytics.fromMap(data['analytics'] ?? {}),
      subscription: SubscriptionInfo.fromMap(data['subscription'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'basicInfo': basicInfo.toMap(),
      'verification': verification.toMap(),
      'businessType': businessType.toString(),
      'productCategories': productCategories,
      'settings': settings.toMap(),
      'analytics': analytics.toMap(),
      'subscription': subscription.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isActive': isActive,
    };
  }
}

/// Business Basic Information
class BusinessBasicInfo {
  final String name;
  final String description;
  final String email;
  final String phone;
  final String? whatsapp;
  final String? website;
  final String logoUrl;
  final List<String> bannerImages;
  final BusinessAddress address;
  final Map<String, String> socialLinks; // Facebook, Instagram, etc.
  final BusinessType businessType; // Added business type
  final List<String> categories; // Added business categories

  BusinessBasicInfo({
    required this.name,
    required this.description,
    required this.email,
    required this.phone,
    this.whatsapp,
    this.website,
    required this.logoUrl,
    this.bannerImages = const [],
    required this.address,
    this.socialLinks = const {},
    required this.businessType, // Required business type
    this.categories = const [], // Required categories list
  });

  factory BusinessBasicInfo.fromMap(Map<String, dynamic> map) {
    return BusinessBasicInfo(
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      whatsapp: map['whatsapp'],
      website: map['website'],
      logoUrl: map['logoUrl'] ?? '',
      bannerImages: List<String>.from(map['bannerImages'] ?? []),
      address: BusinessAddress.fromMap(map['address'] ?? {}),
      socialLinks: Map<String, String>.from(map['socialLinks'] ?? {}),
      businessType: BusinessType.values.firstWhere(
        (type) => type.name == map['businessType'],
        orElse: () => BusinessType.retail,
      ),
      categories: List<String>.from(map['categories'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'email': email,
      'phone': phone,
      'whatsapp': whatsapp,
      'website': website,
      'logoUrl': logoUrl,
      'bannerImages': bannerImages,
      'address': address.toMap(),
      'socialLinks': socialLinks,
      'businessType': businessType.name,
      'categories': categories,
    };
  }
}

/// Business Address Information
class BusinessAddress {
  final String street;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final double? latitude;
  final double? longitude;
  final bool isPhysicalStore; // Has a physical location customers can visit

  BusinessAddress({
    required this.street,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.latitude,
    this.longitude,
    this.isPhysicalStore = false,
  });

  factory BusinessAddress.fromMap(Map<String, dynamic> map) {
    return BusinessAddress(
      street: map['street'] ?? '',
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      postalCode: map['postalCode'] ?? '',
      country: map['country'] ?? '',
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      isPhysicalStore: map['isPhysicalStore'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'postalCode': postalCode,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'isPhysicalStore': isPhysicalStore,
    };
  }

  String get fullAddress {
    return '$street, $city, $state $postalCode, $country';
  }
}

/// Business Verification Status
class BusinessVerification {
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final bool isBusinessDocumentVerified;
  final bool isTaxDocumentVerified;
  final bool isBankAccountVerified;
  final VerificationStatus overallStatus;
  final DateTime? verifiedAt;
  final String? verificationNotes;
  final List<String> requiredDocuments;
  final List<String> submittedDocuments;

  BusinessVerification({
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.isBusinessDocumentVerified = false,
    this.isTaxDocumentVerified = false,
    this.isBankAccountVerified = false,
    required this.overallStatus,
    this.verifiedAt,
    this.verificationNotes,
    this.requiredDocuments = const [],
    this.submittedDocuments = const [],
  });

  factory BusinessVerification.fromMap(Map<String, dynamic> map) {
    return BusinessVerification(
      isEmailVerified: map['isEmailVerified'] ?? false,
      isPhoneVerified: map['isPhoneVerified'] ?? false,
      isBusinessDocumentVerified: map['isBusinessDocumentVerified'] ?? false,
      isTaxDocumentVerified: map['isTaxDocumentVerified'] ?? false,
      isBankAccountVerified: map['isBankAccountVerified'] ?? false,
      overallStatus: VerificationStatus.values.firstWhere(
        (status) => status.toString() == map['overallStatus'],
        orElse: () => VerificationStatus.pending,
      ),
      verifiedAt: map['verifiedAt'] != null 
          ? (map['verifiedAt'] as Timestamp).toDate() 
          : null,
      verificationNotes: map['verificationNotes'],
      requiredDocuments: List<String>.from(map['requiredDocuments'] ?? []),
      submittedDocuments: List<String>.from(map['submittedDocuments'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isEmailVerified': isEmailVerified,
      'isPhoneVerified': isPhoneVerified,
      'isBusinessDocumentVerified': isBusinessDocumentVerified,
      'isTaxDocumentVerified': isTaxDocumentVerified,
      'isBankAccountVerified': isBankAccountVerified,
      'overallStatus': overallStatus.toString(),
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'verificationNotes': verificationNotes,
      'requiredDocuments': requiredDocuments,
      'submittedDocuments': submittedDocuments,
    };
  }

  bool get isFullyVerified {
    return isEmailVerified && 
           isPhoneVerified && 
           isBusinessDocumentVerified && 
           overallStatus == VerificationStatus.verified;
  }

  /// Check if business can add pricing to existing products (only requires email and phone verification)
  bool get canAddProducts {
    return isEmailVerified && isPhoneVerified;
  }

  /// Check if business can manage pricing (same as canAddProducts)
  bool get canManageProducts {
    return canAddProducts;
  }

  /// Check if business can receive full marketplace benefits (requires full verification)
  bool get hasFullMarketplaceAccess {
    return isFullyVerified;
  }
}

/// Business Settings
class BusinessSettings {
  final bool acceptOnlineOrders;
  final bool enablePriceComparison;
  final bool autoUpdatePrices;
  final double defaultDeliveryCharge;
  final int defaultWarrantyMonths;
  final List<String> paymentMethods; // Cash, Card, Online, etc.
  final BusinessHours businessHours;
  final NotificationSettings notifications;

  BusinessSettings({
    this.acceptOnlineOrders = true,
    this.enablePriceComparison = true,
    this.autoUpdatePrices = false,
    this.defaultDeliveryCharge = 0.0,
    this.defaultWarrantyMonths = 12,
    this.paymentMethods = const ['Cash', 'Card'],
    required this.businessHours,
    required this.notifications,
  });

  factory BusinessSettings.fromMap(Map<String, dynamic> map) {
    return BusinessSettings(
      acceptOnlineOrders: map['acceptOnlineOrders'] ?? true,
      enablePriceComparison: map['enablePriceComparison'] ?? true,
      autoUpdatePrices: map['autoUpdatePrices'] ?? false,
      defaultDeliveryCharge: (map['defaultDeliveryCharge'] ?? 0.0).toDouble(),
      defaultWarrantyMonths: map['defaultWarrantyMonths'] ?? 12,
      paymentMethods: List<String>.from(map['paymentMethods'] ?? ['Cash', 'Card']),
      businessHours: BusinessHours.fromMap(map['businessHours'] ?? {}),
      notifications: NotificationSettings.fromMap(map['notifications'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'acceptOnlineOrders': acceptOnlineOrders,
      'enablePriceComparison': enablePriceComparison,
      'autoUpdatePrices': autoUpdatePrices,
      'defaultDeliveryCharge': defaultDeliveryCharge,
      'defaultWarrantyMonths': defaultWarrantyMonths,
      'paymentMethods': paymentMethods,
      'businessHours': businessHours.toMap(),
      'notifications': notifications.toMap(),
    };
  }
}

/// Business Hours
class BusinessHours {
  final Map<String, DayHours> weekDays; // Monday to Sunday

  BusinessHours({
    required this.weekDays,
  });

  factory BusinessHours.fromMap(Map<String, dynamic> map) {
    final weekDays = <String, DayHours>{};
    map.forEach((day, hours) {
      if (hours is Map<String, dynamic>) {
        weekDays[day] = DayHours.fromMap(hours);
      }
    });
    return BusinessHours(weekDays: weekDays);
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    weekDays.forEach((day, hours) {
      map[day] = hours.toMap();
    });
    return map;
  }

  bool get isOpenNow {
    final now = DateTime.now();
    final dayName = _getDayName(now.weekday);
    final todayHours = weekDays[dayName];
    
    if (todayHours == null || !todayHours.isOpen) return false;
    
    final currentTime = TimeOfDay.fromDateTime(now);
    return todayHours.isWithinHours(currentTime);
  }

  String _getDayName(int weekday) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[weekday - 1];
  }
}

/// Day Hours
class DayHours {
  final bool isOpen;
  final TimeOfDay? openTime;
  final TimeOfDay? closeTime;
  final bool is24Hours;

  DayHours({
    this.isOpen = true,
    this.openTime,
    this.closeTime,
    this.is24Hours = false,
  });

  factory DayHours.fromMap(Map<String, dynamic> map) {
    return DayHours(
      isOpen: map['isOpen'] ?? true,
      openTime: map['openTime'] != null 
          ? TimeOfDay(hour: map['openTime']['hour'], minute: map['openTime']['minute'])
          : null,
      closeTime: map['closeTime'] != null 
          ? TimeOfDay(hour: map['closeTime']['hour'], minute: map['closeTime']['minute'])
          : null,
      is24Hours: map['is24Hours'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isOpen': isOpen,
      'openTime': openTime != null 
          ? {'hour': openTime!.hour, 'minute': openTime!.minute}
          : null,
      'closeTime': closeTime != null 
          ? {'hour': closeTime!.hour, 'minute': closeTime!.minute}
          : null,
      'is24Hours': is24Hours,
    };
  }

  bool isWithinHours(TimeOfDay time) {
    if (!isOpen) return false;
    if (is24Hours) return true;
    if (openTime == null || closeTime == null) return false;

    final timeMinutes = time.hour * 60 + time.minute;
    final openMinutes = openTime!.hour * 60 + openTime!.minute;
    final closeMinutes = closeTime!.hour * 60 + closeTime!.minute;

    if (closeMinutes > openMinutes) {
      // Same day (e.g., 9 AM to 6 PM)
      return timeMinutes >= openMinutes && timeMinutes <= closeMinutes;
    } else {
      // Crosses midnight (e.g., 10 PM to 2 AM)
      return timeMinutes >= openMinutes || timeMinutes <= closeMinutes;
    }
  }
}

// Helper class for TimeOfDay
class TimeOfDay {
  final int hour;
  final int minute;

  TimeOfDay({required this.hour, required this.minute});

  factory TimeOfDay.fromDateTime(DateTime dateTime) {
    return TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
  }

  @override
  String toString() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }
}

/// Notification Settings
class NotificationSettings {
  final bool enableOrderNotifications;
  final bool enablePriceAlerts;
  final bool enableInventoryAlerts;
  final bool enableMarketingEmails;

  NotificationSettings({
    this.enableOrderNotifications = true,
    this.enablePriceAlerts = true,
    this.enableInventoryAlerts = true,
    this.enableMarketingEmails = false,
  });

  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      enableOrderNotifications: map['enableOrderNotifications'] ?? true,
      enablePriceAlerts: map['enablePriceAlerts'] ?? true,
      enableInventoryAlerts: map['enableInventoryAlerts'] ?? true,
      enableMarketingEmails: map['enableMarketingEmails'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enableOrderNotifications': enableOrderNotifications,
      'enablePriceAlerts': enablePriceAlerts,
      'enableInventoryAlerts': enableInventoryAlerts,
      'enableMarketingEmails': enableMarketingEmails,
    };
  }
}

/// Business Analytics
class BusinessAnalytics {
  final int totalProducts;
  final int totalClicks;
  final double totalRevenue;
  final int monthlyViews;
  final double averageRating;
  final int totalReviews;
  final DateTime lastUpdated;

  BusinessAnalytics({
    this.totalProducts = 0,
    this.totalClicks = 0,
    this.totalRevenue = 0.0,
    this.monthlyViews = 0,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    required this.lastUpdated,
  });

  factory BusinessAnalytics.fromMap(Map<String, dynamic> map) {
    return BusinessAnalytics(
      totalProducts: map['totalProducts'] ?? 0,
      totalClicks: map['totalClicks'] ?? 0,
      totalRevenue: (map['totalRevenue'] ?? 0.0).toDouble(),
      monthlyViews: map['monthlyViews'] ?? 0,
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      totalReviews: map['totalReviews'] ?? 0,
      lastUpdated: map['lastUpdated'] != null 
          ? (map['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalProducts': totalProducts,
      'totalClicks': totalClicks,
      'totalRevenue': totalRevenue,
      'monthlyViews': monthlyViews,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}

/// Subscription Information
class SubscriptionInfo {
  final SubscriptionPlan plan;
  final DateTime? subscriptionStart;
  final DateTime? subscriptionEnd;
  final bool isActive;
  final double monthlyFee;
  final List<String> features;
  final PaymentStatus paymentStatus;

  SubscriptionInfo({
    this.plan = SubscriptionPlan.basic,
    this.subscriptionStart,
    this.subscriptionEnd,
    this.isActive = false,
    this.monthlyFee = 0.0,
    this.features = const [],
    this.paymentStatus = PaymentStatus.pending,
  });

  factory SubscriptionInfo.fromMap(Map<String, dynamic> map) {
    return SubscriptionInfo(
      plan: SubscriptionPlan.values.firstWhere(
        (plan) => plan.toString() == map['plan'],
        orElse: () => SubscriptionPlan.basic,
      ),
      subscriptionStart: map['subscriptionStart'] != null 
          ? (map['subscriptionStart'] as Timestamp).toDate()
          : null,
      subscriptionEnd: map['subscriptionEnd'] != null 
          ? (map['subscriptionEnd'] as Timestamp).toDate()
          : null,
      isActive: map['isActive'] ?? false,
      monthlyFee: (map['monthlyFee'] ?? 0.0).toDouble(),
      features: List<String>.from(map['features'] ?? []),
      paymentStatus: PaymentStatus.values.firstWhere(
        (status) => status.toString() == map['paymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'plan': plan.toString(),
      'subscriptionStart': subscriptionStart != null 
          ? Timestamp.fromDate(subscriptionStart!)
          : null,
      'subscriptionEnd': subscriptionEnd != null 
          ? Timestamp.fromDate(subscriptionEnd!)
          : null,
      'isActive': isActive,
      'monthlyFee': monthlyFee,
      'features': features,
      'paymentStatus': paymentStatus.toString(),
    };
  }

  bool get isExpired {
    if (subscriptionEnd == null) return false;
    return DateTime.now().isAfter(subscriptionEnd!);
  }
}

/// Enums
enum BusinessType {
  retail,      // Product sellers (shops, stores)
  service,     // Service providers (salons, repair)
  restaurant,  // Food delivery
  rental,      // Vehicle/equipment rental
  logistics,   // Delivery services
  professional // Lawyers, doctors, consultants
}

enum VerificationStatus {
  pending,
  underReview,
  verified,
  rejected,
  suspended
}

enum SubscriptionPlan {
  basic,
  premium,
  enterprise
}

enum PaymentStatus {
  pending,
  paid,
  failed,
  cancelled
}
