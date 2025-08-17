import 'package:flutter/material.dart';
import '../../services/rest_auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserModel? _userData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await RestAuthService.instance.isAuthenticated();
    setState(() {
      _userData = RestAuthService.instance.currentUser;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final name = _userData?.displayName ?? _userData?.email ?? 'User';
    return Scaffold(
      appBar: AppBar(title: const Text('Request Marketplace')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Welcome, $name',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.add_box_outlined),
              title: const Text('Create a Request'),
              subtitle: const Text('Post something you need'),
              onTap: () {},
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Browse Requests'),
              subtitle: const Text('See what others need'),
              onTap: () => Navigator.pushNamed(context, '/browse'),
            ),
          ),
        ],
      ),
    );
  }
}
