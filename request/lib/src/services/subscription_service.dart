import 'api_client.dart';

class SubscriptionPlan {
  final String id;
  final String code;
  final String name;
  final String type; // 'rider' | 'business'
  final String planType; // 'monthly' | 'pay_per_click'
  final String? description;
  final num? price;
  final String? currency;
  final int? durationDays;

  SubscriptionPlan({
    required this.id,
    required this.code,
    required this.name,
    required this.type,
    required this.planType,
    this.description,
    this.price,
    this.currency,
    this.durationDays,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'].toString(),
      code: (json['code'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      type: (json['type'] ?? 'rider').toString(),
      planType: (json['plan_type'] ?? 'monthly').toString(),
      description: json['description']?.toString(),
      price: json['price'] as num?,
      currency: json['currency']?.toString(),
      durationDays: json['duration_days'] is int
          ? json['duration_days'] as int
          : int.tryParse('${json['duration_days']}'),
    );
  }
}

class SubscriptionServiceApi {
  SubscriptionServiceApi._();
  static final SubscriptionServiceApi instance = SubscriptionServiceApi._();
  final ApiClient _api = ApiClient.instance;

  Future<List<SubscriptionPlan>> fetchPlans(
      {String type = 'rider', bool activeOnly = true}) async {
    final qp = <String, String>{'type': type};
    if (activeOnly) qp['active'] = 'true';
    final res = await _api.get<List<dynamic>>('/api/subscription-plans-new',
        queryParameters: qp);
    if (res.isSuccess && res.data != null) {
      final list = res.data!;
      return list
          .map((e) => SubscriptionPlan.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  Future<Map<String, dynamic>?> getMySubscription() async {
    final res = await _api.get<Map<String, dynamic>>('/api/subscriptions/me');
    if (res.isSuccess && res.data != null)
      return res.data!['data'] as Map<String, dynamic>?;
    return null;
  }

  Future<bool> startSubscription(String planId, {String? promoCode}) async {
    final data = <String, dynamic>{'plan_id': planId};
    if (promoCode != null && promoCode.isNotEmpty)
      data['promo_code'] = promoCode;
    final res = await _api
        .post<Map<String, dynamic>>('/api/subscriptions/start', data: data);
    return res.isSuccess == true;
  }

  Future<bool> cancelSubscription({bool immediate = false}) async {
    final res = await _api.post<Map<String, dynamic>>(
        '/api/subscriptions/cancel',
        data: {'immediate': immediate});
    return res.isSuccess == true;
  }
}
