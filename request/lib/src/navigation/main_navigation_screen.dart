import 'package:flutter/material.dart';
import '../home/screens/home_screen.dart';
import '../screens/browse_screen.dart';
import '../screens/pricing/product_search_screen.dart';
import '../screens/messaging/conversations_list_screen.dart';
import '../screens/account_screen.dart';
import '../services/country_service.dart';
import '../services/module_service.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  CountryModules? _countryModules;
  List<_NavigationItem> _navigationItems = [];
  bool _isLoadingModules = true;

  // Navigation item model
  static const List<_NavigationItem> _allNavigationItems = [
    _NavigationItem(
      screen: HomeScreen(),
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
      requiredModule: null, // Always shown
    ),
    _NavigationItem(
      screen: BrowseScreen(),
      icon: Icons.search_outlined,
      activeIcon: Icons.search,
      label: 'Browse',
      requiredModule: null, // Browse is available if any module is enabled
    ),
    _NavigationItem(
      screen: ProductSearchScreen(),
      icon: Icons.price_check_outlined,
      activeIcon: Icons.price_check,
      label: 'Prices',
      requiredModule: 'price', // Only shown if price module is enabled
    ),
    _NavigationItem(
      screen: ConversationsListScreen(),
      icon: Icons.message_outlined,
      activeIcon: Icons.message,
      label: 'Messages',
      requiredModule: null, // Always shown
    ),
    _NavigationItem(
      screen: AccountScreen(),
      icon: Icons.account_circle_outlined,
      activeIcon: Icons.account_circle,
      label: 'Account',
      requiredModule: null, // Always shown
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadModules();
  }

  Future<void> _loadModules() async {
    try {
      final countryCode = CountryService.instance.countryCode;
      if (countryCode != null) {
        _countryModules = await ModuleService.getCountryModules(countryCode);
        _buildNavigationItems();
      } else {
        // Fallback: show all items if no country is set
        _navigationItems = _allNavigationItems.toList();
      }
    } catch (e) {
      print('Error loading modules for navigation: $e');
      // Fallback: show all items on error
      _navigationItems = _allNavigationItems.toList();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingModules = false;
        });
      }
    }
  }

  void _buildNavigationItems() {
    List<_NavigationItem> enabledItems = [];
    
    for (final item in _allNavigationItems) {
      bool shouldShow = false;
      
      if (item.requiredModule == null) {
        // Always show items that don't require a specific module
        shouldShow = true;
      } else {
        // Check if the required module is enabled
        shouldShow = _countryModules?.isModuleEnabled(item.requiredModule!) ?? false;
      }
      
      if (shouldShow) {
        enabledItems.add(item);
      }
    }
    
    _navigationItems = enabledItems;
    
    // Adjust current index if needed
    if (_currentIndex >= _navigationItems.length) {
      _currentIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingModules) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: _navigationItems.isNotEmpty 
          ? _navigationItems[_currentIndex].screen 
          : const Center(child: Text('No modules available')),
      bottomNavigationBar: _navigationItems.length > 1 ? BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: _navigationItems.map((item) => BottomNavigationBarItem(
          icon: Icon(item.icon),
          activeIcon: Icon(item.activeIcon),
          label: item.label,
        )).toList(),
      ) : null,
    );
  }
}

// Navigation item model
class _NavigationItem {
  final Widget screen;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String? requiredModule;

  const _NavigationItem({
    required this.screen,
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.requiredModule,
  });
}
