import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionType {
  rider,
  business,
}

enum SubscriptionStatus {
  active,
  expired,
  cancelled,
  trial,
  suspended,
  pendingPayment
}

enum PaymentModel {
  monthly,       // For riders
  payPerClick,   // For businesses
  yearly,        // For both (with discount)
}

class SubscriptionPlan {
  final String id;
  final String name;
  final String description;
  final SubscriptionType type;
  final PaymentModel paymentModel;
  final Map<String, double> countryPrices; // Country code -> price
  final Map<String, String> currencySymbols; // Country code -> currency symbol
  final List<String> features;
  final Map<String, dynamic> limitations; // For free/trial plans
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubscriptionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.paymentModel,
    required this.countryPrices,
    required this.currencySymbols,
    required this.features,
    required this.limitations,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SubscriptionPlan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubscriptionPlan(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      type: SubscriptionType.values.firstWhere(
        (e) => e.toString() == 'SubscriptionType.${data['type']}',
        orElse: () => SubscriptionType.rider,
      ),
      paymentModel: PaymentModel.values.firstWhere(
        (e) => e.toString() == 'PaymentModel.${data['paymentModel']}',
        orElse: () => PaymentModel.monthly,
      ),
      countryPrices: Map<String, double>.from(data['countryPrices'] ?? {}),
      currencySymbols: Map<String, String>.from(data['currencySymbols'] ?? {}),
      features: List<String>.from(data['features'] ?? []),
      limitations: Map<String, dynamic>.from(data['limitations'] ?? {}),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'paymentModel': paymentModel.toString().split('.').last,
      'countryPrices': countryPrices,
      'currencySymbols': currencySymbols,
      'features': features,
      'limitations': limitations,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  double getPriceForCountry(String countryCode) {
    return countryPrices[countryCode] ?? countryPrices['LK'] ?? 0.0;
  }

  String getCurrencySymbolForCountry(String countryCode) {
    return currencySymbols[countryCode] ?? currencySymbols['LK'] ?? 'Rs';
  }
}

class UserSubscription {
  final String id;
  final String userId;
  final String planId;
  final SubscriptionType type;
  final SubscriptionStatus status;
  final DateTime trialStartDate;
  final DateTime trialEndDate;
  final DateTime? subscriptionStartDate;
  final DateTime? subscriptionEndDate;
  final DateTime? lastPaymentDate;
  final DateTime? nextPaymentDate;
  final String countryCode;
  final double paidAmount;
  final String currency;
  final Map<String, dynamic> usageStats; // clicks, rides, etc.
  final Map<String, dynamic> limitations; // current limitations
  final String? promoCodeApplied;
  final Map<String, dynamic>? promoCodeBenefits;
  final bool isTrialExtended;
  final DateTime? trialExtendedUntil;
  final bool autoRenew;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserSubscription({
    required this.id,
    required this.userId,
    required this.planId,
    required this.type,
    required this.status,
    required this.trialStartDate,
    required this.trialEndDate,
    this.subscriptionStartDate,
    this.subscriptionEndDate,
    this.lastPaymentDate,
    this.nextPaymentDate,
    required this.countryCode,
    this.paidAmount = 0.0,
    required this.currency,
    this.usageStats = const {},
    this.limitations = const {},
    this.promoCodeApplied,
    this.promoCodeBenefits,
    this.isTrialExtended = false,
    this.trialExtendedUntil,
    this.autoRenew = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserSubscription.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserSubscription(
      id: doc.id,
      userId: data['userId'] ?? '',
      planId: data['planId'] ?? '',
      type: SubscriptionType.values.firstWhere(
        (e) => e.toString() == 'SubscriptionType.${data['type']}',
        orElse: () => SubscriptionType.rider,
      ),
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.toString() == 'SubscriptionStatus.${data['status']}',
        orElse: () => SubscriptionStatus.trial,
      ),
      trialStartDate: (data['trialStartDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      trialEndDate: (data['trialEndDate'] as Timestamp?)?.toDate() ?? DateTime.now().add(const Duration(days: 90)),
      subscriptionStartDate: (data['subscriptionStartDate'] as Timestamp?)?.toDate(),
      subscriptionEndDate: (data['subscriptionEndDate'] as Timestamp?)?.toDate(),
      lastPaymentDate: (data['lastPaymentDate'] as Timestamp?)?.toDate(),
      nextPaymentDate: (data['nextPaymentDate'] as Timestamp?)?.toDate(),
      countryCode: data['countryCode'] ?? 'LK',
      paidAmount: (data['paidAmount'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'LKR',
      usageStats: Map<String, dynamic>.from(data['usageStats'] ?? {}),
      limitations: Map<String, dynamic>.from(data['limitations'] ?? {}),
      promoCodeApplied: data['promoCodeApplied'],
      promoCodeBenefits: data['promoCodeBenefits'] != null 
          ? Map<String, dynamic>.from(data['promoCodeBenefits']) 
          : null,
      isTrialExtended: data['isTrialExtended'] ?? false,
      trialExtendedUntil: (data['trialExtendedUntil'] as Timestamp?)?.toDate(),
      autoRenew: data['autoRenew'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'planId': planId,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'trialStartDate': Timestamp.fromDate(trialStartDate),
      'trialEndDate': Timestamp.fromDate(trialEndDate),
      'subscriptionStartDate': subscriptionStartDate != null ? Timestamp.fromDate(subscriptionStartDate!) : null,
      'subscriptionEndDate': subscriptionEndDate != null ? Timestamp.fromDate(subscriptionEndDate!) : null,
      'lastPaymentDate': lastPaymentDate != null ? Timestamp.fromDate(lastPaymentDate!) : null,
      'nextPaymentDate': nextPaymentDate != null ? Timestamp.fromDate(nextPaymentDate!) : null,
      'countryCode': countryCode,
      'paidAmount': paidAmount,
      'currency': currency,
      'usageStats': usageStats,
      'limitations': limitations,
      'promoCodeApplied': promoCodeApplied,
      'promoCodeBenefits': promoCodeBenefits,
      'isTrialExtended': isTrialExtended,
      'trialExtendedUntil': trialExtendedUntil != null ? Timestamp.fromDate(trialExtendedUntil!) : null,
      'autoRenew': autoRenew,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  bool get isTrialActive {
    return status == SubscriptionStatus.trial && DateTime.now().isBefore(trialEndDate);
  }

  bool get isSubscriptionActive {
    return status == SubscriptionStatus.active && 
           subscriptionEndDate != null && 
           DateTime.now().isBefore(subscriptionEndDate!);
  }

  bool get hasActiveAccess {
    return isTrialActive || isSubscriptionActive;
  }

  int get remainingTrialDays {
    if (!isTrialActive) return 0;
    return trialEndDate.difference(DateTime.now()).inDays;
  }

  int get remainingSubscriptionDays {
    if (!isSubscriptionActive || subscriptionEndDate == null) return 0;
    return subscriptionEndDate!.difference(DateTime.now()).inDays;
  }

  UserSubscription copyWith({
    String? id,
    String? userId,
    String? planId,
    SubscriptionType? type,
    SubscriptionStatus? status,
    DateTime? trialStartDate,
    DateTime? trialEndDate,
    DateTime? subscriptionStartDate,
    DateTime? subscriptionEndDate,
    DateTime? lastPaymentDate,
    DateTime? nextPaymentDate,
    String? countryCode,
    double? paidAmount,
    String? currency,
    Map<String, dynamic>? usageStats,
    Map<String, dynamic>? limitations,
    String? promoCodeApplied,
    Map<String, dynamic>? promoCodeBenefits,
    bool? isTrialExtended,
    DateTime? trialExtendedUntil,
    bool? autoRenew,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserSubscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planId: planId ?? this.planId,
      type: type ?? this.type,
      status: status ?? this.status,
      trialStartDate: trialStartDate ?? this.trialStartDate,
      trialEndDate: trialEndDate ?? this.trialEndDate,
      subscriptionStartDate: subscriptionStartDate ?? this.subscriptionStartDate,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      nextPaymentDate: nextPaymentDate ?? this.nextPaymentDate,
      countryCode: countryCode ?? this.countryCode,
      paidAmount: paidAmount ?? this.paidAmount,
      currency: currency ?? this.currency,
      usageStats: usageStats ?? this.usageStats,
      limitations: limitations ?? this.limitations,
      promoCodeApplied: promoCodeApplied ?? this.promoCodeApplied,
      promoCodeBenefits: promoCodeBenefits ?? this.promoCodeBenefits,
      isTrialExtended: isTrialExtended ?? this.isTrialExtended,
      trialExtendedUntil: trialExtendedUntil ?? this.trialExtendedUntil,
      autoRenew: autoRenew ?? this.autoRenew,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class PaymentTransaction {
  final String id;
  final String userId;
  final String subscriptionId;
  final double amount;
  final String currency;
  final String countryCode;
  final String paymentMethod;
  final String transactionType; // subscription, click_payment, etc.
  final Map<String, dynamic> metadata;
  final String status; // pending, completed, failed, refunded
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentTransaction({
    required this.id,
    required this.userId,
    required this.subscriptionId,
    required this.amount,
    required this.currency,
    required this.countryCode,
    required this.paymentMethod,
    required this.transactionType,
    this.metadata = const {},
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PaymentTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentTransaction(
      id: doc.id,
      userId: data['userId'] ?? '',
      subscriptionId: data['subscriptionId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      currency: data['currency'] ?? 'LKR',
      countryCode: data['countryCode'] ?? 'LK',
      paymentMethod: data['paymentMethod'] ?? '',
      transactionType: data['transactionType'] ?? '',
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      status: data['status'] ?? 'pending',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'subscriptionId': subscriptionId,
      'amount': amount,
      'currency': currency,
      'countryCode': countryCode,
      'paymentMethod': paymentMethod,
      'transactionType': transactionType,
      'metadata': metadata,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
