import 'package:flutter/material.dart';
import 'package:request_marketplace/src/auth/screens/welcome_screen.dart';
import 'package:request_marketplace/src/auth/screens/login_screen.dart';
import 'package:request_marketplace/src/drivers/screens/driver_registration_screen.dart' as legacy_driver;
import 'package:request_marketplace/src/profiles/screens/role_selection_screen.dart';
import 'package:request_marketplace/src/profiles/screens/business_registration_screen.dart';
import 'package:request_marketplace/src/profiles/screens/service_provider_setup_screen.dart';
import 'package:request_marketplace/src/profiles/screens/driver_registration_screen.dart';
import 'package:request_marketplace/src/profiles/screens/courier_registration_screen.dart';
import 'package:request_marketplace/src/profiles/screens/van_rental_registration_screen.dart';
import 'package:request_marketplace/src/navigation/main_navigation_screen.dart';
import 'package:request_marketplace/src/dashboard/screens/unified_dashboard_screen.dart';
import 'package:request_marketplace/src/settings/screens/settings_screen.dart';
import 'package:request_marketplace/src/settings/screens/about_screen.dart';
import 'package:request_marketplace/src/legal/screens/privacy_policy_screen.dart';
import 'package:request_marketplace/src/legal/screens/terms_of_service_screen.dart';
import 'package:request_marketplace/src/support/screens/help_support_screen.dart';
import 'package:request_marketplace/src/support/screens/faq_screen.dart';
import 'package:request_marketplace/src/safety/screens/safety_screen.dart';
import 'package:request_marketplace/src/screens/main_dashboard_screen.dart';
import 'package:request_marketplace/src/screens/activity_center_screen.dart';
import 'package:request_marketplace/src/screens/profile_center_screen.dart';
import 'package:request_marketplace/src/screens/simplified_profile_center_screen.dart';

class AppRoutes {
  static const String welcome = '/';
  static const String login = '/login';
  static const String driverRegistration = '/driver-registration';
  static const String roleSelection = '/role-selection';
  static const String businessSetup = '/business-setup';
  static const String serviceProviderSetup = '/service-provider-setup';
  static const String driverSetup = '/driver-setup';
  static const String courierRegistration = '/courier-registration';
  static const String vanRentalRegistration = '/van-rental-registration';
  static const String home = '/home';
  static const String dashboard = '/dashboard';
  static const String settings = '/settings';
  static const String about = '/about';
  static const String privacyPolicy = '/privacy-policy';
  static const String termsOfService = '/terms-of-service';
  static const String helpSupport = '/help-support';
  static const String faq = '/faq';
  static const String safety = '/safety';
  static const String cleanDashboard = '/clean-dashboard';
  static const String activityCenter = '/activity-center';
  static const String profileCenter = '/profile-center';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
      case login:
        final args = settings.arguments as Map<String, dynamic>?;
        final countryCode = args?['countryCode'] ?? '+94';
        return MaterialPageRoute(builder: (_) => LoginScreen(countryCode: countryCode));
      case driverRegistration:
        return MaterialPageRoute(builder: (_) => const legacy_driver.DriverRegistrationScreen());
      case roleSelection:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => RoleSelectionScreen(
            userId: args?['userId'] ?? '',
            userName: args?['userName'],
            userEmail: args?['userEmail'],
          ),
        );
      case businessSetup:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => BusinessRegistrationScreen(
            userId: args?['userId'] ?? '',
          ),
        );
      case serviceProviderSetup:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ServiceProviderSetupScreen(
            userId: args?['userId'] ?? '',
          ),
        );
      case driverSetup:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => DriverRegistrationScreen(
            userId: args?['userId'] ?? '',
          ),
        );
      case courierRegistration:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => CourierRegistrationScreen(
            userId: args?['userId'] ?? '',
          ),
        );
      case vanRentalRegistration:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => VanRentalRegistrationScreen(
            userId: args?['userId'] ?? '',
          ),
        );
      case home:
        return MaterialPageRoute(builder: (_) => const MainNavigationScreen());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const UnifiedDashboardScreen());
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      case '/about':
        return MaterialPageRoute(builder: (_) => const AboutScreen());
      case '/privacy-policy':
        return MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen());
      case '/terms-of-service':
        return MaterialPageRoute(builder: (_) => const TermsOfServiceScreen());
      case '/help-support':
        return MaterialPageRoute(builder: (_) => const HelpSupportScreen());
      case '/faq':
        return MaterialPageRoute(builder: (_) => const FAQScreen());
      case '/safety':
        return MaterialPageRoute(builder: (_) => const SafetyScreen());
      case cleanDashboard:
        return MaterialPageRoute(builder: (_) => const MainDashboardScreen());
      case activityCenter:
        return MaterialPageRoute(builder: (_) => const ActivityCenterScreen());
      case profileCenter:
        return MaterialPageRoute(builder: (_) => const SimplifiedProfileCenterScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Page not found'),
            ),
          ),
        );
    }
  }
}
