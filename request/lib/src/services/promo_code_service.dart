import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/promo_code_model.dart';
import '../models/subscription_model.dart';

class PromoCodeService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _promoCodesCollection = 'promoCodes';
  static const String _promoCodeUsageCollection = 'promoCodeUsage';
  static const String _subscriptionsCollection = 'subscriptions';

  // Validate and apply promo code
  static Future<Map<String, dynamic>> validateAndApplyPromoCode(
    String code,
    String userType,
    String countryCode,
  ) async {
    try {
      // Find promo code
      final promoQuery = await _firestore
          .collection(_promoCodesCollection)
          .where('code', isEqualTo: code.toUpperCase())
          .limit(1)
          .get();

      if (promoQuery.docs.isEmpty) {
        return {
          'success': false,
          'message': 'Invalid promo code',
        };
      }

      final promoDoc = promoQuery.docs.first;
      final promoCode = PromoCodeModel.fromFirestore(promoDoc);

      // Validate promo code
      final validationResult = await _validatePromoCode(promoCode, userType, countryCode);
      if (!validationResult['isValid']) {
        return {
          'success': false,
          'message': validationResult['message'],
        };
      }

      // Check if user already used this promo code
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final usageQuery = await _firestore
            .collection(_promoCodeUsageCollection)
            .where('promoCodeId', isEqualTo: promoCode.id)
            .where('userId', isEqualTo: userId)
            .get();

        if (usageQuery.docs.isNotEmpty) {
          return {
            'success': false,
            'message': 'You have already used this promo code',
          };
        }
      }

      return {
        'success': true,
        'promoCode': promoCode,
        'benefits': _calculateBenefits(promoCode, userType, countryCode),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error validating promo code: $e',
      };
    }
  }

  // Apply promo code to user subscription
  static Future<Map<String, dynamic>> applyPromoCodeToSubscription(
    PromoCodeModel promoCode,
    String userType,
    String countryCode,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return {
          'success': false,
          'message': 'User not authenticated',
        };
      }

      // Calculate benefits
      final benefits = _calculateBenefits(promoCode, userType, countryCode);

      // Update subscription with benefits
      await _firestore.collection(_subscriptionsCollection).doc(userId).update({
        'promoCodeApplied': promoCode.code,
        'promoCodeBenefits': benefits,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Record promo code usage
      await _firestore.collection(_promoCodeUsageCollection).add(
        PromoCodeUsage(
          id: '',
          promoCodeId: promoCode.id,
          userId: userId,
          userType: userType,
          countryCode: countryCode,
          usedAt: DateTime.now(),
          discountApplied: benefits['discountAmount'] ?? 0.0,
          benefits: benefits,
        ).toFirestore(),
      );

      // Update promo code usage count
      await _firestore.collection(_promoCodesCollection).doc(promoCode.id).update({
        'currentUses': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return {
        'success': true,
        'benefits': benefits,
        'message': 'Promo code applied successfully!',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error applying promo code: $e',
      };
    }
  }

  // Get active promo codes for user type and country
  static Future<List<PromoCodeModel>> getActivePromoCodes(
    String userType,
    String countryCode,
  ) async {
    try {
      final now = Timestamp.now();
      
      final query = await _firestore
          .collection(_promoCodesCollection)
          .where('status', isEqualTo: 'active')
          .where('validFrom', isLessThanOrEqualTo: now)
          .where('validTo', isGreaterThan: now)
          .get();

      final promoCodes = query.docs
          .map((doc) => PromoCodeModel.fromFirestore(doc))
          .where((promo) => promo.isApplicableForUser(userType, countryCode))
          .where((promo) => promo.currentUses < promo.maxUses)
          .toList();

      return promoCodes;
    } catch (e) {
      print('Error fetching promo codes: $e');
      return [];
    }
  }

  // Private helper methods
  static Future<Map<String, dynamic>> _validatePromoCode(
    PromoCodeModel promoCode,
    String userType,
    String countryCode,
  ) async {
    if (!promoCode.isValid) {
      return {
        'isValid': false,
        'message': 'Promo code has expired or is not active',
      };
    }

    if (!promoCode.isApplicableForUser(userType, countryCode)) {
      return {
        'isValid': false,
        'message': 'This promo code is not applicable for your account type or location',
      };
    }

    return {
      'isValid': true,
      'message': 'Valid promo code',
    };
  }

  static Map<String, dynamic> _calculateBenefits(
    PromoCodeModel promoCode,
    String userType,
    String countryCode,
  ) {
    final benefits = <String, dynamic>{};

    switch (promoCode.type) {
      case PromoCodeType.percentageDiscount:
        benefits['discountPercentage'] = promoCode.value;
        benefits['discountAmount'] = 0.0; // Will be calculated at payment time
        break;

      case PromoCodeType.fixedDiscount:
        benefits['discountAmount'] = promoCode.value;
        benefits['discountPercentage'] = 0.0;
        break;

      case PromoCodeType.freeTrialExtension:
        benefits['extraTrialDays'] = promoCode.value.toInt();
        break;

      case PromoCodeType.unlimitedResponses:
        benefits['unlimitedResponses'] = true;
        benefits['duration'] = promoCode.value.toInt(); // days
        break;

      case PromoCodeType.businessFreeClicks:
        benefits['freeClicks'] = promoCode.value.toInt();
        benefits['validForDays'] = promoCode.conditions['validForDays'] ?? 30;
        break;
    }

    benefits['type'] = promoCode.type.toString().split('.').last;
    benefits['appliedAt'] = DateTime.now().toIso8601String();
    benefits['countryCode'] = countryCode;
    benefits['userType'] = userType;

    return benefits;
  }

  // Admin methods for managing promo codes
  static Future<String> createPromoCodeForApproval(
    PromoCodeModel promoCode,
    String creatingAdminId,
    String adminCountryCode,
  ) async {
    try {
      // Set promo code to pending approval status
      final promoCodeToCreate = PromoCodeModel(
        id: '',
        code: promoCode.code,
        title: promoCode.title,
        description: promoCode.description,
        type: promoCode.type,
        status: PromoCodeStatus.pendingApproval,
        value: promoCode.value,
        validFrom: promoCode.validFrom,
        validTo: promoCode.validTo,
        maxUses: promoCode.maxUses,
        currentUses: 0,
        applicableUserTypes: promoCode.applicableUserTypes,
        applicableCountries: promoCode.applicableCountries,
        conditions: promoCode.conditions,
        createdBy: creatingAdminId,
        approvedBy: null,
        approvedAt: null,
        rejectionReason: null,
        createdByCountry: adminCountryCode,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final docRef = await _firestore.collection(_promoCodesCollection)
          .add(promoCodeToCreate.toFirestore());

      // Send notification to super admins for approval
      await _notifySuperAdminsForApproval(docRef.id, promoCode.code, adminCountryCode);

      return docRef.id;
    } catch (e) {
      throw Exception('Error creating promo code for approval: $e');
    }
  }

  // Super admin approval methods
  static Future<bool> approvePromoCode(
    String promoCodeId,
    String superAdminId, {
    String? modifiedTitle,
    String? modifiedDescription,
    double? modifiedValue,
    int? modifiedMaxUses,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': PromoCodeStatus.active.toString().split('.').last,
        'approvedBy': superAdminId,
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Apply any modifications requested by super admin
      if (modifiedTitle != null) updateData['title'] = modifiedTitle;
      if (modifiedDescription != null) updateData['description'] = modifiedDescription;
      if (modifiedValue != null) updateData['value'] = modifiedValue;
      if (modifiedMaxUses != null) updateData['maxUses'] = modifiedMaxUses;

      await _firestore.collection(_promoCodesCollection)
          .doc(promoCodeId)
          .update(updateData);

      // Notify the creating admin about approval
      await _notifyAdminAboutApproval(promoCodeId, true);

      return true;
    } catch (e) {
      print('Error approving promo code: $e');
      return false;
    }
  }

  static Future<bool> rejectPromoCode(
    String promoCodeId,
    String superAdminId,
    String rejectionReason,
  ) async {
    try {
      await _firestore.collection(_promoCodesCollection)
          .doc(promoCodeId)
          .update({
        'status': PromoCodeStatus.rejected.toString().split('.').last,
        'rejectionReason': rejectionReason,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Notify the creating admin about rejection
      await _notifyAdminAboutApproval(promoCodeId, false, rejectionReason);

      return true;
    } catch (e) {
      print('Error rejecting promo code: $e');
      return false;
    }
  }

  // Get promo codes pending approval for super admins
  static Future<List<PromoCodeModel>> getPendingPromoCodesForApproval() async {
    try {
      final query = await _firestore
          .collection(_promoCodesCollection)
          .where('status', isEqualTo: 'pendingApproval')
          .orderBy('createdAt', descending: true)
          .get();

      return query.docs
          .map((doc) => PromoCodeModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching pending promo codes: $e');
      return [];
    }
  }

  // Get promo codes created by a specific country admin
  static Future<List<PromoCodeModel>> getPromoCodesByCountryAdmin(
    String adminId,
    String? countryCode,
  ) async {
    try {
      var query = _firestore
          .collection(_promoCodesCollection)
          .where('createdBy', isEqualTo: adminId);

      if (countryCode != null) {
        query = query.where('createdByCountry', isEqualTo: countryCode);
      }

      final snapshot = await query
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PromoCodeModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching admin promo codes: $e');
      return [];
    }
  }

  // Helper method to check admin permissions
  static Future<bool> canAdminCreatePromoCode(
    String adminId,
    String countryCode,
  ) async {
    try {
      // Check if user is a country admin for the specified country
      final adminDoc = await _firestore
          .collection('admin_users')
          .doc(adminId)
          .get();

      if (!adminDoc.exists) return false;

      final adminData = adminDoc.data() as Map<String, dynamic>;
      final adminRole = adminData['role'] ?? '';
      final adminCountries = List<String>.from(adminData['countries'] ?? []);

      return (adminRole == 'country_admin' || adminRole == 'super_admin') &&
             adminCountries.contains(countryCode);
    } catch (e) {
      print('Error checking admin permissions: $e');
      return false;
    }
  }

  // Notification helper methods
  static Future<void> _notifySuperAdminsForApproval(
    String promoCodeId,
    String promoCodeText,
    String countryCode,
  ) async {
    try {
      // Get all super admins
      final superAdminsQuery = await _firestore
          .collection('admin_users')
          .where('role', isEqualTo: 'super_admin')
          .get();

      // Create notification for each super admin
      for (final adminDoc in superAdminsQuery.docs) {
        await _firestore.collection('admin_notifications').add({
          'recipientId': adminDoc.id,
          'type': 'promo_code_approval_request',
          'title': 'Promo Code Approval Required',
          'message': 'Country admin from $countryCode has created promo code "$promoCodeText" for approval.',
          'promoCodeId': promoCodeId,
          'countryCode': countryCode,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error notifying super admins: $e');
    }
  }

  static Future<void> _notifyAdminAboutApproval(
    String promoCodeId,
    bool isApproved, [
    String? rejectionReason,
  ]) async {
    try {
      // Get the promo code to find the creating admin
      final promoCodeDoc = await _firestore
          .collection(_promoCodesCollection)
          .doc(promoCodeId)
          .get();

      if (!promoCodeDoc.exists) return;

      final promoCodeData = promoCodeDoc.data() as Map<String, dynamic>;
      final creatingAdminId = promoCodeData['createdBy'];
      final promoCodeText = promoCodeData['code'];

      // Create notification for the creating admin
      await _firestore.collection('admin_notifications').add({
        'recipientId': creatingAdminId,
        'type': isApproved ? 'promo_code_approved' : 'promo_code_rejected',
        'title': isApproved ? 'Promo Code Approved' : 'Promo Code Rejected',
        'message': isApproved
            ? 'Your promo code "$promoCodeText" has been approved and is now active.'
            : 'Your promo code "$promoCodeText" has been rejected. Reason: ${rejectionReason ?? 'No reason provided'}',
        'promoCodeId': promoCodeId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error notifying admin about approval: $e');
    }
  }

  static Future<bool> createPromoCode(PromoCodeModel promoCode) async {
    try {
      await _firestore.collection(_promoCodesCollection).add(promoCode.toFirestore());
      return true;
    } catch (e) {
      print('Error creating promo code: $e');
      return false;
    }
  }

  static Future<bool> updatePromoCodeStatus(String promoCodeId, PromoCodeStatus status) async {
    try {
      await _firestore.collection(_promoCodesCollection).doc(promoCodeId).update({
        'status': status.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      print('Error updating promo code status: $e');
      return false;
    }
  }

  // Get promo code usage statistics
  static Future<Map<String, dynamic>> getPromoCodeStats(String promoCodeId) async {
    try {
      final usageQuery = await _firestore
          .collection(_promoCodeUsageCollection)
          .where('promoCodeId', isEqualTo: promoCodeId)
          .get();

      final totalUses = usageQuery.docs.length;
      final userTypes = <String, int>{};
      final countries = <String, int>{};
      double totalDiscount = 0.0;

      for (final doc in usageQuery.docs) {
        final usage = PromoCodeUsage.fromFirestore(doc);
        userTypes[usage.userType] = (userTypes[usage.userType] ?? 0) + 1;
        countries[usage.countryCode] = (countries[usage.countryCode] ?? 0) + 1;
        totalDiscount += usage.discountApplied;
      }

      return {
        'totalUses': totalUses,
        'userTypeBreakdown': userTypes,
        'countryBreakdown': countries,
        'totalDiscountGiven': totalDiscount,
      };
    } catch (e) {
      print('Error fetching promo code stats: $e');
      return {};
    }
  }
}
