import 'package:flutter/material.dart';
import '../../services/country_service.dart';
import '../../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedCountry;
  String? _currencySymbol;
  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadCountryData();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      _userData = await AuthService.instance.getCurrentUserData();
      setState(() {});
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadCountryData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get user's selected country
      _selectedCountry = await CountryService.instance.getUserCountry();
      _currencySymbol = CountryService.instance.getCurrencySymbol();
    } catch (e) {
      print('Error loading country data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        foregroundColor: Colors.grey[800],
        elevation: 1,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // User Name on the left
            Expanded(
              child: Text(
                _getUserName(),
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // Notification and Profile on the right
            IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: Colors.grey[700],
              ),
              onPressed: _showNotifications,
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _showProfileMenu,
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                backgroundImage: _userData?['profilePicture'] != null 
                    ? NetworkImage(_userData!['profilePicture'])
                    : null,
                child: _userData?['profilePicture'] == null 
                    ? Icon(
                        Icons.person,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 16),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : const Center(
              child: Text(
                'Home Screen - Coming Soon',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                  color: Colors.grey,
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewRequest,
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
      ),
    );
  }

  void _createNewRequest() {
    if (_selectedCountry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a country first'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Create New Request',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.shopping_bag),
                      title: const Text('Item Request'),
                      subtitle: const Text('Request for products or items'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/create-item-request');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.build),
                      title: const Text('Service Request'),
                      subtitle: const Text('Request for services'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/create-service-request');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.directions_car),
                      title: const Text('Ride Request'),
                      subtitle: const Text('Request for transportation'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/create-ride-request');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.local_shipping),
                      title: const Text('Delivery Request'),
                      subtitle: const Text('Request for delivery services'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/create-delivery-request');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.key),
                      title: const Text('Rental Request'),
                      subtitle: const Text('Rent vehicles, equipment, or items'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/create-rental-request');
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon!'),
        action: SnackBarAction(
          label: 'OK',
          onPressed: () {},
        ),
      ),
    );
  }

  String _getUserName() {
    final currentUser = AuthService.instance.currentUser;
    
    // Try to get name from user data first
    if (_userData != null) {
      if (_userData!['fullName'] != null && _userData!['fullName'].toString().isNotEmpty) {
        return _userData!['fullName'];
      }
      if (_userData!['name'] != null && _userData!['name'].toString().isNotEmpty) {
        return _userData!['name'];
      }
    }
    
    // Fallback to Firebase Auth display name
    if (currentUser?.displayName != null && currentUser!.displayName!.isNotEmpty) {
      return currentUser.displayName!;
    }
    
    // Fallback to email/phone
    if (currentUser?.email != null) {
      return currentUser!.email!.split('@').first;
    }
    
    if (currentUser?.phoneNumber != null) {
      return currentUser!.phoneNumber!;
    }
    
    return 'Guest User';
  }

  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: const Text('No new notifications at this time.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon('Profile');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon('Settings');
              },
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Change Country'),
              onTap: () {
                Navigator.pop(context);
                _changeCountry();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeCountry() async {
    // Navigate back to welcome screen to change country
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Country'),
        content: const Text('Do you want to change your country? This will take you back to the welcome screen.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/welcome');
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _logout() async {
    try {
      await AuthService.instance.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/welcome');
      }
    } catch (e) {
      print('Error during logout: $e');
    }
  }
}
