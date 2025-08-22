import '../services/api_client.dart';

class PaymentMethod {
  final String id; // country_payment_methods.id
  final String name;
  final String description;
  final String category;
  final String imageUrl;
  final String fees;

  PaymentMethod({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.fees,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? 'other',
      imageUrl: json['imageUrl'] ?? json['image_url'] ?? '',
      fees: json['fees']?.toString() ?? '',
    );
  }
}

class PaymentMethodsService {
  static final ApiClient _api = ApiClient.instance;

  // List active country payment methods for a country
  static Future<List<PaymentMethod>> getPaymentMethodsForCountry(
      String countryCode) async {
    try {
      final resp = await _api.get<dynamic>(
        '/api/payment-methods/public/list',
        queryParameters: {'country': countryCode},
      );
      if (!resp.isSuccess || resp.data == null) return [];

      // Response may be array or wrapped; normalize
      final data = resp.data;
      final List<dynamic> list = data is List
          ? data
          : (data is Map<String, dynamic> && data['value'] is List
              ? data['value'] as List
              : []);
      return list
          .map((e) => PaymentMethod.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getPaymentMethodsForCountry: $e');
      return [];
    }
  }

  // Get currently selected methods for a business (returns country method IDs)
  static Future<List<String>> getSelectedForBusiness(String businessId) async {
    try {
      final resp =
          await _api.get<dynamic>('/api/payment-methods/business/$businessId');
      if (!resp.isSuccess || resp.data == null) return [];
      final data = resp.data;
      final List<dynamic> list = data is List
          ? data
          : (data is Map<String, dynamic> && data['value'] is List
              ? data['value'] as List
              : []);
      // backend returns paymentMethodId for each mapping
      return list
          .map(
              (e) => (e as Map<String, dynamic>)['paymentMethodId']?.toString())
          .whereType<String>()
          .toList();
    } catch (e) {
      print('Error getSelectedForBusiness: $e');
      return [];
    }
  }

  // Set the mapping list for a business
  static Future<bool> setSelectedForBusiness(
      String businessId, List<String> paymentMethodIds) async {
    try {
      final resp = await _api.post(
        '/api/payment-methods/business/$businessId',
        data: {'paymentMethodIds': paymentMethodIds},
      );
      if (resp.isSuccess) return true;
      // Some backends wrap success: true in body
      final body = resp.data;
      if (body is Map && (body['success'] == true)) return true;
      return false;
    } catch (e) {
      print('Error setSelectedForBusiness: $e');
      return false;
    }
  }
}
