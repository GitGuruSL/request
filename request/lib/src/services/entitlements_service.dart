import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EntitlementsService {
  static const String baseUrl = 'https://54.144.9.226:3001/api';

  /// Get user's current entitlements
  static Future<Map<String, dynamic>?> getUserEntitlements() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/entitlements/me?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Error getting user entitlements: $e');
      return null;
    }
  }

  /// Check if user can see contact details
  static Future<bool> canSeeContactDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) return false;

      final response = await http.get(
        Uri.parse('$baseUrl/entitlements/contact-details?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return data['data']['canSeeContactDetails'] ?? false;
        }
      }
      return false;
    } catch (e) {
      print('Error checking contact details entitlement: $e');
      return false;
    }
  }

  /// Check if user can send messages
  static Future<bool> canSendMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) return false;

      final response = await http.get(
        Uri.parse('$baseUrl/entitlements/messaging?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return data['data']['canSendMessages'] ?? false;
        }
      }
      return false;
    } catch (e) {
      print('Error checking messaging entitlement: $e');
      return false;
    }
  }

  /// Check if user can respond to requests
  static Future<bool> canRespond() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) return false;

      final response = await http.get(
        Uri.parse('$baseUrl/entitlements/respond?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          return data['data']['canRespond'] ?? false;
        }
      }
      return false;
    } catch (e) {
      print('Error checking response entitlement: $e');
      return false;
    }
  }

  /// Get entitlements summary for UI display
  static Future<EntitlementsSummary> getEntitlementsSummary() async {
    final entitlements = await getUserEntitlements();

    if (entitlements == null) {
      return EntitlementsSummary(
        canSeeContactDetails: false,
        canSendMessages: false,
        canRespond: false,
        responseCount: 0,
        remainingResponses: '0',
        subscriptionType: 'free',
        planName: 'Free Plan',
      );
    }

    return EntitlementsSummary(
      canSeeContactDetails: entitlements['canSeeContactDetails'] ?? false,
      canSendMessages: entitlements['canSendMessages'] ?? false,
      canRespond: entitlements['canRespond'] ?? false,
      responseCount: entitlements['responseCount'] ?? 0,
      remainingResponses: entitlements['remainingResponses']?.toString() ?? '0',
      subscriptionType: entitlements['subscriptionType'] ?? 'free',
      planName: entitlements['planName'] ?? 'Free Plan',
    );
  }
}

class EntitlementsSummary {
  final bool canSeeContactDetails;
  final bool canSendMessages;
  final bool canRespond;
  final int responseCount;
  final String remainingResponses;
  final String subscriptionType;
  final String planName;

  EntitlementsSummary({
    required this.canSeeContactDetails,
    required this.canSendMessages,
    required this.canRespond,
    required this.responseCount,
    required this.remainingResponses,
    required this.subscriptionType,
    required this.planName,
  });

  bool get isSubscribed => subscriptionType != 'free';
  bool get hasUnlimitedResponses => remainingResponses == 'unlimited';

  String get statusText {
    if (isSubscribed) {
      return 'Subscribed: $planName';
    } else {
      return 'Free Plan: $remainingResponses responses remaining';
    }
  }
}
