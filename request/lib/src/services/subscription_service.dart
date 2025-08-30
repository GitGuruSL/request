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
    // Subscriptions removed
    return [];
  }

  Future<List<SubscriptionPlan>> fetchUserResponsePlans(
      {bool activeOnly = true}) async {
    return [];
  }

  Future<List<SubscriptionPlan>> fetchProductSellerPlans(
      {bool activeOnly = true}) async {
    return [];
  }

  Future<Map<String, dynamic>?> getMySubscription() async {
    // Subscriptions removed
    return {'hasSubscription': false};
  }

  Future<Map<String, dynamic>?> createSubscription({
    required String planId,
    required String countryCode,
    String? promoCode,
  }) async {
    return {'success': false, 'error': 'disabled'};
  }

  Future<Map<String, dynamic>?> checkoutSubscription({
    required String subscriptionId,
    String? provider,
  }) async {
    return {'success': false, 'error': 'disabled'};
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
