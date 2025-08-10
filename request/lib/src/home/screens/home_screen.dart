import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/country_service.dart';
import '../../services/auth_service.dart';
import '../../models/request_model.dart';
import '../../screens/requests/rental_request_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedCountry;
  String? _currencySymbol;
  List<RequestModel> _requests = [];
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
      
      // Load country-filtered requests
      await _loadRequests();
    } catch (e) {
      print('Error loading country data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRequests() async {
    try {
      // Get country-filtered query
      Query? query = CountryService.instance.getCountryFilteredQuery(
        FirebaseFirestore.instance.collection('requests')
      );
      
      if (query != null) {
        final querySnapshot = await query.limit(20).get();
        _requests = querySnapshot.docs
            .map((doc) => RequestModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      print('Error loading requests: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Light subtle background
      appBar: AppBar(
        backgroundColor: Colors.grey[100], // Subtle grey background
        foregroundColor: Colors.grey[800], // Dark grey text
        elevation: 1, // Subtle shadow
        automaticallyImplyLeading: false, // Remove back button
        title: Row(
          children: [
            // User Name on the left
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getUserName(),
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_selectedCountry != null)
                    Text(
                      '$_selectedCountry $_currencySymbol',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                ],
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
          : Column(
              children: [
                // Country Info Card
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Location',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              _selectedCountry ?? 'No country selected',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const Spacer(),
                            if (_currencySymbol != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _currencySymbol!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Showing requests from your country only',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Requests List
                Expanded(
                  child: _requests.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No requests found',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _selectedCountry != null
                                    ? 'No requests available in $_selectedCountry yet'
                                    : 'Please select a country first',
                                style: Theme.of(context).textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _requests.length,
                          itemBuilder: (context, index) {
                            final request = _requests[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  child: Icon(_getRequestIcon(request.type.name)),
                                ),
                                title: Text(request.title),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(request.description),
                                    const SizedBox(height: 4),
                                    if (request.budget != null)
                                      Text(
                                        'Budget: ${CountryService.instance.formatPrice(request.budget!)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.location_on, size: 16),
                                    Text(
                                      request.location?.city ?? 'Location not set',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  // Navigate to request detail
                                  _showRequestDetail(request);
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewRequest,
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
      ),
    );
  }

  IconData _getRequestIcon(String type) {
    switch (type.toLowerCase()) {
      case 'item':
        return Icons.shopping_bag;
      case 'service':
        return Icons.build;
      case 'ride':
        return Icons.directions_car;
      case 'delivery':
        return Icons.local_shipping;
      case 'rental':
        return Icons.key;
      default:
        return Icons.help_outline;
    }
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
                        _showComingSoon('Item Request');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.build),
                      title: const Text('Service Request'),
                      subtitle: const Text('Request for services'),
                      onTap: () {
                        Navigator.pop(context);
                        _showComingSoon('Service Request');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.directions_car),
                      title: const Text('Ride Request'),
                      subtitle: const Text('Request for transportation'),
                      onTap: () {
                        Navigator.pop(context);
                        _showComingSoon('Ride Request');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.local_shipping),
                      title: const Text('Delivery Request'),
                      subtitle: const Text('Request for delivery services'),
                      onTap: () {
                        Navigator.pop(context);
                        _showComingSoon('Delivery Request');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.key),
                      title: const Text('Rental Request'),
                      subtitle: const Text('Rent vehicles, equipment, or items'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RentalRequestScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.compare_arrows),
                      title: const Text('Price Request'),
                      subtitle: const Text('Request price quotes for items or services'),
                      onTap: () {
                        Navigator.pop(context);
                        _showComingSoon('Price Request');
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

  void _showRequestDetail(RequestModel request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(request.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${request.type}'),
            const SizedBox(height: 8),
            Text('Description: ${request.description}'),
            const SizedBox(height: 8),
            if (request.budget != null)
              Text('Budget: ${CountryService.instance.formatPrice(request.budget!)}'),
            const SizedBox(height: 8),
            Text('Location: ${request.location?.city ?? 'Not specified'}'),
            const SizedBox(height: 8),
            Text('Status: ${request.status}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showComingSoon('Respond to Request');
            },
            child: const Text('Respond'),
          ),
        ],
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
