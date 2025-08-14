// Flutter Integration - Direct Firestore Approach
// Add this to your Flutter app

import 'package:cloud_firestore/cloud_firestore.dart';

class ModuleConfigService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get enabled modules for a specific country
  static Future<CountryModules?> getCountryModules(String countryCode) async {
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
      
      return CountryModules(
        success: true,
        countryCode: countryCode.toUpperCase(),
        modules: Map<String, bool>.from(data['modules'] ?? {}),
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
}

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
}

// Usage in your Flutter widget:
class CreateRequestScreen extends StatefulWidget {
  final String userCountry;
  
  const CreateRequestScreen({Key? key, this.userCountry = 'LK'}) : super(key: key);
  
  @override
  _CreateRequestScreenState createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  CountryModules? countryModules;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchModules();
  }

  Future<void> _fetchModules() async {
    try {
      final result = await ModuleConfigService.getCountryModules(widget.userCountry);
      setState(() {
        countryModules = result;
        isLoading = false;
      });
    } catch (error) {
      print('Error fetching modules: $error');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (countryModules == null || !countryModules!.success) {
      return const Center(child: Text('Error loading modules'));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Create New Request')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Create New Request',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // Only show enabled modules
          if (countryModules!.modules['item'] == true)
            _buildRequestOption(
              icon: Icons.shopping_bag,
              title: 'Item Request',
              subtitle: 'Request for products or items',
              onTap: () => _navigateToItemRequest(),
            ),
            
          if (countryModules!.modules['service'] == true)
            _buildRequestOption(
              icon: Icons.build,
              title: 'Service Request',
              subtitle: 'Request for services',
              onTap: () => _navigateToServiceRequest(),
            ),
            
          if (countryModules!.modules['delivery'] == true)
            _buildRequestOption(
              icon: Icons.local_shipping,
              title: 'Delivery Request',
              subtitle: 'Request for delivery services',
              onTap: () => _navigateToDeliveryRequest(),
            ),
            
          if (countryModules!.modules['rent'] == true)
            _buildRequestOption(
              icon: Icons.calendar_today,
              title: 'Rental Request',
              subtitle: 'Rent vehicles, equipment, or items',
              onTap: () => _navigateToRentalRequest(),
            ),
            
          if (countryModules!.modules['ride'] == true)
            _buildRequestOption(
              icon: Icons.directions_car,
              title: 'Ride Request',
              subtitle: 'Request for transportation',
              onTap: () => _navigateToRideRequest(),
            ),
            
          if (countryModules!.modules['price'] == true)
            _buildRequestOption(
              icon: Icons.attach_money,
              title: 'Price Request',
              subtitle: 'Request price quotes for items or services',
              onTap: () => _navigateToPriceRequest(),
            ),
        ],
      ),
    );
  }

  Widget _buildRequestOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 32),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  void _navigateToItemRequest() {
    // Navigate to item request screen
  }

  void _navigateToServiceRequest() {
    // Navigate to service request screen
  }

  void _navigateToDeliveryRequest() {
    // Navigate to delivery request screen
  }

  void _navigateToRentalRequest() {
    // Navigate to rental request screen
  }

  void _navigateToRideRequest() {
    // Navigate to ride request screen
  }

  void _navigateToPriceRequest() {
    // Navigate to price request screen
  }
}
