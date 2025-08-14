import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for managing business module configurations per country
class ModuleService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Module information for UI display
  static const Map<String, Map<String, dynamic>> moduleInfo = {
    'item': {
      'name': 'Item Request',
      'subtitle': 'Request for products or items',
      'icon': 'Icons.shopping_bag',
      'color': 0xFFFF6B35,
    },
    'service': {
      'name': 'Service Request',
      'subtitle': 'Request for services',
      'icon': 'Icons.build',
      'color': 0xFF4ECDC4,
    },
    'rent': {
      'name': 'Rental Request',
      'subtitle': 'Rent vehicles, equipment, or items',
      'icon': 'Icons.key',
      'color': 0xFF45B7D1,
    },
    'delivery': {
      'name': 'Delivery Request',
      'subtitle': 'Request for delivery services',
      'icon': 'Icons.local_shipping',
      'color': 0xFF96CEB4,
    },
    'ride': {
      'name': 'Ride Request',
      'subtitle': 'Request for transportation',
      'icon': 'Icons.directions_car',
      'color': 0xFFFFEAA7,
    },
    'price': {
      'name': 'Price Request',
      'subtitle': 'Request price quotes for items or services',
      'icon': 'Icons.compare_arrows',
      'color': 0xFFDDA0DD,
    },
  };

  /// Get enabled modules for a specific country
  static Future<CountryModules> getCountryModules(String countryCode) async {
    try {
      print('🌍 Fetching modules for country: $countryCode');
      
      final docRef = _firestore
          .collection('country_modules')
          .doc(countryCode.toUpperCase());
          
      final docSnapshot = await docRef.get();
      
      if (!docSnapshot.exists) {
        print('⚠️ No module config found for $countryCode, using defaults');
        
        // Return default configuration
        return CountryModules(
          success: true,
          countryCode: countryCode.toUpperCase(),
          modules: {
            'item': true,
            'service': true,
            'rent': false,
            'delivery': false,
            'ride': false,
            'price': false,
          },
          coreDependencies: {
            'payment': true,
            'messaging': true,
            'location': true,
            'driver': false,
          },
        );
      }
      
      final data = docSnapshot.data()!;
      print('✅ Found module config for $countryCode: ${data['modules']}');
      print('🔍 Raw Firestore data: $data');
      
      final modules = Map<String, bool>.from(data['modules'] ?? {});
      print('🎯 Parsed modules map: $modules');
      
      return CountryModules(
        success: true,
        countryCode: countryCode.toUpperCase(),
        modules: modules,
        coreDependencies: Map<String, bool>.from(data['coreDependencies'] ?? {}),
        lastUpdated: data['updatedAt']?.toDate(),
      );
      
    } catch (error) {
      print('❌ Error fetching country modules: $error');
      return CountryModules(
        success: false,
        countryCode: countryCode.toUpperCase(),
        error: error.toString(),
      );
    }
  }

  /// Get list of enabled modules for UI display
  static List<ModuleInfo> getEnabledModulesForDisplay(Map<String, bool> modules) {
    List<ModuleInfo> enabledModules = [];
    
    print('🎪 Building modules list from: $modules');
    
    modules.forEach((moduleId, isEnabled) {
      print('🔍 Checking module: $moduleId = $isEnabled');
      if (isEnabled && moduleInfo.containsKey(moduleId)) {
        final info = moduleInfo[moduleId]!;
        enabledModules.add(ModuleInfo(
          id: moduleId,
          name: info['name'],
          subtitle: info['subtitle'],
          iconName: info['icon'],
          color: Color(info['color']),
        ));
        print('✅ Added module: ${info['name']}');
      } else if (isEnabled && !moduleInfo.containsKey(moduleId)) {
        print('❌ Module $moduleId is enabled but not found in moduleInfo map');
      }
    });
    
    print('🎯 Final enabled modules count: ${enabledModules.length}');
    enabledModules.forEach((module) {
      print('📱 Will show: ${module.name}');
    });
    
    // Sort modules in a specific order for consistency
    final order = ['item', 'service', 'rent', 'delivery', 'ride', 'price'];
    enabledModules.sort((a, b) {
      final aIndex = order.indexOf(a.id);
      final bIndex = order.indexOf(b.id);
      return aIndex.compareTo(bIndex);
    });
    
    return enabledModules;
  }

  /// Check if a specific module is enabled for a country
  static Future<bool> isModuleEnabled(String countryCode, String moduleId) async {
    final modules = await getCountryModules(countryCode);
    return modules.modules[moduleId] ?? false;
  }
}

/// Country modules configuration model
class CountryModules {
  final bool success;
  final String countryCode;
  final Map<String, bool> modules;
  final Map<String, bool> coreDependencies;
  final DateTime? lastUpdated;
  final String? error;

  CountryModules({
    required this.success,
    required this.countryCode,
    this.modules = const {},
    this.coreDependencies = const {},
    this.lastUpdated,
    this.error,
  });

  /// Get list of enabled module IDs
  List<String> get enabledModules {
    return modules.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();
  }

  /// Check if a specific module is enabled
  bool isModuleEnabled(String moduleId) {
    return modules[moduleId] ?? false;
  }
}

/// Module information for UI display
class ModuleInfo {
  final String id;
  final String name;
  final String subtitle;
  final String iconName;
  final Color color;

  ModuleInfo({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.iconName,
    required this.color,
  });
}
