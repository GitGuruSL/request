import 'api_client.dart';

class SubscriptionPlan {
  final String id;
  final String code;
  final String name;
  final String type; // 'user_response' | 'product_seller'
  final String
      planType; // For user response: response_type, For product: billing_type
  final String? description;
  final num? price;
  final String? currency;
  final int? responseLimit; // For user response plans
  final List<String>? features; // For user response plans

  SubscriptionPlan({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.planType,
    this.description,
    this.price,
    this.currency,
    this.responseLimit,
    this.features,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json, String type) {
    return SubscriptionPlan(
      id: json['id'].toString(),
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      type: type,
      planType: type == 'user_response'
          ? (json['response_type'] ?? 'other').toString()
          : (json['billing_type'] ?? 'monthly').toString(),
      description: json['description']?.toString(),
      price: json['monthly_price'] as num? ??
          json['price_per_click'] as num? ??
          json['monthly_fee'] as num?,
      currency: json['currency']?.toString(),
      responseLimit: json['response_limit'] as int?,
      features: json['features'] != null
          ? List<String>.from(json['features'] as List)
          : null,
    );
  }

  // Helper getters
  bool get isFree => planType == 'free' || (price ?? 0) == 0;
  bool get isUnlimited => responseLimit == null;
  String get displayPrice {
    if (isFree) return 'Free';
    if (price == null) return 'Contact for pricing';

    if (type == 'product_seller') {
      if (planType == 'per_click') {
        return '${(price! * 10000).toStringAsFixed(4)} per click';
      } else {
        return '${price!.toStringAsFixed(2)} /month';
      }
    } else {
      return '${price!.toStringAsFixed(2)} /month';
    }
  }
}

class SubscriptionServiceApi {
  SubscriptionServiceApi._();
  static final SubscriptionServiceApi instance = SubscriptionServiceApi._();
  final ApiClient _api = ApiClient.instance;

  Future<List<SubscriptionPlan>> fetchPlans({
    String type = 'user_response', // 'user_response' or 'product_seller'
    bool activeOnly = true,
  }) async {
    // Use new subscription management endpoints
    final endpoint = type == 'user_response'
        ? '/api/subscription-management/user-response-plans'
        : '/api/subscription-management/product-seller-plans';

    final qp = <String, String>{};
    if (activeOnly) qp['active'] = 'true';

    final res =
        await _api.get<Map<String, dynamic>>(endpoint, queryParameters: qp);
    if (res.isSuccess && res.data != null) {
      final list = (res.data!['data'] as List?) ?? [];
      return list
          .map(
              (e) => SubscriptionPlan.fromJson(e as Map<String, dynamic>, type))
          .toList();
    }
    return [];
  }

  Future<List<SubscriptionPlan>> fetchUserResponsePlans(
      {bool activeOnly = true}) async {
    return fetchPlans(type: 'user_response', activeOnly: activeOnly);
  }

  Future<List<SubscriptionPlan>> fetchProductSellerPlans(
      {bool activeOnly = true}) async {
    return fetchPlans(type: 'product_seller', activeOnly: activeOnly);
  }

  Future<Map<String, dynamic>?> getMySubscription() async {
    final res = await _api.get<Map<String, dynamic>>('/api/subscriptions/me');
    if (res.isSuccess && res.data != null) {
      return res.data!['data'] as Map<String, dynamic>?;
    }
    return null;
  }

  Future<Map<String, dynamic>?> createSubscription({
    required String planId,
    required String countryCode,
    String? promoCode,
  }) async {
    final data = <String, dynamic>{
      'plan_id': planId,
      'country_code': countryCode,
      if (promoCode != null && promoCode.isNotEmpty) 'promo_code': promoCode,
    };
    final res = await _api.post<Map<String, dynamic>>(
      '/api/subscriptions',
      data: data,
    );
    if (res.isSuccess && res.data != null) {
      return res.data!['data'] as Map<String, dynamic>?;
    }
    return null;
  }

  Future<Map<String, dynamic>?> checkoutSubscription({
    required String subscriptionId,
    String? provider,
  }) async {
    final res = await _api.post<Map<String, dynamic>>(
      '/api/payments/checkout-subscription',
      data: {
        'subscription_id': subscriptionId,
        if (provider != null) 'provider': provider,
      },
    );
    if (res.isSuccess && res.data != null) {
      return res.data!['data'] as Map<String, dynamic>?;
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getCountryGateways(
      String countryCode) async {
    final res = await _api.get<Map<String, dynamic>>(
      '/api/country-payment-gateways',
      queryParameters: {'country': countryCode},
    );
    if (res.isSuccess && res.data != null) {
      final list = (res.data!['data'] as List?) ?? [];
      return list.cast<Map<String, dynamic>>();
    }
    return [];
  }
}
