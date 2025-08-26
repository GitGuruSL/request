import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/service_manager.dart';
import '../../widgets/custom_logo.dart';
import '../../theme/glass_theme.dart';
import '../../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _controller.forward();

    // After animation, decide where to go based on auth + last tab
    _startNavigation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _startNavigation() async {
    // Ensure splash shows for ~2s while we do work
    final splashDelay = Future.delayed(const Duration(milliseconds: 2000));

    // Check auth and load last tab in parallel
    final authFuture = ServiceManager.instance.isAuthenticated();
    final prefsFuture = SharedPreferences.getInstance();

    final results = await Future.wait([authFuture, prefsFuture, splashDelay]);
    if (!mounted || _navigated) return;

    final bool isAuthed = results[0] as bool;
    final SharedPreferences prefs = results[1] as SharedPreferences;
    final int lastTab = prefs.getInt('last_tab_index') ?? 0;

    _navigated = true;
    if (isAuthed) {
      // Go to home/main with last tab restored
      Navigator.of(context).pushReplacementNamed(
        '/home',
        arguments: {'initialIndex': lastTab},
      );
    } else {
      Navigator.of(context).pushReplacementNamed('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassTheme.backgroundContainer(
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo with animation
                      CustomLogo.splash(),
                      const SizedBox(height: 24),
                      // App name
                      Text(
                        'Request',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Tagline
                      Text(
                        'Get what you need',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.textSecondary,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.of(context).pushNamed('/api-test');
          },
          backgroundColor: GlassTheme.colors.primaryBlue,
          foregroundColor: Colors.white,
          child: const Icon(Icons.api),
          tooltip: 'Test API',
        ),
      ),
    );
  }
}
