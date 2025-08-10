import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/enhanced_driver_model.dart';
import '../services/user_service.dart';

class EnhancedDriverService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final UserService _userService = UserService();

  // Get current driver profile
  Future<EnhancedDriverModel?> getDriverProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('drivers').doc(user.uid).get();
      if (!doc.exists) return null;
      
      final data = doc.data() as Map<String, dynamic>;
      
      // Extract timestamp values safely
      DateTime createdAt = DateTime.now();
      DateTime updatedAt = DateTime.now();
      
      try {
        if (data['createdAt'] is Timestamp) {
          createdAt = (data['createdAt'] as Timestamp).toDate();
        }
      } catch (e) {
        print('Warning: Could not parse createdAt timestamp: $e');
      }
      
      try {
        if (data['updatedAt'] is Timestamp) {
          updatedAt = (data['updatedAt'] as Timestamp).toDate();
        }
      } catch (e) {
        print('Warning: Could not parse updatedAt timestamp: $e');
      }
      
      // Create driver model with safe data extraction
      return EnhancedDriverModel(
        id: doc.id,
        userId: user.uid,
        name: data['name'] ?? data['displayName'] ?? 'Unknown Driver',
        photoUrl: data['documentVerification']?['driverPhoto']?['url'],
        licenseNumber: data['licenseNumber'] ?? '',
        licenseExpiry: DateTime.now().add(const Duration(days: 365)),
        insuranceNumber: data['insuranceNumber'] ?? '',
        insuranceExpiry: DateTime.now().add(const Duration(days: 365)),
        vehicles: [], // Empty for now
        status: _getDriverStatus(data['status']),
        subscriptionPlan: SubscriptionPlan.free,
        subscriptionExpiry: null,
        isAvailable: data['availability'] ?? false,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
    } catch (e) {
      print('Error getting driver profile: $e');
      // Return a basic fallback profile
      return EnhancedDriverModel(
        id: user.uid,
        userId: user.uid,
        name: 'Driver',
        licenseNumber: '',
        licenseExpiry: DateTime.now().add(const Duration(days: 365)),
        insuranceNumber: '',
        insuranceExpiry: DateTime.now().add(const Duration(days: 365)),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }
  
  DriverStatus _getDriverStatus(dynamic status) {
    if (status == null) return DriverStatus.pending;
    if (status is String) {
      switch (status.toLowerCase()) {
        case 'approved':
          return DriverStatus.approved;
        case 'suspended':
          return DriverStatus.suspended;
        case 'rejected':
          return DriverStatus.rejected;
        default:
          return DriverStatus.pending;
      }
    }
    return DriverStatus.pending;
  }

  // Create or update driver profile
  Future<void> createOrUpdateDriverProfile({
    required String licenseNumber,
    required DateTime licenseExpiry,
    required String insuranceNumber,
    required DateTime insuranceExpiry,
    File? driverPhoto,
    File? licenseDocument,
    File? insuranceDocument,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      // Get user data
      final userData = await _userService.getUserById(user.uid);
      final userName = userData?.displayName ?? 'Unknown Driver';

      // Check if driver profile already exists
      final existingDoc = await _firestore.collection('drivers').doc(user.uid).get();
      EnhancedDriverModel? existingDriver;
      
      if (existingDoc.exists) {
        existingDriver = EnhancedDriverModel.fromFirestore(existingDoc);
      }

      // Upload documents if provided
      DocumentVerification licenseVerification = existingDriver?.licenseVerification ?? DocumentVerification();
      DocumentVerification insuranceVerification = existingDriver?.insuranceVerification ?? DocumentVerification();
      DocumentVerification photoVerification = existingDriver?.photoVerification ?? DocumentVerification();

      if (driverPhoto != null) {
        final photoUrl = await _uploadFile(driverPhoto, 'drivers/${user.uid}/driver_photo');
        photoVerification = DocumentVerification(
          status: VerificationStatus.pending,
          submittedAt: DateTime.now(),
          documentUrl: photoUrl,
        );
      }

      if (licenseDocument != null) {
        final licenseUrl = await _uploadFile(licenseDocument, 'drivers/${user.uid}/license');
        licenseVerification = DocumentVerification(
          status: VerificationStatus.pending,
          submittedAt: DateTime.now(),
          documentUrl: licenseUrl,
        );
      }

      if (insuranceDocument != null) {
        final insuranceUrl = await _uploadFile(insuranceDocument, 'drivers/${user.uid}/insurance');
        insuranceVerification = DocumentVerification(
          status: VerificationStatus.pending,
          submittedAt: DateTime.now(),
          documentUrl: insuranceUrl,
        );
      }

      // Create or update driver profile
      final driver = EnhancedDriverModel(
        id: user.uid,
        userId: user.uid,
        name: userName,
        photoUrl: photoVerification.documentUrl,
        licenseNumber: licenseNumber,
        licenseExpiry: licenseExpiry,
        licenseVerification: licenseVerification,
        insuranceNumber: insuranceNumber,
        insuranceExpiry: insuranceExpiry,
        insuranceVerification: insuranceVerification,
        photoVerification: photoVerification,
        vehicles: existingDriver?.vehicles ?? [],
        primaryVehicleId: existingDriver?.primaryVehicleId,
        status: existingDriver?.status ?? DriverStatus.pending,
        subscriptionPlan: existingDriver?.subscriptionPlan ?? SubscriptionPlan.free,
        subscriptionExpiry: existingDriver?.subscriptionExpiry,
        rating: existingDriver?.rating ?? 0.0,
        totalRides: existingDriver?.totalRides ?? 0,
        totalEarnings: existingDriver?.totalEarnings ?? 0.0,
        isAvailable: existingDriver?.isAvailable ?? false,
        createdAt: existingDriver?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('drivers').doc(user.uid).set(driver.toMap());
    } catch (e) {
      print('Error creating/updating driver profile: $e');
      throw Exception('Failed to update driver profile: $e');
    }
  }

  // Add vehicle to driver profile
  Future<void> addVehicle({
    required VehicleType type,
    required String number,
    required String model,
    required String color,
    required int year,
    required List<File> vehicleImages,
    File? registrationDocument,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final driver = await getDriverProfile();
      if (driver == null) throw Exception('Driver profile not found');

      // Upload vehicle images
      List<String> imageUrls = [];
      for (int i = 0; i < vehicleImages.length; i++) {
        final url = await _uploadFile(
          vehicleImages[i], 
          'drivers/${user.uid}/vehicles/${DateTime.now().millisecondsSinceEpoch}_$i'
        );
        imageUrls.add(url);
      }

      // Upload registration document if provided
      DocumentVerification registrationVerification = DocumentVerification();
      if (registrationDocument != null) {
        final regUrl = await _uploadFile(
          registrationDocument, 
          'drivers/${user.uid}/vehicles/registration_${DateTime.now().millisecondsSinceEpoch}'
        );
        registrationVerification = DocumentVerification(
          status: VerificationStatus.pending,
          submittedAt: DateTime.now(),
          documentUrl: regUrl,
        );
      }

      // Create new vehicle
      final vehicleId = DateTime.now().millisecondsSinceEpoch.toString();
      final newVehicle = VehicleModel(
        id: vehicleId,
        type: type,
        number: number,
        model: model,
        color: color,
        year: year,
        imageUrls: imageUrls,
        registrationVerification: registrationVerification,
        createdAt: DateTime.now(),
      );

      // Update driver with new vehicle
      final updatedVehicles = [...driver.vehicles, newVehicle];
      final updatedDriver = EnhancedDriverModel(
        id: driver.id,
        userId: driver.userId,
        name: driver.name,
        photoUrl: driver.photoUrl,
        licenseNumber: driver.licenseNumber,
        licenseExpiry: driver.licenseExpiry,
        licenseVerification: driver.licenseVerification,
        insuranceNumber: driver.insuranceNumber,
        insuranceExpiry: driver.insuranceExpiry,
        insuranceVerification: driver.insuranceVerification,
        photoVerification: driver.photoVerification,
        vehicles: updatedVehicles,
        primaryVehicleId: driver.primaryVehicleId ?? vehicleId, // Set as primary if first vehicle
        status: driver.status,
        subscriptionPlan: driver.subscriptionPlan,
        subscriptionExpiry: driver.subscriptionExpiry,
        rating: driver.rating,
        totalRides: driver.totalRides,
        totalEarnings: driver.totalEarnings,
        isAvailable: driver.isAvailable,
        createdAt: driver.createdAt,
        updatedAt: DateTime.now(),
      );

      await _firestore.collection('drivers').doc(user.uid).set(updatedDriver.toMap());
    } catch (e) {
      print('Error adding vehicle: $e');
      throw Exception('Failed to add vehicle: $e');
    }
  }

  // Update document verification (for rejected documents)
  Future<void> updateDocument({
    required String documentType, // 'license', 'insurance', 'photo'
    required File documentFile,
    String? vehicleId, // For vehicle registration documents
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    try {
      final driver = await getDriverProfile();
      if (driver == null) throw Exception('Driver profile not found');

      // Upload new document
      final documentUrl = await _uploadFile(
        documentFile, 
        'drivers/${user.uid}/$documentType${vehicleId != null ? '_$vehicleId' : ''}'
      );

      // Update appropriate verification
      DocumentVerification newVerification = DocumentVerification(
        status: VerificationStatus.pending,
        submittedAt: DateTime.now(),
        documentUrl: documentUrl,
      );

      EnhancedDriverModel updatedDriver;

      switch (documentType) {
        case 'license':
          updatedDriver = EnhancedDriverModel(
            id: driver.id,
            userId: driver.userId,
            name: driver.name,
            photoUrl: driver.photoUrl,
            licenseNumber: driver.licenseNumber,
            licenseExpiry: driver.licenseExpiry,
            licenseVerification: newVerification,
            insuranceNumber: driver.insuranceNumber,
            insuranceExpiry: driver.insuranceExpiry,
            insuranceVerification: driver.insuranceVerification,
            photoVerification: driver.photoVerification,
            vehicles: driver.vehicles,
            primaryVehicleId: driver.primaryVehicleId,
            status: driver.status,
            subscriptionPlan: driver.subscriptionPlan,
            subscriptionExpiry: driver.subscriptionExpiry,
            rating: driver.rating,
            totalRides: driver.totalRides,
            totalEarnings: driver.totalEarnings,
            isAvailable: driver.isAvailable,
            createdAt: driver.createdAt,
            updatedAt: DateTime.now(),
          );
          break;
        case 'insurance':
          updatedDriver = EnhancedDriverModel(
            id: driver.id,
            userId: driver.userId,
            name: driver.name,
            photoUrl: driver.photoUrl,
            licenseNumber: driver.licenseNumber,
            licenseExpiry: driver.licenseExpiry,
            licenseVerification: driver.licenseVerification,
            insuranceNumber: driver.insuranceNumber,
            insuranceExpiry: driver.insuranceExpiry,
            insuranceVerification: newVerification,
            photoVerification: driver.photoVerification,
            vehicles: driver.vehicles,
            primaryVehicleId: driver.primaryVehicleId,
            status: driver.status,
            subscriptionPlan: driver.subscriptionPlan,
            subscriptionExpiry: driver.subscriptionExpiry,
            rating: driver.rating,
            totalRides: driver.totalRides,
            totalEarnings: driver.totalEarnings,
            isAvailable: driver.isAvailable,
            createdAt: driver.createdAt,
            updatedAt: DateTime.now(),
          );
          break;
        case 'photo':
          updatedDriver = EnhancedDriverModel(
            id: driver.id,
            userId: driver.userId,
            name: driver.name,
            photoUrl: documentUrl,
            licenseNumber: driver.licenseNumber,
            licenseExpiry: driver.licenseExpiry,
            licenseVerification: driver.licenseVerification,
            insuranceNumber: driver.insuranceNumber,
            insuranceExpiry: driver.insuranceExpiry,
            insuranceVerification: driver.insuranceVerification,
            photoVerification: newVerification,
            vehicles: driver.vehicles,
            primaryVehicleId: driver.primaryVehicleId,
            status: driver.status,
            subscriptionPlan: driver.subscriptionPlan,
            subscriptionExpiry: driver.subscriptionExpiry,
            rating: driver.rating,
            totalRides: driver.totalRides,
            totalEarnings: driver.totalEarnings,
            isAvailable: driver.isAvailable,
            createdAt: driver.createdAt,
            updatedAt: DateTime.now(),
          );
          break;
        case 'vehicle_registration':
          if (vehicleId == null) throw Exception('Vehicle ID required for vehicle registration');
          
          final updatedVehicles = driver.vehicles.map((vehicle) {
            if (vehicle.id == vehicleId) {
              return VehicleModel(
                id: vehicle.id,
                type: vehicle.type,
                number: vehicle.number,
                model: vehicle.model,
                color: vehicle.color,
                year: vehicle.year,
                imageUrls: vehicle.imageUrls,
                registrationVerification: newVerification,
                isActive: vehicle.isActive,
                createdAt: vehicle.createdAt,
              );
            }
            return vehicle;
          }).toList();

          updatedDriver = EnhancedDriverModel(
            id: driver.id,
            userId: driver.userId,
            name: driver.name,
            photoUrl: driver.photoUrl,
            licenseNumber: driver.licenseNumber,
            licenseExpiry: driver.licenseExpiry,
            licenseVerification: driver.licenseVerification,
            insuranceNumber: driver.insuranceNumber,
            insuranceExpiry: driver.insuranceExpiry,
            insuranceVerification: driver.insuranceVerification,
            photoVerification: driver.photoVerification,
            vehicles: updatedVehicles,
            primaryVehicleId: driver.primaryVehicleId,
            status: driver.status,
            subscriptionPlan: driver.subscriptionPlan,
            subscriptionExpiry: driver.subscriptionExpiry,
            rating: driver.rating,
            totalRides: driver.totalRides,
            totalEarnings: driver.totalEarnings,
            isAvailable: driver.isAvailable,
            createdAt: driver.createdAt,
            updatedAt: DateTime.now(),
          );
          break;
        default:
          throw Exception('Invalid document type');
      }

      await _firestore.collection('drivers').doc(user.uid).set(updatedDriver.toMap());
    } catch (e) {
      print('Error updating document: $e');
      throw Exception('Failed to update document: $e');
    }
  }

  // Check if user is registered driver
  Future<bool> isRegisteredDriver() async {
    final driver = await getDriverProfile();
    return driver != null;
  }

  // Check if driver is approved
  Future<bool> isApprovedDriver() async {
    final driver = await getDriverProfile();
    return driver?.status == DriverStatus.approved;
  }

  // Toggle driver availability
  Future<void> toggleAvailability() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final driver = await getDriverProfile();
    if (driver == null) throw Exception('Driver profile not found');

    await _firestore.collection('drivers').doc(user.uid).update({
      'isAvailable': !driver.isAvailable,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Upload file to Firebase Storage
  Future<String> _uploadFile(File file, String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.putFile(file);
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading file: $e');
      throw Exception('Failed to upload file');
    }
  }

  // Admin functions for verification (to be called from web backend)
  Future<void> verifyDocument({
    required String driverId,
    required String documentType,
    required VerificationStatus status,
    String? rejectionReason,
    String? vehicleId,
  }) async {
    try {
      final doc = await _firestore.collection('drivers').doc(driverId).get();
      if (!doc.exists) throw Exception('Driver not found');

      final driver = EnhancedDriverModel.fromFirestore(doc);
      DocumentVerification verification = DocumentVerification(
        status: status,
        verifiedAt: status == VerificationStatus.verified ? DateTime.now() : null,
        rejectionReason: rejectionReason,
        submittedAt: DateTime.now(),
      );

      Map<String, dynamic> updateData = {'updatedAt': FieldValue.serverTimestamp()};

      switch (documentType) {
        case 'license':
          updateData['licenseVerification'] = verification.toMap();
          break;
        case 'insurance':
          updateData['insuranceVerification'] = verification.toMap();
          break;
        case 'photo':
          updateData['photoVerification'] = verification.toMap();
          break;
        case 'vehicle_registration':
          if (vehicleId == null) throw Exception('Vehicle ID required');
          updateData['vehicles'] = driver.vehicles.map((vehicle) {
            if (vehicle.id == vehicleId) {
              return VehicleModel(
                id: vehicle.id,
                type: vehicle.type,
                number: vehicle.number,
                model: vehicle.model,
                color: vehicle.color,
                year: vehicle.year,
                imageUrls: vehicle.imageUrls,
                registrationVerification: verification,
                isActive: vehicle.isActive,
                createdAt: vehicle.createdAt,
              ).toMap();
            }
            return vehicle.toMap();
          }).toList();
          break;
      }

      await _firestore.collection('drivers').doc(driverId).update(updateData);

      // Check if driver can be approved
      final updatedDoc = await _firestore.collection('drivers').doc(driverId).get();
      final updatedDriver = EnhancedDriverModel.fromFirestore(updatedDoc);
      
      if (updatedDriver.canBeApproved && updatedDriver.status == DriverStatus.pending) {
        await _firestore.collection('drivers').doc(driverId).update({
          'status': DriverStatus.approved.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error verifying document: $e');
      throw Exception('Failed to verify document: $e');
    }
  }
}
