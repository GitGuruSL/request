import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:request_marketplace/src/routes/routes.dart';
import 'package:request_marketplace/src/theme/app_theme.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Preserve the splash screen while we initialize
  FlutterNativeSplash.preserve(widgetsBinding: WidgetsFlutterBinding.ensureInitialized());
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
    
    // Small delay to ensure proper splash screen display
    await Future.delayed(const Duration(seconds: 1));
    
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
    // Re-throw error if Firebase initialization fails
    rethrow;
  } finally {
    // Remove splash screen once initialization is complete
    FlutterNativeSplash.remove();
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Request',
      theme: AppTheme.lightTheme,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      initialRoute: AppRoutes.welcome,
    );
  }
}
