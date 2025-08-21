import 'package:flutter/material.dart';
// New service imports for REST API
import 'src/services/service_manager.dart';
import 'src/auth/screens/splash_screen.dart';
import 'src/auth/screens/welcome_screen.dart';
import 'src/auth/screens/login_screen.dart';
import 'src/auth/screens/otp_screen.dart';
import 'src/auth/screens/password_screen.dart';
import 'src/auth/screens/profile_completion_screen.dart';
import 'src/navigation/main_navigation_screen.dart';
import 'src/home/screens/home_screen.dart';
import 'src/home/screens/browse_requests_screen.dart';
import 'src/screens/browse_screen.dart';
import 'src/screens/pricing/price_comparison_screen.dart';
import 'src/screens/pricing/product_search_screen.dart';
import 'src/screens/pricing/business_pricing_dashboard.dart';
import 'src/screens/account_screen.dart';
import 'src/screens/requests/ride/create_ride_request_screen.dart';
import 'src/screens/unified_request_response/unified_response_edit_screen.dart';
import 'src/screens/driver_registration_screen.dart'; // Driver registration (was driver_verification)
import 'src/screens/driver_verification_screen.dart'; // Driver verification (was driver_documents_view)
import 'src/screens/business_verification_screen.dart';
import 'src/screens/business_registration_screen.dart';
import 'src/screens/delivery_verification_screen.dart';
import 'src/screens/verification_status_screen.dart';
import 'src/screens/role_management_screen.dart';
import 'src/screens/modern_menu_screen.dart';
import 'src/screens/content_page_screen.dart';
import 'src/screens/content_test_screen.dart';
import 'src/screens/api_test_screen.dart'; // API test screen
import 'src/models/master_product.dart';
import 'src/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize REST API services instead of Firebase
    await ServiceManager.instance.initialize();

    debugPrint('✅ REST API services initialized successfully');
  } catch (e) {
    debugPrint('❌ Service initialization failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Request Marketplace',
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(
              builder: (context) => const SplashScreen(),
            );
          case '/welcome':
            return MaterialPageRoute(
              builder: (context) => const WelcomeScreen(),
            );
          case '/login':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => LoginScreen(
                countryCode: args?['countryCode'] ?? 'LK',
                phoneCode: args?['phoneCode'],
              ),
            );
          case '/otp':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => OTPScreen(
                emailOrPhone: args?['emailOrPhone'] ?? '',
                isEmail: args?['isEmail'] ?? false,
                isNewUser: args?['isNewUser'] ?? false,
                countryCode: args?['countryCode'] ?? 'LK',
              ),
            );
          case '/password':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => PasswordScreen(
                isNewUser: args?['isNewUser'] ?? false,
                emailOrPhone: args?['emailOrPhone'] ?? '',
              ),
            );
          case '/profile':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => ProfileCompletionScreen(
                emailOrPhone: args?['emailOrPhone'],
                isNewUser: args?['isNewUser'],
                isEmail: args?['isEmail'],
                countryCode: args?['countryCode'],
                otpToken: args?['otpToken'],
              ),
            );
          case '/driver-registration':
            return MaterialPageRoute(
              builder: (context) => const DriverRegistrationScreen(),
            );
          case '/driver-verification':
            return MaterialPageRoute(
              builder: (context) => const DriverVerificationScreen(),
            );
          case '/business-verification':
            return MaterialPageRoute(
              builder: (context) => const BusinessVerificationScreen(),
            );
          case '/business-registration':
            return MaterialPageRoute(
              builder: (context) => const BusinessRegistrationScreen(),
            );
          case '/delivery-verification':
            return MaterialPageRoute(
              builder: (context) => const DeliveryVerificationScreen(),
            );
          case '/verification-status':
            return MaterialPageRoute(
              builder: (context) => const VerificationStatusScreen(),
            );
          case '/driver-documents-view':
            return MaterialPageRoute(
              builder: (context) => const DriverVerificationScreen(),
            );
          case '/role-management':
            return MaterialPageRoute(
              builder: (context) => const RoleManagementScreen(),
            );
          case '/api-test':
            return MaterialPageRoute(
              builder: (context) => const ApiTestScreen(),
            );
          case '/main-dashboard':
          case '/home':
            return MaterialPageRoute(
              builder: (context) => const MainNavigationScreen(),
            );
          case '/browse':
            return MaterialPageRoute(
              builder: (context) => const BrowseRequestsScreen(),
            );
          case '/browse-old':
            return MaterialPageRoute(
              builder: (context) => const BrowseScreen(),
            );
          case '/price':
            // Redirect to product search since price comparison needs a specific product
            return MaterialPageRoute(
              builder: (context) => const ProductSearchScreen(),
            );
          case '/pricing-search':
            return MaterialPageRoute(
              builder: (context) => const ProductSearchScreen(),
            );
          case '/pricing-comparison':
            final args = settings.arguments as Map<String, dynamic>?;
            final product = args?['product'] as MasterProduct?;
            if (product != null) {
              return MaterialPageRoute(
                builder: (context) => PriceComparisonScreen(product: product),
              );
            } else {
              // Redirect to search if no product provided
              return MaterialPageRoute(
                builder: (context) => const ProductSearchScreen(),
              );
            }
          case '/business-pricing':
            return MaterialPageRoute(
              builder: (context) => const BusinessPricingDashboard(),
            );
          case '/account':
            return MaterialPageRoute(
              builder: (context) => const AccountScreen(),
            );
          case '/create-ride-request':
            return MaterialPageRoute(
              builder: (context) => const CreateRideRequestScreen(),
            );
          case '/edit-response':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => UnifiedResponseEditScreen(
                response: args?['response'],
                request: args?['request'],
              ),
            );
          case '/menu':
            return MaterialPageRoute(
              builder: (context) => const ModernMenuScreen(),
            );
          case '/content-page':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => ContentPageScreen(
                slug: args?['slug'] ?? '',
                title: args?['title'],
              ),
            );
          case '/content-test':
            return MaterialPageRoute(
              builder: (context) => const ContentTestScreen(),
            );
          // Placeholder routes for menu items
          case '/saved':
          case '/marketplace':
          case '/memories':
          case '/groups':
          case '/reels':
          case '/find-friends':
          case '/feeds':
          case '/events':
          case '/avatars':
          case '/birthdays':
          case '/finds':
          case '/games':
          case '/messenger-kids':
          case '/help':
          case '/settings':
          case '/meta-apps':
          case '/search':
            return MaterialPageRoute(
              builder: (context) => _buildPlaceholderScreen(settings.name!),
            );
          default:
            return MaterialPageRoute(
              builder: (context) => const WelcomeScreen(),
            );
        }
      },
    );
  }

  Widget _buildPlaceholderScreen(String routeName) {
    final title =
        routeName.replaceAll('/', '').replaceAll('-', ' ').toUpperCase();
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF1976D2),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            Text(
              '$title - Coming Soon!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'This feature is under development',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
