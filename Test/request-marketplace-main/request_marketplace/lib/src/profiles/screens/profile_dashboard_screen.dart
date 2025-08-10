import 'package:flutter/material.dart';
import '../../models/enhanced_user_model.dart';
import '../../services/user_profile_service.dart';

class ProfileDashboardScreen extends StatefulWidget {
  final String userId;
  
  const ProfileDashboardScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ProfileDashboardScreen> createState() => _ProfileDashboardScreenState();
}

class _ProfileDashboardScreenState extends State<ProfileDashboardScreen> {
  final UserProfileService _userProfileService = UserProfileService();
  EnhancedUserModel? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _userProfileService.getEnhancedUserProfile(widget.userId);
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profiles'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUserProfile,
          ),
        ],
      ),
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userProfile == null
              ? const Center(
                  child: Text(
                    'Profile not found',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Basic Info Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.white,
                                  child: Text(
                                    _userProfile!.displayName?.isNotEmpty == true
                                        ? _userProfile!.displayName![0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6A1B9A),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _userProfile!.displayName?.isNotEmpty == true
                                            ? _userProfile!.displayName!
                                            : 'User',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        _userProfile!.email ?? 'No email',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      _buildUserTypeChip(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Active Roles Section
                      const Text(
                        'My Active Roles',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Role Cards
                      if (_userProfile!.businessProfile != null)
                        _buildBusinessProfileCard(),
                      
                      if (_userProfile!.serviceProviderProfile != null)
                        _buildServiceProviderCard(),
                        
      if (_userProfile!.driverProfile != null)
        _buildDriverProfileCard(),

      if (_userProfile!.courierProfile != null)
        _buildCourierProfileCard(),
        
      if (_userProfile!.vanRentalProfile != null)
        _buildVanRentalProfileCard(),

      if (_userProfile!.consumerProfile != null)
        _buildConsumerProfileCard(),                      // Add Role Button if not all roles are active
                      const SizedBox(height: 24),
                      _buildAddRoleSection(),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: "profile_dashboard_fab", // Unique hero tag
        onPressed: () {
          // Navigate to role selection to add more roles
          Navigator.pushNamed(
            context,
            '/role-selection',
            arguments: {'userId': widget.userId, 'isAddingRole': true},
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Role'),
        backgroundColor: const Color(0xFF6A1B9A),
      ),
    );
  }

  Widget _buildUserTypeChip() {
    String typeText = 'Consumer'; // Default
    Color color = Colors.blue;

    if (_userProfile!.primaryType == UserType.business) {
      typeText = 'Business';
      color = Colors.green;
    } else if (_userProfile!.primaryType == UserType.serviceProvider) {
      typeText = 'Service Provider';
      color = Colors.orange;
    } else if (_userProfile!.primaryType == UserType.driver) {
      typeText = 'Driver';
      color = Colors.orange;
    } else if (_userProfile!.primaryType == UserType.courier) {
      typeText = 'Courier';
      color = Colors.teal;
    } else if (_userProfile!.primaryType == UserType.vanRental) {
      typeText = 'Van Rental';
      color = Colors.indigo;
    } else if (_userProfile!.primaryType == UserType.hybrid) {
      typeText = 'Multi-Role User';
      color = Colors.purple;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        typeText,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildBusinessProfileCard() {
    final business = _userProfile!.businessProfile!;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.business, color: Colors.green[700]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        business.businessName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        business.businessType.name.toUpperCase(),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                _buildVerificationBadge(business.verificationStatus),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              business.description,
              style: const TextStyle(color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber[600], size: 16),
                Text(' ${business.averageRating.toStringAsFixed(1)}'),
                const SizedBox(width: 16),
                Icon(Icons.reviews, color: Colors.grey[600], size: 16),
                Text(' ${business.totalReviews} reviews'),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to business management
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Business management coming soon!')),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('Manage Business'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[50],
                foregroundColor: Colors.green[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceProviderCard() {
    final provider = _userProfile!.serviceProviderProfile!;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.handyman, color: Colors.blue[700]),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Service Provider',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Professional Services',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                _buildVerificationBadge(provider.verificationStatus),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              provider.description,
              style: const TextStyle(color: Colors.grey),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            if (provider.skills.isNotEmpty)
              Wrap(
                spacing: 4,
                children: provider.skills.take(3).map((skill) {
                  return Chip(
                    label: Text(skill),
                    labelStyle: const TextStyle(fontSize: 10),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber[600], size: 16),
                Text(' ${provider.averageRating.toStringAsFixed(1)}'),
                const SizedBox(width: 16),
                Icon(Icons.work, color: Colors.grey[600], size: 16),
                Text(' ${provider.completedJobs} jobs'),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to service provider management
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Service management coming soon!')),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('Manage Services'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[50],
                foregroundColor: Colors.blue[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverProfileCard() {
    final driver = _userProfile!.driverProfile!;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.directions_car, color: Colors.orange[700]),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Driver',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Transportation Services',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                _buildVerificationBadge(driver.verificationStatus),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'License: ${driver.licenseNumber}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: driver.isOnline ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    driver.isOnline ? 'Online' : 'Offline',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.local_taxi, color: Colors.grey[600], size: 16),
                Text(' ${driver.vehicleIds.length} vehicles'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber[600], size: 16),
                Text(' ${driver.averageRating.toStringAsFixed(1)}'),
                const SizedBox(width: 16),
                Icon(Icons.route, color: Colors.grey[600], size: 16),
                Text(' ${driver.completedRides} rides'),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to driver management
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Driver management coming soon!')),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('Manage Driving'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[50],
                foregroundColor: Colors.orange[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourierProfileCard() {
    final courier = _userProfile!.courierProfile!;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.delivery_dining, color: Colors.teal[700]),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Courier',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Delivery Services',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                _buildVerificationBadge(courier.verificationStatus),
              ],
            ),
            const SizedBox(height: 12),
            if (courier.vehicleType != null)
              Text(
                'Vehicle: ${courier.vehicleType} ${courier.vehicleRegistration ?? ''}',
                style: const TextStyle(color: Colors.grey),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: courier.isOnline ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    courier.isOnline ? 'Online' : 'Offline',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.location_city, color: Colors.grey[600], size: 16),
                Text(' ${courier.serviceAreas.length} areas'),
                const SizedBox(width: 16),
                if (courier.canHandleCOD) ...[
                  Icon(Icons.money, color: Colors.green[600], size: 16),
                  const Text(' COD', style: TextStyle(fontSize: 12)),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber[600], size: 16),
                Text(' ${courier.averageRating.toStringAsFixed(1)}'),
                const SizedBox(width: 16),
                Icon(Icons.local_shipping, color: Colors.grey[600], size: 16),
                Text(' ${courier.completedDeliveries} deliveries'),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to courier management
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Courier management coming soon!')),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('Manage Delivery'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[50],
                foregroundColor: Colors.teal[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVanRentalProfileCard() {
    final rental = _userProfile!.vanRentalProfile!;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.airport_shuttle, color: Colors.indigo[700]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rental.businessName.isNotEmpty ? rental.businessName : 'Van Rental',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'Vehicle Rental Services',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                _buildVerificationBadge(rental.verificationStatus),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Location: ${rental.operatingLocation}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.local_taxi, color: Colors.grey[600], size: 16),
                Text(' ${rental.vehicleIds.length} vehicles'),
                const SizedBox(width: 16),
                Icon(Icons.location_city, color: Colors.grey[600], size: 16),
                Text(' ${rental.serviceAreas.length} areas'),
                const SizedBox(width: 16),
                if (rental.acceptsDeposit) ...[
                  Icon(Icons.security, color: Colors.blue[600], size: 16),
                  Text(' ${rental.securityDepositPercent.toInt()}% deposit'),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber[600], size: 16),
                Text(' ${rental.averageRating.toStringAsFixed(1)}'),
                const SizedBox(width: 16),
                Icon(Icons.event_available, color: Colors.grey[600], size: 16),
                Text(' ${rental.completedRentals} rentals'),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to van rental management
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Van rental management coming soon!')),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('Manage Rentals'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[50],
                foregroundColor: Colors.indigo[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConsumerProfileCard() {
    final consumer = _userProfile!.consumerProfile!;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.person, color: Colors.purple[700]),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Consumer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Request Services & Products',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.shopping_cart, color: Colors.grey[600], size: 16),
                Text(' ${consumer.totalRequests} requests'),
                const SizedBox(width: 16),
                Icon(Icons.favorite, color: Colors.grey[600], size: 16),
                Text(' ${consumer.favoriteCategories.length} favorites'),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to consumer settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Consumer settings coming soon!')),
                );
              },
              icon: const Icon(Icons.settings),
              label: const Text('Consumer Settings'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple[50],
                foregroundColor: Colors.purple[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationBadge(VerificationStatus status) {
    IconData icon;
    Color color;
    String text;

    switch (status) {
      case VerificationStatus.verified:
        icon = Icons.verified;
        color = Colors.green;
        text = 'Verified';
        break;
      case VerificationStatus.pending:
        icon = Icons.pending;
        color = Colors.orange;
        text = 'Pending';
        break;
      case VerificationStatus.rejected:
        icon = Icons.cancel;
        color = Colors.red;
        text = 'Rejected';
        break;
      case VerificationStatus.notRequired:
        icon = Icons.info;
        color = Colors.grey;
        text = 'Not Required';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildAddRoleSection() {
    final hasAllRoles = _userProfile!.businessProfile != null &&
        _userProfile!.serviceProviderProfile != null &&
        _userProfile!.driverProfile != null &&
        _userProfile!.courierProfile != null &&
        _userProfile!.vanRentalProfile != null;

    if (hasAllRoles) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.add_circle_outline, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              'Want to earn more?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Register as a service provider and start earning from multiple services.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            // Available service options
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (_userProfile!.businessProfile == null)
                  _buildAddServiceChip('Business', Icons.business, Colors.green, UserType.business),
                if (_userProfile!.serviceProviderProfile == null)
                  _buildAddServiceChip('Services', Icons.handyman, Colors.blue, UserType.serviceProvider),
                if (_userProfile!.driverProfile == null)
                  _buildAddServiceChip('Driving', Icons.directions_car, Colors.orange, UserType.driver),
                if (_userProfile!.courierProfile == null)
                  _buildAddServiceChip('Delivery', Icons.delivery_dining, Colors.teal, UserType.courier),
                if (_userProfile!.vanRentalProfile == null)
                  _buildAddServiceChip('Van Rental', Icons.airport_shuttle, Colors.indigo, UserType.vanRental),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddServiceChip(String label, IconData icon, Color color, UserType type) {
    return ActionChip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(
        'Add $label',
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
      backgroundColor: color.withOpacity(0.1),
      onPressed: () {
        _showServiceRegistrationDialog(type);
      },
    );
  }

  void _showServiceRegistrationDialog(UserType serviceType) {
    String title = '';
    String description = '';
    IconData icon = Icons.work;
    Color color = Colors.blue;

    switch (serviceType) {
      case UserType.business:
        title = 'Register Your Business';
        description = 'Start selling products and services to customers in your area.';
        icon = Icons.business;
        color = Colors.green;
        break;
      case UserType.serviceProvider:
        title = 'Become a Service Provider';
        description = 'Offer your skills and expertise to customers who need your services.';
        icon = Icons.handyman;
        color = Colors.blue;
        break;
      case UserType.driver:
        title = 'Register as a Driver';
        description = 'Provide ride services and earn money driving customers around.';
        icon = Icons.directions_car;
        color = Colors.orange;
        break;
      case UserType.courier:
        title = 'Join as a Courier';
        description = 'Deliver packages and earn money providing delivery services.';
        icon = Icons.delivery_dining;
        color = Colors.teal;
        break;
      case UserType.vanRental:
        title = 'Start Van Rental Business';
        description = 'Rent out your vehicles and earn passive income from rentals.';
        icon = Icons.airport_shuttle;
        color = Colors.indigo;
        break;
      default:
        return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Text(title),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(description),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'You\'ll need to complete verification to start earning.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Maybe Later'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToServiceRegistration(serviceType);
              },
              style: ElevatedButton.styleFrom(backgroundColor: color),
              child: const Text('Get Started'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToServiceRegistration(UserType serviceType) {
    String route = '';
    Map<String, dynamic> arguments = {
      'userId': widget.userId,
      'serviceType': serviceType.name,
    };

    switch (serviceType) {
      case UserType.business:
        // Navigate to business registration
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Business registration coming soon!')),
        );
        break;
      case UserType.serviceProvider:
        // Navigate to service provider registration
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service provider registration coming soon!')),
        );
        break;
      case UserType.driver:
        // Navigate to driver registration
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Driver registration coming soon!')),
        );
        break;
      case UserType.courier:
        // Navigate to courier registration
        route = '/courier-registration';
        break;
      case UserType.vanRental:
        // Navigate to van rental registration
        route = '/van-rental-registration';
        break;
      default:
        return;
    }

    if (route.isNotEmpty) {
      Navigator.pushNamed(context, route, arguments: arguments).then((_) {
        // Refresh profile after registration
        _loadUserProfile();
      });
    }
  }
}
