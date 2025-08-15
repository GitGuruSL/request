import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/subscription_model.dart';
import '../models/promo_code_model.dart';
import 'promo_code_service.dart';
import 'country_service.dart';

class SubscriptionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  static const String _subscriptionPlansCollection = 'subscription_plans';
  static const String _userSubscriptionsCollection = 'user_subscriptions';
  static const String _paymentTransactionsCollection = 'payment_transactions';
  static const String _clickTrackingCollection = 'click_tracking';

  // ==================== SUBSCRIPTION PLANS ====================

  /// Get all available subscription plans by country
  static Future<List<SubscriptionPlan>> getAvailablePlans(String countryCode) async {
    try {
      final snapshot = await _firestore
          .collection(_subscriptionPlansCollection)
          .where('isActive', isEqualTo: true)
          .get();
      
      final allPlans = snapshot.docs
          .map((doc) => SubscriptionPlan.fromFirestore(doc.data(), doc.id))
          .toList();
      
      // Filter plans that have pricing for this country
      return allPlans.where((plan) => 
        plan.pricingByCountry.containsKey(countryCode)
      ).toList();
    } catch (e) {
      print('Error getting available plans: $e');
      return [];
    }
  }

  /// Get all subscription plans (optionally filtered by country)
  static Future<List<SubscriptionPlan>> getSubscriptionPlans(
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_subscriptionPlansCollection)
          .where('type', isEqualTo: type.toString().split('.').last)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt')
          .get();

      return snapshot.docs.map((doc) => SubscriptionPlan.fromFirestore(doc)).toList();
    } catch (e) {
      print('Error fetching subscription plans: $e');
      return [];
    }
  }

  /// Get a specific subscription plan
  static Future<SubscriptionPlan?> getSubscriptionPlan(String planId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection(_subscriptionPlansCollection)
          .doc(planId)
          .get();

      if (doc.exists) {
        return SubscriptionPlan.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error fetching subscription plan: $e');
      return null;
    }
  }

  // ==================== USER SUBSCRIPTIONS ====================

  /// Get user's current subscription
  static Future<UserSubscription?> getUserSubscription(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_userSubscriptionsCollection)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return UserSubscription.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      print('Error fetching user subscription: $e');
      return null;
    }
  }

  // Create user subscription with optional promo code
  static Future<UserSubscription> createUserSubscription(
    String userId,
    String planId,
    SubscriptionType type,
    String countryCode, {
    PromoCodeModel? appliedPromoCode,
  }) async {
    try {
      final now = DateTime.now();
      final trialEndDate = now.add(const Duration(days: 90)); // 3 months trial

      Map<String, dynamic>? promoCodeBenefits;
      bool isTrialExtended = false;
      DateTime? trialExtendedUntil;

      // Apply promo code benefits if provided
      if (appliedPromoCode != null) {
        final promoResult = await PromoCodeService.applyPromoCodeToSubscription(
          appliedPromoCode,
          type.toString().split('.').last,
          countryCode,
        );

        if (promoResult['success']) {
          promoCodeBenefits = promoResult['benefits'];
          
          // Handle trial extension
          if (appliedPromoCode.type == PromoCodeType.freeTrialExtension) {
            isTrialExtended = true;
            trialExtendedUntil = trialEndDate.add(
              Duration(days: (promoCodeBenefits?['extraTrialDays'] ?? 0).toInt()),
            );
          }
        }
      }

      final subscription = UserSubscription(
        id: '',
        userId: userId,
        planId: planId,
        type: type,
        status: SubscriptionStatus.trial,
        trialStartDate: now,
        trialEndDate: isTrialExtended ? trialExtendedUntil! : trialEndDate,
        countryCode: countryCode,
        currency: _getCurrencyForCountry(countryCode),
        usageStats: _getInitialUsageStats(type),
        limitations: _getTrialLimitations(type),
        promoCodeApplied: appliedPromoCode?.code,
        promoCodeBenefits: promoCodeBenefits,
        isTrialExtended: isTrialExtended,
        trialExtendedUntil: trialExtendedUntil,
        createdAt: now,
        updatedAt: now,
      );

      final docRef = await _firestore.collection(_userSubscriptionsCollection).add(subscription.toFirestore());
      
      return subscription.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Failed to create subscription: $e');
    }
  }

  /// Upgrade subscription to paid plan
  static Future<void> upgradeSubscription(
    String userId,
    String planId,
    String paymentMethod,
  ) async {
    try {
      final userSubscription = await getUserSubscription(userId);
      if (userSubscription == null) {
        throw Exception('User subscription not found');
      }

      final plan = await getSubscriptionPlan(planId);
      if (plan == null) {
        throw Exception('Subscription plan not found');
      }

      final now = DateTime.now();
      final price = plan.getPriceForCountry(userSubscription.countryCode);

      // Calculate subscription period based on payment model
      DateTime? subscriptionEndDate;
      DateTime? nextPaymentDate;
      
      if (plan.paymentModel == PaymentModel.monthly) {
        subscriptionEndDate = now.add(const Duration(days: 30));
        nextPaymentDate = subscriptionEndDate;
      } else if (plan.paymentModel == PaymentModel.yearly) {
        subscriptionEndDate = now.add(const Duration(days: 365));
        nextPaymentDate = subscriptionEndDate;
      }
      // Pay-per-click doesn't have end date

      // Create payment transaction
      await _createPaymentTransaction(
        userId: userId,
        subscriptionId: userSubscription.id,
        amount: price,
        currency: userSubscription.currency,
        countryCode: userSubscription.countryCode,
        paymentMethod: paymentMethod,
        transactionType: 'subscription_upgrade',
      );

      // Update subscription
      final updatedLimitations = <String, dynamic>{};
      if (plan.type == SubscriptionType.rider) {
        updatedLimitations['maxRidesPerMonth'] = -1; // Unlimited
        updatedLimitations['notificationsEnabled'] = true;
      } else {
        updatedLimitations['payPerClick'] = plan.paymentModel == PaymentModel.payPerClick;
        updatedLimitations['clickRate'] = price;
      }

      await _firestore.collection(_userSubscriptionsCollection).doc(userSubscription.id).update({
        'planId': planId,
        'status': SubscriptionStatus.active.toString().split('.').last,
        'subscriptionStartDate': Timestamp.fromDate(now),
        'subscriptionEndDate': subscriptionEndDate != null ? Timestamp.fromDate(subscriptionEndDate) : null,
        'lastPaymentDate': Timestamp.fromDate(now),
        'nextPaymentDate': nextPaymentDate != null ? Timestamp.fromDate(nextPaymentDate) : null,
        'paidAmount': price,
        'limitations': updatedLimitations,
        'updatedAt': Timestamp.fromDate(now),
      });
    } catch (e) {
      print('Error upgrading subscription: $e');
      rethrow;
    }
  }

  /// Check if user can perform action based on subscription
  static Future<bool> canPerformAction(String userId, String action) async {
    try {
      final subscription = await getUserSubscription(userId);
      if (subscription == null) return false;

      // If trial or active subscription, allow most actions
      if (subscription.hasActiveAccess) {
        return true;
      }

      // Check specific limitations for expired/free users
      switch (action) {
        case 'respond_to_ride':
          if (subscription.type == SubscriptionType.rider) {
            final ridesThisMonth = subscription.usageStats['ridesResponded'] ?? 0;
            return ridesThisMonth < 3; // Free limit: 3 rides per month
          }
          return true;

        case 'receive_notifications':
          if (subscription.type == SubscriptionType.rider) {
            return subscription.hasActiveAccess; // No notifications for free users
          }
          return true;

        case 'business_click':
          if (subscription.type == SubscriptionType.business) {
            // Always allowed, but will be charged if not in trial/active
            return true;
          }
          return true;

        default:
          return subscription.hasActiveAccess;
      }
    } catch (e) {
      print('Error checking action permission: $e');
      return false;
    }
  }

  /// Record business click and handle billing
  static Future<void> recordBusinessClick(
    String businessUserId,
    Map<String, dynamic> clickMetadata,
  ) async {
    try {
      final subscription = await getUserSubscription(businessUserId);
      if (subscription == null) return;

      final now = DateTime.now();

      // Record click in tracking collection
      await _firestore.collection(_clickTrackingCollection).add({
        'userId': businessUserId,
        'subscriptionId': subscription.id,
        'metadata': clickMetadata,
        'timestamp': Timestamp.fromDate(now),
        'charged': false,
        'amount': 0.0,
      });

      // Update usage stats
      final currentClicks = subscription.usageStats['clicksReceived'] ?? 0;
      await _firestore.collection(_userSubscriptionsCollection).doc(subscription.id).update({
        'usageStats.clicksReceived': currentClicks + 1,
        'updatedAt': Timestamp.fromDate(now),
      });

      // If not in trial or active subscription, charge for click
      if (!subscription.hasActiveAccess && subscription.limitations['payPerClick'] == true) {
        final clickRate = subscription.limitations['clickRate'] ?? 100.0;
        await _chargeForClick(subscription, clickRate, clickMetadata);
      }
    } catch (e) {
      print('Error recording business click: $e');
    }
  }

  /// Record rider action (responding to ride)
  static Future<void> recordRiderAction(String userId, String action) async {
    try {
      final subscription = await getUserSubscription(userId);
      if (subscription == null) return;

      if (action == 'respond_to_ride') {
        final currentRides = subscription.usageStats['ridesResponded'] ?? 0;
        await _firestore.collection(_userSubscriptionsCollection).doc(subscription.id).update({
          'usageStats.ridesResponded': currentRides + 1,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    } catch (e) {
      print('Error recording rider action: $e');
    }
  }

  /// Get subscription status and limitations for UI display
  static Future<Map<String, dynamic>> getSubscriptionStatus(String userId) async {
    try {
      final subscription = await getUserSubscription(userId);
      if (subscription == null) {
        return {
          'hasSubscription': false,
          'needsTrial': true,
        };
      }

      return {
        'hasSubscription': true,
        'status': subscription.status.toString().split('.').last,
        'type': subscription.type.toString().split('.').last,
        'hasActiveAccess': subscription.hasActiveAccess,
        'isTrialActive': subscription.isTrialActive,
        'isSubscriptionActive': subscription.isSubscriptionActive,
        'remainingTrialDays': subscription.remainingTrialDays,
        'remainingSubscriptionDays': subscription.remainingSubscriptionDays,
        'usageStats': subscription.usageStats,
        'limitations': subscription.limitations,
        'currency': subscription.currency,
        'countryCode': subscription.countryCode,
        'trialEndDate': subscription.trialEndDate.toIso8601String(),
        'subscriptionEndDate': subscription.subscriptionEndDate?.toIso8601String(),
      };
    } catch (e) {
      print('Error getting subscription status: $e');
      return {
        'hasSubscription': false,
        'error': e.toString(),
      };
    }
  }

  // ==================== PRIVATE METHODS ====================

  static Future<void> _createPaymentTransaction({
    required String userId,
    required String subscriptionId,
    required double amount,
    required String currency,
    required String countryCode,
    required String paymentMethod,
    required String transactionType,
    Map<String, dynamic> metadata = const {},
  }) async {
    final docRef = _firestore.collection(_paymentTransactionsCollection).doc();
    
    final transaction = PaymentTransaction(
      id: docRef.id,
      userId: userId,
      subscriptionId: subscriptionId,
      amount: amount,
      currency: currency,
      countryCode: countryCode,
      paymentMethod: paymentMethod,
      transactionType: transactionType,
      metadata: metadata,
      status: 'completed', // In real app, this would be 'pending' until payment gateway confirms
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await docRef.set(transaction.toFirestore());
  }

  static Future<void> _chargeForClick(
    UserSubscription subscription,
    double clickRate,
    Map<String, dynamic> clickMetadata,
  ) async {
    try {
      // Create payment transaction for click
      await _createPaymentTransaction(
        userId: subscription.userId,
        subscriptionId: subscription.id,
        amount: clickRate,
        currency: subscription.currency,
        countryCode: subscription.countryCode,
        paymentMethod: 'auto_charge', // This would integrate with payment gateway
        transactionType: 'click_charge',
        metadata: clickMetadata,
      );

      // Update total spent
      final currentSpent = subscription.usageStats['totalSpent'] ?? 0.0;
      await _firestore.collection(_userSubscriptionsCollection).doc(subscription.id).update({
        'usageStats.totalSpent': currentSpent + clickRate,
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      print('Error charging for click: $e');
    }
  }

  // ==================== ADMIN FUNCTIONS ====================

  /// Initialize default subscription plans (run once during setup)
  static Future<void> initializeDefaultPlans() async {
    try {
      // Country-specific pricing (base prices in local currency)
      final Map<String, Map<String, dynamic>> countryData = {
        'LK': {'price_monthly': 500.0, 'price_yearly': 5000.0, 'click_rate': 100.0, 'currency': 'Rs'},
        'IN': {'price_monthly': 200.0, 'price_yearly': 2000.0, 'click_rate': 50.0, 'currency': '₹'},
        'US': {'price_monthly': 9.99, 'price_yearly': 99.99, 'click_rate': 2.0, 'currency': '$'},
        'GB': {'price_monthly': 7.99, 'price_yearly': 79.99, 'click_rate': 1.5, 'currency': '£'},
        'AU': {'price_monthly': 12.99, 'price_yearly': 129.99, 'click_rate': 2.5, 'currency': 'A$'},
      };

      // Rider Monthly Plan
      final riderMonthlyPrices = <String, double>{};
      final riderYearlyPrices = <String, double>{};
      final businessClickRates = <String, double>{};
      final currencySymbols = <String, String>{};

      for (final entry in countryData.entries) {
        final countryCode = entry.key;
        final data = entry.value;
        riderMonthlyPrices[countryCode] = data['price_monthly'];
        riderYearlyPrices[countryCode] = data['price_yearly'];
        businessClickRates[countryCode] = data['click_rate'];
        currencySymbols[countryCode] = data['currency'];
      }

      final plans = [
        // Rider Monthly Plan
        SubscriptionPlan(
          id: 'rider_monthly',
          name: 'Rider Monthly',
          description: 'Full access to ride notifications and unlimited responses',
          type: SubscriptionType.rider,
          paymentModel: PaymentModel.monthly,
          countryPrices: riderMonthlyPrices,
          currencySymbols: currencySymbols,
          features: [
            'Unlimited ride responses',
            'Real-time ride notifications',
            'Priority matching',
            'Advanced filters',
          ],
          limitations: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),

        // Rider Yearly Plan (with discount)
        SubscriptionPlan(
          id: 'rider_yearly',
          name: 'Rider Yearly',
          description: 'Best value - Full access for entire year with 2 months free',
          type: SubscriptionType.rider,
          paymentModel: PaymentModel.yearly,
          countryPrices: riderYearlyPrices,
          currencySymbols: currencySymbols,
          features: [
            'Unlimited ride responses',
            'Real-time ride notifications',
            'Priority matching',
            'Advanced filters',
            '2 months FREE',
          ],
          limitations: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),

        // Business Pay-Per-Click Plan
        SubscriptionPlan(
          id: 'business_pay_per_click',
          name: 'Business Pay-Per-Click',
          description: 'Pay only when customers click on your products',
          type: SubscriptionType.business,
          paymentModel: PaymentModel.payPerClick,
          countryPrices: businessClickRates,
          currencySymbols: currencySymbols,
          features: [
            'Product listing visibility',
            'Customer inquiries',
            'Business profile',
            'Analytics dashboard',
            'Pay only for results',
          ],
          limitations: {},
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Save plans to Firestore
      for (final plan in plans) {
        await _firestore.collection(_subscriptionPlansCollection).doc(plan.id).set(plan.toFirestore());
      }

      print('✅ Default subscription plans initialized successfully');
    } catch (e) {
      print('Error initializing default plans: $e');
      rethrow;
    }
  }

  /// Get currency for country
  static String _getCurrencyForCountry(String countryCode) {
    const currencies = {
      'US': 'USD',
      'GB': 'GBP', 
      'IN': 'INR',
      'LK': 'LKR',
      'AU': 'AUD',
      'CA': 'CAD',
      'SG': 'SGD',
      'MY': 'MYR',
      'TH': 'THB',
      'PH': 'PHP',
      'ID': 'IDR',
      'VN': 'VND',
    };
    return currencies[countryCode] ?? 'USD';
  }

  /// Get initial usage stats for subscription type
  static Map<String, int> _getInitialUsageStats(SubscriptionType type) {
    return {
      'requestsCreated': 0,
      'responsesReceived': 0,
      'messagesExchanged': 0,
      'promoCodesUsed': 0,
    };
  }

  /// Get trial limitations for subscription type
  static Map<String, int> _getTrialLimitations(SubscriptionType type) {
    switch (type) {
      case SubscriptionType.rider:
        return {
          'maxRequestsPerDay': 5,
          'maxResponsesPerRequest': 10,
          'maxMessagesPerDay': 50,
        };
      case SubscriptionType.business:
        return {
          'maxRequestsPerDay': 20,
          'maxResponsesPerRequest': 50,
          'maxMessagesPerDay': 200,
          'maxBusinessListings': 10,
        };
    }
  }
}
