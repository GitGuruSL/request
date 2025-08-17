import 'package:flutter/material.dart';
import '../../services/rest_auth_service.dart';
import '../../screens/unified_request_response/unified_request_create_screen.dart';
import '../../models/enhanced_user_model.dart' show RequestType;
import '../../screens/requests/ride/create_ride_request_screen.dart';
import '../../screens/requests/create_price_request_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
          color: const Color(0xFFFF8A3D),
        ),
        _RequestType(
          type: 'service',
          title: 'Service Request',
          subtitle: 'Request for services',
          icon: Icons.build_outlined,
          color: const Color(0xFF22B8A7),
        ),
        _RequestType(
          type: 'rental',
          title: 'Rental Request',
          subtitle: 'Rent vehicles, equipment, or items',
          icon: Icons.vpn_key_outlined,
          color: const Color(0xFF37A7FF),
        ),
        _RequestType(
          type: 'delivery',
          title: 'Delivery Request',
          subtitle: 'Request for delivery services',
          icon: Icons.local_shipping_outlined,
          color: const Color(0xFF3BB273),
        ),
        _RequestType(
          type: 'ride',
          title: 'Ride Request',
          subtitle: 'Request for transportation',
          icon: Icons.directions_car_filled_outlined,
          color: const Color(0xFFFFC84A),
        ),
        _RequestType(
          type: 'price',
          title: 'Price Request',
          subtitle: 'Request price quotes for items or services',
          icon: Icons.price_check_outlined,
          color: const Color(0xFFB085F5),
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

  String _capitalize(String s) => s.isEmpty
      ? s
      : s.length == 1
          ? s.toUpperCase()
          : s[0].toUpperCase() + s.substring(1);

  void _openCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    // Limit height to 80% of screen; rest scrolls
                    maxHeight: MediaQuery.of(ctx).size.height * 0.8,
                  ),
                  child: SingleChildScrollView(
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
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
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
            ),
          ),
        );
      },
    );
  }

  void _selectRequestType(String type) {
    Navigator.of(context).pop();
    switch (type) {
      case 'item':
        _openUnified(RequestType.item);
        break;
      case 'service':
        _openUnified(RequestType.service);
        break;
      case 'rental':
        _openUnified(RequestType.rental);
        break;
      case 'delivery':
        _openUnified(RequestType.delivery);
        break;
      case 'ride':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateRideRequestScreen()),
        );
        break;
      case 'price':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreatePriceRequestScreen()),
        );
        break;
    }
  }

  void _openUnified(RequestType type) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UnifiedRequestCreateScreen(initialType: type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = RestAuthService.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const SizedBox.shrink(),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
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
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Hello, ${_greetingName()}!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateSheet,
        tooltip: 'New Request',
        child: const Icon(Icons.add),
      ),
    );
  }
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
