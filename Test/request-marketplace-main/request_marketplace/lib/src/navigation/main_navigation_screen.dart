import 'package:flutter/material.dart';
import 'package:request_marketplace/src/home/screens/home_screen.dart';
import 'package:request_marketplace/src/browse/screens/browse_screen.dart';
import 'package:request_marketplace/src/screens/price_comparison_screen.dart';
import 'package:request_marketplace/src/chat/screens/conversations_screen.dart';
import 'package:request_marketplace/src/services/chat_service.dart';
import 'package:request_marketplace/src/account/screens/account_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final ChatService _chatService = ChatService();
  int _unreadCount = 0;

  static final List<Widget> _pages = <Widget>[
    const HomeScreen(),
    const BrowseScreen(),
    const PriceComparisonScreen(),
    const AccountScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final count = await _chatService.getUnreadMessageCount();
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    } catch (e) {
      print('Error loading unread count: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.explore_outlined),
            activeIcon: Icon(Icons.explore),
            label: 'Browse',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.compare_arrows_outlined),
            activeIcon: Icon(Icons.compare_arrows),
            label: 'Compare',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
      // Add floating action button for messages
      floatingActionButton: _unreadCount > 0
          ? Badge(
              label: Text(_unreadCount.toString()),
              child: FloatingActionButton(
                heroTag: "main_nav_fab_with_badge", // Unique hero tag
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ConversationsScreen(),
                    ),
                  ).then((_) => _loadUnreadCount()); // Refresh unread count when returning
                },
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: const Icon(Icons.chat_bubble, color: Colors.white),
              ),
            )
          : FloatingActionButton(
              heroTag: "main_nav_fab", // Unique hero tag
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ConversationsScreen(),
                  ),
                ).then((_) => _loadUnreadCount()); // Refresh unread count when returning
              },
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            ),
    );
  }
}
