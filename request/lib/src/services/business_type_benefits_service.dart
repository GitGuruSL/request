import 'dart:convert';
import 'package:http/http.dart' as http;

class BusinessTypeBenefitsService {
  static const String baseUrl = 'https://request-backend.herokuapp.com/api';
  // For local development, use: 'http://localhost:3000/api'

  static Future<Map<String, dynamic>?> getBusinessTypeBenefits(
      int countryId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/business-type-benefits/$countryId'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          return data['businessTypeBenefits'] as Map<String, dynamic>;
        }
      }

      print('Failed to fetch business type benefits: ${response.statusCode}');
      return null;
    } catch (e) {
      print('Error fetching business type benefits: $e');
      return null;
    }
  }

  static Future<bool> updateBusinessTypeBenefits({
    required int countryId,
    required int businessTypeId,
    required String planType,
    int? responsesPerMonth,
    bool? contactRevealed,
    bool? canMessageRequester,
    bool? respondButtonEnabled,
    bool? instantNotifications,
    bool? priorityInSearch,
  }) async {
    try {
      final body = <String, dynamic>{};

      if (responsesPerMonth != null)
        body['responsesPerMonth'] = responsesPerMonth;
      if (contactRevealed != null) body['contactRevealed'] = contactRevealed;
      if (canMessageRequester != null)
        body['canMessageRequester'] = canMessageRequester;
      if (respondButtonEnabled != null)
        body['respondButtonEnabled'] = respondButtonEnabled;
      if (instantNotifications != null)
        body['instantNotifications'] = instantNotifications;
      if (priorityInSearch != null) body['priorityInSearch'] = priorityInSearch;

      final response = await http.put(
        Uri.parse(
            '$baseUrl/business-type-benefits/$countryId/$businessTypeId/$planType'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['success'] == true;
      }

      print('Failed to update business type benefits: ${response.statusCode}');
      return false;
    } catch (e) {
      print('Error updating business type benefits: $e');
      return false;
    }
  }
}
