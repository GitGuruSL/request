import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'src/auth/screens/splash_screen.dart';
import 'src/auth/screens/welcome_screen.dart';
import 'src/auth/screens/login_screen.dart';
import 'src/auth/screens/otp_screen.dart';
import 'src/auth/screens/password_screen.dart';
import 'src/auth/screens/profile_completion_screen.dart';
import 'src/home/screens/home_screen.dart';
import 'src/navigation/main_navigation_screen.dart';
import 'src/screens/browse_screen.dart';
import 'src/screens/price_comparison_screen.dart';
import 'src/screens/account_screen.dart';
import 'src/screens/requests/item/create_item_request_screen.dart';
import 'src/screens/requests/service/create_service_request_screen.dart';
import 'src/screens/requests/ride/create_ride_request_screen.dart';
import 'src/screens/requests/delivery/create_delivery_request_screen.dart';
import 'src/screens/requests/rent/create_rent_request_screen.dart';
import 'src/services/country_service.dart';
import 'src/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await CountryService.instance.initialize();
  } catch (e) {
    print('Initialization failed: $e');
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
            return MaterialPageRoute(builder: (context) => const SplashScreen());
          case '/welcome':
            return MaterialPageRoute(builder: (context) => const WelcomeScreen());
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
                verificationId: args?['verificationId'],
                emailOrPhone: args?['phoneNumber'],
                isEmail: false,
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
            return MaterialPageRoute(builder: (context) => const ProfileCompletionScreen());
          case '/home':
            return MaterialPageRoute(builder: (context) => const MainNavigationScreen());
          case '/browse':
            return MaterialPageRoute(builder: (context) => const BrowseScreen());
          case '/price':
            return MaterialPageRoute(builder: (context) => const PriceComparisonScreen());
          case '/account':
            return MaterialPageRoute(builder: (context) => const AccountScreen());
          case '/create-item-request':
            return MaterialPageRoute(builder: (context) => const CreateItemRequestScreen());
          case '/create-service-request':
            return MaterialPageRoute(builder: (context) => const CreateServiceRequestScreen());
          case '/create-ride-request':
            return MaterialPageRoute(builder: (context) => const CreateRideRequestScreen());
          case '/create-delivery-request':
            return MaterialPageRoute(builder: (context) => const CreateDeliveryRequestScreen());
          case '/create-rental-request':
            return MaterialPageRoute(builder: (context) => const CreateRentRequestScreen());
          default:
            return MaterialPageRoute(builder: (context) => const WelcomeScreen());
        }
      },
    );
  }
}
