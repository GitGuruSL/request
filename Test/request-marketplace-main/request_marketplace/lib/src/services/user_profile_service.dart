import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/enhanced_user_model.dart';
import '../models/user_model.dart';

class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user's enhanced profile
  Future<EnhancedUserModel?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return EnhancedUserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Get enhanced user profile by ID
  Future<EnhancedUserModel?> getEnhancedUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return EnhancedUserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Create or update enhanced user profile
  Future<void> createOrUpdateUserProfile(EnhancedUserModel userProfile) async {
    try {
      await _firestore
          .collection('users')
          .doc(userProfile.id)
          .set(userProfile.toMap(), SetOptions(merge: true));
    } catch (e) {
      print('Error creating/updating user profile: $e');
      throw Exception('Failed to save user profile: $e');
    }
  }

  // Update user roles
  Future<void> updateUserRoles(String userId, List<UserType> roles, UserType primaryType) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'roles': roles.map((role) => role.name).toList(),
        'primaryType': primaryType.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user roles: $e');
      throw Exception('Failed to update user roles: $e');
    }
  }

  // Add business profile to user
  Future<void> addBusinessProfile(String userId, BusinessProfile businessProfile) async {
    print('📝 UserProfileService: Adding business profile for user $userId');
    
    try {
      // First, check if user document exists
      print('🔍 Checking if user document exists...');
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        print('❌ User document does not exist. Creating user document first...');
        // Create the user document if it doesn't exist
        await _firestore.collection('users').doc(userId).set({
          'userId': userId,
          'createdAt': FieldValue.serverTimestamp(),
          'roles': [UserType.business.name],
          'businessProfile': businessProfile.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ User document created with business profile');
      } else {
        print('✅ User document exists. Updating with business profile...');
        // Update existing user document
        await _firestore.collection('users').doc(userId).update({
          'businessProfile': businessProfile.toMap(),
          'roles': FieldValue.arrayUnion([UserType.business.name]),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ User document updated with business profile');
      }
      
      print('🎉 Business profile added successfully!');
    } catch (e, stackTrace) {
      print('❌ Error adding business profile: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to add business profile: $e');
    }
  }

  // Add service provider profile to user
  Future<void> addServiceProviderProfile(String userId, ServiceProviderProfile serviceProfile) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'serviceProviderProfile': serviceProfile.toMap(),
        'roles': FieldValue.arrayUnion([UserType.serviceProvider.name]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding service provider profile: $e');
      throw Exception('Failed to add service provider profile: $e');
    }
  }

  // Add driver profile to user
  Future<void> addDriverProfile(String userId, DriverProfile driverProfile) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'driverProfile': driverProfile.toMap(),
        'roles': FieldValue.arrayUnion([UserType.driver.name]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding driver profile: $e');
      throw Exception('Failed to add driver profile: $e');
    }
  }

  // Migrate existing user from old model to enhanced model
  Future<EnhancedUserModel> migrateUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) {
        throw Exception('User not found');
      }

      // Try to parse as enhanced user first
      try {
        return EnhancedUserModel.fromFirestore(doc);
      } catch (e) {
        // If parsing fails, it's likely an old user model, so migrate
        print('Migrating old user model to enhanced model...');
        
        final oldUser = UserModel.fromFirestore(doc);
        final enhancedUser = EnhancedUserModel.fromLegacyUser(oldUser);
        
        // Save the enhanced model
        await createOrUpdateUserProfile(enhancedUser);
        
        return enhancedUser;
      }
    } catch (e) {
      print('Error migrating user profile: $e');
      throw Exception('Failed to migrate user profile: $e');
    }
  }

  // Get users by role (for admin/business purposes)
  Future<List<EnhancedUserModel>> getUsersByRole(UserType role) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('roles', arrayContains: role.name)
          .get();

      return querySnapshot.docs
          .map((doc) => EnhancedUserModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error getting users by role: $e');
      throw Exception('Failed to get users by role: $e');
    }
  }

  // Get nearby service providers
  Future<List<EnhancedUserModel>> getNearbyServiceProviders({
    required double latitude,
    required double longitude,
    required double radiusKm,
    String? category,
  }) async {
    try {
      // Note: This is a simplified implementation
      // In production, you'd want to use GeoFirestore or similar for efficient geo-queries
      
      Query query = _firestore
          .collection('users')
          .where('roles', arrayContains: UserType.serviceProvider.name)
          .where('serviceProviderProfile.isAvailable', isEqualTo: true);

      if (category != null) {
        query = query.where('serviceProviderProfile.skills', arrayContains: category);
      }

      final querySnapshot = await query.get();
      
      List<EnhancedUserModel> providers = querySnapshot.docs
          .map((doc) => EnhancedUserModel.fromFirestore(doc))
          .where((user) => user.serviceProviderProfile != null)
          .toList();

      // Filter by distance (simplified - in production use proper geo-distance calculation)
      providers = providers.where((provider) {
        if (provider.serviceProviderProfile!.serviceAreas.isEmpty) return false;
        // For now, just return all - implement proper geo-distance filtering later
        return true;
      }).toList();

      // Sort by rating
      providers.sort((a, b) => 
          b.serviceProviderProfile!.averageRating.compareTo(a.serviceProviderProfile!.averageRating));

      return providers;
    } catch (e) {
      print('Error getting nearby service providers: $e');
      throw Exception('Failed to get nearby service providers: $e');
    }
  }

  // Get available drivers
  Future<List<EnhancedUserModel>> getAvailableDrivers({
    required double latitude,
    required double longitude,
    required double radiusKm,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('roles', arrayContains: UserType.driver.name)
          .where('driverProfile.isOnline', isEqualTo: true)
          .where('driverProfile.verificationStatus', isEqualTo: VerificationStatus.verified.name)
          .get();

      List<EnhancedUserModel> drivers = querySnapshot.docs
          .map((doc) => EnhancedUserModel.fromFirestore(doc))
          .where((user) => user.driverProfile != null)
          .toList();

      // Filter by distance and sort by proximity
      // Simplified implementation - use proper geo-distance in production
      drivers.sort((a, b) => 
          b.driverProfile!.averageRating.compareTo(a.driverProfile!.averageRating));

      return drivers;
    } catch (e) {
      print('Error getting available drivers: $e');
      throw Exception('Failed to get available drivers: $e');
    }
  }

  // Update driver location
  Future<void> updateDriverLocation(String userId, double latitude, double longitude) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'driverProfile.latitude': latitude,
        'driverProfile.longitude': longitude,
        'driverProfile.currentLocation': 'Updated via GPS',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating driver location: $e');
      throw Exception('Failed to update driver location: $e');
    }
  }

  // Toggle driver online status
  Future<void> toggleDriverStatus(String userId, bool isOnline) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'driverProfile.isOnline': isOnline,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error toggling driver status: $e');
      throw Exception('Failed to toggle driver status: $e');
    }
  }

  // Update service provider availability
  Future<void> updateServiceProviderAvailability(String userId, bool isAvailable) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'serviceProviderProfile.isAvailable': isAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating service provider availability: $e');
      throw Exception('Failed to update service provider availability: $e');
    }
  }

  // Get business statistics
  Future<Map<String, dynamic>> getBusinessStatistics(String userId) async {
    try {
      // This would typically aggregate data from orders, requests, etc.
      // For now, return basic structure
      return {
        'totalOrders': 0,
        'totalRevenue': 0.0,
        'averageRating': 0.0,
        'totalProducts': 0,
        'activeListings': 0,
        'monthlyStats': {},
      };
    } catch (e) {
      print('Error getting business statistics: $e');
      throw Exception('Failed to get business statistics: $e');
    }
  }

  // Add courier profile to existing user
  Future<void> addCourierProfile(String userId, CourierProfile courierProfile) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data()!;
      final currentRoles = List<String>.from(userData['roles'] ?? []);
      
      if (!currentRoles.contains(UserType.courier.name)) {
        currentRoles.add(UserType.courier.name);
      }

      await _firestore.collection('users').doc(userId).update({
        'roles': currentRoles,
        'courierProfile': courierProfile.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding courier profile: $e');
      throw Exception('Failed to add courier profile: $e');
    }
  }

  // Add van rental profile to existing user
  Future<void> addVanRentalProfile(String userId, VanRentalProfile vanRentalProfile) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        throw Exception('User not found');
      }

      final userData = userDoc.data()!;
      final currentRoles = List<String>.from(userData['roles'] ?? []);
      
      if (!currentRoles.contains(UserType.vanRental.name)) {
        currentRoles.add(UserType.vanRental.name);
      }

      await _firestore.collection('users').doc(userId).update({
        'roles': currentRoles,
        'vanRentalProfile': vanRentalProfile.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding van rental profile: $e');
      throw Exception('Failed to add van rental profile: $e');
    }
  }

  // Update courier availability
  Future<void> updateCourierAvailability(String userId, bool isOnline) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'courierProfile.isOnline': isOnline,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating courier availability: $e');
      throw Exception('Failed to update courier availability: $e');
    }
  }

  // Get available couriers for delivery
  Future<List<EnhancedUserModel>> getAvailableCouriers({
    required double latitude,
    required double longitude,
    required double radiusKm,
    List<String>? serviceAreas,
  }) async {
    try {
      Query query = _firestore
          .collection('users')
          .where('roles', arrayContains: UserType.courier.name)
          .where('courierProfile.isOnline', isEqualTo: true)
          .where('courierProfile.verificationStatus', isEqualTo: VerificationStatus.verified.name);

      final querySnapshot = await query.get();

      List<EnhancedUserModel> couriers = querySnapshot.docs
          .map((doc) => EnhancedUserModel.fromFirestore(doc))
          .where((user) => user.courierProfile != null)
          .toList();

      // Filter by service areas if provided
      if (serviceAreas != null && serviceAreas.isNotEmpty) {
        couriers = couriers.where((courier) {
          return serviceAreas.any((area) => 
              courier.courierProfile!.serviceAreas.contains(area));
        }).toList();
      }

      // Sort by rating
      couriers.sort((a, b) => 
          b.courierProfile!.averageRating.compareTo(a.courierProfile!.averageRating));

      return couriers;
    } catch (e) {
      print('Error getting available couriers: $e');
      throw Exception('Failed to get available couriers: $e');
    }
  }

  // Get available van rentals
  Future<List<EnhancedUserModel>> getAvailableVanRentals({
    List<String>? serviceAreas,
  }) async {
    try {
      Query query = _firestore
          .collection('users')
          .where('roles', arrayContains: UserType.vanRental.name)
          .where('vanRentalProfile.verificationStatus', isEqualTo: VerificationStatus.verified.name);

      final querySnapshot = await query.get();

      List<EnhancedUserModel> rentals = querySnapshot.docs
          .map((doc) => EnhancedUserModel.fromFirestore(doc))
          .where((user) => user.vanRentalProfile != null)
          .toList();

      // Filter by service areas if provided
      if (serviceAreas != null && serviceAreas.isNotEmpty) {
        rentals = rentals.where((rental) {
          return serviceAreas.any((area) => 
              rental.vanRentalProfile!.serviceAreas.contains(area));
        }).toList();
      }

      // Sort by rating and number of vehicles
      rentals.sort((a, b) {
        final ratingCompare = b.vanRentalProfile!.averageRating
            .compareTo(a.vanRentalProfile!.averageRating);
        if (ratingCompare != 0) return ratingCompare;
        return b.vanRentalProfile!.vehicleIds.length
            .compareTo(a.vanRentalProfile!.vehicleIds.length);
      });

      return rentals;
    } catch (e) {
      print('Error getting available van rentals: $e');
      throw Exception('Failed to get available van rentals: $e');
    }
  }
}
