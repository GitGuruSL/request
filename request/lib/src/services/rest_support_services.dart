import 'package:flutter/foundation.dart';

class CountryService {
  CountryService._();
  static final CountryService instance = CountryService._();

  String? countryCode = 'LK';
  String countryName = 'Sri Lanka';
  String currency = 'LKR';

  String getCurrencySymbol() => 'Rs';
  String formatPrice(num amount) => 'Rs ${amount.toStringAsFixed(2)}';
}

class CountryModules {
  final Map<String, bool> modules;
  CountryModules(this.modules);

  bool isModuleEnabled(String moduleId) => modules[moduleId] ?? false;
}

class ModuleService {
  ModuleService._();
  static final Map<String, CountryModules> _cache = {};

  static Future<CountryModules> getCountryModules(String countryCode) async {
    if (_cache.containsKey(countryCode)) return _cache[countryCode]!;
    final modules = CountryModules({
      'ride': true,
      'delivery': true,
      'item': true,
      'service': true,
      'rent': true,
      'price': true,
    });
    _cache[countryCode] = modules;
    if (kDebugMode) {
      print('Loaded default module set for $countryCode');
    }
    return modules;
  }
}
