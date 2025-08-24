enum PromoCodeType {
  percentageDiscount,
  fixedDiscount,
  freeTrialExtension,
  unlimitedResponses,
  businessFreeClicks
}

enum PromoCodeStatus {
  pendingApproval,
  active,
  expired,
  used,
  disabled,
  rejected
}

class PromoCodeModel {
  final String id;
  final String code;
  final String title;
  final String description;
  final PromoCodeType type;
  final PromoCodeStatus status;
  final double value; // percentage or fixed amount
  final DateTime validFrom;
  final DateTime validTo;
  final int maxUses;
  final int currentUses;
  final List<String> applicableUserTypes; // ['rider', 'business', 'driver']
  final List<String> applicableCountries; // country codes
  final Map<String, dynamic> conditions; // additional conditions
  final String createdBy; // admin user ID who created it
  final String? approvedBy; // super admin user ID who approved it
  final DateTime? approvedAt; // when it was approved
  final String? rejectionReason; // reason for rejection if applicable
  final String createdByCountry; // country code of the creating admin
  final DateTime createdAt;
  final DateTime updatedAt;

  PromoCodeModel({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.value,
    required this.validFrom,
    required this.validTo,
    required this.maxUses,
    required this.currentUses,
    required this.applicableUserTypes,
    required this.applicableCountries,
    required this.conditions,
    required this.createdBy,
    this.approvedBy,
    this.approvedAt,
    this.rejectionReason,
    required this.createdByCountry,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PromoCodeModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return PromoCodeModel(
      id: doc.id,
      code: data['code'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: PromoCodeType.values.firstWhere(
        (e) => e.toString() == 'PromoCodeType.${data['type']}',
        orElse: () => PromoCodeType.percentageDiscount,
      ),
      status: PromoCodeStatus.values.firstWhere(
        (e) => e.toString() == 'PromoCodeStatus.${data['status']}',
        orElse: () => PromoCodeStatus.active,
      ),
      value: (data['value'] ?? 0).toDouble(),
      validFrom: (data['validFrom'] as Timestamp).toDate(),
      validTo: (data['validTo'] as Timestamp).toDate(),
      maxUses: data['maxUses'] ?? 0,
      currentUses: data['currentUses'] ?? 0,
      applicableUserTypes: List<String>.from(data['applicableUserTypes'] ?? []),
      applicableCountries: List<String>.from(data['applicableCountries'] ?? []),
      conditions: Map<String, dynamic>.from(data['conditions'] ?? {}),
      createdBy: data['createdBy'] ?? '',
      approvedBy: data['approvedBy'],
      approvedAt: data['approvedAt'] != null
          ? (data['approvedAt'] as Timestamp).toDate()
          : null,
      rejectionReason: data['rejectionReason'],
      createdByCountry: data['createdByCountry'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'value': value,
      'validFrom': Timestamp.fromDate(validFrom),
      'validTo': Timestamp.fromDate(validTo),
      'maxUses': maxUses,
      'currentUses': currentUses,
      'applicableUserTypes': applicableUserTypes,
      'applicableCountries': applicableCountries,
      'conditions': conditions,
      'createdBy': createdBy,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'rejectionReason': rejectionReason,
      'createdByCountry': createdByCountry,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  bool get isValid {
    final now = DateTime.now();
    return status == PromoCodeStatus.active &&
        now.isAfter(validFrom) &&
        now.isBefore(validTo) &&
        currentUses < maxUses;
  }

  bool get isPendingApproval {
    return status == PromoCodeStatus.pendingApproval;
  }

  bool get isApproved {
    return approvedBy != null && approvedAt != null;
  }

  bool get isRejected {
    return status == PromoCodeStatus.rejected;
  }

  bool isApplicableForUser(String userType, String countryCode) {
    return applicableUserTypes.contains(userType) &&
        (applicableCountries.isEmpty ||
            applicableCountries.contains(countryCode));
  }

  String get displayValue {
    switch (type) {
      case PromoCodeType.percentageDiscount:
        return '${value.toInt()}% OFF';
      case PromoCodeType.fixedDiscount:
        return '-${value.toStringAsFixed(2)}';
      case PromoCodeType.freeTrialExtension:
        return '+${value.toInt()} days free';
      case PromoCodeType.unlimitedResponses:
        return 'Unlimited responses';
      case PromoCodeType.businessFreeClicks:
        return '${value.toInt()} free clicks';
      default:
        return 'Special offer';
    }
  }
}

class PromoCodeUsage {
  final String id;
  final String promoCodeId;
  final String userId;
  final String userType;
  final String countryCode;
  final DateTime usedAt;
  final double discountApplied;
  final Map<String, dynamic> benefits;

  PromoCodeUsage({
    required this.id,
    required this.promoCodeId,
    required this.userId,
    required this.userType,
    required this.countryCode,
    required this.usedAt,
    required this.discountApplied,
    required this.benefits,
  });

  factory PromoCodeUsage.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return PromoCodeUsage(
      id: doc.id,
      promoCodeId: data['promoCodeId'] ?? '',
      userId: data['userId'] ?? '',
      userType: data['userType'] ?? '',
      countryCode: data['countryCode'] ?? '',
      usedAt: (data['usedAt'] as Timestamp).toDate(),
      discountApplied: (data['discountApplied'] ?? 0).toDouble(),
      benefits: Map<String, dynamic>.from(data['benefits'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'promoCodeId': promoCodeId,
      'userId': userId,
      'userType': userType,
      'countryCode': countryCode,
      'usedAt': Timestamp.fromDate(usedAt),
      'discountApplied': discountApplied,
      'benefits': benefits,
    };
  }
}
