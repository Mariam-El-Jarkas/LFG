import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/session_screens.dart';
import 'screens/profile_screen.dart';

/// LFG Connect - Gaming Session & Friend Management Application
/// 
/// Main entry point for the application. Sets up dependency injection,
/// theming, and routing configuration for the entire app.
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}

/// The root widget of the LFG Connect application.
/// 
/// Configures the MaterialApp with:
/// - Application theme and styling
/// - Authentication state management via Provider
/// - Route definitions and navigation
/// - Global application settings
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Application title shown in task manager/device app switcher
      title: 'LFG Connect',
      
      // Hide debug banner in release builds
      debugShowCheckedModeBanner: false,
      
      // Application theme configuration
      theme: ThemeData(
        // Primary brand color (purple)
        primaryColor: const Color(0xFF6C63FF),
        
        // Color scheme for consistent theming
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF6C63FF),      // Primary purple
          secondary: const Color(0xFFFF6584),    // Secondary pink
          background: const Color(0xFFF5F7FF),   // Light background
        ),
        
        // Scaffold background color
        scaffoldBackgroundColor: const Color(0xFFF5F7FF),
        
        // AppBar theming
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF6C63FF),  // Purple background
          foregroundColor: Colors.white,       // White text/icons
          elevation: 4,                        // Subtle shadow
        ),
        
        // Elevated button theming
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),  // Purple background
            foregroundColor: Colors.white,             // White text
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Rounded corners
            ),
          ),
        ),
        
        // Input field theming
        inputDecorationTheme: InputDecorationTheme(
          filled: true,                          // Filled background
          fillColor: Colors.white,               // White fill
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),  // Rounded corners
            borderSide: BorderSide.none,         // No border
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF6C63FF),          // Purple border on focus
              width: 2,
            ),
          ),
        ),
        
        // Use Material 2 design system (not Material 3)
        useMaterial3: false,
      ),
      
      // Home screen based on authentication state
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          // If authenticated, show dashboard; otherwise show login screen
          return authProvider.isAuthenticated ? DashboardScreen() : LoginScreen();
        },
      ),
      
      // Named route definitions for navigation
      routes: {
        '/login': (context) =>  LoginScreen(),              // Login screen
        '/dashboard': (context) =>  DashboardScreen(),      // Main dashboard
        '/create-session': (context) =>  SessionCreateScreen(), // Create session
        '/profile': (context) =>  ProfileScreen(),          // User profile
      },
      
      // Dynamic route generation for routes that require parameters
      onGenerateRoute: (settings) {
        // Handle session detail route with session ID parameter
        if (settings.name == '/session-detail') {
          // Extract session ID from route arguments
          final sessionId = settings.arguments as int;
          return MaterialPageRoute(
            builder: (context) => SessionDetailScreen(sessionId: sessionId),
          );
        }
        
        // Return null for unknown routes (will show 404)
        return null;
      },
    );
  }
}