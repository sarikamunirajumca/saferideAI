import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:saferide_ai_app/screens/login_screen.dart';
import 'package:saferide_ai_app/screens/multi_user_admin_dashboard.dart';
import 'package:saferide_ai_app/screens/detection_screen_auto.dart';
import 'package:saferide_ai_app/screens/analytics_screen.dart';
import 'package:saferide_ai_app/screens/profile_management_screen.dart';
import 'package:saferide_ai_app/screens/emergency_screen.dart';
import 'package:saferide_ai_app/services/camera_service.dart';
import 'package:saferide_ai_app/services/detection_service.dart';
import 'package:saferide_ai_app/utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CameraService()),
        ChangeNotifierProvider(create: (_) => DetectionService()),
      ],
      child: MaterialApp(
        title: 'SafeRide AI',
        debugShowCheckedModeBanner: false,
        theme: _buildLightTheme(),
        darkTheme: _buildDarkTheme(),
        themeMode: ThemeMode.dark,
        initialRoute: '/login',
        routes: {
          '/login': (context) => const LoginScreen(),
          '/admin_dashboard': (context) => const MultiUserAdminDashboard(),
          '/detection': (context) => const DetectionScreenAuto(),
          '/analytics': (context) => const AnalyticsScreen(),
          '/profiles': (context) => const ProfileManagementScreen(),
          '/emergency': (context) => const EmergencyScreen(),
        },
      ),
    );
  }
  
  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppConstants.primaryColor,
      scaffoldBackgroundColor: AppConstants.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: AppConstants.primaryColor,
        secondary: AppConstants.successColor,
        surface: AppConstants.surfaceDark,
        background: AppConstants.backgroundDark,
        error: AppConstants.dangerColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppConstants.textPrimary,
        onBackground: AppConstants.textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppConstants.surfaceDark,
        foregroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24.0,
            vertical: 16.0,
          ),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppConstants.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: AppConstants.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: TextStyle(
          color: AppConstants.textPrimary,
        ),
        bodyMedium: TextStyle(
          color: AppConstants.textSecondary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppConstants.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
          side: BorderSide(
            color: AppConstants.borderColor.withOpacity(0.2),
            width: 1.0,
          ),
        ),
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
  
  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppConstants.primaryColor,
      colorScheme: const ColorScheme.light(
        primary: AppConstants.primaryColor,
        secondary: AppConstants.successColor,
        error: AppConstants.dangerColor,
      ),
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}
