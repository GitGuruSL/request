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

  /// Get available vehicles for the user's country
  Future<List<VehicleTypeModel>> getAvailableVehicles() async {
    try {
      final country = await CountryService.instance.getCurrentCountry();
      
      // Return cached vehicles if same country
      if (_cachedVehicles != null && _cachedCountry == country) {
        return _cachedVehicles!;
      }

      // Get all active vehicle types
      final vehicleTypesSnapshot = await _firestore
          .collection('vehicle_types')
          .where('isActive', isEqualTo: true)
          .orderBy('displayOrder')
          .get();

      if (vehicleTypesSnapshot.docs.isEmpty) {
        print('No active vehicle types found');
        return [];
      }

      // Get country-specific vehicles
      final countryVehiclesSnapshot = await _firestore
          .collection('country_vehicles')
          .where('country', isEqualTo: country)
          .where('isEnabled', isEqualTo: true)
          .get();

      final enabledVehicleIds = countryVehiclesSnapshot.docs
          .map((doc) => doc.data()['vehicleTypeId'] as String)
          .toSet();

      // Filter vehicles that are enabled in this country
      final availableVehicles = vehicleTypesSnapshot.docs
          .where((doc) => enabledVehicleIds.contains(doc.id))
          .map((doc) => VehicleTypeModel.fromMap({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();

      // Cache the results
      _cachedVehicles = availableVehicles;
      _cachedCountry = country;

      print('Found ${availableVehicles.length} available vehicles for $country');
      return availableVehicles;
    } catch (e) {
      print('Error fetching available vehicles: $e');
      return _getFallbackVehicles();
    }
  }

  /// Clear cache when needed (e.g., when country changes)
  void clearCache() {
    _cachedVehicles = null;
    _cachedCountry = null;
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
