import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subscription_model.dart';
import 'subscription_service.dart';

class UsageLimiterService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Usage tracking collections
  static const String _rideResponsesCollection = 'ride_responses';
  static const String _businessClicksCollection = 'business_clicks';
  static const String _userSubscriptionsCollection = 'user_subscriptions';

  // ==================== RIDER USAGE LIMITS ====================

  /// Check if rider can respond to a ride request
  static Future<Map<String, dynamic>> canRiderRespond() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return {'canRespond': false, 'reason': 'User not authenticated'};
      }

      final subscription = await SubscriptionService.getUserSubscription(userId);
      if (subscription == null) {
        return {'canRespond': false, 'reason': 'No subscription found'};
      }

      // Check if user has active subscription or trial
      if (subscription.hasActiveAccess) {
        return {'canRespond': true, 'reason': 'Active subscription or trial'};
      }

      // Check promo code benefits
      if (subscription.promoCodeBenefits != null) {
        final benefits = subscription.promoCodeBenefits!;
        
        // Check for unlimited responses benefit
        if (benefits['unlimitedResponses'] == true) {
          final validUntil = DateTime.parse(benefits['appliedAt'])
              .add(Duration(days: (benefits['duration'] ?? 30).toInt()));
          
          if (DateTime.now().isBefore(validUntil)) {
            return {'canRespond': true, 'reason': 'Promo code unlimited responses'};
          }
        }
      }

      // For expired subscriptions, check if they're within the 3 responses limit
      final currentMonth = DateTime.now().month;
      final currentYear = DateTime.now().year;
      
      final responsesThisMonth = await _getRideResponsesCount(
        userId, 
        DateTime(currentYear, currentMonth, 1),
        DateTime(currentYear, currentMonth + 1, 1),
      );

      if (responsesThisMonth < 3) {
        return {
          'canRespond': true, 
          'reason': 'Within free limit',
          'remainingResponses': 3 - responsesThisMonth
        };
      }

      return {
        'canRespond': false, 
        'reason': 'Monthly limit reached',
        'message': 'You have reached your 3 free responses for this month. Subscribe to get unlimited responses!'
      };

    } catch (e) {
      return {'canRespond': false, 'reason': 'Error checking limits: $e'};
    }
  }

  /// Record a ride response for usage tracking
  static Future<bool> recordRideResponse(String rideRequestId, Map<String, dynamic> responseData) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      await _firestore.collection(_rideResponsesCollection).add({
        'userId': userId,
        'rideRequestId': rideRequestId,
        'responseData': responseData,
        'timestamp': FieldValue.serverTimestamp(),
        'month': DateTime.now().month,
        'year': DateTime.now().year,
      });

      // Update usage stats in subscription
      await _updateSubscriptionUsageStats(userId, 'rideResponses', 1);
      
      return true;
    } catch (e) {
      print('Error recording ride response: $e');
      return false;
    }
  }

  // ==================== BUSINESS USAGE LIMITS ====================

  /// Check if business can receive click notifications (and charge accordingly)
  static Future<Map<String, dynamic>> canBusinessReceiveClick(String businessId) async {
    try {
      final subscription = await SubscriptionService.getUserSubscription(businessId);
      if (subscription == null) {
        return {'canReceive': false, 'reason': 'No subscription found'};
      }

      // During trial period, all clicks are free
      if (subscription.isTrialActive) {
        return {
          'canReceive': true, 
          'reason': 'Trial period',
          'cost': 0.0,
          'chargeUser': false
        };
      }

      // Check promo code benefits for free clicks
      if (subscription.promoCodeBenefits != null) {
        final benefits = subscription.promoCodeBenefits!;
        
        if (benefits['freeClicks'] != null) {
          final freeClicks = (benefits['freeClicks'] as int);
          final usedFreeClicks = subscription.usageStats['freeClicksUsed'] ?? 0;
          
          if (usedFreeClicks < freeClicks) {
            return {
              'canReceive': true,
              'reason': 'Promo code free clicks',
              'cost': 0.0,
              'chargeUser': false,
              'remainingFreeClicks': freeClicks - usedFreeClicks
            };
          }
        }
      }

      // For active subscriptions, determine cost per click
      final plan = await SubscriptionService.getSubscriptionPlan(subscription.planId);
      if (plan == null) {
        return {'canReceive': false, 'reason': 'Subscription plan not found'};
      }

      final costPerClick = plan.getPriceForCountry(subscription.countryCode);
      
      return {
        'canReceive': true,
        'reason': 'Pay per click',
        'cost': costPerClick,
        'chargeUser': true,
        'currency': subscription.currency
      };

    } catch (e) {
      return {'canReceive': false, 'reason': 'Error checking limits: $e'};
    }
  }

  /// Record a business click and handle charging
  static Future<Map<String, dynamic>> recordBusinessClick(
    String businessId,
    String clickType,
    Map<String, dynamic> clickData
  ) async {
    try {
      final clickCheckResult = await canBusinessReceiveClick(businessId);
      
      if (!clickCheckResult['canReceive']) {
        return {
          'success': false,
          'message': clickCheckResult['reason']
        };
      }

      // Record the click
      await _firestore.collection(_businessClicksCollection).add({
        'businessId': businessId,
        'clickType': clickType,
        'clickData': clickData,
        'cost': clickCheckResult['cost'] ?? 0.0,
        'charged': clickCheckResult['chargeUser'] ?? false,
        'timestamp': FieldValue.serverTimestamp(),
        'month': DateTime.now().month,
        'year': DateTime.now().year,
      });

      // Update usage stats
      if (clickCheckResult['chargeUser']) {
        await _updateSubscriptionUsageStats(businessId, 'paidClicks', 1);
        await _updateSubscriptionUsageStats(businessId, 'totalSpent', clickCheckResult['cost']);
      } else {
        if (clickCheckResult['reason'] == 'Promo code free clicks') {
          await _updateSubscriptionUsageStats(businessId, 'freeClicksUsed', 1);
        }
        await _updateSubscriptionUsageStats(businessId, 'freeClicks', 1);
      }

      return {
        'success': true,
        'cost': clickCheckResult['cost'],
        'charged': clickCheckResult['chargeUser'],
        'message': clickCheckResult['chargeUser'] 
            ? 'Click charged: ${clickCheckResult['cost']} ${clickCheckResult['currency']}'
            : 'Free click recorded'
      };

    } catch (e) {
      return {
        'success': false,
        'message': 'Error recording click: $e'
      };
    }
  }

  // ==================== NOTIFICATION LIMITS ====================

  /// Check if user should receive notifications based on subscription
  static Future<bool> canReceiveNotifications(String userId) async {
    try {
      final subscription = await SubscriptionService.getUserSubscription(userId);
      if (subscription == null) return false;

      // Active subscription or trial users get notifications
      if (subscription.hasActiveAccess) return true;

      // Check promo code benefits
      if (subscription.promoCodeBenefits != null) {
        final benefits = subscription.promoCodeBenefits!;
        if (benefits['unlimitedResponses'] == true) {
          final validUntil = DateTime.parse(benefits['appliedAt'])
              .add(Duration(days: (benefits['duration'] ?? 30).toInt()));
          return DateTime.now().isBefore(validUntil);
        }
      }

      // Free users don't get notifications
      return false;
    } catch (e) {
      print('Error checking notification limits: $e');
      return false;
    }
  }

  // ==================== HELPER METHODS ====================

  /// Get the count of ride responses for a user in a date range
  static Future<int> _getRideResponsesCount(String userId, DateTime startDate, DateTime endDate) async {
    try {
      final snapshot = await _firestore
          .collection(_rideResponsesCollection)
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThan: Timestamp.fromDate(endDate))
          .get();
      
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting ride responses count: $e');
      return 0;
    }
  }

  /// Update subscription usage statistics
  static Future<void> _updateSubscriptionUsageStats(String userId, String statKey, dynamic incrementValue) async {
    try {
      final subscription = await SubscriptionService.getUserSubscription(userId);
      if (subscription == null) return;

      final currentStats = Map<String, dynamic>.from(subscription.usageStats);
      
      if (incrementValue is num) {
        currentStats[statKey] = (currentStats[statKey] ?? 0) + incrementValue;
      } else {
        currentStats[statKey] = incrementValue;
      }

      await _firestore.collection(_userSubscriptionsCollection).doc(subscription.id).update({
        'usageStats': currentStats,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating usage stats: $e');
    }
  }

  /// Get usage statistics for a user
  static Future<Map<String, dynamic>> getUserUsageStats(String userId) async {
    try {
      final subscription = await SubscriptionService.getUserSubscription(userId);
      if (subscription == null) return {};

      final currentMonth = DateTime.now().month;
      final currentYear = DateTime.now().year;

      // Get current month's ride responses
      final monthlyResponses = await _getRideResponsesCount(
        userId,
        DateTime(currentYear, currentMonth, 1),
        DateTime(currentYear, currentMonth + 1, 1),
      );

      // Get total clicks for business users
      int totalClicks = 0;
      double totalSpent = 0.0;
      
      if (subscription.type == SubscriptionType.business) {
        final clicksSnapshot = await _firestore
            .collection(_businessClicksCollection)
            .where('businessId', isEqualTo: userId)
            .get();
        
        totalClicks = clicksSnapshot.docs.length;
        totalSpent = clicksSnapshot.docs.fold(0.0, (sum, doc) {
          final data = doc.data() as Map<String, dynamic>;
          return sum + ((data['cost'] ?? 0.0) as double);
        });
      }

      return {
        'subscription': subscription,
        'monthlyRideResponses': monthlyResponses,
        'remainingFreeResponses': subscription.hasActiveAccess ? -1 : (3 - monthlyResponses),
        'totalClicks': totalClicks,
        'totalSpent': totalSpent,
        'canReceiveNotifications': await canReceiveNotifications(userId),
      };
    } catch (e) {
      print('Error getting usage stats: $e');
      return {};
    }
  }

  /// Check if a specific feature is available to the user
  static Future<bool> isFeatureAvailable(String userId, String featureName) async {
    try {
      final subscription = await SubscriptionService.getUserSubscription(userId);
      if (subscription == null) return false;

      // During trial or active subscription, all features are available
      if (subscription.hasActiveAccess) return true;

      // Check promo code benefits
      if (subscription.promoCodeBenefits != null) {
        final benefits = subscription.promoCodeBenefits!;
        
        switch (featureName) {
          case 'unlimited_responses':
            if (benefits['unlimitedResponses'] == true) {
              final validUntil = DateTime.parse(benefits['appliedAt'])
                  .add(Duration(days: (benefits['duration'] ?? 30).toInt()));
              return DateTime.now().isBefore(validUntil);
            }
            break;
          case 'notifications':
            return await canReceiveNotifications(userId);
          case 'business_analytics':
            return subscription.type == SubscriptionType.business;
        }
      }

      // Define what features are available for free users
      switch (featureName) {
        case 'basic_ride_responses':
          return true; // Limited to 3 per month
        case 'basic_business_listing':
          return subscription.type == SubscriptionType.business;
        default:
          return false;
      }
    } catch (e) {
      print('Error checking feature availability: $e');
      return false;
    }
  }
}
