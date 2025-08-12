import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CountryService {
  static const String _countryCodeKey = 'user_country_code';
  static const String _countryNameKey = 'user_country_name';
  static const String _phoneCodeKey = 'user_phone_code';
  static const String _currencyKey = 'user_currency';
  
  static CountryService? _instance;
  static CountryService get instance => _instance ??= CountryService._();
  
  CountryService._();
  
  String? _currentCountryCode;
  String? _currentCountryName;
  String? _currentPhoneCode;
  String? _currentCurrency;
  
  // Getters
  String? get countryCode => _currentCountryCode;
  String? get countryName => _currentCountryName;
  String? get phoneCode => _currentPhoneCode;
  String? get currency => _currentCurrency;
  
  /// Get user's country name (alias for countryName getter)
  String? getUserCountry() => _currentCountryName;
  
  // Currency mapping for different countries
  static const Map<String, String> countryCurrencyMap = {
    'US': 'USD',
    'GB': 'GBP',
    'CA': 'CAD',
    'AU': 'AUD',
    'DE': 'EUR',
    'FR': 'EUR',
    'ES': 'EUR',
    'IT': 'EUR',
    'JP': 'JPY',
    'CN': 'CNY',
    'IN': 'INR',
    'BR': 'BRL',
    'MX': 'MXN',
    'ZA': 'ZAR',
    'NG': 'NGN',
    'EG': 'EGP',
    'KE': 'KES',
    'GH': 'GHS',
    'LK': 'LKR', // Sri Lanka
    // Add more countries as needed
  };
  
  /// Initialize country service - call this on app startup
  Future<void> initialize() async {
    await _loadFromPreferences();
    await _loadFromFirestore();
  }
  
  /// Set user's country (call this during registration/welcome screen)
  Future<void> setUserCountry({
    required String countryCode,
    required String countryName,
    required String phoneCode,
  }) async {
    _currentCountryCode = countryCode;
    _currentCountryName = countryName;
    _currentPhoneCode = phoneCode;
    _currentCurrency = countryCurrencyMap[countryCode] ?? 'LKR';
    
    // Save to local preferences
    await _saveToPreferences();
    
    // Save to Firestore if user is logged in
    await _saveToFirestore();
  }
  
  /// Get currency symbol for the user's country
  String getCurrencySymbol() {
    switch (_currentCurrency) {
      case 'USD': return '\$';
      case 'EUR': return '€';
      case 'GBP': return '£';
      case 'JPY': return '¥';
      case 'INR': return '₹';
      case 'NGN': return '₦';
      case 'ZAR': return 'R';
      case 'CAD': return 'C\$';
      case 'AUD': return 'A\$';
      case 'BRL': return 'R\$';
      case 'MXN': return '\$';
      case 'CNY': return '¥';
      case 'EGP': return 'E£';
      case 'KES': return 'KSh';
      case 'GHS': return 'GH₵';
      case 'LKR': return 'LKR'; // Sri Lankan Rupee
      default: return 'LKR'; // Default to LKR instead of USD
    }
  }
  
  /// Format price with country's currency
  String formatPrice(double amount) {
    final symbol = getCurrencySymbol();
    return '$symbol${amount.toStringAsFixed(2)}';
  }
  
  /// Check if user is in the same country as a request
  bool isInSameCountry(String requestCountry) {
    return _currentCountryName?.toLowerCase() == requestCountry.toLowerCase();
  }
  
  /// Get Firestore query filter for user's country
  Query<Map<String, dynamic>> getCountryFilteredQuery(
    CollectionReference<Map<String, dynamic>> collection
  ) {
    try {
      if (_currentCountryName == null) {
        // If no country set, return all active requests (fallback)
        return collection
            .where('status', whereNotIn: ['completed', 'fulfilled'])
            .orderBy('createdAt', descending: true);
      }

      return collection
          .where('country', isEqualTo: _currentCountryName!)
          .where('status', whereNotIn: ['completed', 'fulfilled'])
          .orderBy('createdAt', descending: true);
    } on FirebaseException catch (e) {
      // Graceful fallback if composite index not yet created
      if (e.code == 'failed-precondition') {
        print('⚠️ Missing index for country+status query. Falling back to simpler query.');
        if (_currentCountryName != null) {
          return collection
              .where('country', isEqualTo: _currentCountryName!)
              .orderBy('createdAt', descending: true);
        }
        return collection.orderBy('createdAt', descending: true);
      }
      rethrow;
    }
  }
  
  /// Save country info to SharedPreferences
  Future<void> _saveToPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentCountryCode != null) {
      await prefs.setString(_countryCodeKey, _currentCountryCode!);
      await prefs.setString(_countryNameKey, _currentCountryName!);
      await prefs.setString(_phoneCodeKey, _currentPhoneCode!);
      await prefs.setString(_currencyKey, _currentCurrency!);
    }
  }
  
  /// Load country info from SharedPreferences
  Future<void> _loadFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _currentCountryCode = prefs.getString(_countryCodeKey);
    _currentCountryName = prefs.getString(_countryNameKey);
    _currentPhoneCode = prefs.getString(_phoneCodeKey);
    _currentCurrency = prefs.getString(_currencyKey);
  }
  
  /// Save country info to Firestore user profile
  Future<void> _saveToFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _currentCountryCode != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
          'countryCode': _currentCountryCode,
          'countryName': _currentCountryName,
          'phoneCode': _currentPhoneCode,
          'currency': _currentCurrency,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        print('Error saving country to Firestore: $e');
      }
    }
  }
  
  /// Load country info from Firestore user profile
  Future<void> _loadFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
            
        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            _currentCountryCode = data['countryCode'];
            _currentCountryName = data['countryName'];
            _currentPhoneCode = data['phoneCode'];
            _currentCurrency = data['currency'];
            
            // Update local preferences with Firestore data
            await _saveToPreferences();
          }
        }
      } catch (e) {
        print('Error loading country from Firestore: $e');
      }
    }
  }
  
  /// Clear all country data (useful for logout)
  Future<void> clearCountryData() async {
    _currentCountryCode = null;
    _currentCountryName = null;
    _currentPhoneCode = null;
    _currentCurrency = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_countryCodeKey);
    await prefs.remove(_countryNameKey);
    await prefs.remove(_phoneCodeKey);
    await prefs.remove(_currencyKey);
  }
}
