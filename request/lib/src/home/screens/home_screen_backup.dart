import 'package:flutter/material.dart';
import '../../services/rest_auth_service.dart';
// Removed category/city/list imports for simplified home UI

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  List<_RequestType> get _requestTypes => [
        _RequestType(
          type: 'item',
          title: 'Item Request',
          subtitle: 'Request for products or items',
          icon: Icons.shopping_bag_outlined,
          color: Color(0xFFFF8A3D),
        ),
        _RequestType(
          type: 'service',
          title: 'Service Request',
          subtitle: 'Request for services',
          icon: Icons.build_outlined,
          color: Color(0xFF22B8A7),
        ),
        _RequestType(
          type: 'rental',
          title: 'Rental Request',
          subtitle: 'Rent vehicles, equipment, or items',
          icon: Icons.vpn_key_outlined,
          color: Color(0xFF37A7FF),
        ),
        _RequestType(
          type: 'delivery',
          title: 'Delivery Request',
          subtitle: 'Request for delivery services',
          icon: Icons.local_shipping_outlined,
          color: Color(0xFF3BB273),
        ),
        _RequestType(
          type: 'ride',
          title: 'Ride Request',
          subtitle: 'Request for transportation',
          icon: Icons.directions_car_filled_outlined,
          color: Color(0xFFFFC84A),
        ),
        _RequestType(
          type: 'price',
          title: 'Price Request',
          subtitle: 'Request price quotes for items or services',
          icon: Icons.price_check_outlined,
          color: Color(0xFFB085F5),
        ),
      ];

  String _greetingName() {
    final user = RestAuthService.instance.currentUser;
    if (user == null) return '';
    if (user.firstName != null && user.firstName!.trim().isNotEmpty) {
      return _capitalize(user.firstName!.trim());
    }
    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      final first = user.displayName!.trim().split(RegExp(r'\s+')).first;
      if (first.isNotEmpty) return _capitalize(first);
    }
    final emailLocal = user.email.split('@').first;
    if (emailLocal.isEmpty) return '';
    final token = emailLocal.split(RegExp(r'[._-]+')).firstWhere(
          (p) => p.isNotEmpty,
          orElse: () => emailLocal,
        );
    return _capitalize(token);
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    if (s.length == 1) return s.toUpperCase();
    return s[0].toUpperCase() + s.substring(1);
  }

  void _onCreateRequest() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final items = _requestTypes;
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Create New Request',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    ...items.map(
                      (it) => _RequestTypeTile(
                        icon: it.icon,
                        iconColor: it.color,
                        title: it.title,
                        subtitle: it.subtitle,
                        onTap: () => _selectRequestType(it.type),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _selectRequestType(String type) {
    Navigator.of(context).pop();
    // TODO: Navigate to actual creation form based on type
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Selected: $type request')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = RestAuthService.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        // No title per new design; greeting moves to banner in body
        title: const SizedBox.shrink(),
        actions: [
          IconButton(
              tooltip: 'Notifications',
              onPressed: () {},
              icon: const Icon(Icons.notifications_none)),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () {},
              child: CircleAvatar(
                radius: 18,
                child: Text(
                  (user?.displayName?.isNotEmpty == true
                          ? user!.displayName![0]
                          : user?.email.isNotEmpty == true
                              ? user!.email[0]
                              : 'U')
                      .toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Banner
              Text(
                'Hello, ${_greetingName()}!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              // Subtitle removed (was learning-focused, not relevant to requests app)
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _onCreateRequest,
        tooltip: 'New Request',
        child: const Icon(Icons.add),
      ),
    );
  }

  // (Reserved for future expansion)
}

class _RequestTypeTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _RequestTypeTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}

class _RequestType {
  final String type;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  const _RequestType({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}
