import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

/// Authentication Provider
/// 
/// Manages user authentication state throughout the application using
/// Provider pattern. Handles login, registration, logout, and persistent
/// authentication state using SharedPreferences.
/// 
/// This provider notifies listeners when authentication state changes,
/// allowing UI components to react to login/logout events.
class AuthProvider extends ChangeNotifier {
  /// Current authenticated user, null if no user is logged in
  User? _currentUser;
  
  /// Authentication status flag
  bool _isAuthenticated = false;

  /// Getter for current user
  /// 
  /// Returns the currently authenticated user or null if no user is logged in
  User? get currentUser => _currentUser;
  
  /// Getter for authentication status
  /// 
  /// Returns true if a user is currently authenticated, false otherwise
  bool get isAuthenticated => _isAuthenticated;

  /// Constructor
  /// 
  /// Initializes the authentication provider and checks for existing
  /// authentication state from SharedPreferences
  AuthProvider() {
    _checkAuthStatus();
  }

  /// Check Authentication Status
  /// 
  /// Verifies if a user session exists in persistent storage (SharedPreferences)
  /// and restores the authentication state if a valid user ID is found.
  /// 
  /// This is called automatically during provider initialization to maintain
  /// user sessions across app restarts.
  /// 
  /// 
  /// Future is a promise or IOU note from Dart that says:
  // "I don't have the answer right now, but I PROMISE I'll get it for you later.
  // Future<void> is SPECIAL - it means "I'll finish later but WON'T return data"

  Future<void> _checkAuthStatus() async {
    // . SharedPreferences IS an object (class instance)
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (userId != null) {
      try {
        // Attempt to fetch user data from API using stored user ID
        _currentUser = await ApiService.getUser(int.parse(userId));
        _isAuthenticated = true;
        notifyListeners();
        //tell us that these vars changed
      } catch (e) {
        // If user fetch fails, clear invalid authentication state
        logout();
      }
    }
  }

  /// Register New User
  /// 
  /// Creates a new user account and automatically logs them in upon success.
  /// 
  /// @param username - Desired username for the new account
  /// @param email - User's email address (used for login)
  /// @param password - User's password (should be securely hashed server-side)
  /// 
  /// @throws Exception if registration fails (e.g., duplicate email, invalid data)
  /// 
  /// @example
  /// ```dart
  /// await authProvider.register(
  ///   username: 'gamer123',
  ///   email: 'user@example.com',
  ///   password: 'securePassword123',
  /// );
  /// ```
  Future<void> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      // Call API to register new user
      final result = await ApiService.register(
        username: username,
        email: email,
        password: password,
      );
      
      // Store user ID in persistent storage for session persistence
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', result['user']['id'].toString());
      
      // Update authentication state
      _currentUser = User.fromJson(result['user']);
      _isAuthenticated = true;
      
      // Notify all listeners (UI components) of state change
      notifyListeners();
    } catch (e) {
      // Re-throw exception for error handling in UI layer
      rethrow;
    }
  }

  /// Login Existing User
  /// 
  /// Authenticates a user with email and password, then updates the
  /// authentication state and persists the session.
  /// 
  /// @param email - User's registered email address
  /// @param password - User's password
  /// 
  /// @throws Exception if login fails (e.g., invalid credentials, network error)
  /// 
  /// @example
  /// ```dart
  /// await authProvider.login(
  ///   email: 'user@example.com',
  ///   password: 'securePassword123',
  /// );
  /// ```
  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      // Call API to authenticate user
      final result = await ApiService.login(email: email, password: password);
      
      // Update user data from API response
      _currentUser = User.fromJson(result['user']);
      _isAuthenticated = true;
      
      // Store user ID for session persistence
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', result['user']['id'].toString());
      
      // Notify all listeners (UI components) of successful login
      notifyListeners();
    } catch (e) {
      // Re-throw exception for error handling in UI layer
      rethrow;
    }
  }

  /// Logout Current User
  /// 
  /// Clears the current authentication state, removes stored user data,
  /// and resets the provider to unauthenticated state.
  /// 
  /// This method should be called when:
  /// - User explicitly logs out
  /// - Session expires
  /// - Invalid authentication state is detected
  /// 
  /// @example
  /// ```dart
  /// await authProvider.logout();
  /// // Redirect to login screen
  /// ```
  Future<void> logout() async {
    // Remove user ID from persistent storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    
    // Clear authentication state
    _currentUser = null;
    _isAuthenticated = false;
    
    // Notify all listeners (UI components) of logout
    notifyListeners();
  }
}