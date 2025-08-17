import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import existing Firebase services
import 'auth_service.dart';
import 'category_service.dart';
import 'country_service.dart';
import 'enhanced_request_service.dart';

// Import new REST API services
import 'rest_auth_service.dart';
import 'rest_category_service.dart';
import 'rest_city_service.dart';
import 'rest_vehicle_type_service.dart';
import 'rest_request_service.dart';

enum ServiceMode { firebase, restApi }

/// Service Manager to handle transition from Firebase to REST API
/// This allows gradual migration and easy switching between services
class ServiceManager {
  static ServiceManager? _instance;
  static ServiceManager get instance => _instance ??= ServiceManager._();

  ServiceManager._();

  ServiceMode _currentMode = ServiceMode.restApi; // Default to REST API
  static const String _serviceModeKey = 'service_mode';

  ServiceMode get currentMode => _currentMode;

  Future<void> initialize() async {
    await _loadServiceMode();

    // Initialize the appropriate services
    switch (_currentMode) {
      case ServiceMode.firebase:
        await _initializeFirebaseServices();
        break;
      case ServiceMode.restApi:
        await _initializeRestApiServices();
        break;
    }
  }

  Future<void> _loadServiceMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeString = prefs.getString(_serviceModeKey);

      if (modeString != null) {
        _currentMode = ServiceMode.values.firstWhere(
          (mode) => mode.toString() == modeString,
          orElse: () => ServiceMode.restApi,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading service mode: $e');
      }
      _currentMode = ServiceMode.restApi;
    }
  }

  Future<void> _saveServiceMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_serviceModeKey, _currentMode.toString());
    } catch (e) {
      if (kDebugMode) {
        print('Error saving service mode: $e');
      }
    }
  }

  Future<void> switchToMode(ServiceMode mode) async {
    if (_currentMode == mode) return;

    _currentMode = mode;
    await _saveServiceMode();

    // Initialize the new services
    switch (mode) {
      case ServiceMode.firebase:
        await _initializeFirebaseServices();
        break;
      case ServiceMode.restApi:
        await _initializeRestApiServices();
        break;
    }
  }

  Future<void> _initializeFirebaseServices() async {
    // Initialize Firebase services
    if (kDebugMode) {
      print('Initializing Firebase services');
    }
    // TODO: Initialize Firebase services if needed
  }

  Future<void> _initializeRestApiServices() async {
    // Initialize REST API services
    if (kDebugMode) {
      print('Initializing REST API services');
    }
    await RestAuthService.instance.initialize();
  }

  // Auth Service Methods
  dynamic get authService {
    switch (_currentMode) {
      case ServiceMode.firebase:
        return AuthService.instance;
      case ServiceMode.restApi:
        return RestAuthService.instance;
    }
  }

  // Category Service Methods
  dynamic get categoryService {
    switch (_currentMode) {
      case ServiceMode.firebase:
        return CategoryService.instance;
      case ServiceMode.restApi:
        return RestCategoryService.instance;
    }
  }

  // City Service Methods
  dynamic get cityService {
    switch (_currentMode) {
      case ServiceMode.firebase:
        return CountryService
            .instance; // Assuming this handles cities in Firebase
      case ServiceMode.restApi:
        return RestCityService.instance;
    }
  }

  // Vehicle Type Service Methods
  dynamic get vehicleTypeService {
    switch (_currentMode) {
      case ServiceMode.firebase:
        // TODO: Return Firebase vehicle service
        return null; // Replace with actual Firebase service
      case ServiceMode.restApi:
        return RestVehicleTypeService.instance;
    }
  }

  // Request Service Methods
  dynamic get requestService {
    switch (_currentMode) {
      case ServiceMode.firebase:
        return EnhancedRequestService.instance;
      case ServiceMode.restApi:
        return RestRequestService.instance;
    }
  }

  // Helper methods for common operations
  Future<bool> isUserAuthenticated() async {
    switch (_currentMode) {
      case ServiceMode.firebase:
        final authService = AuthService.instance;
        return authService.currentUser != null;
      case ServiceMode.restApi:
        final authService = RestAuthService.instance;
        return await authService.getCurrentUser() != null;
    }
  }

  Future<String?> getCurrentUserId() async {
    switch (_currentMode) {
      case ServiceMode.firebase:
        final authService = AuthService.instance;
        return authService.currentUser?.uid;
      case ServiceMode.restApi:
        final authService = RestAuthService.instance;
        final user = await authService.getCurrentUser();
        return user?.id;
    }
  }

  Future<void> signOut() async {
    switch (_currentMode) {
      case ServiceMode.firebase:
        await AuthService.instance.signOut();
        break;
      case ServiceMode.restApi:
        await RestAuthService.instance.signOut();
        break;
    }
  }

  // Migration helper methods
  Future<bool> testRestApiConnection() async {
    try {
      // Try to fetch categories as a connection test
      final categories = await RestCategoryService.instance.getCategories();
      return categories.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('REST API connection test failed: $e');
      }
      return false;
    }
  }

  Future<void> migrateToRestApi() async {
    if (_currentMode == ServiceMode.restApi) return;

    try {
      // Test REST API connection first
      final isConnected = await testRestApiConnection();
      if (!isConnected) {
        throw Exception('Cannot connect to REST API');
      }

      // Switch to REST API mode
      await switchToMode(ServiceMode.restApi);

      if (kDebugMode) {
        print('Successfully migrated to REST API');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Migration to REST API failed: $e');
      }
      rethrow;
    }
  }

  // Development/debugging methods
  void clearAllCaches() {
    switch (_currentMode) {
      case ServiceMode.firebase:
        // Clear Firebase caches if any
        break;
      case ServiceMode.restApi:
        RestCategoryService.instance.clearCache();
        RestCityService.instance.clearCache();
        RestVehicleTypeService.instance.clearCache();
        break;
    }
  }

  Map<String, dynamic> getServiceStatus() {
    return {
      'currentMode': _currentMode.toString(),
      'isFirebaseMode': _currentMode == ServiceMode.firebase,
      'isRestApiMode': _currentMode == ServiceMode.restApi,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
