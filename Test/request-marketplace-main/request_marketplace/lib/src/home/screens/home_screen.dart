import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:request_marketplace/src/auth/screens/welcome_screen.dart';
import '../../models/request_model.dart';
import '../../requests/screens/create_item_request_screen.dart';
import '../../requests/screens/create_service_request_screen.dart';
import '../../requests/screens/create_ride_request_screen.dart';
import '../../requests/screens/create_rental_request_screen.dart';
import '../../requests/screens/create_delivery_request_screen.dart';
import '../../dashboard/screens/unified_dashboard_screen.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import 'package:request_marketplace/src/services/auth_service.dart';
import 'package:request_marketplace/src/services/notification_service.dart';
import 'package:request_marketplace/src/notifications/screens/notifications_screen.dart';
import '../../screens/price_comparison_screen.dart';
import '../../profiles/screens/edit_profile_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../screens/main_dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();
  UserModel? _user;
  bool _isLoading = true;
  int _unreadNotificationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      print('🏠 HomeScreen: Loading user data...');
      final userDoc = await _authService.getUserDetails();
      print('🏠 HomeScreen: User document exists: ${userDoc?.exists}');
      
      if (userDoc != null && userDoc.exists) {
        print('🏠 HomeScreen: User document data: ${userDoc.data()}');
        final userData = userDoc.data() as Map<String, dynamic>;
        print('🏠 HomeScreen: Display name from doc: ${userData['displayName']}');
        print('🏠 HomeScreen: Name from doc: ${userData['name']}');
        
        setState(() {
          _user = UserModel.fromFirestore(userDoc);
        });
        print('🏠 HomeScreen: User model created with displayName: ${_user?.displayName}');
      } else {
        print('🏠 HomeScreen: No user document found');
      }

      // Load notification count
      try {
        final count = await _notificationService.getUnreadNotificationCount();
        print('🏠 HomeScreen: Found $count unread notifications');
        setState(() {
          _unreadNotificationCount = count;
        });
      } catch (e) {
        print('🏠 HomeScreen: Error loading notification count: $e');
      }
    } catch (e) {
      print("🏠 HomeScreen: Error loading user data: $e");
      // Optionally show a snackbar or error message
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _navigateToPriceComparison() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PriceComparisonScreen(),
      ),
    );
  }

  Future<void> _signOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isLoading
            ? const Text('Loading...')
            : Text('Welcome, ${_user?.displayName ?? 'User'}!'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
                    ),
                  ).then((_) {
                    // Refresh notification count when returning
                    _loadUserData();
                  });
                },
              ),
              if (_unreadNotificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_unreadNotificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              child: _isLoading || _user == null
                  ? const Icon(Icons.person_outline)
                  : Text(_user!.displayName?.isNotEmpty == true ? _user!.displayName![0] : 'U'),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MainDashboardScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Request For',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // First row with 3 request types
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildRequestButton(context, 'assets/icons/item_icon.svg', 'Item', RequestType.item),
                          _buildRequestButton(context, 'assets/icons/service_icon.svg', 'Service', RequestType.service),
                          _buildRequestButton(context, 'assets/icons/ride_icon.svg', 'Ride', RequestType.ride),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Second row with 2 new request types
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildRequestButton(context, 'assets/icons/rental_icon.svg', 'Rental', RequestType.rental),
                          _buildRequestButton(context, 'assets/icons/delivery_icon.svg', 'Delivery', RequestType.delivery),
                        ],
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: _navigateToPriceComparison,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6750A4),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.compare_arrows_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Price',
                                    style: TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Request a price for any item you can find cheapest',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Recent Activity',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Placeholder for recent activity
                      Center(
                        child: Text(
                          'No recent activity.',
                          style: TextStyle(
                            color: AppTheme.textTertiary,
                            fontSize: 16,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildRequestButton(
      BuildContext context, String iconPath, String label, RequestType type) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            if (type == RequestType.item) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateItemRequestScreen(),
                ),
              );
            } else if (type == RequestType.service) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateServiceRequestScreen(),
                ),
              );
            } else if (type == RequestType.ride) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateRideRequestScreen(),
                ),
              );
            } else if (type == RequestType.rental) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateRentalRequestScreen(),
                ),
              );
            } else if (type == RequestType.delivery) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateDeliveryRequestScreen(),
                ),
              );
            }
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  spreadRadius: 0,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: SvgPicture.asset(
                iconPath,
                width: 48,
                height: 48,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label, 
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
