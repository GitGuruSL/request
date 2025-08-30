import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class EnhancedBusinessBenefitsService {
  static const String _baseUrl =
      '${ApiConfig.productionUrl}/enhanced-business-benefits';

  /// Get all business type benefits for a country
  static Future<Map<String, dynamic>> getBusinessTypeBenefits(
      String countryCode) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$countryCode'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to load business benefits: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching business benefits: $e');
    }
  }

  /// Get benefit plans for a specific business type
  static Future<Map<String, dynamic>> getBusinessTypePlans(
      String countryCode, int businessTypeId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$countryCode/$businessTypeId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to load business type plans: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching business type plans: $e');
    }
  }

  /// Create a new benefit plan
  static Future<Map<String, dynamic>> createBenefitPlan({
    required String countryCode,
    required int businessTypeId,
    required String planCode,
    required String planName,
    required String pricingModel,
    Map<String, dynamic>? features,
    Map<String, dynamic>? pricing,
    List<String>? allowedResponseTypes,
  }) async {
    try {
      final requestBody = {
        'countryId': countryCode,
        'businessTypeId': businessTypeId,
        'planCode': planCode,
        'planName': planName,
        'pricingModel': pricingModel,
        if (features != null) 'features': features,
        if (pricing != null) 'pricing': pricing,
        if (allowedResponseTypes != null)
          'allowedResponseTypes': allowedResponseTypes,
      };

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to create benefit plan: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating benefit plan: $e');
  }
  
  static Future<Map<String, dynamic>> getBusinessTypeBenefits(String countryCode) async {
    return { 'success': true, 'data': { 'plans': [] } };
  }
  
  static Future<void> deleteBenefitPlan(String planId) async {
    // no-op
  }
}
    Map<String, dynamic>? pricing,
    List<String>? allowedResponseTypes,
    bool? isActive,
  }) async {
    try {
      final requestBody = <String, dynamic>{};

      if (planName != null) requestBody['planName'] = planName;
      if (pricingModel != null) requestBody['pricingModel'] = pricingModel;
      if (features != null) requestBody['features'] = features;
      if (pricing != null) requestBody['pricing'] = pricing;
      if (allowedResponseTypes != null)
        requestBody['allowedResponseTypes'] = allowedResponseTypes;
      if (isActive != null) requestBody['isActive'] = isActive;

      final response = await http.put(
        Uri.parse('$_baseUrl/$planId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to update benefit plan: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating benefit plan: $e');
    }
  }

  /// Delete a benefit plan
  static Future<Map<String, dynamic>> deleteBenefitPlan(int planId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/$planId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to delete benefit plan: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting benefit plan: $e');
    }
  }
}
