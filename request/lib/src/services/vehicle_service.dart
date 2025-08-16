import 'package:cloud_firestore/cloud_firestore.dart';
import 'country_service.dart';
import '../models/vehicle_type_model.dart';

class VehicleService {
  static final VehicleService _instance = VehicleService._internal();
  factory VehicleService() => _instance;
  VehicleService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<VehicleTypeModel>? _cachedVehicles;
  String? _cachedCountry;

  /// Get available vehicles for the user's country with two-level filtering
  Future<List<VehicleTypeModel>> getAvailableVehicles() async {
    try {
      final countryCode = CountryService.instance.countryCode;
      
      // If no country is set, initialize and try again
      if (countryCode == null || countryCode.isEmpty) {
        print('No country code found, returning fallback vehicles');
        return _getFallbackVehicles();
      }
      
      // Return cached vehicles if same country
      if (_cachedVehicles != null && _cachedCountry == countryCode) {
        return _cachedVehicles!;
      }

      print('🚗 Starting two-level vehicle filtering for country code: $countryCode');

      // STEP 1: Get country-enabled vehicle types
      final countryVehiclesSnapshot = await _firestore
          .collection('country_vehicles')
          .where('countryCode', isEqualTo: countryCode)
          .get();

      if (countryVehiclesSnapshot.docs.isEmpty) {
        print('❌ No country vehicle configuration found for $countryCode');
        return [];
      }

      final enabledVehicleIds = List<String>.from(
        countryVehiclesSnapshot.docs.first.data()['enabledVehicles'] ?? []
      );

      if (enabledVehicleIds.isEmpty) {
        print('❌ No vehicles enabled for $countryCode');
        return [];
      }

      print('✅ Country-enabled vehicles: ${enabledVehicleIds.length}');

      // STEP 2: Get vehicle types with registered drivers
      final driversSnapshot = await _firestore
          .collection('new_driver_verifications')
          .where('country', isEqualTo: countryCode)
          .where('status', isEqualTo: 'approved')
          .where('availability', isEqualTo: true)
          .where('isActive', isEqualTo: true)
          .get();

      // Count drivers by vehicle type
      final vehicleDriverCounts = <String, int>{};
      for (final doc in driversSnapshot.docs) {
        final vehicleType = doc.data()['vehicleType'] as String?;
        if (vehicleType != null) {
          vehicleDriverCounts[vehicleType] = (vehicleDriverCounts[vehicleType] ?? 0) + 1;
        }
      }

      print('✅ Found ${driversSnapshot.docs.length} approved drivers');
      print('🔢 Driver counts by vehicle type: $vehicleDriverCounts');

      // STEP 3: Apply two-level filtering
      final availableVehicleIds = enabledVehicleIds
          .where((vehicleId) => vehicleDriverCounts.containsKey(vehicleId))
          .toList();

      print('🎯 Vehicles after two-level filtering: ${availableVehicleIds.length}');

      if (availableVehicleIds.isEmpty) {
        print('❌ No vehicles available (no registered drivers)');
        return [];
      }

      // STEP 4: Get vehicle type details
      final vehicleTypesSnapshot = await _firestore
          .collection('vehicle_types')
          .where('isActive', isEqualTo: true)
          .orderBy('displayOrder')
          .get();

      // Filter and build available vehicles
      final availableVehicles = vehicleTypesSnapshot.docs
          .where((doc) => availableVehicleIds.contains(doc.id))
          .map((doc) => VehicleTypeModel.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();

      // Cache the results
      _cachedVehicles = availableVehicles;
      _cachedCountry = countryCode;

      print('✅ Final result: ${availableVehicles.length} vehicle types available');
      for (final vehicle in availableVehicles) {
        final driverCount = vehicleDriverCounts[vehicle.id] ?? 0;
        print('  - ${vehicle.name}: $driverCount drivers');
      }

      return availableVehicles;
    } catch (e) {
      print('❌ Error fetching available vehicles: $e');
      return _getFallbackVehicles();
    }
  }

  /// Clear cache when needed (e.g., when country changes)
  void clearCache() {
    _cachedVehicles = null;
    _cachedCountry = null;
    print('🗑️ Vehicle cache cleared');
  }

  /// Force refresh vehicles by clearing cache and fetching fresh data
  Future<List<VehicleTypeModel>> refreshVehicles() async {
    clearCache();
    return await getAvailableVehicles();
  }

  /// Fallback vehicles if database fetch fails
  List<VehicleTypeModel> _getFallbackVehicles() {
    return [
      VehicleTypeModel(
        id: 'bike',
        name: 'Bike',
        description: 'Quick & affordable',
        icon: 'two_wheeler',
        displayOrder: 1,
        isActive: true,
        passengerCapacity: 1,
      ),
      VehicleTypeModel(
        id: 'threewheeler',
        name: 'Three Wheeler',
        description: 'Local transport',
        icon: 'local_taxi',
        displayOrder: 2,
        isActive: true,
        passengerCapacity: 3,
      ),
      VehicleTypeModel(
        id: 'car',
        name: 'Car',
        description: 'Comfortable ride',
        icon: 'directions_car',
        displayOrder: 3,
        isActive: true,
        passengerCapacity: 4,
      ),
    ];
  }
}
