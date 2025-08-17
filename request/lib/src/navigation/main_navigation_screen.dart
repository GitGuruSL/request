import 'package:flutter/material.dart';
import '../home/screens/home_screen.dart';
import '../home/screens/browse_requests_screen.dart';
import '../screens/pricing/product_search_screen.dart';
import '../screens/modern_menu_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  late final List<_NavigationItem> _navigationItems = [
    _NavigationItem(
      screen: const HomeScreen(),
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
    ),
    _NavigationItem(
      screen: const BrowseRequestsScreen(),
      icon: Icons.search_outlined,
      activeIcon: Icons.search,
      label: 'Browse',
    ),
    _NavigationItem(
      screen: const ProductSearchScreen(),
      icon: Icons.local_offer_outlined,
      activeIcon: Icons.local_offer,
      label: 'Prices',
    ),
    _NavigationItem(
      screen: const ModernMenuScreen(),
      icon: Icons.menu_outlined,
      activeIcon: Icons.menu,
      label: 'Menu',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _navigationItems[_currentIndex].screen,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        elevation: 8,
        items: _navigationItems
            .map((item) => BottomNavigationBarItem(
                  icon: Icon(item.icon, size: 28),
                  activeIcon: Icon(item.activeIcon, size: 28),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }
}

class _NavigationItem {
  final Widget screen;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavigationItem({
    required this.screen,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
